# New vehicle data WindowStatus

* Proposal: [SDL-0261](0261-New-vehicle-data-WindowStatus.md)
* Author: [Ankur Tiwari](https://github.com/atiwari9)
* Status: **Accepted with Revisions**
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
	<description>Describes the status of a window of a door/liftgate etc.</description>
	<param name="location" type="Grid" mandatory="true"/>
	<param name="state" type="WindowState" mandatory="true"/>			
</struct>
```

#### Add new struct `WindowState`:

```xml    
<struct name="WindowState" since="X.x">
  <param name="approximatePosition" type="Integer" minvalue="0" maxvalue="100" mandatory="true">
    <description>The approximate percentage that the window is open - 0 being fully closed, 100 being fully open</description>
  </param>
  <param name="deviation" type="Integer" minvalue="0" maxvalue="100" mandatory="true">
    <description>The percentage deviation of the approximatePosition. e.g. If the approximatePosition is 50 and the deviation is 10, then the window's location is somewhere between 40 and 60.</description>
  </param>
</struct>
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
<param name="windowStatus" type="WindowStatus" array="true" minsize="0" maxsize="100" mandatory="false">
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
	<description>Describes the status of a window of a door/liftgate etc.</description>
	<param name="location" type="Common.Grid" mandatory="true"/>
	<param name="state" type="Common.WindowState" mandatory="true"/>			
</struct>
```

#### Add new struct `WindowState` in `Common` interface:

```xml    
<struct name="WindowState">
  <param name="approximatePosition" type="Integer" minvalue="0" maxvalue="100" mandatory="true">
    <description>The approximate percentage that the window is open - 0 being fully closed, 100 being fully open</description>
  </param>
  <param name="deviation" type="Integer" minvalue="0" maxvalue="100" mandatory="true">
    <description>The percentage deviation of the approximatePosition. e.g. If the approximatePosition is 50 and the deviation is 10, then the window's location is somewhere between 40 and 60.</description>
  </param>
</struct>
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
<param name="windowStatus" type="Common.WindowStatus" array="true" minsize="0" maxsize="100" mandatory="false">
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
