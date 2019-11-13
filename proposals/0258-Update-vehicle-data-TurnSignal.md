# Update vehicle data TurnSignal

* Proposal: [SDL-0258](0258-Update-vehicle-data-TurnSignal.md)
* Author: [Ankur Tiwari](https://github.com/atiwari9)
* Status: **Withdrawn**
* Impacted Platforms: [Core | HMI | iOS | Java Suite | RPC]

## Introduction

This proposal is to add additional param `hazardLights` to `TurnSignal`.

## Motivation

In order to partner with more diverse app partners, we need to provide additional sets of vehicle data items through SDL. This goes in line with commitment to enhance SDL with even richer vehicle data content. Hazard lights information is useful for Emergency apps and Insurance apps to know if a vehicle/driver needs any assistance.

## Proposed Solution 
We need to add `hazardLights` to `TurnSignal` for `GetVehicleData`, `SubscribeVehicleData`, `UnsubscribeVehicleData` & `OnVehicleData` RPCs. Following are the changes needed in MOBILE_API and HMI_API:

### Updates in MOBILE_API:

#### Add new struct `TurnSignalData`

```xml
<struct name="TurnSignalData" since="X.x">
	<param name="turnSignal" type="TurnSignal" mandatory="false" since="X.x">
		<description>See TurnSignal</description>
	</param>	
	<param name="hazardLights" type="VehicleDataStatus" mandatory="false" since="X.x">
		<description>Status of hazard lights</description>
	</param>
</struct>
```

#### Update the following parameter to these function requests:
* `SubscribeVehicleData`
* `UnsubscribeVehicleData`
* `GetVehicleData`

```xml
<param name="turnSignal" type="Boolean" mandatory="false" since="5.0">
	<description>See TurnSignalData</description>
	<history>
		<description>See TurnSignal</description>
	</history>
</param>
```

#### Update the following parameter to these function responses:
* `SubscribeVehicleData`
* `UnsubscribeVehicleData`

```xml
<param name="turnSignal" type="VehicleDataResult" mandatory="false" since="5.0">
	<description>See TurnSignalData</description>
	<history>
		<description>See TurnSignal</description>
	</history>
</param>
```

#### Update the following parameter to these function responses:
* `GetVehicleData`
* `OnVehicleData`

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

### Updates in HMI_API:

#### Add new struct enum `TurnSignalData` in `Common` interface: 

```xml
<struct name="TurnSignalData">
	<param name="turnSignal" type="Common.TurnSignal" mandatory="false">
		<description>See TurnSignal</description>
	</param>	
	<param name="hazardLights" type="Common.VehicleDataStatus" mandatory="false">
		<description>Status of hazard lights</description>
	</param>
</struct>

```

#### Update the following parameter to these function requests:
* `SubscribeVehicleData`
* `UnsubscribeVehicleData`
* `GetVehicleData`

```xml
<param name="turnSignal" type="Boolean" mandatory="false">
	<description>See Common.TurnSignalData</description>	
</param>
```

#### Update the following parameter to these function responses:
* `SubscribeVehicleData`
* `UnsubscribeVehicleData`

```xml
<param name="turnSignal" type="Common.VehicleDataResult" mandatory="false">
	<description>See Common.TurnSignalData</description>	
</param>
```

#### Update the following parameter to these function responses:
* `GetVehicleData`
* `OnVehicleData`

```xml
<param name="turnSignal" type="Common.TurnSignalData" mandatory="false">
	<description>See TurnSignalData</description>
	</history>
</param>
```

## Potential downsides

Since this is a breaking change, HMI would need to be updated as well.
 
## Impact on existing code

* SDL Core needs to be updated as per new API.
* HMI needs to be updated to support refactored structures.
* iOS/Java Suite need to be updated for `TurnSignal` getters/setters as per new API.

## Alternatives considered

* Instead of adding `hazardLights` to `TurnSignal`, it can be a new vehicle data items in itself.
