# Refactor Fuel Information Related Vehicle Data

* Proposal: [SDL-0254](0254-Refactor-Fuel-Information-Related-Vehicle-Data.md)
* Author: [Ankur Tiwari](https://github.com/atiwari9)
* Status: **In Review**
* Impacted Platforms: [Core | HMI | iOS | Java Suite | RPC]

## Introduction

This proposal is to consolidate Fuel Information related vehicle data so that it supports multiple type of propulsion sources used by vehicle.

## Motivation

In order to partner with more diverse app partners, we need to provide additional sets of vehicle data items through SDL. This goes in line with commitment to enhance SDL with even richer vehicle data content. We need to provide the battery charge level for Electric and Hybrid vehicles to apps that provide navigation, charge station information etc. While we are doing that, we should also work towards making the API leaner and scalable for future demands.

## Proposed Solution 

We need to:
* Update `FuelRange` Struct to include:
   * `type` (existing)
   * `range` (existing)
   * `FuelLevel` (moved)
   * `FuelLevel_State` (moved)
   * `capacity` (new)
   * `capacityUnit` (new)
* Add new enum `CapacityUnit`.
* Deprecate vehicle data `FuelLevel`.
* Deprecate vehicle data `FuelLevel_State`.

### Updates in MOBILE_API:

#### Update enum `VehicleDataType`: 

```xml	
<element name="VEHICLEDATA_FUELLEVEL" until="X.x"/>
<element name="VEHICLEDATA_FUELLEVEL_STATE" until="X.x"/>
```

#### Add new enum `CapacityUnit`:
```xml
+<enum name="CapacityUnit" since="X.x">
+    <element name="LITERS" />
+    <element name="KILOWATTHOURS" />
+</enum>
```

#### Update Struct `FuelRange`:
```xml
<struct name="FuelRange" since="5.0">
    <param name="type" type="FuelType" mandatory="false"/>
    <param name="range" type="Float" minvalue="0" maxvalue="10000" mandatory="false">
        <description>
            The estimate range in KM the vehicle can travel based on fuel level and consumption.
        </description>
    </param>
+   <param name="level" type="Float" minvalue="-6" maxvalue="170" mandatory="false" since="X.x">
+       <description>The relative remaining capacity of this fuel type (percentage).</description>
+   </param>
+   <param name="levelState" type="ComponentVolumeStatus" mandatory="false" since="X.x">
+        <description>The fuel level state</description>
+    </param>
+   <param name="capacity" minvalue="0" maxvalue="1500" mandatory="false" since="X.x">
+       <description>The absolute capacity of this fuel type.</description>
+   </param>
+   <param name="capacityUnit" type="CapacityUnit" mandatory="false" since="X.x">
+       <description>The unit of the capacity of this fuel type such as liters for gasoline or kWh for batteries.</description>
+   </param>
</struct>
```

#### Add the following parameter to these function requests:
* `SubscribeVehicleData`
* `UnsubscribeVehicleData`
* `GetVehicleData`

```xml	
<param name="FuelLevel" type="Boolean" mandatory="false" deprecated="true" since="X.x">
	<description>The fuel level in the tank (percentage)</description>
</param>
<param name="FuelLevel_State" type="Boolean" mandatory="false" deprecated="true" since="X.x">
	<description>The fuel level state</description>
</param>
```

#### Add the following parameter to these function responses:
* `SubscribeVehicleData`
* `UnsubscribeVehicleData`

```xml	
<param name="FuelLevel" type="VehicleDataResult" mandatory="false" deprecated="true" since="X.x">
	<description>The fuel level in the tank (percentage)</description>
</param>
<param name="FuelLevel_State" type="VehicleDataResult" mandatory="false" deprecated="true" since="X.x">
	<description>The fuel level state</description>
</param>
```

#### Add the following parameter to these function responses:
* `GetVehicleData`
* `OnVehicleData`

```xml	
<param name="fuelLevel" type="Float" minvalue="-6" maxvalue="106" mandatory="false" deprecated="true" since="X.x">
	<description>The fuel level in the tank (percentage)</description>
</param>
<param name="fuelLevel_State" type="ComponentVolumeStatus" mandatory="false" deprecated="true" since="X.x">
	<description>The fuel level state</description>
</param>
```

### Updates in HMI_API 


#### Add new enum `CapacityUnit` in `Common` interface:
```xml
+<enum name="CapacityUnit">
+    <element name="LITERS" />
+    <element name="KILOWATTHOURS" />
+</enum>
```

#### Update Struct `FuelRange`:
```xml
<struct name="FuelRange">
    <param name="type" type="Common.FuelType" mandatory="false"/>
    <param name="range" type="Float" minvalue="0" maxvalue="10000" mandatory="false">
        <description>
            The estimate range in KM the vehicle can travel based on fuel level and consumption.
        </description>
    </param>
+   <param name="level" type="Float" minvalue="-6" maxvalue="170" mandatory="false">
+       <description>The relative remaining capacity of this fuel type (percentage).</description>
+   </param>
+   <param name="levelState" type="Common.ComponentVolumeStatus" mandatory="false">
+        <description>The fuel level state</description>
+    </param>
+   <param name="capacity" minvalue="0" maxvalue="1500" mandatory="false">
+       <description>The absolute capacity of this fuel type.</description>
+   </param>
+   <param name="capacityUnit" type="Common.CapacityUnit" mandatory="false">
+       <description>The unit of the capacity of this fuel type such as liters for gasoline or kWh for batteries.</description>
+   </param>
</struct>
```


## Potential downsides

This deprecates `FuelLevel` and `FuelLevel_State`, but that is inevitable when we try to consolicate vehicle data items to more meaningful Structs.

## Impact on existing code

* SDL Core needs to be updated as per new API.
* iOS/Java Suite needs to be updated to support getters/setters as per new API.
* HMI needs to be updated to support new vehicle data items.

## Alternatives considered

* See history of this proposal and comments in [issue discussion](https://github.com/smartdevicelink/sdl_evolution/issues/842)
