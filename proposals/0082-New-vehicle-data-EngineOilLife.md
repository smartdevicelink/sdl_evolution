# New vehicle data - EngineOilLife

* Proposal: [SDL-0082](0082-New-vehicle-data-EngineOilLife.md)
* Author: [Robin Kurian](https://github.com/robinmk)
* Status: **In Review**
* Impacted Platforms: [Core/Android/iOS/RPC]

## Introduction

This proposal is about adding a new vehicle data to get the remaining engine oil life of a vehicle.

## Motivation

The Ford Owner application requires the engine oil life data to provide related information to the user.
A service application may want to use this data to provide reminders to the customer when an oil change is required or maybe even to route the user to the nearest service center.

## Proposed solution

The solution proposes adding the possibility to get and subscribe to the engine oil life by making the following additions to the Mobile API and HMI API.

### Additions to Mobile_API

```xml
<enum name="VehicleDataType">
            :
    <element name="VEHICLEDATA_ENGINEOILLIFE" />
</enum>

<function name="SubscribeVehicleData" functionID="SubscribeVehicleDataID" messagetype="request">
            :
    <param name="engineOilLife" type="Boolean" mandatory="false">
        <description>The estimated percentage of remaining oil life of the engine.</description>
    </param>
</function>
<function name="SubscribeVehicleData" functionID="SubscribeVehicleDataID" messagetype="response">
            :
    <param name="engineOilLife" type="VehicleDataResult" mandatory="false">
        <description>The estimated percentage of remaining oil life of the engine.</description>
    </param>
</function>

<function name="UnsubscribeVehicleData" functionID="UnsubscribeVehicleDataID" messagetype="request">
            :
    <param name="engineOilLife" type="Boolean" mandatory="false">
        <description>The estimated percentage of remaining oil life of the engine.</description>
    </param>
</function>
<function name="UnsubscribeVehicleData" functionID="UnsubscribeVehicleDataID" messagetype="response">
            :
    <param name="engineOilLife" type="VehicleDataResult" mandatory="false">
        <description>The estimated percentage of remaining oil life of the engine.</description>
    </param>
</function>

<function name="GetVehicleData" functionID="GetVehicleDataID" messagetype="request">
            :
	<param name="engineOilLife" type="Boolean" mandatory="false">
        <description>The estimated percentage of remaining oil life of the engine.</description>
    </param>
</function>
<function name="GetVehicleData" functionID="GetVehicleDataID" messagetype="response">
            :
    <param name="engineOilLife" type="Float" minvalue="0" maxvalue="100" mandatory="false">
        <description>The estimated percentage of remaining oil life of the engine.</description>
    </param>
</function>

<function name="OnVehicleData" functionID="OnVehicleDataID" messagetype="notification">
            :
    <param name="engineOilLife" type="Float" minvalue="0" maxvalue="100" mandatory="false">
        <description>The estimated percentage of remaining oil life of the engine.</description>
    </param>
</function>
```

### Additions to HMI_API

Changes to enums and functions in the mobile API should also be applied to the HMI API.

### HMI

If the HMI can provide the engine oil life it should read the CAN signals related to the engine oil life and map it to the `engineOilLife` parameter. Otherwise the HMI should reply with `VEHICLE_DATA_NOT_AVAILABLE` if the head unit cannot provide the data.

## Potential downsides

NA

## Impact on existing code

- requires changes on SDL core, both SDKs (Android, iOS) and APIs (mobile, HMI).
- would require a minor version change.

Existing head units of an older version replies with INVALID_DATA as expected if an app tries to subscribe to this signal.

## Alternatives considered

NA
