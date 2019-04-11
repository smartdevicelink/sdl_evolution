# Support for Android custom RouterService
* Proposal: [SDL-0220](0220-support-for-android-custom-routerservice.md)
* Author: [Shinichi Watanabe](https://github.com/shiniwat)
* Status: **Returned for Revisions**
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

RouterService needs to communicate with every SDL application on device, so it's important to see how and when a SDL application starts proxy.

### How and when SDL apps start proxy
There are two major triggers where SDL applications start SdlProxy; one is a broadcast intent sent from RouterService, and the other is all other cases where the app starts SdlProxy by itself.
Let's see those two triggers in detail.

#### A trigger sent from RouterService

A SDL app usually starts proxy when the app receives START_ROUTER_SERVICE_ACTION, which is a broadcast intent sent from RouterService. In this case, the broadcast intent includes ComponentName of the RouterService, which is taken by SdlBroadcastReceiver, set it to an instance variable (called queuedService) and then onSdlEnabled is called.
The SDL app is responsible for overriding onSdlEnabled, starts its own service, and then starts Proxy. The Proxy checks to see queuedService, and uses that ComponentName to determine the target RouterService to bind with.
This case works fine regardless of whether or not the RouterService is custom.

#### All other triggers on demand

This refers to all cases other than "the trigger sent from RouterService". This case requires the app to determine which RouterService to bind with.
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
The following section focuses on the case other than "a trigger sent from RouterService". For example, in the following cases, the app will start proxy:
- When OnLanguageChange is notified: in this case, the app has to restart the proxy.
- When a user removes the app from Recent List: in this case, ActivityManager may automatically restart the killed service, and restart proxy in there. RouterService internally uses DeathRecipient interface to detect binderDied case, which might help some cases, but not all the cases.
- When a user enforces the app to stop by settings | Apps | force stop: in this case ActivityManager may automatically restart the killed service as well as the remove from Recent list case.
- An app may pay attention to some error case (e.g. onProxyClosed, etc), and then restart the proxy to get recovered.
- An app may restart proxy when yet another transport is connected. This might be useful especially if the SDL core does not support secondary transport. For instance, if BT transport is connected, the app uses NON_MEDIA layout. When user connects USB or WIFI, then the app restarts the proxy instance and then uses NAV_FULLSCREEN_MAP layout.

In addition to above cases, SdlProxyBase#cycleProxy function also internally restarts the proxy when some errors are detected.
All the cases above have some issues to work with custom RouterService.

## Proposed solution

Suppose a custom RouterService is basically designed for OEM-specific head units, and the head unit only works with that specific custom RouterService.
The current logic may not work very well to identify the custom RouterService even if the custom RouterService is already connected with OEM-specific head unit.
To improve the connectivity of custom RouterService, the approach would be:

1. Do not rely on the user app to call queryForConnectedService; instead, SdlProxy should automatically check to see if the RouterService connects with SDL Core whenever needed.

2. Custom RouterService cannot rely on other apps to be woken up, because of its priority order. Instead, it needs to start RouterService on its own.

3. We can reuse the existing logic that verifies the trusted RouterService. If a RouterService is not trusted, SdlProxy can wake up the best possible RouterService in the same way the current proxy does. 

In approach #1, the important point is the location to check if the RouterService's primary transport connects with the head unit. It should be in the RouterServiceValidator class.

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

		final FindConnectedRouterCallback findRouterCallback = new FindConnectedRouterCallback() {
			@Override
			public void onFound(ComponentName component) {
				Log.d(TAG, "FindConnectedRouterCallback.onFound got called. Package=" + component);
				checkTrustedRouter(callback, pm, component);
			}

			@Override
			public void onFailed() {
				Log.d(TAG, "FindConnectedRouterCallback.onFailed was called");
				if (callback != null) {
					callback.onFinishedValidation(false, null);
				}
			}
		};

		if(this.service == null){
			Log.d(TAG, "about finding the best Router by using retrieveBestRouterServiceName");
			new FindRouterTask(findRouterCallback).execute(this.context);
		} else {
			// already found the RouterService
			checkTrustedRouter(callback, pm, service);
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

The pseudo-code of FindRouterTask will be:
```java
	class FindRouterTask extends AsyncTask<Context, Void, ComponentName> {
		FindConnectedRouterCallback mCallback;
		ServiceNameHolder serviceNameHolder = null;

		FindRouterTask(FindConnectedRouterCallback callback) {
			if (callback != null) {
				mCallback = callback;
			}
		}

		@Override
		protected ComponentName doInBackground(final Context... contexts) {
			// let's use ServiceFinder here
			Context context = contexts[0];
			new ServiceFinder(context, context.getPackageName(), new ServiceFinder.ServiceFinderCallback() {
				@Override
				public void onComplete(Vector<ComponentName> routerServices) {
					// OK, we found the routerServices. Let's see one-by-one.
					if (routerServices == null || routerServices.isEmpty()) {
						return;
					}
					serviceNameHolder = new ServiceNameHolder(contexts[0]);
					if (serviceNameHolder.isValid()) {
						routerServices.insertElementAt(serviceNameHolder.getServiceName(), 0);
					}

					for (ComponentName name: routerServices) {
						final boolean isLast = name.equals(routerServices.lastElement());
						final SdlRouterStatusProvider provider = new SdlRouterStatusProvider(contexts[0], name, new SdlRouterStatusProvider.ConnectedStatusCallback() {
							@Override
							public void onConnectionStatusUpdate(boolean connected, ComponentName service, Context context) {
								if (connected) {
									serviceNameHolder.setServiceName(service);
									serviceNameHolder.save(contexts[0]);
									if (mCallback != null) {
										mCallback.onFound(service);
									}
								} else {
									if (isLast && mCallback != null && !serviceNameHolder.isValid()) {
										mCallback.onFailed();
										serviceNameHolder.clear();
									}
								}
							}
						});
						provider.checkIsConnected();
						provider.cancel();
					}
				}
			});
			return null;
		}

		@Override
		protected void onPostExecute(ComponentName componentName) {
			super.onPostExecute(componentName);
		}
	}
```

ServiceNameHolder will be a helper class that holds the last connected service name.
The pseudo-code would be:
```java
	class ServiceNameHolder {
		static final String prefName = "RouterServiceValidator.FindRouterTask";
		static final String packageKey = "packageName";
		static final String classKey = "className";
		static final String tsKey = "timestamp";
		final int _validSpan = 300; // 300 seconds == 5 minutes
		ComponentName _serviceName;
		long _timeStamp;
		Context mContext;

		public ServiceNameHolder(String packageName, String className, long timeStamp) {
			_serviceName = new ComponentName(packageName, className);
			_timeStamp = timeStamp;
		}
		public ServiceNameHolder(Context context) {
			SharedPreferences pref = context.getSharedPreferences(prefName, Context.MODE_PRIVATE);
			String packageName = pref.getString(packageKey, "");
			String className = pref.getString(classKey, "");
			_serviceName = new ComponentName(packageName, className);
			_timeStamp = pref.getLong(tsKey, 0);
			mContext = context;
		}

		public ComponentName getServiceName() {
			return _serviceName;
		}
		public void setServiceName(ComponentName name) {
			_serviceName = name;
		}
		public long getTimeStamp() {
			return _timeStamp;
		}

		@TargetApi(9)
		public void save(Context context) {
			SharedPreferences pref = context.getSharedPreferences(prefName, Context.MODE_PRIVATE);
			SharedPreferences.Editor editor = pref.edit();
			editor.putString(packageKey, _serviceName.getPackageName());
			editor.putString(classKey, _serviceName.getClassName());
			_timeStamp = System.currentTimeMillis() / 1000;
			editor.putLong(tsKey, _timeStamp);
			editor.apply();
		}

		public boolean isValid() {
			return (_timeStamp != 0 && System.currentTimeMillis() / 1000 - _timeStamp < _validSpan);
		}

		@TargetApi(9)
		public void clear() {
			if (mContext != null) {
				SharedPreferences pref = mContext.getSharedPreferences(prefName, Context.MODE_PRIVATE);
				SharedPreferences.Editor editor = pref.edit();
				editor.putString(packageKey, "");
				editor.putString(classKey, "");
				editor.putLong(tsKey, 0);
				editor.apply();
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
It internally utilize ServiceFinder class, which sends broadcast to currently running RouterServices, and receive another broadcast from them. So this way will check currently running RouterService only, and avoid starting services merely for checking the currently connected service.
