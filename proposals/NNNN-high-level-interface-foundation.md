# High level interface: Foundation

* Proposal: [SDL-NNNN](NNNN-high-level-interface-foundation.md)
* Author: [Kujtim Shala](https://github.com/kshala-ford)
* Status: **Awaiting review**
* Impacted Platforms: [ iOS / Android ]

## Introduction

This proposal is about setting up a foundation to provide a high level developer interface to the Android and iOS libraries. It proposes a solution to mimic the UI framework of the native OS SDKs. It contains an overview and basic design but won't go much into details of a specific section. Subsequent proposal will be created in the near future in order to provide detailed designs whenever necessary.

As discussed in the steering committee meeting from March 20 (see [here](https://github.com/smartdevicelink/sdl_evolution/issues/379#issuecomment-374736496)) this proposal is a counterproposal to [0133 - Enhanced iOS Proxy Interface](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0133-EnhancediOSProxyInterface.md).

## Motivation

In order to work with SDL app developers need to learn a new API which mostly doesn't adopt familiar patterns. Including but not limited to 
- read best practices and implement proxy lifecycle (Android above all)
- the use of RPCs and handle notifications, requests and responses
- manually manage concurrent and sequential operations (e.g. image upload)

The time for an app developer to learn SDL (non-productive time) is high and not accepted by some developers. The SDL iOS library already improves the current situation by abstracting painful implementations. However the management layer is still unfamiliar and causes a high learning curve.

## Proposed solution

This proposal is about adding a new abstraction layer which utilizes the management layer and provides a high level interface familiar to the UIKit famework in iOS and Activity package in Android.

| High level interface |
|----------------------|
| Management layer     |
| Proxy layer          |
| Protocol layer       |
| Transport layer      |

The high level interface sits on top of the management layer. It should provide classes like 
- SDL Application to abstract SDL-centric application lifecycle including HMI status, capabilities, language etc. 
- SDL ViewController (iOS) or Activity (Android) to allow architecture SDL use cases beyond todays possibilities (incl. UI stack)
- SDL View with subclasses to simplify the HMI screen manipulation throughout the UI stack

### iOS

### Application lifecycle

This subsection is not complete but provides an descriptive overview to avoid confusion. If agreed by the steering committee the details of the application lifecycle will be proposed separately.

#### SDLApplication (mimic UIApplication)

The application lifecycle `SDLApplication` should utilize the lifecycle manager and provide 
- a state machine abstracting transitions of the HMI level, audio streaming state etc.
- properties to access (appliation related) capabilities (from `RegisterAppInterfaceResponse` or `GetSystemCapabilities`)
- refer to an SDL root view controller which will be used as the entry point for the app UI. 

#### SDLAppState (mimic UIApplicationState)

Inspired by [`UIApplicationState`](https://developer.apple.com/documentation/uikit/uiapplicationstate) an SDL application can behave very similar to a native iOS app

```objc
typedef SDLEnum SDLAppState SDL_SWIFT_ENUM;
extern SDLAppState const SDLAppStateActive; // Equivalent to HMI_FULL
extern SDLAppState const SDLAppStateInactive; // Equivalent to HMI_LIMITED
extern SDLAppState const SDLAppStateBackground; // Equivalent to HMI_BACKGROUND
extern SDLAppState const SDLAppStateNotRunning; // Equivalent to HMI_NONE
extern SDLAppState const SDLAppStateDisconnected; // Equivalent to not connected/registered
```

#### SDLAppDelegate (mimic UIApplicationDelegate)

This protocol corresponds to [UIApplicationDelegate](https://developer.apple.com/documentation/uikit/uiapplicationdelegate) and provides method called on certain commonly used transitions. All of the transitions would also be notified through the notification center.

*AppDelegate protocol*

```objc
@protocol SDLAppDelegate
@optional
- (void)appDidConnect:(SDLApplication *)app;
- (void)appDidDisconnect:(SDLApplication *)app;

- (void)appDidFinishLaunch:(SDLApplication *)app;
- (void)appDidClose:(SDLApplication *)app;

- (void)appDidBecomeInactive:(SDLApplication *)app;
- (void)appDidBecomeActive:(SDLApplication *)app

- (void)appDidEnterBackground:(SDLApplication *)app;
@end
```

*Transition flow*

![application-lifecycle](../assets/proposals/NNNN-high-level-interface-foundation/application-lifecycle.png)

*Transition table*

| From          | To            | Delegate call(s)                                                      | Case/Example                                                          |
|---------------|---------------|-----------------------------------------------------------------------|-----------------------------------------------------------------------|
| Any level     | Not connected | `appDidDisconnect:`                                                   | Phone's disconnected                                                  |
| Not connected | NONE          | `appDidConnect:`                                                      | App just registered                                                   |
| Not connected | BACKGROUND    | `appDidConnect:`<br>`appDidFinishLaunch:`<br>`appDidEnterBackground:` | App with background service just registered                           |
| Not connected | LIMITED       | `appDidConnect:`<br>`appDidFinishLaunch:`<br>`appDidBecomeInactive:`  | Media app resumed after ignition cycle while HMI is e.g. in Nav       |
| Not connected | FULL          | `appDidConnect:`<br>`appDidFinishLaunch:`<br>`appDidBecomeActive:`    | Media app resumed after ignition cycle and became visible on HMI      |
| NONE          | BACKGROUND    | `appDidFinishLaunch:`<br>`appDidEnterBackground:`                     | App just got permission to serve in background                        |
| NONE          | LIMITED       | `appDidFinishLaunch:`<br>`appDidBecomeInactive:`                      | ?                                                                     |
| NONE          | FULL          | `appDidFinishLaunch:`<br>`appDidBecomeActive:`                        | App was selected by the user (or system)                              |
| BACKGROUND    | NONE          | `appDidClose:`                                                        | Background app was closed                                             |
| BACKGROUND    | LIMITED       | `appDidBecomeInactive:`                                               | ?                                                                     |
| BACKGROUND    | FULL          | `appDidBecomeActive:`                                                 | Background app was selected by the user                               |
| LIMITED       | NONE          | `appDidClose:`                                                        | Active media app was closed by the user while HMI is e.g. in Nav      |
| LIMITED       | BACKGROUND    | `appDidEnterBackground:`                                              | Active media app was closed as the user selected another media app    |
| LIMITED       | FULL          | `appDidBecomeActive:`                                                 | Active media app was selected by the user                             |
| FULL          | NONE          | `appDidClose:`                                                        | App was closed by the user                                            |
| FULL          | BACKGROUND    | `appDidBecomeInactive:`<br>`appDidEnterBackground:`                   | Non-media app is backgrounded as the user moved to e.g. media         |
| FULL          | LIMITED       | `appDidBecomeInactive:`                                               | Media app was background as the user moved to e.g. Nav                | 

### Android

## Potential downsides

The initial workload in order to implement this high level interface is expected to be quite high. Once implemented it is expected that developers will be able to implement SDL into their apps in less time as they would need today. At the end the maintenance of the high level interface may be lower compared to the counterproposal for different reasons.

This proposal mimics the native UI API. Compared to the counterproposal this proposal is not that close to the native UI kit experience. On the other side some SDL specific APIs can be easily abstracted and integrated into the rest of the high level interface.

## Impact on existing code

This proposal will add a total new high level interface layer abstracting many parts of SDL. Existing code should not be affected in a short term but it would make parts of the code obsolete therefore to be deprecated and made private.

## Alternatives considered

There are no other alternatives considered.
