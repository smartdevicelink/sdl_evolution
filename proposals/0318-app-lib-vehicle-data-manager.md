# App Library: Vehicle Data Manager

* Proposal: [SDL-0318](0318-app-lib-vehicle-data-manager.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **In Review**
* Impacted Platforms: [iOS / Java Suite / JavaScript Suite]

## Introduction
This proposal introduces the `VehicleDataManager` to include high-level app library APIs for interacting with vehicle data RPCs.

## Motivation
The app libraries have increasingly moved in the direction of providing "native" high-level APIs for dealing with complex RPC systems so that developers don't need to manage the system of permissions, capabilities, etc. that come with needing to send and receive raw RPCs.

One large and important system of RPCs for SDL is vehicle data. We should provide higher-level APIs for app developers to deal with vehicle data RPCs.

## Proposed solution
The proposed solution will be to add a new manager onto `SDLManager` (iOS example shown below):

```objc
@interface SDLManager
// Existing interface

@property (strong, nonatomic, readonly) SDLVehicleDataManager *vehicleDataManager;

@end
```

This manager will handle all vehicle data related RPCs and permissions. It will support retrieving updated information, subscribing to vehicle data, and determining what information is available to the developer based on permissions. This section will be structured to show each individual aspect of the manager in turn.

It will be initialized along with the other managers but has a dependency on the permission manager.

### Determining Permissions
Determining permissions is very important because most apps will only have the ability to access some – but not all – available vehicle data, some head units have different vehicle data available, and the availability of vehicle data may change over the app's lifecycle (based on user permissions, HMI level, etc.).

#### iOS
```objc
/// The update handler for vehicle data permissions.
///
/// @param updatedPermissionStatuses The permission status of the subscribed vehicle data types. Will contain [key: type, value: YES if allowed, NO if disallowed].
/// @param status The group status of the updatedPermissionStatuses. Allowed if all the types are allowed, Disallowed if all the types are disallowed, Mixed if some are allowed and some are disallowed, Unknown if the status is not known.
typedef void (^SDLVehicleDataPermissionsChangedHandler)(NSDictionary<SDLVehicleDataType, NSNumber<SDLBool> *> *updatedPermissionStatuses, SDLPermissionGroupStatus status);

/// Subscribe to the permissions for given vehicle data types. This is a convenience method for the SDLPermissionManager. Pass the vehicle data types that you wish to subscribe permissions, the group type, which governs when the permissionsHandler will be called, and the permissions handler, which returns the permissions of the various vehicle data types.
///
/// Under the hood, the manager checks the ability to use the `GetVehicleData`, `SubscribeVehicleData`, and `UnsubscribeVehicleData` RPCs. If any of these RPCs are not allowed, the permissions dictionary will be returned with all permissions as `@NO`. When this method is called, a `GetVehicleData` permission check will be set up with the appropriate parameter permissions. When these permissions are retrieved or updated, the `permissionsHandler` will be called with updated permissions based on the parameter permissions.
///
/// @param vehicleDataTypes The vehicle data types to check
/// @param groupType When the permissionsHandler should be called. If `AllAllowed`, the handler will be called only when the permissions are either all permitted or go from all permitted to some not permitted. The handler will not be called for the first time until all types are permitted. If `Any`, the handler will be called whenever the permissions change and will be called for the first time as soon as data is available.
/// @param permissionsHandler The block to be called when permissions are available and the `groupType` constraint is satisfied.
/// @return The observer identifier for this permission subscription. This identifier can be used to unsubscribe from either this manager or from the `SDLPermissionManager`.
- (SDLPermissionObserverIdentifier)subscribeToPermissionsWithVehicleDataTypes:(NSArray<SDLVehicleDataType> *)vehicleDataTypes groupType:(SDLPermissionGroupType)groupType permissionsHandler:(SDLVehicleDataPermissionsChangedHandler)permissionsHandler;

/// Unsubscribe from permissions for vehicle data type based on an identifier retrieved from the `subscribeToPermissionsWithVehicleDataTypes:groupType:permissionsHandler`.
///
/// @param permissionIdentifier An identifer to use to unsubscribe
- (void)unsubscribeVehicleDataTypePermissions:(SDLPermissionObserverIdentifier)permissionIdentifier;
```

#### Java Suite
```java
public interface OnVehicleDataPermissionChangeListener {
    void onPermissionsChange(@NonNull Map<VehicleDataType, Bool> allowedVehicleData, @NonNull @PermissionManager.PermissionGroupStatus int status);
}

public UUID addListener(@NonNull List<VehicleDataType> types, @PermissionGroupType int groupType, @NonNull OnVehicleDataPermissionChangeListener listener);

public void removeListener(@NonNull UUID listenerId);
```

#### JavaScript Suite
```js
addListener(vehicleDataTypes, groupType, listener)
removeListener(permissionUuid)
```

### Retrieving Current Data
There are two ways to retrieve data without a subscription: retrieving the cached data and updating the newest data. Whenever app data is updated the cached data will be updated as well.

#### iOS

##### Cached Data
The iOS library will cache vehicle data in a similar way to how it caches system capabilities: each piece of vehicle data will be stored separately on the manager, like so:

```objc
@property (strong, nonatomic, nullable) SDLGPSData *gps;
@property (nullable, strong, nonatomic) NSNumber<SDLFloat> *speed;
@property (nullable, strong, nonatomic) NSNumber<SDLInt> *rpm;
@property (nullable, strong, nonatomic) NSNumber<SDLFloat> *fuelLevel;
@property (nullable, strong, nonatomic) SDLComponentVolumeStatus fuelLevelState;
@property (nullable, strong, nonatomic) NSArray<SDLFuelRange *> *fuelRange;
@property (nullable, strong, nonatomic) NSNumber<SDLFloat> *instantFuelConsumption;
@property (nullable, strong, nonatomic) NSNumber<SDLFloat> *externalTemperature;
@property (nullable, strong, nonatomic) NSString *vin;
@property (nullable, strong, nonatomic) SDLPRNDL prndl;
@property (nullable, strong, nonatomic) SDLTireStatus *tirePressure;
@property (nullable, strong, nonatomic) NSNumber<SDLInt> *odometer;
@property (nullable, strong, nonatomic) SDLBeltStatus *beltStatus;
@property (nullable, strong, nonatomic) SDLBodyInformation *bodyInformation;
@property (nullable, strong, nonatomic) SDLDeviceStatus *deviceStatus;
@property (nullable, strong, nonatomic) SDLVehicleDataEventStatus driverBraking;
@property (nullable, strong, nonatomic) SDLWiperStatus wiperStatus;
@property (nullable, strong, nonatomic) SDLHeadLampStatus *headLampStatus;
@property (nullable, strong, nonatomic) NSNumber<SDLFloat> *engineOilLife;
@property (nullable, strong, nonatomic) NSNumber<SDLFloat> *engineTorque;
@property (nullable, strong, nonatomic) NSNumber<SDLFloat> *accPedalPosition;
@property (nullable, strong, nonatomic) NSNumber<SDLFloat> *steeringWheelAngle;
@property (nullable, strong, nonatomic) SDLECallInfo *eCallInfo;
@property (nullable, strong, nonatomic) SDLAirbagStatus *airbagStatus;
@property (nullable, strong, nonatomic) SDLEmergencyEvent *emergencyEvent;
@property (nullable, strong, nonatomic) SDLClusterModeStatus *clusterModeStatus;
@property (nullable, strong, nonatomic) SDLMyKey *myKey;
@property (nullable, strong, nonatomic) SDLElectronicParkBrakeStatus electronicParkBrakeStatus;
@property (nullable, strong, nonatomic) SDLTurnSignal turnSignal;
@property (nullable, strong, nonatomic) NSString *cloudAppVehicleID;
```

Note that the above is a 1-1 representation of `OnVehicleData`, however, this may not always be the case. For example, with the change recommended in [SDL-0256 Refactor Fuel Information Related Data](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0256-Refactor-Fuel-Information-Related-Vehicle-Data.md), the SDLC Project Maintainer may decide that it is best to deprecate all the old elements and to coerce the old data types into the new data structure automatically.

##### Retrieving Updated Data
Retrieving updated data is similar to subscribing, but only happens one time and uses `GetVehicleData` under the hood.

```objc
/// A handler to be called when vehicle data updates
///
/// @param type The vehicle data type that updated
/// @param manager The vehicle data manager. Retrieve the updated vehicle data by retrieving the cached data on the manager.
/// @param error An error if one occurred. The error will specify if the type was disallowed by the system, the user, or some other reason.
typedef void (^SDLVehicleDataUpdateHandler)(SDLVehicleDataType type, NSError *_nullable error, SDLVehicleDataManager *manager);

/// Requests updated data from the head unit for some vehicle data types. If the data is already subscribed by some observer, the cached data is up to date, so no request will be sent for that type.
/// @param type The vehicle data types to request.
/// @param handler The handler to be called when the vehicle data has finished updating.
- (void)updateVehicleDataTypes:(NSArray<SDLVehicleDataType> *)types completionHandler:(SDLVehicleDataUpdateHandler)handler;
```

#### Java Suite
##### Cached Data
The Java Suite handles cached data differently than the iOS and JavaScript Suite libraries. They provide a single method and rely on the developer to cast the result.

```java
public Object getCapability(final VehicleDataType type);
```

##### Retrieving Updated Data
```java
public interface OnVehicleDataListener {
    void onVehicleDataChanged(@NonNull VehicleDataType type, VehicleDataManager manager);
    void onVehicleDataError(String info);
}

public void updateCapabilities(final List<VehicleDataType> types, final OnVehicleDataListener listener);
```

#### JavaScript Suite
##### Cached Data
The cached data will be similar to the iOS version of cached data above.

##### Retrieving Updated Data
```js
async updateCapability (vehicleDataType)
```

### Subscribing to Data
When data is subscribed, the developer will receive updates on a regular basis as the vehicle data value updates. It uses the `SubscribeVehicleData` and `UnsubscribeVehicleData` RPCs under the hood.

#### iOS
```objc
/// A handler to be called when vehicle data unsubscribes
///
/// @param error An error if one occurred while unsubscribing
typedef void (^SDLVehicleDataUnsubscribeHandler)(NSError *_nullable error);

/// Subscribes to one or more pieces of vehicle data and calls a handler when any of the types is updated. It will call the handler individually for each update. Vehicle data will be subscribed individually under-the-hood, meaning that the if an error is called, it only relates to that one vehicle data type, but that the callback may be called multiple times with multiple errors.
///
/// @param types The vehicle data types to subscribe to for this handler
/// @param handler The handler to call every time any of the specified vehicle data types update
/// @return A unique object that can be passed to `unsubscribeFromVehicleData:withObserver:`
- (id<NSObject>)subscribeToVehicleData:(NSArray<SDLVehicleDataType>)types withUpdateHandler:(SDLVehicleDataUpdateHandler)handler;

/// Subscribes to one or more pieces of vehicle data and calls a selector on an observer when any of these types is updated. It will call the handler individually for each update. Vehicle data will be subscribed individually under the hood, meaning that if an error is called, it only relates to that one vehicle data type, but that the callback may be called multiple times with multiple errors.
///
/// The selector must exist with between 0 and 3 parameters. If zero parameters, the selector will be called, but you will be unable to determine which type was updated or know about any errors that occur. If one parameter, the parameter must be of type `SDLVehicleDataType`, which is the type that was updated. If two parameters, the second parameter must be of type `NSError` and will be an error that occurs when subscribing to the `types`. If three parameters, the third parameter must be of type `SDLVehicleDataManager`. For example, `vehicleDataTypeDidUpdate:(SDLVehicleDataType)type error:(NSError *)error manager:(SDLVehicleDataManager *)manager`.
- (id<NSObject>)subscribeToVehicleData:(NSArray<SDLVehicleDataType>)types withObserver:(id)observer selector:(SEL)selector;

/// Unsubscribes from one or more pieces of vehicle data on the given observer. This means that you can unsubscribe from only some vehicle data for the given observer and leave the rest. Attempting to unsubscribe from vehicle data types that are not subscribed for this observer will silently ignore those types and not fail. If there are no more observers subscribed to a given type, the app library will unsubscribe from the head unit for that type.
///
/// @param types The vehicle data types that will be unsubscribed for the observer.
/// @param observer The observer to unsubscribe types on.
/// @param unsubscribeHandler The handler that will be called when unsubscribing completes, including an error if one occurred.
- (void)unsubscribeFromVehicleData:(NSArray<SDLVehicleDataType>)types withObserver:(id)observer completionHandler:(SDLVehicleDataUnsubscribeHandler)unsubscribeHandler;
```

#### Java Suite
```java
public void addOnVehicleDataListener(final List<VehicleDataType> types, final OnVehicleDataListener listener);

public void removeOnVehicleDataListener(final List<VehicleDataType> types, final OnVehicleDataListener listener);
```

#### JavaScript Suite
```js
addVehicleDataListener(vehicleDataTypes, listener)
removeVehicleDataListener(vehicleDataTypes, listener)
```

## Potential downsides
1. Introducing a vehicle data manager means that additions, deprecations, and changes to the RPC structure of vehicle data become more complex. Proposal authors must consider the manager system and update it accordingly. Most of the time this will be simple. However, some recent proposals like [SDL-0256 Refactor Fuel Information Related Data](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0256-Refactor-Fuel-Information-Related-Vehicle-Data.md) may require larger changes to handle various versions of Core in a simple API for developers (e.g. to pull new or old data into a common interface so that developers can build once / run anywhere).

2. This will increase the maintenance burden on the app libraries to support updating the vehicle data manager when vehicle data elements update. However, the author has tried to make this manager require a minimum of updates when vehicle data is added or deprecated. There may be additional work needed in the deprecation case to support mitigation strategies if necessary.

## Impact on existing code
This will be a minor version change for all of the app libraries and is a purely additive change.

## Alternatives considered
1. Instead of passing the manager in the `SDLVehicleDataUpdateHandler` / equivalent, we could pass an `OnVehicleData` RPC with the correct data filled in. Or, we could pass an `id` / any type equivalent and assume the developer will know how to cast the data to the correct type for use.
