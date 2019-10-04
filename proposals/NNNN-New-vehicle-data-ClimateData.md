# New vehicle data ClimateData

* Proposal: [SDL-NNNN](NNNN-New-vehicle-data-ClimateData.md)
* Author: [Ankur Tiwari](https://github.com/atiwari9)
* Status: **Awaiting review**
* Impacted Platforms: [Core | HMI | Policy Server | SHAID | iOS | Java Suite]

## Introduction

This proposal is to add new vehicle data `ClimateData` to know cabin temperature, atmospheric pressure and external temperature.

## Motivation

In order to partner with more diverse app partners, we need to provide additional sets of vehicle data items through SDL. This goes in line with commitment to enhance SDL with even richer vehicle data content. Weather apps need additional information on climate conditions and that can be provided with external/internal temperature and atmospheric pressure.

## Proposed Solution 

We need to add `ClimateData` for `GetVehicleData`, `SubscribeVehicleData`, `UnsubscribeVehicleData` & `OnVehicleData` RPCs. Following are the changes needed in MOBILE_API and HMI_API:

### Updates in MOBILE_API:

#### Add to enum `VehicleDataType`: 

```xml	
<element name="VEHICLEDATA_CLIMATEDATA" since="X.x"/>
```
#### Add new struct `ClimateData`:

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

#### Add the following parameter to these function requests:
* `SubscribeVehicleData`
* `UnsubscribeVehicleData`
* `GetVehicleData`

```xml	
<param name="climateData" type="Boolean" mandatory="false" since="X.x">
	<description>See ClimateData</description>
</param>
```

#### Add the following parameter to these function responses:
* `SubscribeVehicleData`
* `UnsubscribeVehicleData`

```xml	
<param name="climateData" type="VehicleDataResult" mandatory="false" since="X.x">
	<description>See ClimateData</description>
</param>
```

#### Add the following parameter to these function responses:
* `GetVehicleData`
* `OnVehicleData`

```xml	
<param name="climateData" type="ClimateData" mandatory="false" since="X.x">
	<description>See ClimateData</description>
</param>
```

### Updates in HMI_API 

#### Add to enum `VehicleDataType` in `Common` interface: 

```xml	
<element name="VEHICLEDATA_CLIMATEDATA"/>
```
#### Add new struct `ClimateData` in `Common` interface:

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

#### Add the following parameter to these function requests:
* `SubscribeVehicleData`
* `UnsubscribeVehicleData`
* `GetVehicleData`

```xml	
<param name="climateData" type="Boolean" mandatory="false">
	<description>See ClimateData</description>
</param>
```

#### Add the following parameter to these function responses:
* `SubscribeVehicleData`
* `UnsubscribeVehicleData`

```xml	
<param name="climateData" type="Common.VehicleDataResult" mandatory="false">
	<description>See ClimateData</description>
</param>
```

#### Add the following parameter to these function responses:
* `GetVehicleData`
* `OnVehicleData`

```xml	
<param name="climateData" type="Common.ClimateData" mandatory="false">
	<description>See ClimateData</description>
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
