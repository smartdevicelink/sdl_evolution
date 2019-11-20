# New vehicle data SeatOccupancy

* Proposal: [SDL-0262](0262-New-vehicle-data-SeatOccupancy.md)
* Author: [Ankur Tiwari](https://github.com/atiwari9)
* Status: **In Review**
* Impacted Platforms: [Core | HMI | Policy Server | SHAID | iOS | Java Suite | RPC]

## Introduction

This proposal is to add new vehicle data `SeatOccupancy` to know if a vehicle seat is occupied and belted.

## Motivation

In order to partner with more diverse app partners, we need to provide additional sets of vehicle data items through SDL. This goes in line with commitment to enhance SDL with even richer vehicle data content. For insurance apps and emergency assistance apps, it is important to know which seats are occupied and belted.

## Proposed Solution 

We need to add `SeatOccupancy` for `GetVehicleData`, `SubscribeVehicleData`, `UnsubscribeVehicleData` & `OnVehicleData` RPCs. Following are the changes needed in MOBILE_API and HMI_API:

### Updates in MOBILE_API:


#### Add to enum `VehicleDataType`: 

```xml
<element name="VEHICLEDATA_SEATOCCUPANCY" since="X.x"/>
```

#### Add new struct `SeatStatus`:
```xml
<struct name="SeatStatus" since="X.x">
	<description>Describes the status of a parameter of seat.</description>
	<param name="seatLocation" type="SeatLocation"  mandatory="true"/>
	<param name="conditionActive" type="Boolean"  mandatory="true"/>	
</struct>
```

#### Add new struct `SeatOccupancy`:

```xml	
<struct name="SeatOccupancy" since="X.x">
	<param name="seatsOccupied" type="SeatStatus" array="true" minsize="0" maxsize="100" mandatory="false">
		<description>If seat is occupied, true. Otherwise false.</description>
	</param>
	<param name="seatsBelted" type="SeatStatus" array="true" minsize="0" maxsize="100" mandatory="false">
		<description>If seat belt is belted, true. Otherwise false.</description>
	</param>	
</struct>
```

#### Add the following parameter to these function requests:
* `SubscribeVehicleData`
* `UnsubscribeVehicleData`
* `GetVehicleData`

```xml
<param name="seatOccupancy" type="Boolean" mandatory="false" since="X.x">
	<description>See SeatOccupancy</description>
</param>
```

#### Add the following parameter to these function responses:
* `SubscribeVehicleData`
* `UnsubscribeVehicleData`

```xml
<param name="seatOccupancy" type="VehicleDataResult" mandatory="false" since="X.x">
	<description>See SeatOccupancy</description>
</param>
```

#### Add the following parameter to these function responses:
* `GetVehicleData`
* `OnVehicleData`

```xml
<param name="seatOccupancy" type="SeatOccupancy" mandatory="false" since="X.x">
	<description>See SeatOccupancy</description>
</param>
```

### Updates in HMI_API:

#### Add to enum `VehicleDataType` in `Common` interface: 

```xml
<element name="VEHICLEDATA_SEATOCCUPANCY"/>
```

#### Add new struct `SeatStatus` in `Common` interface:

```xml
<struct name="SeatStatus">
	<description>Describes the status of a parameter of seat.</description>
	<param name="seatLocation" type="Common.SeatLocation"  mandatory="true"/>
	<param name="conditionActive" type="Boolean"  mandatory="true"/>
</struct>
```

#### Add new struct `SeatOccupancy` in `Common` interface:

```xml	
<struct name="SeatOccupancy">
	<param name="seatsOccupied" type="Common.SeatStatus" array="true" minsize="0" maxsize="100" mandatory="false">
		<description>If seat is occupied, true. Otherwise false.</description>
	</param>
	<param name="seatsBelted" type="Common.SeatStatus" array="true" minsize="0" maxsize="100" mandatory="false">
		<description>If seat belt is belted, true. Otherwise false.</description>
</struct>
```

#### Add the following parameter to these function requests:
* `SubscribeVehicleData`
* `UnsubscribeVehicleData`
* `GetVehicleData`

```xml
<param name="seatOccupancy" type="Boolean" mandatory="false">
	<description>See SeatOccupancy</description>
</param>
```

#### Add the following parameter to these function responses:
* `SubscribeVehicleData`
* `UnsubscribeVehicleData`

```xml
<param name="seatOccupancy" type="Common.VehicleDataResult" mandatory="false">
	<description>See SeatOccupancy</description>
</param>
```

#### Add the following parameter to these function responses:
* `GetVehicleData`
* `OnVehicleData`

```xml
<param name="seatOccupancy" type="Common.SeatOccupancy" mandatory="false">
	<description>See SeatOccupancy</description>
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

* `SeatOccupancy` has information on if seat is occupied and belt buckled status. Potentially these can be separate vehicle data items as well. If we do separate these two, it'd need additional coding and maintenance for one more vehicle data item.
