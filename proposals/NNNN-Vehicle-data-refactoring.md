# Vehicle data refactoring

* Proposal: [SDL_NNNN](NNNN-Vehicle-data-refactoring.md)
* Author: [Ankur Tiwari](https://github.com/atiwari9)
* Status: **Awaiting review**
* Impacted Platforms: [Core | HMI | Policy Server | SHAID | iOS | Java Suite]

## Introduction

This proposal is to refactor current vehicle data items to accommodate new vehicle data items and to remove redundancy due to new vehicle data items added in proposals mentioned in [New vehicle data ClimateData](https://github.com/smartdevicelink/sdl_evolution/pull/838) and [New vehicle data GearStatus](https://github.com/smartdevicelink/sdl_evolution/pull/837) PRs. This proposal cannot be brought into review until above proposals are voted upon. (*Author will update the links to above proposals as well before pulling this proposal to in review*)

## Motivation

In order to partner with more diverse app partners, we need to provide additional sets of vehicle data items through SDL. This goes in line with commitment to enhance SDL with even richer vehicle data content.

## Proposed Solution 

We need to refactor existing vehicle data items to enhance and/or remove redundancy in vehicle data items. Following are the details on all the changes proposed.

#### Updates to existing vehicle data items:

1. Remove `externalTemperature`.
   * `externalTemperature` is available in new vehicle data item `ClimateData`.
2. Remove `PRNDL` vehicle data item.
   * `PRNDL` is now available in new vehicle data item `GearStatus` as a parameter `gearDriveMode`.


### 1. Remove `externalTemperature`.

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

### 2. Remove `PRNDL` vehicle data item.

`PRNDL` is now available in new vehicle data item `GearStatus` as a parameter `gearDriveMode`. 


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

* None
