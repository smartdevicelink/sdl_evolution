# Vehicle Data Additions

* Proposal: [SDL-NNNN](NNNN-Vehicle-data-additions.md)
* Author: [Ankur Tiwari](https://github.com/atiwari9)
* Status: **Awaiting review**
* Impacted Platforms: [Core | HMI | SDL SERVER | SHAID | PROXY]

## Introduction

This proposal is to add new vehicle data items to SDL.

## Motivation

In order to partner with more diverse app partners, we need to provide additional set of vehicle data item through SDL. This goes in line with commitment to enhance SDL with even more rich vehicle data content.

## Proposed Solution 

We need to add some new vehicle data items. Following are the details on all the changed proposed.


#### New vehicle data items:
1. `WindowStatus`
2. `SeatOccupancy`
3. `StabilityControlsStatus`
4. `GearStatus`
5. `ClimateData`
6. `handsOffSteering`
7. `hvBatteryLevel`
8. Additions to `BodyInformation` struct


### 1. New vehicle data item `WindowStatus`


#### Updates in MOBILE_API:


##### Add to enum `VehicleDataType`: 

```xml
<element name="VEHICLEDATA_WINDOWSTATUS" since="X.x"/>
```
##### Add new struct `WindowStatus`

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
##### Add new enum `WindowState`:

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

##### Add to function `SubscribeVehicleData` request: 

```xml
<param name="windowStatus" type="Boolean" mandatory="false" since="X.x">
	<description>See WindowStatus</description>
</param>
```
##### Add to function `SubscribeVehicleData` response: 

```xml
<param name="windowStatus" type="VehicleDataResult" mandatory="false" since="X.x">
	<description>See WindowStatus</description>
</param>
```
##### Add to function `UnsubscribeVehicleData` request: 

```xml
<param name="windowStatus" type="Boolean" mandatory="false" since="X.x">
	<description>See WindowStatus</description>
</param>
```
##### Add to function `UnsubscribeVehicleData` response: 

```xml
<param name="windowStatus" type="VehicleDataResult" mandatory="false" since="X.x">
	<description>See WindowStatus</description>
</param>
```
##### Add to function `GetVehicleData` request: 

```xml
<param name="windowStatus" type="Boolean" mandatory="false" since="X.x">
	<description>See WindowStatus</description>
</param>
```
##### Add to function `GetVehicleData` response: 

```xml
<param name="windowStatus" type="WindowStatus" mandatory="false" since="X.x">
	<description>See WindowStatus</description>
</param>
```
##### Add to function `OnVehicleData` response: 

```xml
<param name="windowStatus" type="WindowStatus" mandatory="false" since="X.x">
	<description>See WindowStatus</description>
</param>
```
#### Updates in HMI_API:


##### Add to enum `VehicleDataType` in `Common` interface: 

```xml
<element name="VEHICLEDATA_WINDOWSTATUS"/>
```
##### Add new struct `WindowStatus` in `Common` interface:

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
##### Add new enum `WindowState` in `Common` interface:

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

##### Add to function `SubscribeVehicleData` request: 

```xml
<param name="windowStatus" type="Boolean" mandatory="false">
	<description>See WindowStatus</description>
</param>
```
##### Add to function `SubscribeVehicleData` response: 

```xml
<param name="windowStatus" type="Common.VehicleDataResult" mandatory="false">
	<description>See WindowStatus</description>
</param>
```
##### Add to function `UnsubscribeVehicleData` request: 

```xml
<param name="windowStatus" type="Boolean" mandatory="false">
	<description>See WindowStatus</description>
</param>
```
##### Add to function `UnsubscribeVehicleData` response: 

```xml
<param name="windowStatus" type="Common.VehicleDataResult" mandatory="false">
	<description>See WindowStatus</description>
</param>
```
##### Add to function `GetVehicleData` request: 

```xml
<param name="windowStatus" type="Boolean" mandatory="false">
	<description>See WindowStatus</description>
</param>
```
##### Add to function `GetVehicleData` response: 

```xml
<param name="windowStatus" type="Common.WindowStatus" mandatory="false">
	<description>See WindowStatus</description>
</param>
```
##### Add to function `OnVehicleData` response: 

```xml
<param name="windowStatus" type="Common.WindowStatus" mandatory="false">
	<description>See WindowStatus</description>
</param>
```
### 2. New vehicle data item `SeatOccupancy`


#### Updates in MOBILE_API:


##### Add to enum `VehicleDataType`: 

```xml
<element name="VEHICLEDATA_SEATOCCUPANCY" since="X.x"/>
```
##### Add new struct `SeatOccupancy`:

```xml	
<struct name="SeatOccupancy" since="x.x">
	<param name="row1DriverOccupied" type="Boolean" mandatory="false">
		<description>true if row1 driver side seat is occupied, else false</description>
	</param>
	<param name="row1PassengerOccupied" type="Boolean" mandatory="false">
		<description>true if row1 passenger side seat is occupied, else false</description>
	</param>
	<param name="row1MiddleOccupied" type="Boolean" mandatory="false">
		<description>true if row1 middle seat is occupied, else false</description>
	</param>	
	<param name="row2DriverOccupied" type="Boolean" mandatory="false">
		<description>true if row2 driver side seat is occupied, else false</description>
	</param>
	<param name="row2PassengerOccupied" type="Boolean" mandatory="false">
		<description>true if row2 passenger side seat is occupied, else false</description>
	</param>
	<param name="row2MiddleOccupied" type="Boolean" mandatory="false">
		<description>true if row2 middle seat is occupied, else false</description>
	</param>	
	<param name="row3DriverOccupied" type="Boolean" mandatory="false">
		<description>true if row3 driver side seat is occupied, else false</description>
	</param>
	<param name="row3PassengerOccupied" type="Boolean" mandatory="false">
		<description>true if row3 passenger side seat is occupied, else false</description>
	</param>
	<param name="row3MiddleOccupied" type="Boolean" mandatory="false">
		<description>true if row3 middle seat is occupied, else false</description>
	</param>
	<param name="row1DriverBelted" type="Boolean" mandatory="false">
		<description>true if row1 driver side seat belt is belted, else false</description>
	</param>
	<param name="row1PassengerBelted" type="Boolean" mandatory="false">
		<description>true if row1 passenger side seat belt is belted, else false</description>
	</param>
	<param name="row1MiddleBelted" type="Boolean" mandatory="false">
		<description>true if row1 middle seat belt is belted, else false</description>
	</param>	
	<param name="row2DriverBelted" type="Boolean" mandatory="false">
		<description>true if row2 driver side seat belt is belted, else false</description>
	</param>
	<param name="row2PassengerBelted" type="Boolean" mandatory="false">
		<description>true if row2 passenger side seat belt is belted, else false</description>
	</param>
	<param name="row2MiddleBelted" type="Boolean" mandatory="false">
		<description>true if row2 middle seat belt is belted, else false</description>
	</param>	
	<param name="row3DriverBelted" type="Boolean" mandatory="false">
		<description>true if row3 driver side seat belt is belted, else false</description>
	</param>
	<param name="row3PassengerBelted" type="Boolean" mandatory="false">
		<description>true if row3 passenger side seat belt is belted, else false</description>
	</param>
	<param name="row3MiddleBelted" type="Boolean" mandatory="false">
		<description>true if row3 middle seat belt is belted, else false</description>
	</param>		
</struct>
```
##### Add to function `SubscribeVehicleData` request: 

```xml
<param name="seatOccupancy" type="Boolean" mandatory="false" since="X.x">
	<description>See SeatOccupancy</description>
</param>
```
##### Add to function `SubscribeVehicleData` response: 

```xml
<param name="seatOccupancy" type="VehicleDataResult" mandatory="false" since="X.x">
	<description>See SeatOccupancy</description>
</param>
```
##### Add to function `UnsubscribeVehicleData` request: 

```xml
<param name="seatOccupancy" type="Boolean" mandatory="false" since="X.x">
	<description>See SeatOccupancy</description>
</param>
```
##### Add to function `UnsubscribeVehicleData` response: 

```xml
<param name="seatOccupancy" type="VehicleDataResult" mandatory="false" since="X.x">
	<description>See SeatOccupancy</description>
</param>
```
##### Add to function `GetVehicleData` request: 

```xml
<param name="seatOccupancy" type="Boolean" mandatory="false" since="X.x">
	<description>See SeatOccupancy</description>
</param>
```
##### Add to function `GetVehicleData` response: 

```xml
<param name="seatOccupancy" type="SeatOccupancy" mandatory="false" since="X.x">
	<description>See SeatOccupancy</description>
</param>
```
##### Add to function `OnVehicleData` response: 

```xml
<param name="seatOccupancy" type="SeatOccupancy" mandatory="false" since="X.x">
	<description>See SeatOccupancy</description>
</param>
```
#### Updates in HMI_API:

##### Add to enum `VehicleDataType` in `Common` interface: 

```xml
<element name="VEHICLEDATA_SEATOCCUPANCY"/>
```
##### Add new struct `SeatOccupancy` in `Common` interface:

```xml	
<struct name="SeatOccupancy">
	<param name="row1DriverOccupied" type="Boolean" mandatory="false">
		<description>true if row1 driver side seat is occupied, else false</description>
	</param>
	<param name="row1PassengerOccupied" type="Boolean" mandatory="false">
		<description>true if row1 passenger side seat is occupied, else false</description>
	</param>
	<param name="row1MiddleOccupied" type="Boolean" mandatory="false">
		<description>true if row1 middle seat is occupied, else false</description>
	</param>	
	<param name="row2DriverOccupied" type="Boolean" mandatory="false">
		<description>true if row2 driver side seat is occupied, else false</description>
	</param>
	<param name="row2PassengerOccupied" type="Boolean" mandatory="false">
		<description>true if row2 passenger side seat is occupied, else false</description>
	</param>
	<param name="row2MiddleOccupied" type="Boolean" mandatory="false">
		<description>true if row2 middle seat is occupied, else false</description>
	</param>	
	<param name="row3DriverOccupied" type="Boolean" mandatory="false">
		<description>true if row3 driver side seat is occupied, else false</description>
	</param>
	<param name="row3PassengerOccupied" type="Boolean" mandatory="false">
		<description>true if row3 passenger side seat is occupied, else false</description>
	</param>
	<param name="row3MiddleOccupied" type="Boolean" mandatory="false">
		<description>true if row3 middle seat is occupied, else false</description>
	</param>
	<param name="row1DriverBelted" type="Boolean" mandatory="false">
		<description>true if row1 driver side seat belt is belted, else false</description>
	</param>
	<param name="row1PassengerBelted" type="Boolean" mandatory="false">
		<description>true if row1 passenger side seat belt is belted, else false</description>
	</param>
	<param name="row1MiddleBelted" type="Boolean" mandatory="false">
		<description>true if row1 middle seat belt is belted, else false</description>
	</param>	
	<param name="row2DriverBelted" type="Boolean" mandatory="false">
		<description>true if row2 driver side seat belt is belted, else false</description>
	</param>
	<param name="row2PassengerBelted" type="Boolean" mandatory="false">
		<description>true if row2 passenger side seat belt is belted, else false</description>
	</param>
	<param name="row2MiddleBelted" type="Boolean" mandatory="false">
		<description>true if row2 middle seat belt is belted, else false</description>
	</param>	
	<param name="row3DriverBelted" type="Boolean" mandatory="false">
		<description>true if row3 driver side seat belt is belted, else false</description>
	</param>
	<param name="row3PassengerBelted" type="Boolean" mandatory="false">
		<description>true if row3 passenger side seat belt is belted, else false</description>
	</param>
	<param name="row3MiddleBelted" type="Boolean" mandatory="false">
		<description>true if row3 middle seat belt is belted, else false</description>
	</param>		
</struct>
```
##### Add to function `SubscribeVehicleData` request: 

```xml
<param name="seatOccupancy" type="Boolean" mandatory="false">
	<description>See SeatOccupancy</description>
</param>
```
##### Add to function `SubscribeVehicleData` response: 

```xml
<param name="seatOccupancy" type="Common.VehicleDataResult" mandatory="false">
	<description>See SeatOccupancy</description>
</param>
```
##### Add to function `UnsubscribeVehicleData` request: 
```xml
<param name="seatOccupancy" type="Boolean" mandatory="false">
	<description>See SeatOccupancy</description>
</param>
```
##### Add to function `UnsubscribeVehicleData` response: 

```xml
<param name="seatOccupancy" type="Common.VehicleDataResult" mandatory="false">
	<description>See SeatOccupancy</description>
</param>
```
##### Add to function `GetVehicleData` request: 

```xml
<param name="seatOccupancy" type="Boolean" mandatory="false">
	<description>See SeatOccupancy</description>
</param>
```
##### Add to function `GetVehicleData` response: 

```xml
<param name="seatOccupancy" type="Common.SeatOccupancy" mandatory="false">
	<description>See SeatOccupancy</description>
</param>
```
##### Add to function `OnVehicleData` response: 

```xml
<param name="seatOccupancy" type="Common.SeatOccupancy" mandatory="false">
	<description>See SeatOccupancy</description>
</param>
```
### 3. New vehicle data item `StabilityControlsStatus`

#### Updates in MOBILE_API:

##### Add to enum `VehicleDataType`: 

```xml
<element name="VEHICLEDATA_STABILITYCONTROLSSTATUS" since="X.x"/>
```
##### Add new struct `StabilityControlsStatus`:

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
##### Add to function `SubscribeVehicleData` request: 

```xml	
<param name="stabilityControlsStatus" type="Boolean" mandatory="false" since="X.x">
	<description>See StabilityControlsStatus</description>
</param>
```
##### Add to function `SubscribeVehicleData` response: 

```xml	
<param name="stabilityControlsStatus" type="VehicleDataResult" mandatory="false" since="X.x">
	<description>See StabilityControlsStatus</description>
</param>
```
##### Add to function `UnsubscribeVehicleData` request: 

```xml	
<param name="stabilityControlsStatus" type="Boolean" mandatory="false" since="X.x">
	<description>See StabilityControlsStatus</description>
</param>
```
##### Add to function `UnsubscribeVehicleData` response: 

```xml	
<param name="stabilityControlsStatus" type="VehicleDataResult" mandatory="false" since="X.x">
	<description>See StabilityControlsStatus</description>
</param>
```
##### Add to function `GetVehicleData` request: 

```xml	
<param name="stabilityControlsStatus" type="Boolean" mandatory="false" since="X.x">
	<description>See StabilityControlsStatus</description>
</param>
```
##### Add to function `GetVehicleData` response: 

```xml	
<param name="stabilityControlsStatus" type="StabilityControlsStatus" mandatory="false" since="X.x">
	<description>See StabilityControlsStatus</description>
</param>
```
##### Add to function `OnVehicleData` response: 

```xml	
<param name="stabilityControlsStatus" type="StabilityControlsStatus" mandatory="false" since="X.x">
	<description>See StabilityControlsStatus</description>
</param>
```
#### Updates in HMI_API 

##### Add to enum `VehicleDataType` in `Common` interface: 

```xml	
<element name="VEHICLEDATA_STABILITYCONTROLSSTATUS"/>
```
##### Add new struct `StabilityControlsStatus` in `Common` interface:

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
##### Add to function `SubscribeVehicleData` request: 

```xml	
<param name="stabilityControlsStatus" type="Boolean" mandatory="false">
	<description>See StabilityControlsStatus</description>
</param>
```
##### Add to function `SubscribeVehicleData` response: 

```xml	
<param name="stabilityControlsStatus" type="Common.VehicleDataResult" mandatory="false">
	<description>See StabilityControlsStatus</description>
</param>
```
##### Add to function `UnsubscribeVehicleData` request: 

```xml	
<param name="stabilityControlsStatus" type="Boolean" mandatory="false">
	<description>See StabilityControlsStatus</description>
</param>
```
##### Add to function `UnsubscribeVehicleData` response: 

```xml	
<param name="stabilityControlsStatus" type="Common.VehicleDataResult" mandatory="false">
	<description>See StabilityControlsStatus</description>
</param>
```
##### Add to function `GetVehicleData` request: 

```xml	
<param name="stabilityControlsStatus" type="Boolean" mandatory="false">
	<description>See StabilityControlsStatus</description>
</param>
```
##### Add to function `GetVehicleData` response: 

```xml	
<param name="stabilityControlsStatus" type="Common.StabilityControlsStatus" mandatory="false">
	<description>See StabilityControlsStatus</description>
</param>
```
##### Add to function `OnVehicleData` response: 

```xml	
<param name="stabilityControlsStatus" type="Common.StabilityControlsStatus" mandatory="false">
	<description>See StabilityControlsStatus</description>
</param>
```
### 4. New vehicle data item `GearStatus`

#### Updates in MOBILE_API:

##### Add to enum `VehicleDataType`: 

```xml	
<element name="VEHICLEDATA_GEARSTATUS" since="X.x"/>
```
##### Add new struct `GearStatus`:

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
##### Add new enum `GearPosition`:

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
##### Add to function `SubscribeVehicleData` request: 

```xml	
<param name="gearStatus" type="Boolean" mandatory="false" since="X.x">
	<description>See GearStatus</description>
</param>
```
##### Add to function `SubscribeVehicleData` response: 

```xml	
<param name="gearStatus" type="VehicleDataResult" mandatory="false" since="X.x">
	<description>See GearStatus</description>
</param>
```
##### Add to function `UnsubscribeVehicleData` request: 

```xml	
<param name="gearStatus" type="Boolean" mandatory="false" since="X.x">
	<description>See GearStatus</description>
</param>
```
##### Add to function `UnsubscribeVehicleData` response: 

```xml	
<param name="gearStatus" type="VehicleDataResult" mandatory="false" since="X.x">
	<description>See GearStatus</description>
</param>
```
##### Add to function `GetVehicleData` request: 

```xml	
<param name="gearStatus" type="Boolean" mandatory="false" since="X.x">
	<description>See GearStatus</description>
</param>
```
##### Add to function `GetVehicleData` response: 

```xml	
<param name="gearStatus" type="GearStatus" mandatory="false" since="X.x">
	<description>See GearStatus</description>
</param>
```
##### Add to function `OnVehicleData` response: 

```xml	
<param name="gearStatus" type="GearStatus" mandatory="false" since="X.x">
	<description>See GearStatus</description>
</param>
```
#### Updates in HMI_API 

##### Add to enum `VehicleDataType` in `Common` interface: 

```xml	
<element name="VEHICLEDATA_GEARSTATUS"/>
```
##### Add new struct `GearStatus` in `Common` interface:

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
##### Add new enum `GearPosition` in `Common` interface:

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
##### Add to function `SubscribeVehicleData` request: 

```xml	
<param name="gearStatus" type="Boolean" mandatory="false">
	<description>See GearStatus</description>
</param>
```
##### Add to function `SubscribeVehicleData` response: 

```xml	
<param name="gearStatus" type="Common.VehicleDataResult" mandatory="false">
	<description>See GearStatus</description>
</param>
```
##### Add to function `UnsubscribeVehicleData` request: 

```xml	
<param name="gearStatus" type="Boolean" mandatory="false">
	<description>See GearStatus</description>
</param>
```
##### Add to function `UnsubscribeVehicleData` response: 

```xml	
<param name="gearStatus" type="Common.VehicleDataResult" mandatory="false">
	<description>See GearStatus</description>
</param>
```
##### Add to function `GetVehicleData` request: 

```xml	
<param name="gearStatus" type="Boolean" mandatory="false">
	<description>See GearStatus</description>
</param>
```
##### Add to function `GetVehicleData` response: 

```xml	
<param name="gearStatus" type="Common.GearStatus" mandatory="false">
	<description>See GearStatus</description>
</param>
```
##### Add to function `OnVehicleData` response: 

```xml	
<param name="gearStatus" type="Common.GearStatus" mandatory="false">
	<description>See GearStatus</description>
</param>
```
### 5. New vehicle data item `ClimateData`

#### Updates in MOBILE_API:

##### Add to enum `VehicleDataType`: 

```xml	
<element name="VEHICLEDATA_CLIMATEDATA" since="X.x"/>
```
##### Add new struct `ClimateData`:

```xml	
<struct name="ClimateData" since="x.x">
	<param name="externalTemperature" type="Float" minvalue="-40" maxvalue="100" mandatory="false">
		<description>The external temperature in degrees celsius</description>
	</param>
	<param name="cabinTemperature" type="Float" minvalue="-40" maxvalue="100" mandatory="false">
		<description>Internal ambient cabin temperature in degrees celsius</description>
	</param>
	<param name="atmosphericPressure" type="Float" minvalue="500" maxvalue="1100" mandatory="false">
		<description>Current atmospheric pressure in mBar</description>
	</param>
</struct>
```
##### Add to function `SubscribeVehicleData` request: 

```xml	
<param name="climateData" type="Boolean" mandatory="false" since="X.x">
	<description>See ClimateData</description>
</param>
```
##### Add to function `SubscribeVehicleData` response: 

```xml	
<param name="climateData" type="VehicleDataResult" mandatory="false" since="X.x">
	<description>See ClimateData</description>
</param>
```
##### Add to function `UnsubscribeVehicleData` request: 

```xml	
<param name="climateData" type="Boolean" mandatory="false" since="X.x">
	<description>See ClimateData</description>
</param>
```
##### Add to function `UnsubscribeVehicleData` response: 

```xml	
<param name="climateData" type="VehicleDataResult" mandatory="false" since="X.x">
	<description>See ClimateData</description>
</param>
```
##### Add to function `GetVehicleData` request: 

```xml	
<param name="climateData" type="Boolean" mandatory="false" since="X.x">
	<description>See ClimateData</description>
</param>
```
##### Add to function `GetVehicleData` response: 

```xml	
<param name="climateData" type="ClimateData" mandatory="false" since="X.x">
	<description>See ClimateData</description>
</param>
```
##### Add to function `OnVehicleData` response: 

```xml	
<param name="climateData" type="ClimateData" mandatory="false" since="X.x">
	<description>See ClimateData</description>
</param>
```
#### Updates in HMI_API 

##### Add to enum `VehicleDataType` in `Common` interface: 

```xml	
<element name="VEHICLEDATA_CLIMATEDATA"/>
```
##### Add new struct `ClimateData` in `Common` interface:

```xml	
<struct name="ClimateData">
	<param name="externalTemperature" type="Float" minvalue="-40" maxvalue="100" mandatory="false">
		<description>The external temperature in degrees celsius</description>
	</param>
	<param name="cabinTemperature" type="Float" minvalue="-40" maxvalue="100" mandatory="false">
		<description>Internal ambient cabin temperature in degrees celsius</description>
	</param>
	<param name="atmosphericPressure" type="Float" minvalue="500" maxvalue="1100" mandatory="false">
		<description>Current atmospheric pressure in mBar</description>
	</param>
</struct>
```
##### Add to function `SubscribeVehicleData` request: 

```xml	
<param name="climateData" type="Boolean" mandatory="false">
	<description>See ClimateData</description>
</param>
```
##### Add to function `SubscribeVehicleData` response: 

```xml	
<param name="climateData" type="Common.VehicleDataResult" mandatory="false">
	<description>See ClimateData</description>
</param>
```
##### Add to function `UnsubscribeVehicleData` request: 

```xml	
<param name="climateData" type="Boolean" mandatory="false">
	<description>See ClimateData</description>
</param>
```
##### Add to function `UnsubscribeVehicleData` response: 

```xml	
<param name="climateData" type="Common.VehicleDataResult" mandatory="false">
	<description>See ClimateData</description>
</param>
```
##### Add to function `GetVehicleData` request: 

```xml	
<param name="climateData" type="Boolean" mandatory="false">
	<description>See ClimateData</description>
</param>
```
##### Add to function `GetVehicleData` response: 

```xml	
<param name="climateData" type="Common.ClimateData" mandatory="false">
	<description>See ClimateData</description>
</param>
```
##### Add to function `OnVehicleData` response: 

```xml	
<param name="climateData" type="Common.ClimateData" mandatory="false">
	<description>See ClimateData</description>
</param>
```
### 6. New vehicle data item `handsOffSteering`

#### Updates in MOBILE_API:

##### Add to enum `VehicleDataType`: 

```xml	
<element name="VEHICLEDATA_HANDSOFFSTEERING" since="X.x"/>
```
##### Add to function `SubscribeVehicleData` request: 

```xml	
<param name="handsOffSteering" type="Boolean" mandatory="false" since="X.x">
	<description>To indicate whether driver hands are off the steering wheel</description>
</param>
```
##### Add to function `SubscribeVehicleData` response: 

```xml	
<param name="handsOffSteering" type="VehicleDataResult" mandatory="false" since="X.x">
	<description>To indicate whether driver hands are off the steering wheel</description>
</param>
```
##### Add to function `UnsubscribeVehicleData` request: 

```xml	
<param name="handsOffSteering" type="Boolean" mandatory="false" since="X.x">
	<description>To indicate whether driver hands are off the steering wheel</description>
</param>
```
##### Add to function `UnsubscribeVehicleData` response: 

```xml	
<param name="handsOffSteering" type="VehicleDataResult" mandatory="false" since="X.x">
	<description>To indicate whether driver hands are off the steering wheel</description>
</param>
```
##### Add to function `GetVehicleData` request: 

```xml	
<param name="handsOffSteering" type="Boolean" mandatory="false" since="X.x">
	<description>To indicate whether driver hands are off the steering wheel</description>
</param>
```
##### Add to function `GetVehicleData` response: 

```xml	
<param name="handsOffSteering" type="Boolean" mandatory="false" since="X.x">
	<description>true indicates driver hands are off the steering wheel</description>
</param>
```
##### Add to function `OnVehicleData` response: 

```xml	
<param name="handsOffSteering" type="Boolean" mandatory="false" since="X.x">
	<description>true indicates driver hands are off the steering wheel</description>
</param>
```
#### Updates in HMI_API 

##### Add to enum `VehicleDataType` in `Common` interface: 

```xml	
<element name="VEHICLEDATA_HANDSOFFSTEERING"/>
```
##### Add to function `SubscribeVehicleData` request: 

```xml	
<param name="handsOffSteering" type="Boolean" mandatory="false">
	<description>To indicate whether driver hands are off the steering wheel</description>
</param>
```
##### Add to function `SubscribeVehicleData` response: 

```xml	
<param name="handsOffSteering" type="Common.VehicleDataResult" mandatory="false">
	<description>To indicate whether driver hands are off the steering wheel</description>
</param>
```
##### Add to function `UnsubscribeVehicleData` request: 

```xml	
<param name="handsOffSteering" type="Boolean" mandatory="false">
	<description>To indicate whether driver hands are off the steering wheel</description>
</param>
```
##### Add to function `UnsubscribeVehicleData` response: 

```xml	
<param name="handsOffSteering" type="Common.VehicleDataResult" mandatory="false">
	<description>To indicate whether driver hands are off the steering wheel</description>
</param>
```
##### Add to function `GetVehicleData` request: 

```xml	
<param name="handsOffSteering" type="Boolean" mandatory="false">
	<description>To indicate whether driver hands are off the steering wheel</description>
</param>
```
##### Add to function `GetVehicleData` response: 

```xml	
<param name="handsOffSteering" type="Boolean" mandatory="false">
	<description>true indicates driver hands are off the steering wheel</description>
</param>
```
##### Add to function `OnVehicleData` response: 

```xml	
<param name="handsOffSteering" type="Boolean" mandatory="false">
	<description>true indicates driver hands are off the steering wheel</description>
</param>
```
### 7. New vehicle data item `hvBatteryLevel`

#### Updates in MOBILE_API:

##### Add to enum `VehicleDataType`: 

```xml	
<element name="VEHICLEDATA_HVBATTERYLEVEL" since="X.x"/>
```
##### Add to function `SubscribeVehicleData` request: 

```xml	
<param name="hvBatteryLevel" type="Boolean" mandatory="false" since="X.x">
	<description>Percentage of High Voltage battery charge available</description>
</param>
```
##### Add to function `SubscribeVehicleData` response: 

```xml	
<param name="hvBatteryLevel" type="VehicleDataResult" mandatory="false" since="X.x">
	<description>Percentage of High Voltage battery charge available</description>
</param>
```
##### Add to function `UnsubscribeVehicleData` request: 

```xml	
<param name="hvBatteryLevel" type="Boolean" mandatory="false" since="X.x">
	<description>Percentage of High Voltage battery charge available</description>
</param>
```
##### Add to function `UnsubscribeVehicleData` response: 

```xml	
<param name="hvBatteryLevel" type="VehicleDataResult" mandatory="false" since="X.x">
	<description>Percentage of High Voltage battery charge available</description>
</param>
```
##### Add to function `GetVehicleData` request: 

```xml	
<param name="hvBatteryLevel" type="Boolean" mandatory="false" since="X.x">
	<description>Percentage of High Voltage battery charge available</description>
</param>
```
##### Add to function `GetVehicleData` response: 

```xml	
<param name="hvBatteryLevel" type="Float" minvalue="0" maxvalue="150" mandatory="false" since="X.x">
	<description>Percentage of High Voltage battery charge available</description>
</param>
```
##### Add to function `OnVehicleData` response: 

```xml	
<param name="hvBatteryLevel" type="Float" minvalue="0" maxvalue="150" mandatory="false" since="X.x">
	<description>Percentage of High Voltage battery charge available</description>
</param>
```
#### Updates in HMI_API 

##### Add to enum `VehicleDataType` in `Common` interface: 

```xml	
<element name="VEHICLEDATA_HVBATTERYLEVEL"/>
```
##### Add to function `SubscribeVehicleData` request: 

```xml	
<param name="hvBatteryLevel" type="Boolean" mandatory="false">
	<description>Percentage of High Voltage battery charge available</description>
</param>
```
##### Add to function `SubscribeVehicleData` response: 

```xml	
<param name="hvBatteryLevel" type="Common.VehicleDataResult" mandatory="false">
	<description>Percentage of High Voltage battery charge available</description>
</param>
```
##### Add to function `UnsubscribeVehicleData` request: 

```xml	
<param name="hvBatteryLevel" type="Boolean" mandatory="false">
	<description>Percentage of High Voltage battery charge available</description>
</param>
```
##### Add to function `UnsubscribeVehicleData` response: 

```xml	
<param name="hvBatteryLevel" type="Common.VehicleDataResult" mandatory="false">
	<description>Percentage of High Voltage battery charge available</description>
</param>
```
##### Add to function `GetVehicleData` request: 

```xml	
<param name="hvBatteryLevel" type="Boolean" mandatory="false">
	<description>Percentage of High Voltage battery charge available</description>
</param>
```
##### Add to function `GetVehicleData` response: 

```xml	
<param name="hvBatteryLevel" type="Float" minvalue="0" maxvalue="150" mandatory="false">
	<description>Percentage of High Voltage battery charge available</description>
</param>
```
##### Add to function `OnVehicleData` response: 

```xml	
<param name="hvBatteryLevel" type="Float" minvalue="0" maxvalue="150" mandatory="false">
	<description>Percentage of High Voltage battery charge available</description>
</param>
```
### 8. Additions to `BodyInformation`

Following vehicle data params are added to `BodyInformation`:
* `trunkAjar`
* `hoodAjar`
* `frontLeftDoorLocked`
* `frontRightDoorLocked`
* `rearLeftDoorLocked`
* `rearRightDoorLocked`
* `trunkLocked`

#### Updates in MOBILE_API:

##### Update struct `BodyInformation`:

```xml	
<struct name="BodyInformation" since="2.0">
	<param name="parkBrakeActive" type="Boolean" mandatory="true">
		<description>References signal "PrkBrkActv_B_Actl".</description>
	</param>
	<param name="ignitionStableStatus" type="IgnitionStableStatus" mandatory="true">
		<description>References signal "Ignition_Switch_Stable". See IgnitionStableStatus.</description>
	</param>
	<param name="ignitionStatus" type="IgnitionStatus" mandatory="true">
		<description>References signal "Ignition_status". See IgnitionStatus.</description>
	</param>
	<param name="driverDoorAjar" type="Boolean" mandatory="false">
		<description>References signal "DrStatDrv_B_Actl".</description>
	</param>
	<param name="passengerDoorAjar" type="Boolean" mandatory="false">
		<description>References signal "DrStatPsngr_B_Actl".</description>
	</param>
	<param name="rearLeftDoorAjar" type="Boolean" mandatory="false">
		<description>References signal "DrStatRl_B_Actl".</description>
	</param>
	<param name="rearRightDoorAjar" type="Boolean" mandatory="false">
		<description>References signal "DrStatRr_B_Actl".</description>
	</param>
	<param name="trunkAjar" type="Boolean" mandatory="false" since="X.x">
		<description>true if vehicle hood is ajar, else false</description>
	</param>
	<param name="hoodAjar" type="Boolean" mandatory="false" since="X.x">
		<description>true if vehicle hood is ajar, else false</description>
	</param>
	<param name="frontLeftDoorLocked" type="Boolean" mandatory="false" since="X.x">
		<description>true if front left door is locked, else false</description>
	</param>
	<param name="frontRightDoorLocked" type="Boolean" mandatory="false" since="X.x">
		<description>true if front right door is locked, else false</description>
	</param>
	<param name="rearLeftDoorLocked" type="Boolean" mandatory="false" since="X.x">
		<description>true if rear left door is locked, else false</description>
	</param>
	<param name="rearRightDoorLocked" type="Boolean" mandatory="false" since="X.x">
		<description>true if rear right door is locked, else false</description>
	</param>
	<param name="trunkLocked" type="Boolean" mandatory="false" since="X.x">
		<description>true if trunk is locked, else false</description>
	</param>			
</struct>
```
#### Updates in HMI_API:

##### Update struct `BodyInformation` in `Common` interface:

```xml	
<struct name="BodyInformation">
	<param name="parkBrakeActive" type="Boolean" mandatory="true">
		<description>References signal "PrkBrkActv_B_Actl".</description>
	</param>
	<param name="ignitionStableStatus" type="Common.IgnitionStableStatus" mandatory="true">
		<description>References signal "Ignition_Switch_Stable". See IgnitionStableStatus.</description>
	</param>
	<param name="ignitionStatus" type="Common.IgnitionStatus" mandatory="true">
		<description>References signal "Ignition_status". See IgnitionStatus.</description>
	</param>
	<param name="driverDoorAjar" type="Boolean" mandatory="false">
		<description>References signal "DrStatDrv_B_Actl".</description>
	</param>
	<param name="passengerDoorAjar" type="Boolean" mandatory="false">
		<description>References signal "DrStatPsngr_B_Actl".</description>
	</param>
	<param name="rearLeftDoorAjar" type="Boolean" mandatory="false">
		<description>References signal "DrStatRl_B_Actl".</description>
	</param>
	<param name="rearRightDoorAjar" type="Boolean" mandatory="false">
		<description>References signal "DrStatRr_B_Actl".</description>
	</param>
	<param name="trunkAjar" type="Boolean" mandatory="false">
		<description>true if vehicle hood is ajar, else false</description>
	</param>
	<param name="hoodAjar" type="Boolean" mandatory="false">
		<description>true if vehicle hood is ajar, else false</description>
	</param>
	<param name="frontLeftDoorLocked" type="Boolean" mandatory="false">
		<description>true if front left door is locked, else false</description>
	</param>
	<param name="frontRightDoorLocked" type="Boolean" mandatory="false">
		<description>true if front right door is locked, else false</description>
	</param>
	<param name="rearLeftDoorLocked" type="Boolean" mandatory="false">
		<description>true if rear left door is locked, else false</description>
	</param>
	<param name="rearRightDoorLocked" type="Boolean" mandatory="false">
		<description>true if rear right door is locked, else false</description>
	</param>
	<param name="trunkLocked" type="Boolean" mandatory="false">
		<description>true if trunk is locked, else false</description>
	</param>			
</struct>
```

## Potential downsides

Author is not aware of any downsides to proposed solution. This proposal just enhances the SDL content.

## Impact on existing code

* SDL Core needs to be updated as per new API.
* Proxy needs to be updated to support getters/setters as per new API.
* SDL Server needs to add permissions for new vehicle data items.
* SHAID needs to add mappings for new vehicle data items as per updated spec.
* HMI needs to be updated to support new vehicle data items.

## Alternatives considered

* `SeatOccupancy` has information on if seat is occupied and belt buckled status. Potentially these can be separate vehicle data items as well. If we do separate these two, it'd need additional coding and maintenance for one more vehicle data item.
