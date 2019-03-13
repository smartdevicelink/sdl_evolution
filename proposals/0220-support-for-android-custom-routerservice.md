# Support for Android custom RouterService
* Proposal: [SDL-0220](0220-support-for-android-custom-routerservice.md)
* Author: [Shinichi Watanabe](https://github.com/shiniwat)
* Status: **In Review**
* Impacted Platforms: Android

## Introduction
This proposal is to improve the case where SDL applications need to work with custom RouterService. A custom RouterService refers to the RouterService that does not use the open source's RouterService code. The app that contains custom RouterService must indicate the flag in its AndroidManifest.xml.
This proposal refers to the case where an OEM-specific head unit requires an OEM-specific app to work as the RouterService.
For instance, if an OEM uses a specific Bluetooth server UUID that differs from SDL standard ones, that should be a custom RouterService.

## Motivation

In order to use a custom RouterService, AndroidManifest.xml must indicate the application has a custom RouterService, similar to the example below:
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

In order to identify the issued cases, let's pay attention to when a SDL app starts proxy.

### When SDL apps start proxy?
There are two major triggers where SDL applications start SdlProxy; one is a broadcast intent sent from RouterService, and the other is all other cases where the app starts SdlProxy by itself.
Let's see those two triggers in detail.

#### A trigger sent from RouterService

A SDL app usually starts proxy when the app receives START_ROUTER_SERVICE_ACTION, which is broadcast intent sent from RouterService. In this case, the broadcast intent includes ComponentName of the RouterService, which is taken by SdlBroadcastReceiver, set it to an instance variable (called queuedService) and then onSdlEnabled is called.
The SDL app is responsible for overriding onSdlEnabled, starts its own service, and then starts Proxy. The Proxy checks to see queuedService, and uses that ComponentName to determine the target RouterService.
This case works fine regardless of the RouterService is custom or not.

#### A trigger invoked by SDL app on demand

This case refers to all other cases than "the trigger sent from RouterService". This case requires the app to determine which RouterService to bind with.
Unless the app identifies the right RouterService, it cannot register with SDL Core. Even in that case, Sdl proxy has some fallback logic. Let's see the current logic anyway.

#### Current logic for finding RouterService

Currently SdlProxy identifies the RouterService in three steps:

1. SdlBroadcastReceiver class has a public method called queryForConnectedService, which finds the RouterService whose primary transport connects with SDL Core. This step also verifies if the RouterService is trusted or not.
    -  Internally, this binds with the RouterService one by one and asks if its primary transport has a connection with the head unit. So it takes some time, and the cost depends on how many SDL apps exist in the device.
2. If the step#1 fails, then SdlProxy wakes up the best possible RouterService.
    -  Internally, SdlProxy has priority order, the latest (which means having the newest version) non-custom RouteService has the priority.
3. Before the app binds with the RouterService, it verifies that the RouterService is the trusted one. If not, then the app falls back to legacy Bluetooth mode.

The problem is that custom RouterService is unlikely chosen in step #2.
Step #1 actually depends on the timing of when the app calls queryForConnectedService. It is up to the application when queryForConnectedService is called, but [the integration-basic document](https://smartdevicelink.com/en/guides/android/getting-started/integration-basics/) suggests it should be called at Main Activities onCreate.

#### The cases where this proposal focuses on
The following section focuses on the case other than "a trigger sent from RouterService". For example, in the following cases, the app may start proxy on demand:
- When OnLanguageChange is notified: in this case, the app has to restart the proxy.
- When user removed the app from Recent List: in this case, ActvityManager may automatically restarts its service, and restarts proxy in there.
- When user enforce the app to stop by settings | Apps | force stop: in this case ActivityManager may automatically restarts its service too.
- An app may pay attention to some error case (e.g. onProxyClosed, etc), and then restarts the proxy to get recovered.
- An app has the capability to restart proxy when yet another transport is connected. This might be useful if the SDL core does not support secondary transport.

## Proposed solution

Suppose a custom RouterService is basically designed for OEM-specific head units, and the head unit only works with that specific custom RouterService.
The current logic may not work very well to identify the custom RouterService even if the custom RouterService is already connected with OEM-specific head unit.
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
When the app finds the connected RouterService, it might be better to cache the service name on somewhere, e.g. SharedPreferences, so that it won't bother the other app's RouterService too often. When the cache is used, the time to clear the cache is very important. This is optional, however.

### If an app contains custom RouterService, it must start by itself
Because the custom RouterService cannot rely on other apps to be woken up, it must start RouterService whenever needed.
The time when the app starts RouterService highly depends on the application, however.

## Potential downsides

- The proposed solution will use SdlRouterStatusProvider, which actually binds to other app's RouterService and asks if the RouterService has connected transports. This will be done in the main thread, so the caller should execute it from the worker thread. This can be done with AsyncTask anyway.
- Also when RouterService is bound from SdlRouterStatusProvider, RouterService should not enter to foreground. This is to avoid unneeded notification messages coming up especially on Android 8 or above.

## Impact on existing code

- RouterServiceValidator's validate will become asynchronous method.
- The synchronous validate() method would be deprecated.

## Alternatives considered
- The solution would be beneficial for both custom RouterService and standard RouterService, because it actually increases the chance to find a RouterService that connects with the head unit.
But one thing to consider is that when finding the connected RouterService, it would be better to try the custom RouterService first, which is different order from what BestRouterComparator in SdlAppInfo offers. It is believed to be better to add another comparator for this purpose.
