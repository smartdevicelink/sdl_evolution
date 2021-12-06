# Android 12 Issues

* Proposal: [SDL-0345](0000-android-12-issues.md)
* Author: [Robert Henigan](https://github.com/RHenigan)
* Status: **Awaiting review**
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

PendingIntents allows us to send an intent on behalf of another app using the context and permissions of the application that created the PendingIntent. Since the `SdlRouterService` will run in the foreground, the `SdlRouterService` could create a PendingIntent to start an apps  `SdlService`. Since the `SdlRouterService` is creating the PendingIntent, the intent would be sent from the `SdlRouterServices` Context.

The PendingIntent in the `SdlRouterService` can be given to the `SdlBroadcastReceiver`. At this point the `SdlReceiver` will be able to send the PendingIntent with and updated Intent where the developer specifies their unique `SdlService` class. By calling `PendingIntent.send()` we are starting a new foreground service of the unique `SdlService` class from the context of the `SdlRouterService`. Since the `SdlRouterService` is running in the foreground we are not longer trying to start a foreground service from the background.

This will require that the exported flag be set to true in the manifest for the apps `SdlService` as an external apps `SdlRouterService` would be the one starting the service.

#### Library Changes
##### AndroidTools.java
~~~ java
//Creating the PendingIntent from SdlRouterService.java
public static void sendExplicitBroadcast(Context context, Intent intent, List<ResolveInfo> apps) {
    //...
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && intent.getBooleanExtra(TransportConstants.PENDING_BOOLEAN_EXTRA, false)) {
        Intent pending = new Intent();
        PendingIntent pendingIntent = PendingIntent.getForegroundService(context, (int) System.currentTimeMillis(), pending, PendingIntent.FLAG_MUTABLE | Intent.FILL_IN_COMPONENT);
        intent.putExtra(TransportConstants.PENDING_INTENT_EXTRA, pendingIntent);
    }

    context.sendBroadcast(intent);
    //...
}
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

### Bluetooth Runtime Permissions
With the new required Bluetooth Runtime permissions we will need developers to include the new permissions in the `AndroidManifest.xml` file. 

#### Developer Changes
##### AndroidManifest.xml
~~~ xml
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT"
    tools:targetApi="31"/>
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"
    android:usesPermissionFlags="neverForLocation"
    tools:targetApi="31" />
~~~

The developers will also need to request these permissions from the user as they are runtime permissions. If the user does not grant these permissions for a given application then that application will not receive any Intent with the `ACL_CONNECTED` action in the `SdlBroadcastReceiver`.

In the event that the user denies bluetooth permissions from the application this complicates the use cases surrounding the `SdlBroadcastReceiver` and `SdlRouterService`. If the permissions are denied for the application then the apps `SdlBroadcastReceiver` will not receive any `ACL_CONNECTED` broadcasts and therefore will not know to start its own `SdlRouterService` when the device connects over bluetooth. Other SDL Apps on the device will see that they were not the designated app to start the `SdlRouterService` and will simply do nothing meaning no `SdlRouterService` will be started even if most of the SDL Apps do have the bluetooth permissions. To correct this in the `SdlBroadcastReceiver` we can see if the designated app has the bluetooth permissions. If they do we will let them start their `SdlRouterService` as normal. If they do not we will search the list of SDL Apps for the first app with the bluetooth permissions, that app will now be considered the designated app to start its `SdlRouterService`. The designated App will then try to start its own `SdlRouterService`.

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
                //Check to see if the first app in the list has the bluetooth permissions granted
                if (!AndroidTools.areBtPermissionsGranted(context, routerService.getPackageName()) && sdlAppInfoList.size() > 1) {
                    //find the first app in the list that does have bluetooth permissions
                    for (SdlAppInfo appInfo : sdlAppInfoList) {
                        if (AndroidTools.areBtPermissionsGranted(context, appInfo.getRouterServiceComponentName().getPackageName())) {
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
                        if (!AndroidTools.areBtPermissionsGranted(context, routerService.getPackageName()) && sdlAppInfoList.size() > 1) {
                            for (SdlAppInfo appInfo : sdlAppInfoList) {
                                if (AndroidTools.areBtPermissionsGranted(context, appInfo.getRouterServiceComponentName().getPackageName())) {
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

We also need to consider interactions with applications supporting older versions of the `SdlRouterService`. If an application using SDL Android 4.11 or older receives an `ACL_CONNECTED` broadcast in the `SdlBroadcastReceiver`, it may try to start up the `SdlRouterService` of an application that is targeting Android 12. If the started `SdlRouterService` does not have Bluetooth Permissions it will not be able to use the `bluetoothTransport`. To solve this issue we can update the `initCheck` within the `SdlRouterService` to check the apps Bluetooth Permissions. If the permissions are not granted we can fail the `initCheck` and try to deploy the next `SdlRouterService`.

If a phone connects to the head unit over USB we can still start the `SdlRouterService` but if the designated app does not have Bluetooth Permissions the `bluetoothTransport` will still not be able to start. This could cause confusion for the user if they expect the `SdlRouterService` to connect over USB and Bluetooth but the `SdlRouterService` will only connect over USB. The suggested solution is to present a notification to the user reminding them to enable Bluetooth Permissions. By clicking on the notification the user will be directed to the apps settings page to grant those permissions. Meanwhile the `SdlRouterService` will wait to initialize the `bluetoothTransport` and will continuously check the permission status. Once the permissions are granted the `bluetoothTransport` will be started.

#### Library Changes
##### SdlRouterService.java
~~~ java
private boolean initCheck() {

    //...

    // If Android 12 or newer and we do not have Bluetooth runtime permissions
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !AndroidTools.areBtPermissionsGranted(this, this.getPackageName())) {
        //If the intent to start the RouterService came from the USB Activity
        if (isConnectedOverUSB) {
            //Delay starting bluetoothTransport
            waitingForBTRuntimePermissions = true;
            btPermissionsHandler = new Handler(Looper.myLooper());
            //Continuously Check for the Bluetooth Permissions
            btPermissionsRunnable = new Runnable() {
                @Override
                public void run() {
                    if (!AndroidTools.areBtPermissionsGranted(SdlRouterService.this, SdlRouterService.this.getPackageName())) {
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
        } else {
            //If the intent to start the RouterService came from somewhere other than the USB Activity
            //i.e. an SDL APP on SDL Android 4.11 or older tries to start this RouterService while the device is connected over Bluetooth
            return false;
        }
    }

    //...

    return true;
}
~~~

### AndroidManifest Exported Flag

Starting in Android 12 any activities, services, or broadcast receivers that use intent filters will need to explicitly declare the `android:exported` attribute for the given app components. The `SdlRouterService` and `SdlReceiver` should already have the exported attribute defined and set to true. But The `USBAccessoryAttachmentActivity` will now also require this attribute to be set. Any activity that had an `intent-filter` would have a default exported value of true. Now we need to explicitly set it.

#### Developer Changes
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

In Android 12, you must specify the mutability of each PendingIntent object that your app creates. This will impact the notifications that the `SdlRouterService` is trying to display, As we do not need to update these intents at any point we can flag them with `FLAG_IMMUTABLE`.

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

Starting in Android 12 when a service tries to present a notification, Android may delay showing the notification for up to 10 seconds. This is to try to allow the service to complete before the notification is presented. If we have connected to a system before we may want to present the `SdlRouterService` notifications immediately. App developers may also want to display the notifications related to the `SdlService` immediately. This can be achieved by setting the foregroundServiceBehavior flag to `Notification.FOREGROUND_SERVICE_IMMEDIATE`.

In the event this is the first time the `SdlRouterService` is trying to connect to a system or if the `SdlRouterService` has seen but not connected with the system we will not use this flag and allow Android to hide the notification.

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

Using `PendingIntents` to start the apps `SdlService` from the `SdlRouterService` creates a potential security risk as the apps `SdlService` will now be required to have the `android:exported` attribute set to true. This could expose apps to have their `SdlService` be started by apps that are not SDL certified. 

### Bluetooth Runtime Permissions

With the new runtime permissions, users will have to grant bluetooth permissions to SDL enabled apps at runtime. This means that if the user denies permissions for a specific app, the app will not know when the device connects to the head unit over bluetooth nor will it be able to start its `bluetoothTransport` in the `SdlRouterService`. However, apps that have their bluetooth permissions denied will still be able to bind to another app's `SdlRouterService` and will still be able to start up a `SdlRouterService` for a USB connection only. If there are not any apps on the device with bluetooth permissions granted then the `SdlRouterService` would never be started when connecting over bluetooth.

## Impact on existing code

### Foreground Services

The `SdlRouterService` currently sends an intent out for each apps `SdlBroadcastReceiver` which notifies the apps to start the `SdlService`. If the app targets Android 12 and tries to start the `SdlService` from the background like this the app will crash. We will need to add a PendingIntent as an extra to this intent to be used by the `SdlReceiver`
These changes will require app developers to change how they implement the `SdlReceiver.onSdlEnabled` method to check the incoming intent for a pendingIntent and send that pendingIntent with the appropriate class name.
This implementation will also require the `SdlService` to have the `android:exported` attribute set to `true` in the `AndroidManifest.xml`.

### Bluetooth Runtime Permissions

The bluetooth logic in the library will now require these 2 new runtime permissions. With these permissions granted there is not any issue with the bluetooth logic but we now need to account for the use cases where a user has denied permissions. Specifically without these permissions the `SdlBroadcastReceiver` will never receive Intents with the `ACL_CONNECTED` action and the `SdlRouterService` will not be able to start the `bluetoothTransport`.

### AndroidManifest Exported Flag

These attributes were already defined where required. The `SdlService` may also require this flag to be set but not as a direct result of Android 12 and rather because of the proposed Solution of starting the `SdlService` from the `SdlRouterService`.

### PendingIntent Mutable Flag

The `SdlRouterService` will crash if the the app targets Android 12 and does not have this flag defined on the PendingIntent used for `SdlRouterService` notifications.

### Service Notification Delays

These notifications may be delayed by Android by up to 10 seconds but we can modify the notification builder to display them immediately as this is the desired behaviour in some cases.

## Alternatives considered

### Foreground Services

Alternatives for the Foreground Service restrictions are limited. We either need to start the `SdlService` from a foreground context or the conditions need to meet one of the exceptions listed by Google. These conditions include:

* Starting the `SdlService` from an Activity.
* Starting the `SdlService` from user interaction with a notification
* Requesting the user ignores battery optimizations for each SDL Application

These options would either require an Activity to be launched for each SDL app, the user to interact with a notification for each SDL app, or for the user to choose battery optimization options for each app which then creates a situation where the user dictates if the given app will have its `SdlService` start when the `SdlRouterService` connects.

If we decide to use `PendingIntents` and export the `SdlService` we could also create a custom SDL `<permission>` to be used by apps as a requirement to be able to start the `SdlService` but nothing is stopping developers from listing that custom permission in their `AndroidManifest.xml`.   

### Bluetooth Runtime Permissions

In the use case of the device only being connected over USB we could try to start the `SdlRouterService` of an application that does have Bluetooth Permissions to ensure we select a `SdlRouterService` that can start the `bluetoothTransport`. The problem with this solution is when we choose to start a `SdlRouterService` that is different than the one started by the `USBAccessoryAttachmentActivity`, the `USBTransferProvider` will try to bind to the wrong `RouterService`. This will require a larger refactor of the `USBTransferProvider`.

### Service Notification Delays

We can leave the notification implementations unchanged and Android would simply delay displaying them if the service they are related to is still running.
