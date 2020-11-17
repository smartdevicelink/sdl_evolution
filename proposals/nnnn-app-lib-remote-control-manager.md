# App Library Remote Control Manager

* Proposal: [SDL-NNNN](nnnn-app-lib-remote-control-manager.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Awaiting review**
* Impacted Platforms: [iOS / Java Suite / JavaScript Suite]

## Introduction
This proposal adds a remote control manager to the app libraries which manages everything related to the remote control systems on head units and allows apps to more conveniently retrieve and set remote control data.

## Motivation
The remote control system on head units is incredibly complicated and requires certain procedures to occur in order to properly control a head unit's remote control modules. Additionally, those requirements have changed over time when we added support for multiple modules of a given type, meaning that developers must go through different procedures depending on the RPC version of the head unit.

## Proposed solution
We will add a remote control manager to handle the various procedures and data retrieval that is possible.

### Startup
If the app's HMI types contains `REMOTE_CONTROL`, then the remote control manager will be started, otherwise, it will not be started and all methods will return an immediate failure. If the RPC version of the connected head unit is less than 4.5 or if `RegisterAppInterface(Response).hmiCapabilities.remoteControl == false`, the manager will not be started and all methods will return an immediate failure. 

After the manager is started, if an `OnRCStatus` notification is received with `OnRCStatus.allowed == false`, methods will return a failure. If the RPC permissions for `GetInteriorVehicleData` are disallowed, methods will return a failure.

When the remote control manager is started, it will subscribe to `SystemCapabilityType.REMOTE_CONTROL` and `OnInteriorVehicleData`, and also subscribe to `OnRCStatus` to track which modules are allocated to the application on RPC 5.0+.

### Seats and User Consent Information
#### Getting Seat Location Information
When connected to a system on RPC 6.0+ and `HMICapabilities.seatLocation == true`, the remote control manager will also attempt to subscribe to `SystemCapabilityType.SEAT_LOCATION`. The seat location information will be stored to a property:

##### iOS
```objc
@property (strong, nonatomic, nullable, readonly) SDLSeatLocationCapability *seatLocations;
```

##### Java Suite
```java
public SeatLocationCapability getSeatLocations()
```

##### JavaScript Suite
```js
getSeatLocations()
```

#### Setting the User's Seat
When connected to v6.0+, developers may set the user's seat location, and it will default to the driver seat. There will be a method to set a new location for the user's seat. If this method is called on less than RPC 6.0, it will immediately return a failure. If this method is called when `HMICapabilities.seatLocation == false` or `SystemCapabilityType.SEAT_LOCATION` information is not available, it will immediately return a failure.

##### iOS
```objc
typedef void(^SDLRemoteControlCompletionHandler)(NSError *__nullable error);

- (void)setUserSeatLocation:(SDLGrid *)location withCompletionHandler:(SDLRemoteControlCompletionHandler)completionHandler;
```

##### Java Suite
```java
public interface RemoteControlCompletionListener {
    void onComplete(boolean success, String errorInfo);
}

public void setUserSeatLocation(Grid location, RemoteControlCompletionListener completionListener)
```

##### JavaScript Suite
```js
async setUserSeatLocation(location)
```

#### Getting User Consent
On RPC 6.0+ systems, an app may be required to request access to a remote control module from the user, but it should only do when it actually needs that access. The developer will be able to request user consent manually for a module or modules whenever it makes sense within their app's flow.

In order to streamline this for developers, if the app is running on a RPC 6.0+ system and consent has not been manually requested for a given module (see below), this RPC will be sent and resolved before attempting to set the module data.

##### iOS
```objc
/// If the moduleId is not present, the request status is unknown.
@property (strong, nonatomic, readonly) NSDictionary<SDLModuleId *, NSNumber<SDLBool> *> *moduleConsentStatus;

/// Request consent to control a module or modules from the SDL system and the user.
- (void)requestConsentForModuleIds:(NSArray<SDLModuleId *> *)moduleIds withCompletionHandler:(SDLRemoteControlCompletionHandler)completionHandler;
```

##### Java Suite
```java
public HashMap<ModuleId, boolean> getModuleConsentStatus;

public void requestConsent(Array<ModuleId *> moduleIds, RemoteControlCompletionListener listener);
```

##### JavaScript Suite
```js
getModuleConsentStatus()

async requestConsent(moduleIds)
```

### Remote Control Capabilities
The remote control capabilities are an important way to know which modules are available for setting / retrieving data. On RPC v4.5 - v5.0, the remote control capabilities will be retrieved after starting the manager using the `SystemCapabilityManager`. On RPC v5.1+, the capability will be subscribed.

The capabilities give information about whether certain module data is available. This _will not_ be used to specify if the developer can request or attempt to set data. That mapping will not be done by the app library. This data will only be used for developer knowledge about making certain features available or unavailable in their app.

These capabilities will be made publicly available:

##### iOS
```objc
@property (strong, nonatomic, readonly, nullable) SDLClimateControlCapabilities *climateCapabilities;
@property (strong, nonatomic, readonly, nullable) SDLRadioControlCapabilities *radioCapabilities;
@property (strong, nonatomic, readonly, nullable) SDLButtonCapabilities *buttonCapabilities;
@property (strong, nonatomic, readonly, nullable) SDLAudioControlCapabilities *audioCapabilities;
@property (strong, nonatomic, readonly, nullable) SDLHMISettingsControlCapabilities *hmiSettingsCapabilities;
@property (strong, nonatomic, readonly, nullable) SDLLightControlCapabilities *lightCapabilities;
@property (strong, nonatomic, readonly, nullable) SDLSeatControlCapabilities *seatCapabilities;
```

##### Java Suite
```java
public RemoteControlCapabilities getCapability(ModuleType type)
```

##### JavaScript Suite
```js
getClimateCapabilities()
getRadioCapabilities()
getButtonCapabilities()
getAudioCapabilities()
getHMISettingsCapabilities()
getLightCapabilities()
getSeatCapabilities()
```

### Retrieving Module Data
Retrieving module data is an important component of remote control modules. The first segment of retrieving module data is the ability to get cached data. This will work similarly to the current `SystemCapabilityManager` and the accepted proposal for a `VehicleDataManager` [SDL-0318](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0318-app-lib-vehicle-data-manager.md).

#### Default Module IDs
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
```java
public Object getModuleData(ModuleType moduleType, String moduleId);
```

##### JavaScript Suite
The cached data will be stored similarly to the iOS data above at the project maintainers discretion.

#### Getting One-Time Module Data
Module data can be retrieved one time without ongoing updates. This method uses `GetInteriorVehicleData` with `subscribe = null` under the hood. If a module is already subscribed, this method will not send an RPC but will just return the cached data.

##### iOS
```objc
typedef void(^SDLRemoteControlDataHandler)(SDLModuleType *updatedType, SDLModuleId *updatedModuleId, SDLRemoteControlManager *remoteControlManager, NSError *_Nullable error);

- (void)updateModuleDataForType:(SDLModuleType)type moduleId:(SDLModuleId)moduleId completionHandler:(SDLRemoteControlDataHandler)handler;
```

##### Java Suite
```java
public interface OnRemoteControlDataListener {
    void onRemoteControlDataChanged(@NonNull ModuleType type, @NonNull ModuleId moduleId, @NonNull RemoteControlManager manager);
    void onRemoteControlDataError(@NonNull String info);
}

public void updateModuleData(final ModuleType type, final ModuleId moduleId, final OnRemoteControlDataListener listener);
```

##### JavaScript Suite
```js
async updateModuleData (moduleType, moduleId)
```

#### Subscribing to Module Data Updates
Module data can also be subscribed to in order to receive ongoing updates. This method uses `GetInteriorVehicleData` with `subscribe = true` under the hood. If a module is already subscribed, this method will not send an RPC but will return the cached data and still call the observer whenever the module data is updated.

##### iOS
```objc
/// A handler to be called when the app unsubscribes from a remote control data module.
///
/// @param error An error if one occurred while unsubscribing
typedef void (^SDLRemoteControlUnsubscribeHandler)(NSError *_nullable error);

/// Subscribes to a remote control module and calls a handler when that module's data is updated.
///
/// @param types The vehicle data types to subscribe to for this handler
/// @param handler The handler to call every time any of the specified vehicle data types update
/// @return A unique object that can be passed to `unsubscribeFromVehicleData:withObserver:`
- (id<NSObject>)subscribeToModuleDataForType:(SDLModuleData)type moduleId:(SDLModuleId)moduleId withUpdateHandler:(SDLRemoteControlDataHandler)handler;

/// Subscribes to a remote control module and calls a selector on an observer when that module's data is updated.
///
/// The selector must exist with between 0 and 4 parameters. If zero parameters, the selector will be called, but you will be unable to determine which module was updated or know about any errors that occur. If one parameter, the parameter must be of type `SDLModuleType`, which is the type that was updated. If two parameters, the second parameter must be of type `SDLModuleId` or `NSString` and will reflect the module id of the module being updated. The third parameter must be of type `NSError` and will be an error if one occurred. If four parameters, the fourth parameter must be of type `SDLRemoteControlManager`. For example, `moduleTypeDidUpdate:(SDLModuleType)type moduleId:(SDLModuleId)moduleId error:(NSError *)error manager:(SDLRemoteControlManager *)manager`.
/// The selector must contain 
- (id<NSObject>)subscribeToModuleDataForType:(SDLModuleData)type moduleId:(SDLModuleId)moduleId withObserver:(id)observer selector:(SEL)selector;

/// Unsubscribes from a given observer. Attempting to unsubscribe from modules that are not subscribed will silently be ignored and not fail. If there are no more observers subscribed to a given module, the app library will unsubscribe from the head unit for that type.
///
/// @param type The module type that will be unsubscribed for the observer.
/// @param moduleId The module id for the given module type that will be unsubscribed for the observer.
/// @param observer The observer to unsubscribe types on.
/// @param unsubscribeHandler The handler that will be called when unsubscribing completes, including an error if one occurred.
- (void)unsubscribeFromModuleType:(SDLModuleType)type moduleId:(SDLModuleId)moduleId withObserver:(id)observer completionHandler:(SDLRemoteControlUnsubscribeHandler)unsubscribeHandler;
```

##### Java Suite
```java
public void addModuleDataObserver(ModuleData type, ModuleId moduleId, OnRemoteControlDataListener dataListener);
public void removeModuleDataObserver(OnRemoteControlDataListener listener)
```

##### JavaScript Suite
```js
addModuleDataObserver(type, moduleId, updateListener)
removeModuleDataObserver(listener)
```

### Button Presses
There will be a method on the `RemoteControlManager` to perform button presses:

#### iOS
```objc
- (void)pressButton:(SDLButtonName)buttonName withCompletionHandler:(SDLRemoteControlCompletionHandler)completionHandler;
```

#### Java Suite
```java
public void pressButton(ButtonName buttonName, CompletionListener completionListener)
```

#### JavaScript Suite
```js
async pressButton(buttonName)
```

### Setting Module Data
An important part of remote control is the "control" part. Remote control module data can be set by the SDL app to change things on the infotainment system such as climate control.

As explained above in the section "Getting User Consent", if the app is running on an RPC 6.0+ connection then consent should be requested before attempting to set any module data. If the developer has not manually requested consent for the module before attempting to set data, consent will be requested on behalf of the app developer before the data is attempted to be set.

#### Managing Allocated Modules
Often, only one app will be allowed to change a module's data at a time, meaning that the app may or may not have the ability to change a module's data even if that module is available.

To determine if the app has the ability to set a module's data, the app should check the information retrieved by the `OnRCStatus` RPC notification. If the app has exclusive access to a module, that module will be in `OnRCStatus.allocatedModules`. If the app has access that is not exclusive (possibly "yet"), it will be in `OnRCStatus.freeModules`.

The developer can still attempt to set data to a module that is not allocated or free. The library will not stop that from happening, however, the attempt will not succeed and the head unit will reject it.

These will be converted into lists of module ids for the app developer like the following:

##### iOS
```objc
@property (strong, nonatomic, readonly, nullable) NSArray<SDLModuleId> allocatedModuleIds;
@property (strong, nonatomic, readonly, nullable) NSArray<SDLModuleId> freeModuleIds;
```

##### Java Suite
```java
public List<SDLModuleId> getAllocatedModuleIds();
public List<SDLModuleId> getFreeModuleIds();
```

##### JavaScript Suite
```js
getAllocatedModuleIds()
getFreeModuleIds()
```

#### Setting the Data
The developer can then set some data onto the module with this API:

##### iOS
```objc
/// Sets some module data for a given module.
/// NOTE: The module type and set module data must match for the module data passed, and the module id must match a known module, or be nil to specify the default module. If they do not, the call will immediately fail with an error.
- (void)setModuleData:(SDLModuleData *)data withCompletionHandler:(SDLRemoteControlCompletionHandler)completionHandler;
```

#### Java Suite
```java
public void setModuleData(ModuleData data, CompletionListener completionListener)
```

#### JavaScript Suite
```js
async setModuleData(data)
```

## Potential downsides
1. This proposal is large and complex because the feature itself is large and complex. Furthermore, remote control has changed over time (e.g. adding user seat, changing from one module to multiple) which makes this API even more complex. A goal of this proposal is to allow developers to use one flow and things will simply work no matter what the RPC version of the head unit they connect to is.
2. Because of this APIs simple existence, adding a new remote control RPC API will become more complex. However, it will be easier for developers to use.

## Impact on existing code
This would be a minor API change for the app libraries and would not affect any other platform.

## Alternatives considered
None identified.