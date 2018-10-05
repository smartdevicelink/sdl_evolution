# Interior Vehicle Data resumption

* Proposal: [SDL-0188](0188-get-interior-data-resumption.md)
* Author: [Alexander Kutsan](https://github.com/LuxoftAKutsan)
* Status: **Accepted**
* Impacted Platforms: [Core, HMI]

## Introduction

This proposal is to restore Interior data subscriptions on application registration after unexpected disconnect or ignition cycle.

## Motivation

There is persistence data resumption mechanism available in SDL. 
Resumption restores persistent data on application registration, after unexpected disconnect or ignition off. 
It improves user experience by keeping persistence data stored on SDL across ignition cycles.  
Subscriptions to interior vehicle data is also persistence data and should be restored during application resumption.

## Proposed solution

Interior vehicle data subscriptions should be added to resumption data. 
SDL should update hash of resumption data after application was subscribed or unsubscribed to interior vehicle data and send `OnHashUpdate` notification to mobile application.

In case application was unexpectedly disconnected or SDL was stopped when application was registered,
SDL should save application subscriptions internally and keep them for 3 ignition cycles.

If correct hash was provided by the next application registration, interior vehicle data subscription should be restored.
All existing resumption rules should be applied for Interior vehicle data resumption.

Documentation has to be added to hashID in registerAppInterface in the RPC spec including the MOBILE_API.xml file in Core.
Hash ID Resumption information should be added to the Best Practices guide.


#### Restoring Interior vehicle data

Restoring interior vehicle data means that SDL should :
 - Send `GetInteriorData(IsSubscribe=true)` to HMI and store data received from HMI in cache.
 - Restore subscription for the app internally (OnInteriorVehicleData notification from HMI should be transmitted to mobile)

SDL should behave the same as before disconnect.

#### Error handling during resumption

If during resumption HMI responds with error to GetInteriorVehicleDataRequest SDL should revert already subscribed data and fail resumption. 
Reverting subscriptions means internally removing information about this subscription.
In the case that after reverting the subscription, there is no application subscribed to a certain module type, SDL should send `GetInteriorData(IsSubscribe=false)` to HMI and clear cache for this module type.
Interior vehicle data resumption error handling should follow the same rules as regular vehicle data resumption error handling. 

## SetInteriorVehicleData behaviour changes: 

If mobile send `SetInteriorVehicleData (subscribe=true, moduleType=MODULE1)`, but the application is already subscribed on `MODULE1` module type the resultCode should be `WARNING` because of double subscription and info should contain information if an app is already subscribed.

## Potential downsides

N/A

## Impact on existing code

Impacts resumption component and basic sequences of SDL usage.
No changes needed in Proxy.
Some changes required for sdl_hmi for testing error response. 

## Alternatives considered

Don't resume interior vehicle data

