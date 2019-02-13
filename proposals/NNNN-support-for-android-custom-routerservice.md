# Support for Android custom RouterService
* Proposal: [SDL-NNNN](NNNN-support-for-android-custom-routerservice.md)
* Author: [Shinichi Watanabe](https://github.com/shiniwat)
* Status: **Awaiting review**
* Impacted Platforms: Android

## Introduction
This proposal is to improve the case where SDL application needs to work with custom RouterService. The definition of custom RouterService is varied, but this proposal refers to the case where the specific OEM's head unit requires the specific application that works as the RouterService.
For instance, if an OEM uses specific Bluetooth server UUID that differs from SDL standard, that should be custom RouterService.

## Motivation

Currently, AndroidManifest.xml can indicate the application has custom RouterService, something like below:
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

When SDL application determines which RouterService to bind with, the app creates the list of SDL enabled apps, and checks to see if connected RouterService exists.
If the custom RouterService is already connected, and the SDL application can identify the connected RouterService correctly, the app will work fine. However, it not, the application instantiates "possibly the best" RouterService. In this case, custom RouterService is unlikely being chosen, because custom RouterService has lower priority for finding the best RouterService.
If the custom RouterService is the only RouterService that connects with the specific head unit, the application unlikely finds the custom RouterService, and hence unlikely get registered to SDL Core.
This proposal is to improve the connectivity with custom RouterService.

### Current logic for finding RouterService

Currently SdlProxy identify the RouterService in three steps:

1. SdlBroadcastReceiver class has the public method called queryForConnectedService, which finds the RouterService that has connection with SDL Core. This also pays attention to if the RouterService is trusted RouterService.
    -  Internally, this binds with RouterService one by one and ask if you're connecting with. So the cost is non-trivial, though.
2. If the step#1 fails, then wake up the possibly the best RouterService.
    -  Internally, SdlProxy has the priority order, the latest (which means having the newer version) non-custom RouteService has the priority.
3. Before the app actually binds with the RouterService, it has validation logic, and the RouterService must be trusted RouterService. If the validation fails. then the app fails to find the trusted RouterService, and fallback to legacy Bluetooth mode.

The problem is that step #2 and #3 unlikely find the custom RouterService, because custom RouterService is lowest order.
Step #1 actually depends on the timing when the app calls queryForConnectedService. It is up to the application that when to calls queryForConnectedService, but [the integration-basic document](https://smartdevicelink.com/en/guides/android/getting-started/integration-basics/) suggests it should be called at Activitiy onCreate.

## Proposed solution

### RouterServiceValidator should pay attention to currently connected RouterService.

The custom RouterService is basically designed for the specific head unit, and the head unit will work only with that specific custom RouterService.
In order to make custom RouterService to work, the app should pay attention to "currently connected RouterService" whenever needed.
When would be the expected time to check? That would be right before the app binds to RouterService, and that should be done automatically without relying on application's specific code.
The proposed solution is to add new asynchronous method to RouterServiceValidator, and calls it right before the TransportManager connect to the RouterService.

### Detailed design of asynchronous method
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

The pseudo-code of FindRoutertask will be:
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
									mCallback.onFound(service);
								}
							} else {
								Log.d(TAG, "SdlRouterStatusProvider returns service=" + service + "; connected=" + connected);
								if (isLast && mCallback != null) {
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

### The caller of the asynchronous method
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

### Using cache for saving cost to find the connected RouterService.
When the app finds the connected RouterService, I think it's better to cache the service name on somewhere, e.g. SharedPreferences, so that it won't bother the other app's RouterService too often.

## Potential downsides

- The proposed solution will use SdlRouterStatusProvider, which actually binds to other app's RouterService and asks if the RouterService has connected transports. This will be done in main thread, so the caller must not be in main thread. This can be done with AsyncTask anyway.
- Also when RouterService is bound from SdlRouterStatusProvider, RouterService should not enter to foreground. This is to avoid unneeded notification message coming up.

## Impact on existing code

- RouterServiceValidator's validate will become asynchronous method.
- The synchronous validate() method would be deprecated.

## Alternatives considered
- The solution would be beneficial for both custom RouterService and standard RouterService, because it actually finds the already connected RouterService. But one thing to consider is that when finding the connected RouterService, I believe it is better to try the custom RouterService first, which is different order from what BestRouterComparator in SdlAppInfo offers. I think it is better to add another comparator for this purpose.

