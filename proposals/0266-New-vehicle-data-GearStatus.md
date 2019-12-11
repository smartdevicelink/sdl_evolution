# New vehicle data GearStatus

* Proposal: [SDL-0266](0266-New-vehicle-data-GearStatus.md)
* Author: [Ankur Tiwari](https://github.com/atiwari9)
* Status: **Returned for Revisions**
* Impacted Platforms: [Core | HMI | Policy Server | SHAID | iOS | Java Suite | RPC]

## Introduction

This proposal is to add new vehicle data `GearStatus` to know drive mode and actual gear the transmission has selected.

## Motivation

In order to partner with more diverse app partners, we need to provide additional sets of vehicle data items through SDL. This goes in line with commitment to enhance SDL with even richer vehicle data content. Adding `gearDriveMode` and `actualGear` information provide more granular information on which drive mode the vehicle is in and what physical gear the transmission has selected. Also we need to add more gears to the enum to support new ten speed transmissions.

## Proposed Solution 

We need to add `GearStatus` for `GetVehicleData`, `SubscribeVehicleData`, `UnsubscribeVehicleData` & `OnVehicleData` RPCs. Vehicle data item `prndl` would be deprecated as it is now covered in `GearStatus`. Following are the changes needed in MOBILE_API and HMI_API:

### Updates in MOBILE_API:

#### Update enum `VehicleDataType`: 

```xml	
<element name="VEHICLEDATA_GEARSTATUS" since="X.x"/>
<element name="VEHICLEDATA_PRNDL" until="X.x"/>
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
		<description>Regular Drive mode</description>
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

#### Deprecate enum `PRNDL`:
```xml
<enum name="PRNDL" since="2.0" until="X.x">
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
	<element name="UNKNOWN">
	</element>
	<element name="FAULT">
	</element>
</enum>
```

#### Update following parameters in these function requests:
* `SubscribeVehicleData`
* `UnsubscribeVehicleData`
* `GetVehicleData`

```xml	
<param name="gearStatus" type="Boolean" mandatory="false" since="X.x">
	<description>See GearStatus</description>
</param>
<param name="prndl" type="Boolean" mandatory="false" deprecated="true" since="X.x">
	<description>See PRNDL. This parameter is deprecated starting RPC Spec X.x.x, please see gearStatus.</description>
</param>
```

#### Update following parameters in these function responses:
* `SubscribeVehicleData`
* `UnsubscribeVehicleData`

```xml	
<param name="gearStatus" type="VehicleDataResult" mandatory="false" since="X.x">
	<description>See GearStatus</description>
</param>
<param name="prndl" type="VehicleDataResult" mandatory="false" deprecated="true" since="X.x">
	<description>See PRNDL. This parameter is deprecated starting RPC Spec X.x.x, please see gearStatus.</description>
</param>
```

#### Update following parameters in these function responses:
* `GetVehicleData`
* `OnVehicleData`

```xml	
<param name="gearStatus" type="GearStatus" mandatory="false" since="X.x">
	<description>See GearStatus</description>
</param>
<param name="prndl" type="PRNDL" mandatory="false" deprecated="true" since="X.x">
	<description>See PRNDL. This parameter is deprecated starting RPC Spec X.x.x, please see gearStatus.</description>
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
	<param name="gearDriveMode" type="Common.GearPosition" mandatory="false">
		<description>Tells the gear drive mode i.e. PARK, DRIVE, SPORT etc</description>
	</param>
	<param name="actualGear" type="Common.GearPosition" mandatory="false">
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
		<description>Regular Drive mode</description>
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
#### Add the following parameter to these function requests:
* `SubscribeVehicleData`
* `UnsubscribeVehicleData`
* `GetVehicleData`

```xml	
<param name="gearStatus" type="Boolean" mandatory="false">
	<description>See GearStatus</description>
</param>
```

#### Add the following parameter to these function responses:
* `SubscribeVehicleData`
* `UnsubscribeVehicleData`

```xml	
<param name="gearStatus" type="Common.VehicleDataResult" mandatory="false">
	<description>See GearStatus</description>
</param>
```

#### Add the following parameter to these function responses:
* `GetVehicleData`
* `OnVehicleData`

```xml	
<param name="gearStatus" type="Common.GearStatus" mandatory="false">
	<description>See GearStatus</description>
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
