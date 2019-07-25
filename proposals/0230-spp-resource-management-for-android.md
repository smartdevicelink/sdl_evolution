# SPP resource management for Android

* Proposal: [SDL-0230](0230-spp-resource-management-for-android.md)
* Author: [Shinichi Watanabe](https://github.com/shiniwat)
* Status: **Accepted with Revisions**
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
All we can do in this case is notify users that SPP channel runs out of available resources, and let users close some apps that may use the BluetoothSocket. It's not practical to show SPP service records that are used by Bluetooth adapter. The proposed approach is to notify users that we're running out of resources, and gives more information if needed (though this proposal does not include the giving more information part).

Prior to detecting the error, Bundle parameter should be added to ```setState``` in MultiplexBaseTransport class, so that ```setState``` can send the extra information to the target RouterService:
```java
    public static final String ERROR_REASON_KEY = "ERROR_REASON";
    public static final byte REASON_SPP_ERROR   = 0x01;    // REASON_SPP_ERROR will be sent as value in message bundle
    public static final byte REASON_NONE        = 0x0;

    protected synchronized void setState(int state, Bundle bundle) {
        if(state == mState){
            return; //State hasn't changed. Will not update listeners.
        }
        int arg2 = mState;
        mState = state;

        // Give the new state to the Handler so the UI Activity can update
        // Also send the previous state so we know if we lost a connection
        Message msg = handler.obtainMessage(SdlRouterService.MESSAGE_STATE_CHANGE, state, arg2, getTransportRecord());
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
        if (stateToTransitionTo == MultiplexBaseTransport.STATE_ERROR) {
            Bundle bundle = new Bundle();
            bundle.putByte(ERROR_REASON_KEY, error);
            setState(stateToTransitionTo, bundle);
        } else {
	        setState(stateToTransitionTo, null);
        }
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

onTransportError in SdlRouterService should take Bundle parameter, and notify the error information if needed:
```java
    @Deprecated
    public void onTransportError(TransportType transportType){
        onTransportError(new TransportRecord(transportType,null), null);
    }

    @Deprecated
    public void onTransportError(TransportRecord record) {
        onTransportError(record, null);
    }

    public void onTransportError(TransportRecord transport, Bundle errorBundle){
        switch (transport.getType()){
            case BLUETOOTH:
                if(bluetoothTransport !=null){
                    bluetoothTransport.setStateManually(MultiplexBluetoothTransport.STATE_NONE);
                    bluetoothTransport = null;
                }
                if (errorBundle != null && errorBundle.getByte(MultiplexBaseTransport.ERROR_REASON_KEY) == MultiplexBaseTransport.REASON_SPP_ERROR) {
                    notifySppError();
                }
                break;
            case USB:
                break;
            case TCP:
                break;
        }
    }
```

When TransportHandler in SdlRouterService detects STATE_ERROR, the error information should be put into onTransportError:
```java
	private static class TransportHandler extends Handler{
	    @Override
	    public void handleMessage(Message msg) {
	        case MESSAGE_STATE_CHANGE:
	            TransportRecord transportRecord = (TransportRecord) msg.obj;
	            switch (msg.arg1) {
	        	....
                case MultiplexBaseTransport.STATE_ERROR:
                    service.onTransportError(transportRecord, msg.getData());
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
	private void notifySppError() {
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

		// Note: we won't use pending intent at this moment as the result of discussion at SDLC.
		...
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

And the channel ("SDL Error") should be configured like below:

![manage notification category setting](../assets/proposals/0230-spp-resource-management-for-android/manage_notification_2.png)

**Fig. 3: Manage notification category setting**

All strings used for this error UX is defined in strings.xml like below:

```java
    <string name="spp_out_of_resource">Too many apps are using Bluetooth</string>
    <string name="notification_title">SmartDeviceLink</string>
    <string name="sdl_error_notification_channel_name">SDL Error</string>
```

The English strings above have been reviewed, and accepted by SDLC steering committee.

### Localization of SPP error UX

Because all strings used for error UX are defined in strings.xml, the standard localization process for Android can be applied; i.e. adding language specific strings.xml per language.
All language enums of [Mobile_API](https://github.com/smartdevicelink/sdl_core/blob/master/src/components/interfaces/MOBILE_API.xml#L167) are assumed as the supported languages. They are:

ar_SA, cs_CZ, da_DK, de_DE, el_GR, en_AU, en_GB, en_IN, en_SA, en_US, es_ES, es_MX, fi_FI, fr_CA, fr_FR, he_IL, hi_IN, hu_HU, id_ID, it_IT, ja_JP, ko_KR, ms_MY, no_NO, pl_PL, pt_BR, pt_PT, ro_RO, ru_RU, sk_SK, sv_SE, th_TH, tr_TR, uk_UA, vi_VN, zh_TW, zh_CN

The default language would be en_US.

Regarding who is responsible for the localization process, two steps are proposed:
1. English strings (which is default language) must be properly reviewed by SDLC steering committee.
2. Localized strings have to be reviewed by SDLC steering committee too, but the localization review will be made in another review process (e.g. as the PR for the upcoming sdl_java_suite issue).

## Potential downsides

In Fig. 3 (Manage notification category setting), if user changed the behavior to "No sound", user won't notice anything even if SPP error occurred. This seems to be a potential issue, but it is up to the user's configuration.
On the other hand, we should be very aware of the fact that SDL proxy notifies error with sound and/or vibration when SPP error occurs.

## Impact on existing code

There's no impact to existing code, because all error UX is provided by Proxy. Developers do not have to implement the error UX at all.

## Alternatives considered

Does sdl_java_suite library need to have all localized strings? This question is raised because the supported languages can be varied on the app. As the result of some discussion, steering committee will be responsible for all localized strings.
