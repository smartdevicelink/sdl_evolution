# New vehicle data HVBatteryLevel

* Proposal: [SDL-0254](0254-New-vehicle-data-HVBatteryLevel.md)
* Author: [Ankur Tiwari](https://github.com/atiwari9)
* Status: **In Review**
* Impacted Platforms: [Core | HMI | Policy Server | SHAID | iOS | Java Suite | RPC]

## Introduction

This proposal is to add new vehicle data `HVBatteryLevel` to know battery charge level for high voltage battery.

## Motivation

In order to partner with more diverse app partners, we need to provide additional sets of vehicle data items through SDL. This goes in line with commitment to enhance SDL with even richer vehicle data content. We need to provide the battery charge level for Electric and Hybrid vehicles to apps which provide navigation, charge station information etc.

## Proposed Solution 

We need to add `HVBatteryLevel` for `GetVehicleData`, `SubscribeVehicleData`, `UnsubscribeVehicleData` & `OnVehicleData` RPCs. Following are the changes needed in MOBILE_API and HMI_API:

### Updates in MOBILE_API:

#### Add to enum `VehicleDataType`: 

```xml	
<element name="VEHICLEDATA_HVBATTERYLEVEL" since="X.x"/>
```

#### Add the following parameter to these function requests:
* `SubscribeVehicleData`
* `UnsubscribeVehicleData`
* `GetVehicleData`

```xml	
<param name="hvBatteryLevel" type="Boolean" mandatory="false" since="X.x">
	<description>Percentage of High Voltage battery charge available</description>
</param>
```

#### Add the following parameter to these function responses:
* `SubscribeVehicleData`
* `UnsubscribeVehicleData`

```xml	
<param name="hvBatteryLevel" type="VehicleDataResult" mandatory="false" since="X.x">
	<description>Percentage of High Voltage battery charge available</description>
</param>
```

#### Add the following parameter to these function responses:
* `GetVehicleData`
* `OnVehicleData`

```xml	
<param name="hvBatteryLevel" type="Float" minvalue="0" maxvalue="150" mandatory="false" since="X.x">
	<description>Percentage of High Voltage battery charge available</description>
</param>
```

### Updates in HMI_API 

#### Add to enum `VehicleDataType` in `Common` interface: 

```xml	
<element name="VEHICLEDATA_HVBATTERYLEVEL"/>
```
#### Add the following parameter to these function requests:
* `SubscribeVehicleData`
* `UnsubscribeVehicleData`
* `GetVehicleData`

```xml	
<param name="hvBatteryLevel" type="Boolean" mandatory="false">
	<description>Percentage of High Voltage battery charge available</description>
</param>
```

#### Add the following parameter to these function responses:
* `SubscribeVehicleData`
* `UnsubscribeVehicleData`

```xml	
<param name="hvBatteryLevel" type="Common.VehicleDataResult" mandatory="false">
	<description>Percentage of High Voltage battery charge available</description>
</param>
```

#### Add the following parameter to these function responses:
* `GetVehicleData`
* `OnVehicleData`

```xml	
<param name="hvBatteryLevel" type="Float" minvalue="0" maxvalue="150" mandatory="false">
	<description>Percentage of High Voltage battery charge available</description>
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
