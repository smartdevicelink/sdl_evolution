# New vehicle data GearStatus

* Proposal: [SDL-NNNN](NNNN-New-vehicle-data-GearStatus.md)
* Author: [Ankur Tiwari](https://github.com/atiwari9)
* Status: **Awaiting review**
* Impacted Platforms: [Core | HMI | Policy Server | SHAID | iOS | Java Suite]

## Introduction

This proposal is to add new vehicle data `GearStatus` to know drive mode and actual gear the transmission has selected.

## Motivation

In order to partner with more diverse app partners, we need to provide additional sets of vehicle data items through SDL. This goes in line with commitment to enhance SDL with even richer vehicle data content.

## Proposed Solution 

We need to add `GearStatus` for `GetVehicleData`, `SubscribeVehicleData`, `UnsubscribeVehicleData` & `OnVehicleData` RPCs. Following are the changes needed in API:

### Updates in MOBILE_API:

#### Add to enum `VehicleDataType`: 

```xml	
<element name="VEHICLEDATA_GEARSTATUS" since="X.x"/>
```
#### Add new struct `GearStatus`:

```xml	
<struct name="GearStatus" since="x.x">
	<param name="gearDriveMode" type="GearPosition" mandatory="false">
		<description>Tells the gear drive mode i.e. PARK, DRIVE, SPORT etc</description>
	</param>
	<param name="actualGear" type="GearPosition" mandatory="false">
		<description>Tells the actual gear selected by transmission</description>
	</param>
</struct>
```
#### Add new enum `GearPosition`:

```xml	
<enum name="GearPosition" since="x.x">
	<description>The selected gear.</description>
	<element name="PARK">
		<description>Parking</description>
	</element>
	<element name="REVERSE">
		<description>Reverse gear</description>
	</element>
	<element name="NEUTRAL">
		<description>No gear</description>
	</element>
	<element name="DRIVE">
	</element>
	<element name="SPORT">
		<description>Drive Sport mode</description>
	</element>
	<element name="LOWGEAR">
		<description>1st gear hold</description>
	</element>
	<element name="FIRST">
	</element>
	<element name="SECOND">
	</element>
	<element name="THIRD">
	</element>
	<element name="FOURTH">
	</element>
	<element name="FIFTH">
	</element>
	<element name="SIXTH">
	</element>
	<element name="SEVENTH">
	</element>
	<element name="EIGHTH">
	</element>
	<element name="NINTH">
	</element>
	<element name="TENTH">
	</element>
	<element name="UNKNOWN">
	</element>
	<element name="FAULT">
	</element>
</enum>	
```
#### Add to function `SubscribeVehicleData` request: 

```xml	
<param name="gearStatus" type="Boolean" mandatory="false" since="X.x">
	<description>See GearStatus</description>
</param>
```
#### Add to function `SubscribeVehicleData` response: 

```xml	
<param name="gearStatus" type="VehicleDataResult" mandatory="false" since="X.x">
	<description>See GearStatus</description>
</param>
```
#### Add to function `UnsubscribeVehicleData` request: 

```xml	
<param name="gearStatus" type="Boolean" mandatory="false" since="X.x">
	<description>See GearStatus</description>
</param>
```
#### Add to function `UnsubscribeVehicleData` response: 

```xml	
<param name="gearStatus" type="VehicleDataResult" mandatory="false" since="X.x">
	<description>See GearStatus</description>
</param>
```
#### Add to function `GetVehicleData` request: 

```xml	
<param name="gearStatus" type="Boolean" mandatory="false" since="X.x">
	<description>See GearStatus</description>
</param>
```
#### Add to function `GetVehicleData` response: 

```xml	
<param name="gearStatus" type="GearStatus" mandatory="false" since="X.x">
	<description>See GearStatus</description>
</param>
```
#### Add to function `OnVehicleData` response: 

```xml	
<param name="gearStatus" type="GearStatus" mandatory="false" since="X.x">
	<description>See GearStatus</description>
</param>
```
### Updates in HMI_API 

#### Add to enum `VehicleDataType` in `Common` interface: 

```xml	
<element name="VEHICLEDATA_GEARSTATUS"/>
```
#### Add new struct `GearStatus` in `Common` interface:

```xml	
<struct name="GearStatus">
	<param name="gearDriveMode" type="GearPosition" mandatory="false">
		<description>Tells the gear drive mode i.e. PARK, DRIVE, SPORT etc</description>
	</param>
	<param name="actualGear" type="GearPosition" mandatory="false">
		<description>Tells the actual gear selected by transmission</description>
	</param>
</struct>
```
#### Add new enum `GearPosition` in `Common` interface:

```xml	
<enum name="GearPosition">
	<description>The selected gear.</description>
	<element name="PARK">
		<description>Parking</description>
	</element>
	<element name="REVERSE">
		<description>Reverse gear</description>
	</element>
	<element name="NEUTRAL">
		<description>No gear</description>
	</element>
	<element name="DRIVE">
	</element>
	<element name="SPORT">
		<description>Drive Sport mode</description>
	</element>
	<element name="LOWGEAR">
		<description>1st gear hold</description>
	</element>
	<element name="FIRST">
	</element>
	<element name="SECOND">
	</element>
	<element name="THIRD">
	</element>
	<element name="FOURTH">
	</element>
	<element name="FIFTH">
	</element>
	<element name="SIXTH">
	</element>
	<element name="SEVENTH">
	</element>
	<element name="EIGHTH">
	</element>
	<element name="NINTH">
	</element>
	<element name="TENTH">
	</element>
	<element name="UNKNOWN">
	</element>
	<element name="FAULT">
	</element>
</enum>	
```
#### Add to function `SubscribeVehicleData` request: 

```xml	
<param name="gearStatus" type="Boolean" mandatory="false">
	<description>See GearStatus</description>
</param>
```
#### Add to function `SubscribeVehicleData` response: 

```xml	
<param name="gearStatus" type="Common.VehicleDataResult" mandatory="false">
	<description>See GearStatus</description>
</param>
```
#### Add to function `UnsubscribeVehicleData` request: 

```xml	
<param name="gearStatus" type="Boolean" mandatory="false">
	<description>See GearStatus</description>
</param>
```
#### Add to function `UnsubscribeVehicleData` response: 

```xml	
<param name="gearStatus" type="Common.VehicleDataResult" mandatory="false">
	<description>See GearStatus</description>
</param>
```
#### Add to function `GetVehicleData` request: 

```xml	
<param name="gearStatus" type="Boolean" mandatory="false">
	<description>See GearStatus</description>
</param>
```
#### Add to function `GetVehicleData` response: 

```xml	
<param name="gearStatus" type="Common.GearStatus" mandatory="false">
	<description>See GearStatus</description>
</param>
```
#### Add to function `OnVehicleData` response: 

```xml	
<param name="gearStatus" type="Common.GearStatus" mandatory="false">
	<description>See GearStatus</description>
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
