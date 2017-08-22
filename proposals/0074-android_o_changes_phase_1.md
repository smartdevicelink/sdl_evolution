# Android O Changes Phase 1

* Proposal: [SDL-0074](0074-android_o_changes_phase_1.md)
* Author: [Joey Grover](https://github.com/joeygrover)
* Status: **Accepted**
* Impacted Platforms: [Android]

## Introduction

Android O introduces a lot of new restrictions in terms of background services and when an app becomes activated. This proposal intends to provide enhancements that will work within the new Android O environment, specifically implicit intents and static broadcast receivers.

## Motivation
The way the sdl_android_library currently works will not be functional if the developer targets their app for Android O. There are a few changes we need to make to ensure compatibility, this is the first phase of those changes. The change introduced in the newest version of Android that this proposal is aiming to handle is Android's reduction in accepted implicit intents for static broadcast receivers. An implicit intent is defined by the intent merely having an "action" field, with no specific destination. Previous versions of Android would allow developers to define static broadcast receivers in their manifests that could listen for an intent with that specific "action". The  only implicit intents that developers can use a static broadcast receiver with will be from the Android OS and defined [here](https://developer.android.com/preview/features/background-broadcasts.html). (Note: dynamic broadcast receivers can still receive implicit intents, however, they are subject to the lifecycle of the component in which they are created.)

The current SDL Android library uses an implicit intent to broadcast that the `SdlRouterService` is currently connected to a module. It is assumed the developers listen for this intent in a static broadcast receiver so the app can be woken up. 


## Proposed solution
The proposed solution is to actually send explicit intents rather than implicit. This is possible due to the fact that Android allows a method to query static broadcast receivers 
for a specific action. Android will return a list of `ResolveInfo` which can be used to address an intent to a specific broadcast receiver. If we create a nearly blank intent with only the action, `sdl.router.startservice`, defined we can find all the SDL enabled apps and their broadcast receivers.

We also need to include a new flag `Intent.FLAG_RECEIVER_FOREGROUND` to ensure the broadcast receiver is woken up from the background and can execute in the foreground. This also has a side effect benefit of reducing the receiving time of the intent as [found by Tuan Nguyen](https://github.com/smartdevicelink/sdl_android/issues/550).

The only code changes will be in the `onTransportConnected` method of the `SdlRouterService`.

#### Previous:

```java
Intent startService = new Intent();  
startService.setAction(TransportConstants.START_ROUTER_SERVICE_ACTION);
startService.putExtra(TransportConstants.START_ROUTER_SERVICE_SDL_ENABLED_EXTRA, true);
startService.putExtra(TransportConstants.FORCE_TRANSPORT_CONNECTED, true);
startService.putExtra(TransportConstants.START_ROUTER_SERVICE_SDL_ENABLED_APP_PACKAGE, getBaseContext().getPackageName());
startService.putExtra(TransportConstants.START_ROUTER_SERVICE_SDL_ENABLED_CMP_NAME, new ComponentName(this, this.getClass()));

sendBroadcast(startService); 
```


#### New:

```java
Intent startService = new Intent();
startService.setAction(TransportConstants.START_ROUTER_SERVICE_ACTION);
startService.putExtra(TransportConstants.START_ROUTER_SERVICE_SDL_ENABLED_EXTRA, true);
startService.putExtra(TransportConstants.FORCE_TRANSPORT_CONNECTED, true);
startService.putExtra(TransportConstants.START_ROUTER_SERVICE_SDL_ENABLED_APP_PACKAGE, getBaseContext().getPackageName());
startService.putExtra(TransportConstants.START_ROUTER_SERVICE_SDL_ENABLED_CMP_NAME, new ComponentName(this, this.getClass()));
startService.addFlags(Intent.FLAG_RECEIVER_FOREGROUND);

final Intent intent = new Intent(TransportConstants.START_ROUTER_SERVICE_ACTION);
List<ResolveInfo> infos = getPackageManager().queryBroadcastReceivers(intent, 0);
for(ResolveInfo info: infos){
	startService.setClassName(info.activityInfo.applicationInfo.packageName, info.activityInfo.name);
	sendBroadcast(startService);
}

```

These changes will work with apps that have not updated as well (assuming one app has updated and its router service is the one that is propagated). The broadcast receiver will still act the same as it doesn't need to know if the intent is implicit or explicit.

## Potential downsides

There shouldn't be any downside to this approach.

## Impact on existing code
Since developers already had to declare a static broadcast receiver with the intent action `sdl.router.startservice` added to their intent filter, developers shouldn't need to do anything new.

The code changes to the library itself are well contained and will not have a large impact. 


## Alternatives considered
- Forcing  developers to target Android Nougat or lower: This is not a real option as we would be handcuffing developers to not be able to use new behavior changes in Android O or any version after that.



