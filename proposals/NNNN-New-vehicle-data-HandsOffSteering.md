# New vehicle data HandsOffSteering

* Proposal: [SDL-NNNN](NNNN-New-vehicle-data-HandsOffSteering.md)
* Author: [Ankur Tiwari](https://github.com/atiwari9)
* Status: **Awaiting review**
* Impacted Platforms: [Core | HMI | Policy Server | SHAID | iOS | Java Suite | RPC]

## Introduction

This proposal is to add new vehicle data `HandsOffSteering` to know whether or not a driver has his or her hands on the steering wheel.

## Motivation

In order to partner with more diverse app partners, we need to provide additional sets of vehicle data items through SDL. This goes in line with commitment to enhance SDL with even richer vehicle data content. Information about whether a driver has hands on the steering wheel or not is useful for apps that compute driver score and provide insurance.

## Proposed Solution 

We need to add `HandsOffSteering` for `GetVehicleData`, `SubscribeVehicleData`, `UnsubscribeVehicleData` & `OnVehicleData` RPCs. Following are the changes needed in MOBILE_API and HMI_API:

### Updates in MOBILE_API:

#### Add to enum `VehicleDataType`: 

```xml	
<element name="VEHICLEDATA_HANDSOFFSTEERING" since="X.x"/>
```

#### Add the following parameter to these function requests:
* `SubscribeVehicleData`
* `UnsubscribeVehicleData`
* `GetVehicleData`

```xml	
<param name="handsOffSteering" type="Boolean" mandatory="false" since="X.x">
	<description>To indicate whether driver hands are off the steering wheel</description>
</param>
```

#### Add the following parameter to these function responses:
* `SubscribeVehicleData`
* `UnsubscribeVehicleData`

```xml	
<param name="handsOffSteering" type="VehicleDataResult" mandatory="false" since="X.x">
	<description>To indicate whether driver hands are off the steering wheel</description>
</param>
```

#### Add the following parameter to these function responses:
* `GetVehicleData`
* `OnVehicleData`

```xml	
<param name="handsOffSteering" type="Boolean" mandatory="false" since="X.x">
	<description>To indicate whether driver hands are off the steering wheel</description>
</param>
```

### Updates in HMI_API 

#### Add to enum `VehicleDataType` in `Common` interface: 

```xml	
<element name="VEHICLEDATA_HANDSOFFSTEERING"/>
```

#### Add the following parameter to these function requests:
* `SubscribeVehicleData`
* `UnsubscribeVehicleData`
* `GetVehicleData`

```xml	
<param name="handsOffSteering" type="Boolean" mandatory="false">
	<description>To indicate whether driver hands are off the steering wheel</description>
</param>
```

#### Add the following parameter to these function responses:
* `SubscribeVehicleData`
* `UnsubscribeVehicleData`

```xml	
<param name="handsOffSteering" type="Common.VehicleDataResult" mandatory="false">
	<description>To indicate whether driver hands are off the steering wheel</description>
</param>
```

#### Add the following parameter to these function responses:
* `GetVehicleData`
* `OnVehicleData`

```xml	
<param name="handsOffSteering" type="Boolean" mandatory="false">
	<description>To indicate whether driver hands are off the steering wheel</description>
</param>
```

## Potential downsides

Author is not aware of any downsides to proposed solution. This proposal just enhances the SDL content.

## Impact on existing code

* SDL Core needs to be updated as per new API.
* iOS/Java Suite need to be updated to support getters/setters as per new API.
* SDL Server needs to add permissions for new vehicle data items.
* SHAID needs to add mappings for new vehicle data items as per updated spec.
* HMI needs to be updated to support new vehicle data items.

## Alternatives considered

* None
