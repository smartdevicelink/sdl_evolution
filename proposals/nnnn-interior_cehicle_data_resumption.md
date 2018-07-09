# Interior vehicle Data resumption

* Proposal: [SDL-NNNN](nnnn-get-interior-data-resumption.md)
* Author: [LuxoftAKutsan](https://github.com/LuxoftAKutsan)
* Status: **Awaiting review**
* Impacted Platforms: [Core / iOS / Android / Web]

## Introduction

Restore Interior data subscriptions on application registration after unexpected disconnect or ignition cycle.

## Motivation

There is persistence data resumption mechanism available in SDL. 
Resumption restores persistent data on application registration, after unexpected disconnect or ignition off. 
It improves user experience by keeping persistence data stored on SDL across ignition cycles. 
Subscriptions to interior vehicle data is also persistence data and should be restored during application resumption.

## Proposed solution

Interior vehicle data subscriptions should be added to resumption data. 
SDL should update hash of resumption data after application was subscribed or unsubscribed to interior vehicle data and send `OnHashUpdate` notification to mobile.

In case when application was unexpectedly disconnected or SDL was stopped when application was registered,
SDL should save application subscriptions internally and keep it for 3 (configured by ini file) ignition cycles.

If correct hash was provided by the next application registration, interior vehicle data subscription should be restored.
All existing resumption rules should be applied for Interior vehicle data resumption.

#### Restoring Interior vehicle data

Restoring interior vehicle data means that SDL should :
 - Send `GetInteriorData(IsSubscribe=true)` to HMI and store received from HMI data in cache.
 - Restore subscription for the app internally (OnInteriorVehicleData notification from HMI should be transmitted to mobile)

SDL should behave the same as before disconnect.

#### Error handling during resumption

In case if during resumption HMI respond with error to GetInteriorVehicleDataRequest SDL should revert already subscribed data and fail resumption. 

## Potential downsides

N/A

## Impact on existing code

Impacts resumption component and basic sequences of SDL usage.

## Alternatives considered

Do not resume interior vehicle data. 

