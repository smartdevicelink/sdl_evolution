# New vehicle data WindowStatus

* Proposal: [SDL-NNNN](NNNN-New-vehicle-data-WindowStatus.md)
* Author: [Ankur Tiwari](https://github.com/atiwari9)
* Status: **Awaiting review**
* Impacted Platforms: [Core | HMI | Policy Server | SHAID | iOS | Java Suite | RPC]

## Introduction

This proposal is to add new vehicle data `WindowStatus` to know position of windows in a vehicle.

## Motivation

In order to partner with more diverse app partners, we need to provide additional sets of vehicle data items through SDL. This goes in line with commitment to enhance SDL with even richer vehicle data content. Position of window is a useful information for micro weather apps, it tells the app if window is open and at what postion.

## Proposed Solution 

We need to add `WindowStatus` for `GetVehicleData`, `SubscribeVehicleData`, `UnsubscribeVehicleData` & `OnVehicleData` RPCs. Following are the changes needed in MOBILE_API and HMI_API:

### Updates in MOBILE_API:


#### Add to enum `VehicleDataType`: 

```xml
<element name="VEHICLEDATA_WINDOWSTATUS" since="X.x"/>
```
#### Add new struct `WindowStatus`

```xml	
<struct name="WindowStatus" since="x.x">
	<param name="driverSideWindow" type="WindowState" mandatory="false">
		<description>Status of driver side window position</description>
	</param>
	<param name="passengerSideWindow" type="WindowState" mandatory="false">
		<description>Status of passenger side window position</description>
	</param>
	<param name="rearDriverSideWindow" type="WindowState" mandatory="false">
		<description>Status of rear driver side window position</description>
	</param>
	<param name="rearPassengerSideWindow" type="WindowState" mandatory="false">
		<description>Status of rear passenger side window position</description>
	</param>	
	<param name="trunkWindow" type="WindowState" mandatory="false">
		<description>Status of trunk/liftgate window position</description>
	</param>		
</struct>
```
#### Add new enum `WindowState`:

```xml    
<enum name="WindowState" since="x.x">
	<description>Reflects the postion of window.</description>
	<element name="UNDEFINED" internal_name="WP_UNDEFINED">
	</element>
	<element name="CLOSED" internal_name="WP_CLOSED">
	</element>
	<element name="BARELY_OPEN" internal_name="WP_BARELY_OPEN">
	</element>
	<element name="NEARLY_HALF_OPEN" internal_name="WP_NEARLY_HALF_OPEN">
	</element>
	<element name="NEARLY_FULL_OPEN" internal_name="WP_NEARLY_FULL_OPEN">
	</element>
	<element name="OPEN" internal_name="WP_OPEN">
	</element>
	<element name="UNUSED" internal_name="WP_UNUSED">
	</element>
</enum>
```

#### Add the following parameter to these function requests:
* `SubscribeVehicleData`
* `UnsubscribeVehicleData`
* `GetVehicleData`

```xml
<param name="windowStatus" type="Boolean" mandatory="false" since="X.x">
	<description>See WindowStatus</description>
</param>
```

#### Add the following parameter to these function responses:
* `SubscribeVehicleData`
* `UnsubscribeVehicleData`

```xml
<param name="windowStatus" type="VehicleDataResult" mandatory="false" since="X.x">
	<description>See WindowStatus</description>
</param>
```

#### Add the following parameter to these function responses:
* `GetVehicleData`
* `OnVehicleData`

```xml
<param name="windowStatus" type="WindowStatus" mandatory="false" since="X.x">
	<description>See WindowStatus</description>
</param>
```

### Updates in HMI_API:


#### Add to enum `VehicleDataType` in `Common` interface: 

```xml
<element name="VEHICLEDATA_WINDOWSTATUS"/>
```
#### Add new struct `WindowStatus` in `Common` interface:

```xml	
<struct name="WindowStatus">
	<param name="driverSideWindow" type="Common.WindowState" mandatory="false">
		<description>Status of driver side window position</description>
	</param>
	<param name="passengerSideWindow" type="Common.WindowState" mandatory="false">
		<description>Status of passenger side window position</description>
	</param>
	<param name="rearDriverSideWindow" type="Common.WindowState" mandatory="false">
		<description>Status of rear driver side window position</description>
	</param>
	<param name="rearPassengerSideWindow" type="Common.WindowState" mandatory="false">
		<description>Status of rear passenger side window position</description>
	</param>	
	<param name="trunkWindow" type="Common.WindowState" mandatory="false">
		<description>Status of trunk/liftgate window position</description>
	</param>		
</struct>
```
#### Add new enum `WindowState` in `Common` interface:

```xml    
<enum name="WindowState">
	<description>Reflects the postion of window.</description>
	<element name="UNDEFINED" internal_name="WP_UNDEFINED">
	</element>
	<element name="CLOSED" internal_name="WP_CLOSED">
	</element>
	<element name="BARELY_OPEN" internal_name="WP_BARELY_OPEN">
	</element>
	<element name="NEARLY_HALF_OPEN" internal_name="WP_NEARLY_HALF_OPEN">
	</element>
	<element name="NEARLY_FULL_OPEN" internal_name="WP_NEARLY_FULL_OPEN">
	</element>
	<element name="OPEN" internal_name="WP_OPEN">
	</element>
	<element name="UNUSED" internal_name="WP_UNUSED">
	</element>
</enum>
```

#### Add the following parameter to these function requests:
* `SubscribeVehicleData`
* `UnsubscribeVehicleData`
* `GetVehicleData`

```xml
<param name="windowStatus" type="Boolean" mandatory="false">
	<description>See WindowStatus</description>
</param>
```

#### Add the following parameter to these function responses:
* `SubscribeVehicleData`
* `UnsubscribeVehicleData`

```xml
<param name="windowStatus" type="Common.VehicleDataResult" mandatory="false">
	<description>See WindowStatus</description>
</param>
```

#### Add the following parameter to these function responses:
* `GetVehicleData`
* `OnVehicleData`

```xml
<param name="windowStatus" type="Common.WindowStatus" mandatory="false">
	<description>See WindowStatus</description>
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
