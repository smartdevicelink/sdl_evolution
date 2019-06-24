# SPP resource management for Android

* Proposal: [SDL-0230](0230-spp-resource-management-for-android.md)
* Author: [Shinichi Watanabe](https://github.com/shiniwat)
* Status: **Returned for Revisions**
* Impacted Platforms: Java Suite

## Introduction

RFCOMM is a connection-oriented, streaming transport over Bluetooth, which is known as Serial Port Profile (SPP) in Android. 
SDL Proxy uses BluetoothServerSocket to listen on a SPP channel, and it is used for primary transport.
On an Android device, the number of SPP resources is limited, and BluetoothServerSocket fails to accept connections when SPP channel runs out of available resources.
Current SDL Proxy does not handle that case very well. This proposal is to improve the SPP resource management in SDL Android.

## Motivation

When SPP resources are exhausted, the SDL app cannot communicate with head unit. Right now, that error is not notified to the app and a user has no way to figure out why connection fails.
This proposal focuses on the case where Proxy detects the SPP resource error, and let users know what happened and suggests possible work around.


## Proposed solution

### Detect the case where BluetoothServerSocket fails to accept a connection from head unit. 
Even though we could detect the case, we cannot increase the number of available SPP resources, because they are used by other apps.
All we can do in this case is notify users that SPP channel runs out of available resources, and let users close some apps that may use the BluetoothSocket. It's not practical to show SPP service records that are used by Bluetooth adapter. The proposed approach is to notify users that we're running out of resources, and gives more information when user wants to.

Prior to detecting the error, ```setState``` and ```notifyStateChanged``` in MultiplexBaseTransport class need to be extended, so that they can notify an error:
```java
    public static final String ERROR_REASON_KEY = "ERROR_REASON";
    public static final byte REASON_SPP_ERROR   = 0x01;    // REASON = SPP error, which is sent through Message.arg2.
    public static final byte REASON_NONE        = 0x0;

    protected synchronized void setState(int state, byte error) {
        if(state == mState){
            return; //State hasn't changed. Will not updated listeners.
        }
        int arg2 = mState;
        mState = state;

        // Give the new state to the Handler so the UI Activity can update
        //Also sending the previous state so we know if we lost a connection
        notifyStateChanged(state, arg2, error);
    }

    private void notifyStateChanged(int arg1, int arg2, byte error) {
        Message msg = handler.obtainMessage(SdlRouterService.MESSAGE_STATE_CHANGE, arg1, arg2, getTransportRecord());
        Bundle bundle = new Bundle();
        bundle.putByte(ERROR_REASON_KEY, error);
        msg.setData(bundle);
        msg.sendToTarget();
    }
```

In MultiplexBluetoothTransport, stop method needs to be extended, so that the error information is passed to setState:
```java
    @Override
    protected synchronized void stop(int stateToTransitionTo, byte error) {
    	super.stop(stateToTransitionTo, error);
    	
    	...
        setState(stateToTransitionTo, error);
    }
```

The stop method gets called when server socket's accept failed:
```java

    try {
        ...
        socket = mServerSocket.accept();
    } catch(IOException e) {
        MultiplexBluetoothTransport.this.stop(STATE_ERROR, REASON_SPP_ERROR);
        return;
    }
```

When TransportHandler in SdlRouterService detected STATE_ERROR, notifies it to user:
```java
	private static class TransportHandler extends Handler{
	    @Override
	    public void handleMessage(Message msg) {
	        case MESSAGE_STATE_CHANGE:
	            TransportRecord transportRecord = (TransportRecord) msg.obj;
	            switch (msg.arg1) {
	        	....
                case MultiplexBaseTransport.STATE_ERROR:
                    service.onTransportError(transportRecord);
                    Bundle reason = msg.getData();
                    if (reason != null && reason.getByte(MultiplexBaseTransport.ERROR_REASON_KEY) == MultiplexBaseTransport.REASON_SPP_ERROR) {
                        service.notifySppError();
                    }
                    break;
                }
	    }
	}
```

notifySppError() method looks like below:
```java
	/**
	 * notifySppError: utilize notification channel to notify the SPP out-of-resource error.
	 */
	@TargetApi(11)
	public void notifySppError() {
		Notification.Builder builder;
		if(android.os.Build.VERSION.SDK_INT < Build.VERSION_CODES.O){
			builder = new Notification.Builder(getApplicationContext());
		} else {
			builder = new Notification.Builder(getApplicationContext(), TransportConstants.SDL_ERROR_NOTIFICATION_CHANNEL_ID);
		}

		builder.setContentTitle(getString(R.string.notification_title));
		builder.setTicker(getString(R.string.sdl_error_notification_channel_name));
		builder.setContentText(getString(R.string.spp_out_of_resource));

		//We should use icon from library resources if available
		int trayId = getResources().getIdentifier("sdl_tray_icon", "drawable", getPackageName());

		builder.setSmallIcon(trayId);
		Bitmap icon = BitmapFactory.decodeResource(getResources(), R.drawable.ic_sdl_error); // use another icon for error notification
		builder.setLargeIcon(icon);

		// Create an intent that will be fired when the user clicks the notification.
		// user apps can override getErrorNotificationIntent, to provide the custom UX when user clicks on the notification.
		Intent intent = getErrorNotificationIntent(MultiplexBaseTransport.REASON_SPP_ERROR);
		if (intent == null) {
			// use Webpage by default
			intent = new Intent(Intent.ACTION_VIEW, Uri.parse(SDL_SPP_ERROR_WEB_PAGE + "?lang=" + Locale.getDefault().getDisplayLanguage()));
		}
		PendingIntent pendingIntent = PendingIntent.getActivity(this, 0, intent, 0);
		builder.setContentIntent(pendingIntent);
		builder.setOngoing(false);

		final String tag = "SDL";
		//Now we need to add a notification channel
		final NotificationManager notificationManager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
		if (notificationManager != null) {
			notificationManager.cancel(tag, TransportConstants.SDL_ERROR_NOTIFICATION_CHANNEL_ID_INT);
			if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
				NotificationChannel notificationChannel = new NotificationChannel(TransportConstants.SDL_ERROR_NOTIFICATION_CHANNEL_ID, getString(R.string.sdl_error_notification_channel_name), NotificationManager.IMPORTANCE_HIGH);
				notificationChannel.enableLights(true);
				notificationChannel.enableVibration(true);
				notificationChannel.setShowBadge(false);
				notificationManager.createNotificationChannel(notificationChannel);
				builder.setChannelId(notificationChannel.getId());
			}
			Notification notification = builder.build();
			notificationManager.notify(tag, TransportConstants.SDL_ERROR_NOTIFICATION_CHANNEL_ID_INT, notification);
		} else {
			Log.e(TAG, "notifySppError: Unable to retrieve notification Manager service");
		}
	}
```

**Code-1: code snippet of notifySppError method**

When notifySppError gets called, the notification is shown like below:

![spp error notification popup](../assets/proposals/0230-spp-resource-management-for-android/spp_notification_popup.png)

**Fig. 1: Notification popup is shown when SPP resource error is detected**

### Expected settings for the notification channel

When SPP resource error is detected, notification is expected to be shown as popup. For this reason, we need another notification channel in addition to existing SDL notification channel, which is used when SdlRouterService enters foreground.
This is why Code-1 above uses different channel ID (SDL_ERROR_NOTIFICATION_CHANNEL_ID), and different setting of channel importance flag (IMPORTANCE_HIGH)

When user opens "manage notifications", the app's notification setting will be shown below:

![manage notification setting](../assets/proposals/0230-spp-resource-management-for-android/manage_notification_1.png)

**Fig. 2: Manage notifications setting**

Please note that channel name ("SDL Error" in Fig. 2) is TBD.

And the channel ("SDL Error") should be configured like below:

![manage notification category setting](../assets/proposals/0230-spp-resource-management-for-android/manage_notification_2.png)


**Fig. 3: Manage notification category setting**

### When user clicks on notification popup

In previous code snippet (Code-1), we get the Intent from getErrorNotificationIntent method, which can be overridden in user's app:

```java
	/**
	 * This method can be overridden by developer in their own SdlRouterService class.
	 * @param error
	 * @return
	 */
	public Intent getErrorNotificationIntent(int error) {
		return null;
	}
```

By default (i.e. if developer does NOT override getErrorNotificationIntent), library will lead users to WebPage, which explains what happened.
The details of error text on the WebPage is still TBD. In addition to the Webpage, sdl_java_suite library is expected to include the error activity to provide the consistent and localized error UX.

The sample UX of SdlNotificationActivity looks like below:

![SdlNotificationActivity UX](../assets/proposals/0230-spp-resource-management-for-android/spp_error_activity.png)

All strings used for this error UX is defined in strings.xml like below:

```java
    <string name="spp_out_of_resource">Too many apps are using Bluetooth</string>
    <string name="notification_title">SmartDeviceLink</string>
    <string name="spp_out_of_resource_message">There are too many bluetooth apps running on your device. Please close some of them and try to re-connect</string>
    <string name="spp_out_of_resource_possible_apps">Following apps may use Bluetooth: </string>
    <string name="button_ok">OK</string>
    <string name="sdl_error_notification_channel_name">SDL Error</string>
```

The strings above are TBD (requires review).

### Localization of SPP error UX

Because all strings used for error UX are defined in strings.xml, the standard localization process for Android can be applied; i.e. adding language specific strings.xml per language.
All language enums of [Mobile_API](https://github.com/smartdevicelink/sdl_core/blob/master/src/components/interfaces/MOBILE_API.xml#L167) are assumed as the supported languages. They are:

ar_SA, cs_CZ, da_DK, de_DE, el_GR, en_AU, en_GB, en_IN, en_SA, en_US, es_ES, es_MX, fi_FI, fr_CA, fr_FR, he_IL, hi_IN, hu_HU, id_ID, it_IT, ja_JP, ko_KR, ms_MY, no_NO, pl_PL, pt_BR, pt_PT, ro_RO, ru_RU, sk_SK, sv_SE, th_TH, tr_TR, uk_UA, vi_VN, zh_TW, zh_CN

The default language would be en_US.

Regarding who is responsible for the localization process, two steps are proposed:
1. English strings (which is default language) must be properly reviewed and maintained by steering committee.
2. Localized strings are maintained by project maintainer, and steering committee will be responsible for sign off those localized strings.  

### Listing application that uses Bluetooth

When SPP resource error is detected, if we can narrow down the apps that actually uses the Bluetooth socket, that will be helpful for users to get recovered. Unfortunately, it is not realistic to identify exactly what apps are using Bluetooth. We can, however, list up applications that requests bluetooth permission, something like below:

```java
	public static List<ApplicationInfo> checkBluetoothApps(Context context) {
		PackageManager pm = context.getPackageManager();
		List<ApplicationInfo> packages = pm.getInstalledApplications(PackageManager.GET_META_DATA);
		List<ApplicationInfo> bluetoothApps = new ArrayList<>();

		// also get SdlPackages
		HashMap<String, ResolveInfo> sdlApps = AndroidTools.getSdlEnabledApps(context, null);

		for (ApplicationInfo applicationInfo : packages) {
			//   let's take a look at non-SDL apps only
			if (sdlApps.containsKey(applicationInfo.packageName)) {
				Log.d(TAG, "skip SDL App: " + applicationInfo.packageName);
			} else {
				try {
					PackageInfo packageInfo = pm.getPackageInfo(applicationInfo.packageName, PackageManager.GET_PERMISSIONS);

					//Get Permissions
					String[] requestedPermissions = packageInfo.requestedPermissions;
					boolean usesBluetooth = false;
					if (requestedPermissions != null) {
						for (int i = 0; i < requestedPermissions.length; i++) {
							if (Manifest.permission.BLUETOOTH.equalsIgnoreCase(requestedPermissions[i])
									|| Manifest.permission.BLUETOOTH_ADMIN.equalsIgnoreCase(requestedPermissions[i])) {
								usesBluetooth = true;
								break;
							}

						}
					}
					if (usesBluetooth) {
						if ((applicationInfo.flags & ApplicationInfo.FLAG_SYSTEM) != 0) {
							Log.i(TAG, "checkBluetoothPermissions: exclude system app: " + applicationInfo.packageName);
						} else {
							bluetoothApps.add(applicationInfo);
							CharSequence appName = pm.getApplicationLabel(applicationInfo);
							if (appName != null) {
								Log.i(TAG, "checkBluetoothPermissions: " + appName + " uses bluetooth");
							} else {
								Log.i(TAG, "checkBluetoothPermissions: null uses bluetooth");
							}
						}
					}
				} catch (PackageManager.NameNotFoundException e) {
					e.printStackTrace();
				}
			}
		}
		return bluetoothApps;
	}
```

Showing the list to the user will be optional (at least developers can choose), because we may need to determine if it is worth doing or not.

## Potential downsides

In Fig. 3 (Manage notification category setting), if user changed the behavior to "No sound", user won't notice anything even if SPP error occurred. This seems to be a potential issue, but it is up to the user's configuration.


## Impact on existing code

There's no impact to existing code, because all error UX is provided by Proxy. Developers do not have to implement the error UX at all.

## Alternatives considered

Does sdl_java_suite library need to have all localized strings? This question is raised because the supported languages can be varied on the app. As the result of some discussion, steering committee will be responsible for all localized strings.
