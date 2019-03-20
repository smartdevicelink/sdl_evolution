# Support for Android custom RouterService
* Proposal: [SDL-0220](0220-support-for-android-custom-routerservice.md)
* Author: [Shinichi Watanabe](https://github.com/shiniwat)
* Status: **Returned for Revisions**
* Impacted Platforms: Android

## Introduction
This proposal is to improve the case where SDL applications need to work with the custom RouterService. The definition of custom RouterService varies, but this proposal refers to the case where a head unit requires an OEM-specific app to work as a RouterService.
For instance, if the OEM uses a specific Bluetooth server UUID that differs from SDL standard ones, that should be a custom RouterService.

## Motivation

Currently, AndroidManifest.xml can indicate the application has a custom RouterService, similar to the example below:
```java
    <service
        android:name=".SdlRouterService"
        android:enabled="true"
        android:exported="true"
        android:process="com.smartdevicelink.router">
        <intent-filter>
            <action android:name="com.smartdevicelink.router.service" />
        </intent-filter>
        <meta-data android:name="sdl_custom_router" android:value="true" />
        <meta-data android:name="sdl_router_version" android:value="@integer/sdl_router_service_version_value" />
    </service>
```

When a SDL application determines which RouterService to bind with, the app creates a list of SDL enabled apps, and checks to see if a RouterService transport connects with the head unit.
If a custom RouterService is already connected with a head unit, and if a SDL application can identify the RouterService correctly, then the app should work fine. However, if not, the application instantiates "possibly the best" RouterService. In this case, the custom RouterService is less likely chosen, because the custom RouterService has lower priority than the non-custom RouterService.
If the custom RouterService is the only RouterService that connects with OEM-specific head unit, and the custom RouterService does not connect, the SDL app is unlikely to find the custom RouterService; which means it is unlikely to register with SDL Core.
This proposal is to improve the connectivity for custom RouterService to work with OEM-specific head units.

### Current logic for finding RouterService

Currently SdlProxy identifies the RouterService in three steps:

1. SdlBroadcastReceiver class has a public method called queryForConnectedService, which finds the RouterService whose primary transport connects with SDL Core. This step also verifies if the RouterService is trusted or not.
    -  Internally, this binds with the RouterService one by one and asks if its primary transport has a connection with the head unit. So it takes some time, and the cost depends on how many SDL apps exist in the device.
2. If the step#1 fails, then SdlProxy wakes up the best possible RouterService.
    -  Internally, SdlProxy has priority order, the latest (which means having the newest version) non-custom RouteService has the priority.
3. Before the app binds with the RouterService, it verifies that the RouterService is the trusted one. If not, then the app falls back to legacy Bluetooth mode.

The problem is that custom RouterService is unlikely chosen in step #2.
Step #1 actually depends on the timing of when the app calls queryForConnectedService. It is up to the application when queryForConnectedService is called, but [the integration-basic document](https://smartdevicelink.com/en/guides/android/getting-started/integration-basics/) suggests it should be called at Main Activities onCreate.

## Proposed solution

Suppose a custom RouterService is basically designed for OEM-specific head units, and the head unit only works with that specific custom RouterService.
The current logic in the previous section does not work very well in this scenario, because it heavily depends on the timing of when the app calls SdlBroadcastReceiver.queryForConnectedService.
To improve the connectivity of custom RouterService, the approach would be:

1. Do not rely on the user app to call queryForConnectedService; instead, SdlProxy should automatically check to see if the RouterService connects with SDL Core whenever needed.

2. Custom RouterService cannot rely on other apps to be woken up, because of its priority order. Instead, it needs to start RouterService on its own.

3. We can reuse the existing logic that verifies the trusted RouterService. If a RouterService is not trusted, SdlProxy can wake up the best possible RouterService in the same way the current proxy does. 

In approach #1, the important point is the location where the RouterService's primary transport connects with the head unit. It should be in the RouterServiceValidator class.

### RouterServiceValidator should pay attention to currently connected RouterService.

The expected time to check if a RouterService connects with head unit would be right before the app binds with the RouterService - this should be done automatically without relying on user application.
The proposed solution is to add new asynchronous method to RouterServiceValidator, and call it right before the TransportManager connects to the RouterService.

#### Detailed design of asynchronous method
The pseudo-code of new asynchronous methos in RouterServiceValidator looks like this:
```java
	public void validateAsync(final ValidationStatusCallback callback) {
		if(securityLevel == -1){
			securityLevel = getSecurityLevel(context);
		}

		if(securityLevel == MultiplexTransportConfig.FLAG_MULTI_SECURITY_OFF){ //If security isn't an issue, just return true;
			if (callback != null) {
				callback.onFinishedValidation(true, null);
			}
		}

		final PackageManager pm = context.getPackageManager();

		if(this.service != null){
			if(Build.VERSION.SDK_INT < Build.VERSION_CODES.O && !isServiceRunning(context,this.service)){
				//This means our service isn't actually running, so set to null. Hopefully we can find a real router service after this.
				service = null;
				Log.w(TAG, "Supplied service is not actually running.");
			} else {
				// If the running router service is created by this app, the validation is good by default
				if (this.service.getPackageName().equals(context.getPackageName()) && callback != null) {
					callback.onFinishedValidation(true, this.service);
					return;
				}
			}
		}

		if(this.service == null){
			// retrieveBestRouterServiceName works asynchronous, and calls FindConnectedRouterCallback when it finished to find
			retrieveBestRouterServiceNameAsync(this.context, new FindConnectedRouterCallback() {
				@Override
				public void onFound(ComponentName component) {
					service = component;
					Log.d(TAG, "FindConnectedRouterCallback.onFound got called. Package=" + component);
					checkTrustedRouter(callback, pm);
				}

				@Override
				public void onFailed() {
					Log.d(TAG, "FindConnectedRouterCallback.onFailed was called");
					if (callback != null) {
						callback.onFinishedValidation(false, null);
					}
					// @REVIEW: do we need this??
					//wakeUpRouterServices();
				}
			});
		} else {
			// already found the RouterService
			checkTrustedRouter(callback, pm);
		}
	}
```

ValidationStatusCallback interface and FindConnectedRouterCallback looks as follows:
```java
	public interface ValidationStatusCallback {
		public void onFinishedValidation(boolean valid, ComponentName name);
	}

	private interface FindConnectedRouterCallback {
		void onFound(ComponentName component);
		void onFailed();
	}

```

retrieveBestRouterServiceNameAsync uses AsyncTask, and look something like below:
```java
	private void retrieveBestRouterServiceNameAsync(Context context, FindConnectedRouterCallback callback) {
		new FindRouterTask(callback).execute(context;
	}
```

The pseudo-code of FindRouterTask will be:
```java
	class FindRouterTask extends AsyncTask<Context, Void, ComponentName> {
		FindConnectedRouterCallback mCallback;

		FindRouterTask(FindConnectedRouterCallback callback) {
			mCallback = callback;
		}

		@Override
		protected ComponentName doInBackground(final Context... contexts) {
			if (RouterServiceValidator.this.service != null) {
				return RouterServiceValidator.this.service;
			}
			List<SdlAppInfo> sdlAppInfoList = AndroidTools.querySdlAppInfo(contexts[0], new SdlAppInfo.BestRouterComparator());
			if (sdlAppInfoList != null && !sdlAppInfoList.isEmpty()) {
				SdlAppInfo lastItem = sdlAppInfoList.get(sdlAppInfoList.size()-1);
				for (SdlAppInfo info: sdlAppInfoList) {
					final boolean isLast = (info.equals(lastItem));
					ComponentName name = info.getRouterServiceComponentName();
					final SdlRouterStatusProvider provider = new SdlRouterStatusProvider(contexts[0], name, new SdlRouterStatusProvider.ConnectedStatusCallback() {
						@Override
						public void onConnectionStatusUpdate(boolean connected, ComponentName service, Context context) {
							if (connected) {
								if (mCallback != null) {
									RouterServiceValidator.this.service = service;
									mCallback.onFound(service);
								}
							} else {
								Log.d(TAG, "SdlRouterStatusProvider returns service=" + service + "; connected=" + connected);
								if (isLast && mCallback != null && RouterServiceValidator.this.service == null) {
									mCallback.onFailed();
								}
							}
						}
					});
					provider.checkIsConnected();
					provider.cancel();
				}
			}
			return null;
		}

		@Override
		protected void onPostExecute(ComponentName componentName) {
			super.onPostExecute(componentName);
			if (componentName != null && mCallback != null) {
				mCallback.onFound(componentName);
			}
		}

	}
```

#### The caller of the asynchronous method
The validateAsync is expected to be called in TransportManager, something like this:

```java
    public TransportManager(final MultiplexTransportConfig config, TransportEventListener listener, final boolean autoStart){

        this.transportListener = listener;
        this.TRANSPORT_STATUS_LOCK = new Object();
        synchronized (TRANSPORT_STATUS_LOCK){
            this.transportStatus = new ArrayList<>();
        }

        if(config.service == null) {
            config.service = SdlBroadcastReceiver.consumeQueuedRouterService();
        }

        contextWeakReference = new WeakReference<>(config.context);

        final RouterServiceValidator validator = new RouterServiceValidator(config);
        validator.validateAsync(new RouterServiceValidator.ValidationStatusCallback() {
            @Override
            public void onFinishedValidation(boolean valid, ComponentName name) {
                if (valid) {
                    if (config.service == null) {
                        config.service = name;
                    }
                    transport = new TransportBrokerImpl(contextWeakReference, config.appId, config.service);
                    // because this callback works asynchrnous, we have to call TransportManager.start here.
                    transport.start();
                } else {
                    enterLegacyMode("Router service is not trusted. Entering legacy mode");
                }
            }
        });
    }

```

#### Using cache for saving cost to find the connected RouterService.
When the app finds the connected RouterService, it might be better to cache the service name on somewhere, e.g. SharedPreferences, so that it won't bother the other app's RouterService too often.

### If an app contains custom RouterService, it must start by itself
Because the custom RouterService cannot rely on other apps to be woken up, it must start RouterService whenever needed.
The pseudo-code in SdlBroadcastReceiver class looks like this:

```java
    @Override
    public void onReceive(Context context, Intent intent) {
        ...
        if(action.equalsIgnoreCase(TransportConstants.START_ROUTER_SERVICE_ACTION)){
            ... // snip
            // if we need to wake up RotuerService, first check to see if we have the custom RouterService.
            try {
                ApplicationInfo appInfo = context.getPackageManager().getApplicationInfo(context.getPackageName(), PackageManager.GET_META_DATA);
                if (appInfo.metaData != null) {
                    boolean isCustom = appInfo.metaData.getBoolean(context.getString(R.string.sdl_router_service_is_custom_name);
                    if (isCustom) {
                        // then startService myself.
                        Intent serviceIntent = new Intent(context, SdlRouterService.class);
                        context.startService(serviceIntent);
                    }
                }
            } catch(PackageManager.NameNotFoundException e) {}
        }
    }
```

## Potential downsides

- The proposed solution will use SdlRouterStatusProvider, which actually binds to other app's RouterService and asks if the RouterService has connected transports. This will be done in the main thread, so the caller should execute it from the worker thread. This can be done with AsyncTask anyway.
- Also when RouterService is bound from SdlRouterStatusProvider, RouterService should not enter to foreground. This is to avoid unneeded notification messages coming up especially on Android 8 or above.

## Impact on existing code

- RouterServiceValidator's validate will become asynchronous method.
- The synchronous validate() method would be deprecated.

## Alternatives considered
- The solution would be beneficial for both custom RouterService and standard RouterService, because it actually increases the chance to find a RouterService that connects with the head unit.
But one thing to consider is that when finding the connected RouterService, it would be better to try the custom RouterService first, which is different order from what BestRouterComparator in SdlAppInfo offers. It is believed to be better to add another comparator for this purpose.
