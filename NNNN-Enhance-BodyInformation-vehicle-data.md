# Enhance BodyInformation vehicle data

* Proposal: [SDL-NNNN](NNNN-Enhance-BodyInformation-vehicle-data.md)
* Author: [Ankur Tiwari](https://github.com/atiwari9)
* Status: **Awaiting review**
* Impacted Platforms: [Core | HMI | iOS | Java Suite | RPC]

## Introduction

This proposal is to enhance `BodyInformation` with more params to get access to more door related signals.

## Motivation

In order to partner with more diverse app partners, we need to provide additional sets of vehicle data items through SDL. This goes in line with commitment to enhance SDL with even richer vehicle data content. We need to provide apps with doors lock status along with if trunk/liftgate or hood/bonut are ajar. This information is handy for all the apps but in particular the apps which provide safety information and insurance.

## Proposed Solution 

Following vehicle data params are added to `BodyInformation` struct:
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

`BodyInformation` struct has twice the params now but this enhancement is very useful in terms of value it provides.

## Impact on existing code

* SDL Core needs to be updated as per new API.
* iOS/Java Suite needs to be updated to support getters/setters as per new API.
* HMI needs to be updated to support new vehicle data params.

## Alternatives considered

* New params can be added as new vehicle data item as well, but that might cause confusion with similar sounding vehicle data items.
