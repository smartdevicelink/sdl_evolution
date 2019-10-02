# Vehicle data refactoring

* Proposal: [SDL_NNNN](NNNN-Vehicle-data-refactoring.md)
* Author: [Ankur Tiwari](https://github.com/atiwari9)
* Status: **Awaiting review**
* Impacted Platforms: [Core | HMI | SDL SERVER | PROXY]

## Introduction

This proposal is to refactor current vehicle data items to accommodate new vehicle data items and to remove redundancy due to new vehicle data items added in [Vehicle Data Additions proposal](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0253-Vehicle-data-additions.md).

## Motivation

In order to partner with more diverse app partners, we need to provide additional set of vehicle data item through SDL. This goes in line with commitment to enhance SDL with even more rich vehicle data content.

## Proposed Solution 

We need to refactor existing vehicle data items to enhance and/or remove redundancy in vehicle data items. Following are the details on all the changes proposed.

#### Updates to existing vehicle data items:

1. Add sub param `hazardLights` to `turnSignal` vehicle data item.
2. Remove `externalTemperature`.
   * `externalTemperature` is available in new vehicle data item `ClimateData`.
3. Remove `PRNDL` vehicle data item.
   * Add new values to `PRNDL` enum.
   * Rename `PRNDL` enum to `GearPosition` enum.


### 1. Add sub param `hazardLights` to `turnSignal` vehicle data item.

#### Updates in MOBILE_API:

##### Add new struct `TurnSignalData`

```xml
<struct name="TurnSignalData" since="X.x">
	<param name="turnSignal" type="TurnSignal" mandatory="false" since="5.0">
		<description>See TurnSignal</description>
	</param>	
	<param name="hazardLights" type="VehicleDataStatus" mandatory="false" since="X.x">
		<description>Status of hazard lights</description>
	</param>
</struct>
```

##### Add to function `SubscribeVehicleData` request: 

```xml
<param name="turnSignal" type="Boolean" mandatory="false" since="5.0">
	<description>See TurnSignalData</description>
	<history>
		<description>See TurnSignal</description>
	</history>
</param>
```

##### Add to function `SubscribeVehicleData` response: 

```xml
<param name="turnSignal" type="VehicleDataResult" mandatory="false" since="5.0">
	<description>See TurnSignalData</description>
	<history>
		<description>See TurnSignal</description>
	</history>
</param>
```

##### Add to function `UnsubscribeVehicleData` request: 

```xml
<param name="turnSignal" type="Boolean" mandatory="false" since="5.0">
	<description>See TurnSignalData</description>
	<history>
		<description>See TurnSignal</description>
	</history>
</param>
```

##### Add to function `UnsubscribeVehicleData` response: 

```xml
<param name="turnSignal" type="VehicleDataResult" mandatory="false" since="5.0">
	<description>See TurnSignalData</description>
	<history>
		<description>See TurnSignal</description>
	</history>
</param>
```

##### Add to function `GetVehicleData` request: 

```xml
<param name="turnSignal" type="Boolean" mandatory="false" since="5.0">
	<description>See TurnSignalData</description>
	<history>
		<description>See TurnSignal</description>
	</history>
</param>
```

##### Add to function `GetVehicleData` response: 

```xml
<param name="turnSignal" type="TurnSignalData" mandatory="false" since="X.x">
	<description>See TurnSignalData</description>
	<history>
		<param name="turnSignal" type="TurnSignal" mandatory="false" since="5.0" until="X.x">
			<description>See TurnSignal</description>
		</param>
	</history>
</param>
```

##### Add to function `OnVehicleData` response: 

```xml
<param name="turnSignal" type="TurnSignalData" mandatory="false" since="X.x">
	<description>See TurnSignalData</description>
	<history>
		<param name="turnSignal" type="TurnSignal" mandatory="false" since="5.0" until="X.x">
			<description>See TurnSignal</description>
		</param>
	</history>
</param>
```

#### Updates in HMI_API:

##### Add new struct enum `TurnSignalData` in `Common` interface: 

```xml
<struct name="TurnSignalData">
	<param name="turnSignal" type="Common.TurnSignal" mandatory="false" since="5.0">
		<description>See TurnSignal</description>
	</param>	
	<param name="hazardLights" type="Common.VehicleDataStatus" mandatory="false" since="X.x">
		<description>Status of hazard lights</description>
	</param>
</struct>

```

##### Update function `SubscribeVehicleData` request: 

```xml
<param name="turnSignal" type="Boolean" mandatory="false">
	<description>See Common.TurnSignalData</description>	
</param>
```

##### Update function `SubscribeVehicleData` response: 

```xml
<param name="turnSignal" type="Common.VehicleDataResult" mandatory="false">
	<description>See Common.TurnSignalData</description>	
</param>
```

##### Update function `UnsubscribeVehicleData` request: 

```xml
<param name="turnSignal" type="Boolean" mandatory="false">
	<description>See Common.TurnSignalData</description>	
</param>
```

##### Update function `UnsubscribeVehicleData` response: 

```xml
<param name="turnSignal" type="Common.VehicleDataResult" mandatory="false">
	<description>See Common.TurnSignalData</description>	
</param>
```

##### Update function `GetVehicleData` request: 

```xml
<param name="turnSignal" type="Boolean" mandatory="false">
	<description>See Common.TurnSignalData</description>
</param>
```

##### Update function `GetVehicleData` response: 

```xml
<param name="turnSignal" type="Common.TurnSignalData" mandatory="false">
	<description>See TurnSignalData</description>
	</history>
</param>
```

##### Update function `OnVehicleData` response: 

```xml
<param name="turnSignal" type="Common.TurnSignalData" mandatory="false">
	<description>See TurnSignalData</description>
</param>
```


### 2. Remove `externalTemperature`.

`externalTemperature` is now available in new vehicle data item `ClimateData` as a parameter. 


#### Updates in MOBILE_API:


##### Update enum `VehicleDataType`: 

```xml
<element name="VEHICLEDATA_EXTERNTEMP" since="2.0" until="X.x"/>
<history>
	<element name="VEHICLEDATA_EXTERNTEMP"/>
</history>
```


##### Update function `SubscribeVehicleData` request: 

```xml
<param name="externalTemperature" type="Boolean" mandatory="false" since="2.0" until="X.x">
	<description>The external temperature in degrees celsius</description>
	<history>
		<param name="externalTemperature" type="Boolean" mandatory="false"/>
	</history>
</param>
```

##### Update function `SubscribeVehicleData` response: 

```xml
<param name="externalTemperature" type="VehicleDataResult" mandatory="false" since="2.0" until="X.x">
	<description>The external temperature in degrees celsius</description>
	<history>
		<param name="externalTemperature" type="VehicleDataResult" mandatory="false"/>
	</history>
</param>
```

##### Update function `UnsubscribeVehicleData` request: 

```xml
<param name="externalTemperature" type="Boolean" mandatory="false" since="2.0" until="X.x">
	<description>The external temperature in degrees celsius</description>
	<history>
		<param name="externalTemperature" type="Boolean" mandatory="false"/>
	</history>
</param>
```

##### Update function `UnsubscribeVehicleData` response: 

```xml
<param name="externalTemperature" type="VehicleDataResult" mandatory="false" since="2.0" until="X.x">
	<description>The external temperature in degrees celsius</description>
	<history>
		<param name="externalTemperature" type="VehicleDataResult" mandatory="false"/>
	</history>
</param>
```

##### Update function `GetVehicleData` request: 

```xml
<param name="externalTemperature" type="Boolean" mandatory="false" since="2.0" until="X.x">
	<description>The external temperature in degrees celsius</description>
	<history>
		<param name="externalTemperature" type="Boolean" mandatory="false"/>
	</history>
</param>
```

##### Update function `GetVehicleData` response: 

```xml
<param name="externalTemperature" type="Float" minvalue="-40" maxvalue="100" mandatory="false" since="2.0" until="X.x">
	<description>The external temperature in degrees celsius</description>
	<history>
		<param name="externalTemperature" type="Float" minvalue="-40" maxvalue="100" mandatory="false"/>
	</history>
</param>
```

##### Update function `OnVehicleData` notification: 

```xml
<param name="externalTemperature" type="Float" minvalue="-40" maxvalue="100" mandatory="false" since="2.0" until="X.x">
	<description>The external temperature in degrees celsius</description>
	<history>
		<param name="externalTemperature" type="Float" minvalue="-40" maxvalue="100" mandatory="false"/>
	</history>
</param>
```

#### Updates in HMI_API:

##### Remove element `VEHICLEDATA_EXTERNTEMP` from enum `VehicleDataType` in `Common` interface: 

```xml
-<element name="VEHICLEDATA_EXTERNTEMP"/>
```


##### Remove param `externalTemperature` from function `SubscribeVehicleData` request: 

```xml
-<param name="externalTemperature" type="Boolean" mandatory="false">
- 	<description>The external temperature in degrees celsius</description>
-</param>
```

##### Remove param `externalTemperature` from function `SubscribeVehicleData` response: 

```xml
-<param name="externalTemperature" type="Common.VehicleDataResult" mandatory="false">
-	<description>The external temperature in degrees celsius</description>
-</param>
```

##### Remove param `externalTemperature` from function `UnsubscribeVehicleData` request: 

```xml
-<param name="externalTemperature" type="Boolean" mandatory="false">
- 	<description>The external temperature in degrees celsius</description>
-</param>
```

##### Remove param `externalTemperature` from function `UnsubscribeVehicleData` response: 

```xml
-<param name="externalTemperature" type="Common.VehicleDataResult" mandatory="false">
-	<description>The external temperature in degrees celsius</description>
-</param>
```


##### Remove param `externalTemperature` from function `GetVehicleData` request: 

```xml
-<param name="externalTemperature" type="Boolean" mandatory="false">
- 	<description>The external temperature in degrees celsius</description>
-</param>
```

##### Remove param `externalTemperature` from function `GetVehicleData` response: 

```xml
-<param name="externalTemperature" type="Float" minvalue="-40" maxvalue="100" mandatory="false">
-	<description>The external temperature in degrees celsius</description>	
-</param>
```

##### Remove param `externalTemperature` from function `OnVehicleData` response: 

```xml
-<param name="externalTemperature" type="Float" minvalue="-40" maxvalue="100" mandatory="false">
-	<description>The external temperature in degrees celsius</description>	
-</param>
```

### 3. Remove `PRNDL` vehicle data item.

`PRNDL` is now available in new vehicle data item `GearStatus` as a parameter. 


#### Updates in MOBILE_API:

##### Update enum `VehicleDataType`: 

```xml
<element name="VEHICLEDATA_PRNDL" since="2.0" until="X.x"/>
<history>
	<element name="VEHICLEDATA_PRNDL"/>
</history>
```

##### Update enum `PRNDL`:

```xml
<enum name="PRNDL" since="2.0" until="X.x">
	<history>
		<enum name="PRNDL" since="2.0">
	</history>	
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

##### Update function `SubscribeVehicleData` request: 

```xml
<param name="prndl" type="Boolean" mandatory="false" since="2.0" until="X.x">
	<description>See PRNDL</description>
	<history>
		<param name="prndl" type="Boolean" mandatory="false"/>
	</history>
</param>
```

##### Update function `SubscribeVehicleData` response: 

```xml
<param name="prndl" type="VehicleDataResult" mandatory="false" since="2.0" until="X.x">
	<description>See PRNDL</description>
	<history>
		<param name="prndl" type="VehicleDataResult" mandatory="false"/>
	</history>
</param>
```

##### Update function `UnsubscribeVehicleData` request: 

```xml
<param name="prndl" type="Boolean" mandatory="false" since="2.0" until="X.x">
	<description>See PRNDL</description>
	<history>
		<param name="prndl" type="Boolean" mandatory="false"/>
	</history>
</param>
```

##### Update function `UnsubscribeVehicleData` response: 

```xml
<param name="prndl" type="VehicleDataResult" mandatory="false" since="2.0" until="X.x">
	<description>See PRNDL</description>
	<history>
		<param name="prndl" type="VehicleDataResult" mandatory="false"/>
	</history>
</param>
```

##### Update function `GetVehicleData` request: 

```xml
<param name="prndl" type="Boolean" mandatory="false" since="2.0" until="X.x">
	<description>See PRNDL</description>
	<history>
		<param name="prndl" type="Boolean" mandatory="false"/>
	</history>
</param>
```

##### Update function `GetVehicleData` response: 

```xml
<param name="prndl" type="PRNDL" mandatory="false" since="2.0" until="X.x">
	<description>See PRNDL</description>
	<history>
		<param name="prndl" type="PRNDL" mandatory="false"/>
	</history>
</param>
```

##### Update function `OnVehicleData` notification: 

```xml
<param name="prndl" type="PRNDL" mandatory="false" since="2.0" until="X.x">
	<description>See PRNDL</description>
	<history>
		<param name="prndl" type="PRNDL" mandatory="false"/>
	</history>
</param>
```

#### Updates in HMI_API: 


##### Remove element `VEHICLEDATA_PRNDL` from enum `VehicleDataType` in `Common` interface: 

```xml
-<element name="VEHICLEDATA_PRNDL"/>
```

##### Remove enum `PRNDL` from `Common` interface:

```xml
-<enum name="PRNDL">
-	<description>The selected gear.</description>
-	<element name="PARK">
-		<description>Parking</description>
-	</element>
	...
- 	<element name="FAULT">
- 	</element>
-</enum>
```


##### Remove param `prndl` from function `SubscribeVehicleData` request: 

```xml
-<param name="prndl" type="Boolean" mandatory="false">
- 	<description>See PRNDL</description>
-</param>
```

##### Remove param `prndl` from function `SubscribeVehicleData` response: 

```xml
-<param name="prndl" type="Common.VehicleDataResult" mandatory="false">
-	<description>See PRNDL</description>
-</param>
```

##### Remove param `prndl` from function `UnsubscribeVehicleData` request: 

```xml
-<param name="prndl" type="Boolean" mandatory="false">
- 	<description>See PRNDL</description>
-</param>
```

##### Remove param `prndl` from function `UnsubscribeVehicleData` response: 

```xml
-<param name="prndl" type="Common.VehicleDataResult" mandatory="false">
-	<description>See PRNDL</description>
-</param>
```


##### Remove param `prndl` from function `GetVehicleData` request: 

```xml
-<param name="prndl" type="Boolean" mandatory="false">
- 	<description>See PRNDL</description>
-</param>
```

##### Remove param `prndl` from function `GetVehicleData` response: 

```xml
-<param name="prndl" type="Common.PRNDL" mandatory="false">
-	<description>See PRNDL</description>	
-</param>
```

##### Remove param `prndl` from function `OnVehicleData` response: 

```xml
-<param name="prndl" type="Common.PRNDL" mandatory="false">
-	<description>See PRNDL</description>	
-</param>
```

## Potential downsides

Since this is a breaking change, HMI would need to be updated as well.
 
## Impact on existing code

* SDL Core needs to be updated as per new API.
* Proxy needs to be updated to support getters/setters as per new API.
* SDL Server needs to update permissions for refactored vehicle data items.
* HMI needs to be updated to support refactored structures.

## Alternatives considered

* Instead of adding `hazardLights`  to `TurnSignal`, it can be a new vehicle data items in itself.
