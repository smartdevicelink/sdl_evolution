# New vehicle data WindowStatus

* Proposal: [SDL-NNNN](NNNN-New-vehicle-data-WindowStatus.md)
* Author: [Ankur Tiwari](https://github.com/atiwari9)
* Status: **Awaiting review**
* Impacted Platforms: [Core | HMI | Policy Server | SHAID | iOS | Java Suite | RPC]

## Introduction

This proposal is to add new vehicle data `WindowStatus` to know the position of windows in a vehicle.

## Motivation

In order to partner with more diverse app partners, we need to provide additional sets of vehicle data items through SDL. This goes in line with commitment to enhance SDL with even richer vehicle data content. The position of windows is useful information for micro weather apps; it tells the app if a window is open and at what position.

## Proposed Solution 

We need to add `WindowStatus` for `GetVehicleData`, `SubscribeVehicleData`, `UnsubscribeVehicleData` & `OnVehicleData` RPCs. Following are the changes needed in MOBILE_API and HMI_API:

### Updates in MOBILE_API:


#### Add to enum `VehicleDataType`: 

```xml
<element name="VEHICLEDATA_WINDOWSTATUS" since="X.x"/>
```

#### Add new struct `WindowStatus`:
```xml	
<struct name="WindowStatus" since="X.x">
	<param name="doorsWindowStatus" type="DoorWindowStatus" array="true" minsize="0" maxsize="100" mandatory="false">
		<description>Status of doors window position</description>
	</param>
	<param name="gatesWindowStatus" type="GateWindowStatus" array="true" minsize="0" maxsize="100" mandatory="false">
		<description>Status of trunk/liftgate window position</description>
	</param>		
</struct>
```

#### Add new struct `DoorWindowStatus`:
```xml	
<struct name="DoorWindowStatus" since="X.x">
	<description>Describes the Status of a window of a door.</description>
	<param name="doorLocation" type="Grid" mandatory="true"/>
	<param name="windowState" type="WindowState" mandatory="true"/>	
</struct>
```

#### Add new struct `GateWindowStatus`:
```xml
<struct name="GateWindowStatus" since="X.x">
	<description>Describes the Status of a window of trunk/hood/etc.</description>
	<param name="gateType" type="GateType" mandatory="true"/>
	<param name="windowState" type="WindowState" mandatory="true"/>	
</struct>
```

#### Add new enum `WindowState`:

```xml    
<enum name="WindowState" since="X.x">
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
	<param name="doorsWindowStatus" type="Common.DoorWindowStatus" array="true" minsize="0" maxsize="100" mandatory="false">
		<description>Status of doors window position</description>
	</param>
	<param name="gatesWindowStatus" type="Common.GateWindowStatus" array="true" minsize="0" maxsize="100" mandatory="false">
		<description>Status of trunk/liftgate window position</description>
	</param>		
</struct>
```

#### Add new struct `DoorWindowStatus` in `Common` interface
```xml	
<struct name="DoorWindowStatus">
	<description>Describes the Status of a window of a door.</description>
	<param name="doorLocation" type="Common.Grid" mandatory="true"/>
	<param name="windowState" type="Common.WindowState" mandatory="true"/>	
</struct>
```

#### Add new struct `GateWindowStatus` in `Common` interface
```xml
<struct name="GateWindowStatus">
	<description>Describes the Status of a window of trunk/hood/etc.</description>
	<param name="gateType" type="Common.GateType" mandatory="true"/>
	<param name="windowState" type="Common.WindowState" mandatory="true"/>	
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
* iOS/Java Suite need to be updated to support getters/setters as per new API.
* SDL Server needs to add permissions for new vehicle data items.
* SHAID needs to add mappings for new vehicle data items as per updated spec.
* HMI needs to be updated to support new vehicle data items.
* Proposal [Enhance BodyInformation vehicle data](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0255-Enhance-BodyInformation-vehicle-data.md) needs to be implemented before or along with this proposal.

## Alternatives considered

* None
