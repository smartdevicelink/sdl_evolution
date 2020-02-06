# Refactor Fuel Information Related Vehicle Data

* Proposal: [SDL-0256](0256-Refactor-Fuel-Information-Related-Vehicle-Data.md)
* Author: [Ankur Tiwari](https://github.com/atiwari9)
* Status: **Accepted with Revisions**
* Impacted Platforms: [Core | HMI | iOS | Java Suite | RPC]

## Introduction

This proposal is to consolidate Fuel Information related vehicle data so that it supports multiple types of propulsion sources used by the vehicle.

## Motivation

In order to partner with more diverse app partners, we need to provide additional sets of vehicle data items through SDL. This goes in line with commitment to enhance SDL with even richer vehicle data content. We need to provide the battery charge level for Electric and Hybrid vehicles to apps that provide navigation, charge station information etc. While we are doing that, we should also work towards making the API leaner and scalable for future demands.

## Proposed Solution 

We need to:
* Update `FuelRange` Struct to include:
   * `type` (existing)
   * `range` (existing)
   * `fuelLevel` (moved)
   * `fuelLevel_State` (moved)
   * `capacity` (new)
   * `capacityUnit` (new)
* Add new enum `CapacityUnit`.
* Deprecate vehicle data `fuelLevel`.
* Deprecate vehicle data `fuelLevel_State`.

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
+    <element name="KILOGRAMS" />
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
+   <param name="level" type="Float" minvalue="-6" maxvalue="1000000" mandatory="false" since="X.x">
+       <description>The relative remaining capacity of this fuel type (percentage).</description>
+   </param>
+   <param name="levelState" type="ComponentVolumeStatus" mandatory="false" since="X.x">
+        <description>The fuel level state</description>
+    </param>
+   <param name="capacity" minvalue="0" maxvalue="1000000" mandatory="false" since="X.x">
+       <description>The absolute capacity of this fuel type.</description>
+   </param>
+   <param name="capacityUnit" type="CapacityUnit" mandatory="false" since="X.x">
+       <description>The unit of the capacity of this fuel type such as liters for gasoline or kWh for batteries.</description>
+   </param>
</struct>
```

#### Update the following parameters in these function requests:
* `SubscribeVehicleData`
* `UnsubscribeVehicleData`
* `GetVehicleData`

```xml	
<param name="fuelLevel" type="Boolean" mandatory="false" deprecated="true" since="X.x">
	<description>The fuel level in the tank (percentage). This parameter is deprecated starting RPC Spec X.x.x, please see fuelRange.</description>
</param>
<param name="fuelLevel_State" type="Boolean" mandatory="false" deprecated="true" since="X.x">
	<description>The fuel level state. This parameter is deprecated starting RPC Spec X.x.x, please see fuelRange.</description>
</param>
<param name="fuelRange" type="Boolean" mandatory="false" since="5.0">
	<description>
		The fuel type, estimated range in KM, fuel level/capacity and fuel level state for the vehicle.
		See struct FuelRange for details.
	</description>
</param>
```

#### Update the following parameters in these function responses:
* `SubscribeVehicleData`
* `UnsubscribeVehicleData`

```xml	
<param name="fuelLevel" type="VehicleDataResult" mandatory="false" deprecated="true" since="X.x">
	<description>The fuel level in the tank (percentage). This parameter is deprecated starting RPC Spec X.x.x, please see fuelRange.</description>
</param>
<param name="fuelLevel_State" type="VehicleDataResult" mandatory="false" deprecated="true" since="X.x">
	<description>The fuel level state. This parameter is deprecated starting RPC Spec X.x.x, please see fuelRange.</description>
</param>
<param name="fuelRange" type="VehicleDataResult" mandatory="false" since="5.0">
	<description>
		The fuel type, estimated range in KM, fuel level/capacity and fuel level state for the vehicle.
		See struct FuelRange for details.
	</description>
</param>
```

#### Update the following parameters in these function responses:
* `GetVehicleData`
* `OnVehicleData`

```xml	
<param name="fuelLevel" type="Float" minvalue="-6" maxvalue="106" mandatory="false" deprecated="true" since="X.x">
	<description>The fuel level in the tank (percentage). This parameter is deprecated starting RPC Spec X.x.x, please see fuelRange.</description>
</param>
<param name="fuelLevel_State" type="ComponentVolumeStatus" mandatory="false" deprecated="true" since="X.x">
	<description>The fuel level state. This parameter is deprecated starting RPC Spec X.x.x, please see fuelRange.</description>
</param>
<param name="fuelRange" type="FuelRange" minsize="0" maxsize="100" array="true" mandatory="false" since="5.0">
	<description>
		The fuel type, estimated range in KM, fuel level/capacity and fuel level state for the vehicle.
		See struct FuelRange for details.
	</description>
</param>
```

### Updates in HMI_API 


#### Add new enum `CapacityUnit` in `Common` interface:
```xml
+<enum name="CapacityUnit">
+    <element name="LITERS" />
+    <element name="KILOWATTHOURS" />
+    <element name="KILOGRAMS" />
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
+   <param name="level" type="Float" minvalue="-6" maxvalue="1000000" mandatory="false">
+       <description>The relative remaining capacity of this fuel type (percentage).</description>
+   </param>
+   <param name="levelState" type="Common.ComponentVolumeStatus" mandatory="false">
+        <description>The fuel level state</description>
+    </param>
+   <param name="capacity" minvalue="0" maxvalue="1000000" mandatory="false">
+       <description>The absolute capacity of this fuel type.</description>
+   </param>
+   <param name="capacityUnit" type="Common.CapacityUnit" mandatory="false">
+       <description>The unit of the capacity of this fuel type such as liters for gasoline or kWh for batteries.</description>
+   </param>
</struct>
```

#### Update the following parameters in these function requests:
* `SubscribeVehicleData`
* `UnsubscribeVehicleData`
* `GetVehicleData`

```xml	
<param name="fuelRange" type="Boolean" mandatory="false">
	<description>
		The fuel type, estimated range in KM, fuel level/capacity and fuel level state for the vehicle.
		See struct FuelRange for details.
	</description>
</param>
```

#### Update the following parameters in these function responses:
* `SubscribeVehicleData`
* `UnsubscribeVehicleData`

```xml	
<param name="fuelRange" type="Common.VehicleDataResult" mandatory="false">
	<description>
		The fuel type, estimated range in KM, fuel level/capacity and fuel level state for the vehicle.
		See struct FuelRange for details.
	</description>
</param>
```

#### Update the following parameters in these function responses:
* `GetVehicleData`
* `OnVehicleData`

```xml	
<param name="fuelRange" type="FuelRange" minsize="0" maxsize="100" array="true" mandatory="false">
	<description>
		The fuel type, estimated range in KM, fuel level/capacity and fuel level state for the vehicle.
		See struct FuelRange for details.
	</description>
</param>
```

## Potential downsides

This deprecates `fuelLevel` and `fuelLevel_State`, but that is inevitable when we try to consolidate vehicle data items into more meaningful Structs.

## Impact on existing code

* SDL Core needs to be updated as per new API.
* iOS/Java Suite need to be updated to support getters/setters as per new API.
* HMI needs to be updated to support new vehicle data items.

## Alternatives considered

* See history of this proposal and comments in [issue discussion](https://github.com/smartdevicelink/sdl_evolution/issues/842)
