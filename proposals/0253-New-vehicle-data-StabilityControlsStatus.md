# New vehicle data StabilityControlsStatus

* Proposal: [SDL-0253](0253-New-vehicle-data-StabilityControlsStatus.md)
* Author: [Ankur Tiwari](https://github.com/atiwari9)
* Status: **Accepted**
* Impacted Platforms: [Core | HMI | Policy Server | SHAID | iOS | Java Suite | RPC]

## Introduction

This proposal is to add new vehicle data `StabilityControlsStatus` to know if stability controls like ESC, Traction Control etc. are active.

## Motivation

In order to partner with more diverse app partners, we need to provide additional sets of vehicle data items through SDL. This goes in line with commitment to enhance SDL with even richer vehicle data content. ESC, Traction Control etc. provide information about vehicle stability controls which are useful for apps that compute driver score, provide insurance and apps which provide performance data.

## Proposed Solution 

We need to add `StabilityControlsStatus` for `GetVehicleData`, `SubscribeVehicleData`, `UnsubscribeVehicleData` & `OnVehicleData` RPCs. Following are the changes needed in the MOBILE_API and HMI_API:

### Updates in MOBILE_API:

#### Add to enum `VehicleDataType`: 

```xml
<element name="VEHICLEDATA_STABILITYCONTROLSSTATUS" since="X.x"/>
```
#### Add new struct `StabilityControlsStatus`:

```xml	
<struct name="StabilityControlsStatus" since="x.x">
	<param name="escSystem" type="VehicleDataStatus" mandatory="false">
		<description>true if vehicle stability control is ON, else false</description>
	</param>
	<param name="trailerSwayControl" type="VehicleDataStatus" mandatory="false">
		<description>true if vehicle trailer sway control is ON, else false</description>
	</param>
</struct>

```

#### Add the following parameter to these function requests:
* `SubscribeVehicleData`
* `UnsubscribeVehicleData`
* `GetVehicleData`

```xml	
<param name="stabilityControlsStatus" type="Boolean" mandatory="false" since="X.x">
	<description>See StabilityControlsStatus</description>
</param>
```

#### Add the following parameter to these function responses:
* `SubscribeVehicleData`
* `UnsubscribeVehicleData`

```xml	
<param name="stabilityControlsStatus" type="VehicleDataResult" mandatory="false" since="X.x">
	<description>See StabilityControlsStatus</description>
</param>
```

#### Add the following parameter to these function responses:
* `GetVehicleData`
* `OnVehicleData`

```xml	
<param name="stabilityControlsStatus" type="StabilityControlsStatus" mandatory="false" since="X.x">
	<description>See StabilityControlsStatus</description>
</param>
```

### Updates in HMI_API 

#### Add to enum `VehicleDataType` in `Common` interface: 

```xml	
<element name="VEHICLEDATA_STABILITYCONTROLSSTATUS"/>
```
#### Add new struct `StabilityControlsStatus` in `Common` interface:

```xml	
<struct name="StabilityControlsStatus">
	<param name="escSystem" type="Common.VehicleDataStatus" mandatory="false">
		<description>true if vehicle stability control is ON, else false</description>
	</param>
	<param name="trailerSwayControl" type="Common.VehicleDataStatus" mandatory="false">
		<description>true if vehicle trailer sway control is ON, else false</description>
	</param>
</struct>
```


#### Add the following parameter to these function requests:
* `SubscribeVehicleData`
* `UnsubscribeVehicleData`
* `GetVehicleData`

```xml	
<param name="stabilityControlsStatus" type="Boolean" mandatory="false">
	<description>See StabilityControlsStatus</description>
</param>
```

#### Add the following parameter to these function responses:
* `SubscribeVehicleData`
* `UnsubscribeVehicleData`

```xml	
<param name="stabilityControlsStatus" type="Common.VehicleDataResult" mandatory="false">
	<description>See StabilityControlsStatus</description>
</param>
```

#### Add the following parameter to these function responses:
* `GetVehicleData`
* `OnVehicleData`

```xml	
<param name="stabilityControlsStatus" type="Common.StabilityControlsStatus" mandatory="false">
	<description>See StabilityControlsStatus</description>
</param>
```

## Potential downsides

Author is not aware of any downsides to proposed solution. This proposal just enhances the SDL content.

## Impact on existing code

* SDL Core needs to be updated as per new API.
* iOS/Java Suite needs to be updated to support getters/setters as per new API.
* SDL Server needs to add permissions for new vehicle data items.
* SHAID needs to add mappings for new vehicle data items as per updated spec.
* HMI needs to be updated to support new vehicle data items.

## Alternatives considered

* None
