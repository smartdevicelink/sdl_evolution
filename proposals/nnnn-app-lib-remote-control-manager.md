# App Library Remote Control Manager

* Proposal: [SDL-NNNN](nnnn-app-lib-remote-control-manager.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Awaiting review**
* Impacted Platforms: [iOS / Java Suite / JavaScript Suite]

## Introduction
This proposal adds a remote control manager to the app libraries which manages everything related to the remote control systems on head units.

## Motivation
The remote control system on head units is incredibly complicated and requires certain procedures to occur in order to properly control a head unit's remote control modules. Additionally, those requirements have changed over time when we added support for multiple modules of a given type, meaning that developers must go through different procedures depending on the RPC version of the head unit.

## Proposed solution
We will add a remote control manager to handle the various procedures and data retrieval that is possible.

### Startup
If the app's HMI types contains `REMOTE_CONTROL`, then the remote control manager will be started, otherwise, it will not be started and all methods will return an immediate failure. If the RPC version of the connected head unit is less than 4.5 or if `RegisterAppInterface(Response).hmiCapabilities.remoteControl == false`, the manager will not be started and all methods will return an immediate failure.

When the remote control manager is started, it will subscribe to `SystemCapabilityType.REMOTE_CONTROL` and `OnInteriorVehicleData` on RPC 4.5+, and `OnRCStatus` to track which modules are allocated to the application on RPC 5.0 and above.

### Getting Seat Location Information
When connected to a system on RPC 6.0+ and `HMICapabilities.seatLocation == true`, the remote control manager will also attempt to subscribe to `SystemCapabilityType.SEAT_LOCATION`. The seat location information will be stored to a property:

#### iOS
```objc
@property (strong, nonatomic, nullable, readonly) SDLSeatLocationCapability *seatLocations;
```

#### Java Suite
```java
public SeatLocationCapability getSeatLocations()
```

#### JavaScript Suite
```js
getSeatLocations()
```

### Setting the User's Seat
When connected to v6.0+, developers may set the user's seat location, and it will default to the driver seat. There will be a method to set a new location for the user's seat. If this method is called on less than RPC 6.0, it will immediately return a failure. If this method is called when `HMICapabilities.seatLocation == false` or `SystemCapabilityType.SEAT_LOCATION` information is not available, it will immediately return a failure.

#### iOS
```objc
- (void)setUserSeatLocation:(SDLGrid *)location withCompletionHandler:(SDLRemoteControlCompletionHandler)completionHandler;
```

#### Java Suite
// TODO

#### JavaScript Suite
// TODO

### Remote Control Capabilities
// TODO

### Retrieving Module Data
Retrieving module data is an important component of remote control modules. The first segment of retrieving module data is the ability to get cached data. This will work similarly to the current `SystemCapabilityManager` and the accepted proposal for a `VehicleDataManager` [SDL-0318](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0318-app-lib-vehicle-data-manager.md).

#### Managing Module IDs
Module ids are an important feature of remote control since RPC v6.0 to allow for multiple modules of a given module type. Because the data type of a module id is a simple string, because a `null` module id refers to the default module (including on pre-6.0 systems), and because we will be storing module data in a hashmap using the module id as a key, we will provide a default string to refer to the default module id.

##### iOS
```objc
typedef NSString SDLModuleId;

extern SDLModuleId SDLDefaultModuleId = @"SDL_DEFAULT_MODULE"; // This isn't entirely correct code, but will be split between .h and .m
```

##### Other App Libraries
Other app libraries would do similar to the above in each project based on language-norms, at the project maintainers discretion.

#### Retrieving Cached Data
As noted above, cached data will be stored in a hashmap for retrieval at any time. This cache will be automatically updated whenever an `OnInteriorVehicleData` with new data is received or when a `GetInteriorVehicleDataResponse` is received with module data.

##### iOS
The iOS code will present properties for each module to retrieve the current cached module data.

```objc
@property (strong, nonatomic, readonly, nullable) NSDictionary<SDLModuleId, SDLRadioControlData *> *radioModules;
@property (strong, nonatomic, readonly, nullable) NSDictionary<SDLModuleId, SDLClimateControlData *> *climateModules;
@property (strong, nonatomic, readonly, nullable) NSDictionary<SDLModuleId, SDLSeatControlData *> *seatModules;
@property (strong, nonatomic, readonly, nullable) NSDictionary<SDLModuleId, SDLAudioControlData *> *audioModules;
@property (strong, nonatomic, readonly, nullable) NSDictionary<SDLModuleId, SDLLightControlData *> *lightModules;
@property (strong, nonatomic, readonly, nullable) NSDictionary<SDLModuleId, SDLHMISettingsControlData *> *hmiSettingsModules;
```

##### Java Suite
// TODO

##### JavaScript Suite
// TODO

#### Getting One-Time Module Data
// TODO

#### Subscribing to Module Data Updates
// TODO

### Button Presses
There will be a method on the `RemoteControlManager` to perform button presses:

#### iOS
```objc
- (void)pressButton:(SDLButtonName)buttonName withCompletionHandler:(SDLRemoteControlCompletionHandler)completionHandler;
```

#### Java Suite
```java
// TODO
```

#### JavaScript Suite
```js
// TODO
```

## Potential downsides

Describe any potential downsides or known objections to the course of action presented in this proposal, then provide counter-arguments to these objections. You should anticipate possible objections that may come up in review and provide an initial response here. Explain why the positives of the proposal outweigh the downsides, or why the downside under discussion is not a large enough issue to prevent the proposal from being accepted.

## Impact on existing code

Describe the impact that this change will have on existing code. Will some SDL integrations stop compiling due to this change? Will applications still compile but produce different behavior than they used to? Is it possible to migrate existing SDL code to use a new feature or API automatically?

## Alternatives considered

Describe alternative approaches to addressing the same problem, and why you chose this approach instead.