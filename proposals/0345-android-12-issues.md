# Android 12 Issues

* Proposal: [SDL-0345](0345-android-12-issues.md)
* Author: [Robert Henigan](https://github.com/RHenigan)
* Status: **Returned for Revisions**
* Impacted Platforms: [Java Suite]

## Introduction

With almost every Android version, Google updates the OS to better distribute the device resources among the running apps to enhance the performance and optimize battery life. However, sometimes the new enhancements come with new restrictions on how apps can use the resources on the device. Android 12 is one of the major Android updates that heavily modify how apps can run in the background and use device resources. This affects how the `SdlRouterService` starts and communicates with other SDL apps and also how the `SdlService` for SDL apps is started. This proposal is to address the issues that have been introduced as a result of Android 12.

## Motivation

Android 12 adds multiple restrictions on how apps can work in the background and access device resources. Some of the new restrictions that affect how SDL Android works are:

- Apps will no longer be able to start foreground services from the background except for in a few select cases. This will directly impact how apps are able to start their own `SdlService` implementation.

- Android 12 introduces new runtime Bluetooth permissions that will be required by the library to successfully establish a Bluetooth connection with the head unit ([`BLUETOOTH_CONNECT` and `BLUETOOTH_SCAN`](https://developer.android.com/about/versions/12/features#bluetooth-permissions)).
 
- Apps will need to explicitly set the exported flag for any services, receivers, and activities that have an `intent-filter` in the manifest.

- `PendingIntents` now require the mutability flag to be set in all cases which impacts some notifications sent by the router service.

- Android 12 may sometimes choose to hide notifications from services for up to 10 seconds to allow short-running services to finish without interrupting the user. This is in most cases a good change. However, in some cases in the library, the notifications should be updated to be displayed immediately.

## Proposed solution

### Foreground Services
With the new restrictions around starting foreground services from the background we will need to meet one of the exceptions that Android 12 would allow to start a foreground service from the background or we would need to start the foreground service from a foreground context.

`PendingIntents` allows us to send an intent on behalf of another app using the context and permissions of the application that created the `PendingIntent`. Since the `SdlRouterService` will run in the foreground, the `SdlRouterService` could create a `PendingIntent` to start an app's `SdlService`. Since the `SdlRouterService` is creating the `PendingIntent`, the intent would be sent from the `SdlRouterService`'s context.

The `PendingIntent` in the `SdlRouterService` can be given to the `SdlBroadcastReceiver`. At this point the `SdlReceiver` will be able to send the `PendingIntent` with and updated Intent where the developer specifies their unique `SdlService` class. By calling `PendingIntent.send()` we are starting a new foreground service of the unique `SdlService` class from the context of the `SdlRouterService`. Since the `SdlRouterService` is running in the foreground we are no longer trying to start a foreground service from the background.

As an external app’s `SdlRouterService` would be starting the developer's `SdlService`, the developer will be required to export their `SdlService` in the manifest so it is accessible to be started by the `SdlRouterService`. This information will be highlighted in the developer guides for the Integration Basics page as well as the appropriate migration guide.

#### Library Changes
##### SdlRouterService.java
~~~ java
//...

public void onTransportConnected(final TransportRecord record) {

    //...

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        Intent pending = new Intent();
        PendingIntent pendingIntent = PendingIntent.getForegroundService(context, (int) System.currentTimeMillis(), pending, PendingIntent.FLAG_MUTABLE | Intent.FILL_IN_COMPONENT);
        startService.putExtra(TransportConstants.PENDING_INTENT_EXTRA, pendingIntent);
    }

    AndroidTools.sendExplicitBroadcast(getApplicationContext(), startService, null);

//...
~~~

#### App Developer Changes
##### AndroidManifest.xml
~~~ xml
<service
    android:name="com.sdl.hellosdlandroid.SdlService"
    android:exported="true" <!--New Addition-->
    android:foregroundServiceType="connectedDevice">
</service>
~~~

##### SdlReceiver.java
~~~ java
//Retrieve, Update, and Send the PendingIntent
@Override
public void onSdlEnabled(Context context, Intent intent) {
    DebugTool.logInfo(TAG, "SDL Enabled");
    intent.setClass(context, SdlService.class);

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        if (intent.getParcelableExtra(TransportConstants.PENDING_INTENT_EXTRA) != null) {
            PendingIntent pendingIntent = (PendingIntent) intent.getParcelableExtra(TransportConstants.PENDING_INTENT_EXTRA);
            try {
                //Here we are allowing the RouterSerivce that is in the Foreground to start the SdlService on our behalf
                pendingIntent.send(context, 0, intent);
            } catch (PendingIntent.CanceledException e) {
                e.printStackTrace();
            }
        }
    } else {
        // SdlService needs to be foregrounded in Android O and above
        // This will prevent apps in the background from crashing when they try to start SdlService
        // Because Android O doesn't allow background apps to start background services
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(intent);
        } else {
            context.startService(intent);
        }
    }
}
~~~

If the developer's `SdlService` is not exported, then the `SdlRouterService` will not be able to start the `SdlService`. In this case the `SdlService` would need to be started from a foreground context to be visible on the IVI the developer could implement to help guide users to manually starting the `SdlService` through the app.

If the service is not exported, `queryForConnectedService` will work if the app developer makes the call while the app is in the foreground. However this will require two things. First, the app developer will be responsible for tracking if the app is in the foreground or not. Second, the `SdlReceiver.onSdlEnabled` will need to be implemented in such a way that it tries to start the `SdlService` in the appropriate way. If the app is in the foreground, the developer can directly call `startForegroundService` to start the `SdlService`. If the app is in the background, the app developer would need the service to be exported and utilize the `pendingIntent` to start the `SdlService`.

##### SdlReceiver.java
~~~ java

private static boolean isForeground;

public static void setIsForeground(boolean status) {
    isForeground = status;
}

@Override
    public void onSdlEnabled(Context context, Intent intent) {
        DebugTool.logInfo(TAG, "SDL Enabled");
        intent.setClass(context, SdlService.class);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (isForeground) {
                context.startForegroundService(intent);
            } else {
                if (intent.getParcelableExtra(TransportConstants.PENDING_INTENT_EXTRA) != null) {
                    PendingIntent pendingIntent = (PendingIntent) intent.getParcelableExtra(TransportConstants.PENDING_INTENT_EXTRA);
                    try {
                        pendingIntent.send(context, 0, intent);
                    } catch (PendingIntent.CanceledException e) {
                        e.printStackTrace();
                    }
                }
            }
        } else {
            // SdlService needs to be foregrounded in Android O and above
            // This will prevent apps in the background from crashing when they try to start SdlService
            // Because Android O doesn't allow background apps to start background services
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent);
            } else {
                context.startService(intent);
            }
        }
    }

~~~

Now that the `SdlRouterService` is starting the app's `SdlService`, we will need to update the exception catcher in the `SdlBroadcastReceiver` to catch the exception that happens if the aforementioned `SdlService` doesn't enter the foreground in time. Since developers are not required to name the SDL Service as `SdlService`, we will need to also add an overridable `getSdlServiceName()` method in the `SdlBroadcastReceiver`. By default this new method would return `SdlService` but developers will be able to override this method to return the appropriate class name for the exception handler to catch the appropriate exception.

This information will be highlighted in the developer guides for the Integration Basics page as well as the appropriate migration guide.

##### SdlBroadcastReceiver.java
~~~ java

//...

public String getSdlServiceName() {
    return "SdlService";
}

//...

static protected void setForegroundExceptionHandler() {
    //...
    foregroundExceptionHandler = new Thread.UncaughtExceptionHandler() {
        @Override
        public void uncaughtException(Thread t, Throwable e) {
            if (e != null
                && e instanceof AndroidRuntimeException
                && ("android.app.RemoteServiceException".equals(e.getClass().getName()) || "android.app.ForegroundServiceDidNotStartInTimeException".equals(e.getClass().getName())) //android.app.RemoteServiceException is a private class
                && e.getMessage() != null
                && (e.getMessage().contains("SdlRouterService")) || e.getMessage().contains("SdlService")) {
                    DebugTool.logInfo(TAG, "Handling failed startForegroundService call");
                    Looper.loop();
                } else if (defaultUncaughtExceptionHandler != null) { //No other exception should be handled
                    defaultUncaughtExceptionHandler.uncaughtException(t, e);
                }
    //...
~~~

##### SdlReceiver.java
~~~ java
//...
@Override
public String getSdlServiceName() {
    return SDL_SERVICE_CLASS_NAME;
}
//...
~~~

### Bluetooth Runtime Permissions
With the new required `BLUETOOTH_CONNECT` runtime permission we will need developers to include the new permission in their `AndroidManifest.xml` file.

#### App Developer Changes
##### AndroidManifest.xml
~~~ xml
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT"
    tools:targetApi="31"/>
~~~

The developer will also need to request this permission from the user as it is a runtime permission. If the user does not grant this permission for a given application, then that application will not receive any Intent with the `ACL_CONNECTED` action in the `SdlBroadcastReceiver`.

In the event that the user denies the Bluetooth permission from the application, this complicates the use cases surrounding the `SdlBroadcastReceiver` and `SdlRouterService`. If the permission is denied for the application then the app's `SdlBroadcastReceiver` will not receive any `ACL_CONNECTED` broadcasts and therefore will not know to start its own SdlRouterService when the device connects over Bluetooth in the event it has been chosen to host it. Other SDL apps on the device will see that they were not the designated app to start the `SdlRouterService` and will simply do nothing, meaning no `SdlRouterService` will be started even if most of the SDL apps do have the Bluetooth permission. To correct this, in the `SdlBroadcastReceiver` we can see if the designated app has the Bluetooth permission. If they do, we will let them start their `SdlRouterService` as normal. If they do not, we will search the list of SDL apps for the first app with the Bluetooth permission; that app will now be considered the designated app to start its `SdlRouterService`. The designated app will then try to start its own `SdlRouterService`.

#### Library Changes
##### SdlBroadCastReceiver.java
~~~ java
private boolean wakeUpRouterService(final Context context, final boolean ping, final boolean altTransportWake, final BluetoothDevice device, final VehicleType vehicleType) {
    new ServiceFinder(context, context.getPackageName(), new ServiceFinder.ServiceFinderCallback() {
        @Override
        public void onComplete(Vector<ComponentName> routerServices) {
            //...
            //If the sdlDeviceListener is enabled we want to see if we are targeting android 12
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                for (SdlAppInfo appInfo : sdlAppInfoList) {
                    //If the RS version is older than Android 12 update version
                    if (appInfo.getRouterServiceVersion() < 16) {
                        preAndroid12RouterServiceOnDevice = true;
                        break;
                    }
                }
                if (!preAndroid12RouterServiceOnDevice && !AndroidTools.isBtConnectPermissionGranted(context, routerService.getPackageName()) && sdlAppInfoList.size() > 1) {
                //find the first app in the list that does have bluetooth permissions
                    for (SdlAppInfo appInfo : sdlAppInfoList) {
                        if (AndroidTools.isBtConnectPermissionGranted(context, appInfo.getRouterServiceComponentName().getPackageName())) {
                            routerService = appInfo.getRouterServiceComponentName();
                            break;
                        }
                    }
                }
            }
            //If this app is the designated app we can start our RouterService
            //Otherwise allow the designated app to start their RouterService
            //...
        }
    }
}

//...

private static SdlDeviceListener getSdlDeviceListener(Context context, BluetoothDevice bluetoothDevice) {

    synchronized (DEVICE_LISTENER_LOCK) {
        if (sdlDeviceListener == null) {
            sdlDeviceListener = new SdlDeviceListener(context, bluetoothDevice, new SdlDeviceListener.Callback() {
                @Override
                public boolean onTransportConnected(Context context, BluetoothDevice bluetoothDevice) {
                    //...
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        boolean preAndroid12RouterServiceOnDevice = false;
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            for (SdlAppInfo appInfo : sdlAppInfoList) {
                                //If the RS version is older than Android 12 update version
                                if (appInfo.getRouterServiceVersion() < 16) {
                                    preAndroid12RouterServiceOnDevice = true;
                                    break;
                                }
                            }
                            if (!preAndroid12RouterServiceOnDevice && !AndroidTools.isBtConnectPermissionGranted(context, routerService.getPackageName()) && sdlAppInfoList.size() > 1) {
                                for (SdlAppInfo appInfo : sdlAppInfoList) {
                                    if (AndroidTools.isBtConnectPermissionGranted(context, appInfo.getRouterServiceComponentName().getPackageName())) {
                                        routerService = appInfo.getRouterServiceComponentName();
                                        break;
                                    }
                                }
                            }
                        }
                    //...
                }
            }
        }
    }
}
~~~

We also need to consider interactions with applications supporting older versions of the `SdlRouterService`. If an application using SDL Android 4.11 or older receives an `ACL_CONNECTED` broadcast in the `SdlBroadcastReceiver`, it may try to start up the `SdlRouterService` of an application that is targeting Android 12. If the started `SdlRouterService` does not have the Bluetooth permission, it will not be able to use the `bluetoothTransport`. To solve this issue we can update the `initCheck` within the `SdlRouterService` to check the app's Bluetooth permission. If the permission is not granted, we can fail the `initCheck` and try to deploy the next `SdlRouterService`.

If a phone connects to the head unit over USB we can still start the `SdlRouterService`, but if the designated app does not have the Bluetooth permission, the `bluetoothTransport` will still not be able to start. This could cause confusion for the user if they expect the `SdlRouterService` to connect over USB and Bluetooth but the `SdlRouterService` will only connect over USB. The suggested solution is to present a notification to the user reminding them to enable the Bluetooth permission. By clicking on the notification the user will be directed to the app's settings page to grant this permission. Meanwhile the `SdlRouterService` will wait to initialize the `bluetoothTransport` and will continuously check the permission status. Once the permission is granted, the `bluetoothTransport` will be started.

Additionally the `MultiplexBluetoothTransport.java` class is using `BluetoothAdapter.cancelDiscovery()`. This requires an additional Runtime Permission of `BLUETOOTH_SCAN`. There is only one use case where this will be called and that is when the the `SdlRouterService` receives a `ROUTER_REQUEST_BT_CLIENT_CONNECT` message. This is never used in a production setting and as such we can check for the `BLUETOOTH_SCAN` permission when it is called but we do not need to require developers to have this permission.

##### SdlRouterService.java
~~~ java

//...

private final static int BT_PERMISSIONS_CHECK_FREQUENCY = 1000;


//...

// Check for BLUETOOTH_SCAN in the RouterHandler
static class RouterHandler extends Handler {

    //...

    @Override
    public void handleMessage(Message msg) {

    //...

    switch (msg.what) {
        case TransportConstants.ROUTER_REQUEST_BT_CLIENT_CONNECT:
            if (!AndroidTools.isBtScanPermissionGranted(service.getApplicationContext(), service.getPackageName())) {
                break;
            }
     //...

//...

private boolean initCheck() {

    //...

    // If Android 12 or newer and we do not have Bluetooth runtime permissions
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !AndroidTools.isBtConnectPermissionGranted(this, this.getPackageName())) {
        if (!isConnectedOverUSB) {
            //If the intent to start the RouterService came from somewhere other than the USB Activity
            //i.e. an SDL APP on SDL Android 4.11 or older tries to start this RouterService while the device is connected over Bluetooth
            return false;
        }
    }

    //...

    return true;

}

//...

public void onTransportConnected(final TransportRecord record) {

//...

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !AndroidTools.isBtConnectPermissionGranted(this, this.getPackageName())) {
        if (isConnectedOverUSB) {
            //Delay starting bluetoothTransport
            waitingForBTRuntimePermissions = true;
            btPermissionsHandler = new Handler(Looper.myLooper());
            //Continuously Check for the Bluetooth Permissions
            btPermissionsRunnable = new Runnable() {
                @Override
                public void run() {
                    if (!AndroidTools.isBtConnectPermissionGranted(SdlRouterService.this, SdlRouterService.this.getPackageName())) {
                        btPermissionsHandler.postDelayed(btPermissionsRunnable, BT_PERMISSIONS_CHECK_FREQUENCY);
                    } else {
                        waitingForBTRuntimePermissions = false;
                        initBluetoothSerialService();
                    }
                }
            };
            btPermissionsHandler.postDelayed(btPermissionsRunnable, BT_PERMISSIONS_CHECK_FREQUENCY);
            //Present Notification to take user to permissions page for the app
        showBTPermissionsNotification();
        }
    }
}

//...

~~~

### AndroidManifest Exported Flag

Starting in Android 12, any activities, services, or broadcast receivers that use intent filters will need to explicitly declare the `android:exported` attribute for the given app components. The `SdlRouterService` and `SdlReceiver` should already have the exported attribute defined and set to `true`, but the `USBAccessoryAttachmentActivity` will now also require this attribute to be set. Any activity that had an `intent-filter` would have a default exported value of `true`. Now we need to explicitly set it.

#### App Developer Changes
##### AndroidManifest.xml
~~~ xml
<activity
    android:name="com.smartdevicelink.transport.USBAccessoryAttachmentActivity"
    android:exported="true" <!--New Addition-->
    android:launchMode="singleTop">
    <intent-filter>
        <action android:name="android.hardware.usb.action.USB_ACCESSORY_ATTACHED" />
    </intent-filter>
    <!-- ... -->
</activity>

~~~

### PendingIntent Mutable Flag

In Android 12, you must specify the mutability of each `PendingIntent` object that your app creates. This will impact the notifications that the `SdlRouterService` is trying to display. As we do not need to update these intents at any point, we can flag them with `FLAG_IMMUTABLE`.

#### Library Changes
##### SdlRouterService.java
~~~ java
private void enterForeground(String content, long chronometerLength, boolean ongoing) {
    //...
    int flag = android.os.Build.VERSION.SDK_INT >= Build.VERSION_CODES.S ? PendingIntent.FLAG_IMMUTABLE : 0;
    PendingIntent pendingIntent = PendingIntent.getActivity(this, 0, intent, flag);
    //...
}
~~~

### Service Notification Delays

Starting in Android 12, when a service tries to present a notification, Android may delay showing the notification for up to 10 seconds. This is to try to allow the service to complete before the notification is presented. If we have connected to a system before, we may want to present the `SdlRouterService` notifications immediately. App developers may also want to display the notifications related to the `SdlService` immediately. This can be achieved by setting the `foregroundServiceBehavior` flag to `Notification.FOREGROUND_SERVICE_IMMEDIATE`.

In the event this is the first time the `SdlRouterService` is trying to connect to a system or if the `SdlRouterService` has seen but not connected with the system, we will not use this flag and instead allow Android to hide the notification.

#### Library Changes
##### SdlRouterService.java
~~~ java
private void enterForeground(String content, long chronometerLength, boolean ongoing) {
    //...
    Notification.Builder builder;
    //...
    if (hasConnectedBefore && android.os.Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        builder.setForegroundServiceBehavior(Notification.FOREGROUND_SERVICE_IMMEDIATE);
    }
    //...
}
~~~

## Potential downsides

### Foreground Services

Using `PendingIntents` to start the app's `SdlService` from the `SdlRouterService` creates a potential security risk as the app's `SdlService` will now be required to have the `android:exported` attribute set to `true`. This could expose apps to have their `SdlService` be started by apps that are not SDLC certified. 

### Bluetooth Runtime Permissions

With the new runtime permission, users will have to grant the Bluetooth permission to SDL-enabled apps at runtime. This means that if the user denies permission for a specific app, the app will not know when the device connects to the head unit over Bluetooth nor will it be able to start its `bluetoothTransport` in the `SdlRouterService`. However, apps that have the Bluetooth permission denied will still be able to bind to another app's `SdlRouterService` and will still be able to start up a `SdlRouterService` for a USB connection only. If there are not any apps on the device with the Bluetooth permission granted, then the `SdlRouterService` will never be started when connecting over Bluetooth.

## Impact on existing code

### Foreground Services

The `SdlRouterService` currently sends an intent out for each app's `SdlBroadcastReceiver` which notifies the apps to start the `SdlService`. If the app targets Android 12 and tries to start the `SdlService` from the background like this, the app will crash. We will need to add a `PendingIntent` as an extra to this intent to be used by the `SdlReceiver`.
These changes will require app developers to change how they implement the `SdlReceiver.onSdlEnabled` method to check the incoming intent for a `pendingIntent` and send that `pendingIntent` with the appropriate class name.
This implementation will also require the `SdlService` to have the `android:exported` attribute set to `true` in the `AndroidManifest.xml`.

### Bluetooth Runtime Permissions

The Bluetooth logic in the library will now require the new runtime permission. With the permission granted, there is not any issue with the Bluetooth logic, but we now need to account for the use cases where a user has denied the permission. Specifically, without the permission the `SdlBroadcastReceiver` will never receive Intents with the `ACL_CONNECTED` action and the `SdlRouterService` will not be able to start the `bluetoothTransport`.

### AndroidManifest Exported Flag

These attributes were already defined where required. The `SdlService` may also require this flag to be set but not as a direct result of Android 12 and rather because of the proposed solution of starting the `SdlService` from the `SdlRouterService`.

### PendingIntent Mutable Flag

The `SdlRouterService` will crash if the the app targets Android 12 and does not have this flag defined on the `PendingIntent` used for `SdlRouterService` notifications.

### Service Notification Delays

These notifications may be delayed by Android by up to 10 seconds, but we can modify the notification builder to display them immediately as this is the desired behavior in some cases.

## Alternatives considered

### Foreground Services

Alternatives for the Foreground Service restrictions are limited. We either need to start the `SdlService` from a foreground context or the conditions need to meet one of the exceptions listed by Google. These conditions include:

* Starting the `SdlService` from an Activity
* Starting the `SdlService` from user interaction with a notification
* Requesting the user ignores battery optimizations for each SDL application

These options would either require an Activity to be launched for each SDL app, the user to interact with a notification for each SDL app, or for the user to choose battery optimization options for each app which then creates a situation where the user dictates if the given app will have its `SdlService` start when the `SdlRouterService` connects.

If we decide to use `PendingIntents` and export the `SdlService` we could also create a custom SDL `<permission>` to be used by apps as a requirement to be able to start the `SdlService`, but nothing is stopping developers from listing that custom permission in their `AndroidManifest.xml`.   

### Bluetooth Runtime Permissions

In the use case of the device only being connected over USB, we could try to start the `SdlRouterService` of an application that does have the Bluetooth permission to ensure we select an `SdlRouterService` that can start the `bluetoothTransport`. The problem with this solution is when we choose to start an `SdlRouterService` that is different than the one started by the `USBAccessoryAttachmentActivity`, the `USBTransferProvider` will try to bind to the wrong `RouterService`. This will require a larger refactor of the `USBTransferProvider`.

### Service Notification Delays

We can leave the notification implementations unchanged and Android would simply delay displaying them if the service they are related to is still running.
