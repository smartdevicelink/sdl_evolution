# New vehicle data - TurnSignal

* Proposal: [SDL-0107](0107-New-vehicle-data-turnSignal.md)
* Author: [Robin Kurian](https://github.com/robinmk)
* Status: **Accepted**
* Impacted Platforms: [Core/Android/iOS/RPC]

## Introduction

This proposal is about adding a new vehicle data to get the value of the turn signal.

## Motivation

Currently it is not possible to detect the turn signal through SDL. The turn signal is a requested feature by the Ford Owner application team.

## Proposed solution

The solution proposes adding the possibility to get and subscribe to the turn signal.

### Additions to Mobile_API

```xml
<enum name="VehicleDataType">
            :
    <element name="VEHICLEDATA_TURNSIGNAL" />
</enum>

<function name="SubscribeVehicleData" functionID="SubscribeVehicleDataID" messagetype="request">
            :
    <param name="turnSignal" type="Boolean" mandatory="false">
        <description>See TurnSignal</description>
    </param>
</function>
<function name="SubscribeVehicleData" functionID="SubscribeVehicleDataID" messagetype="response">
            :
            :
    <param name="turnSignal" type="VehicleDataResult" mandatory="false">
        <description>See TurnSignal</description>
    </param>
</function>

<function name="UnsubscribeVehicleData" functionID="UnsubscribeVehicleDataID" messagetype="request">
            :
    <param name="turnSignal" type="Boolean" mandatory="false">
        <description>See TurnSignal</description>
    </param>
</function>
<function name="UnsubscribeVehicleData" functionID="UnsubscribeVehicleDataID" messagetype="response">
            :
    <param name="turnSignal" type="VehicleDataResult" mandatory="false">
        <description>See TurnSignal</description>
    </param>
</function>

<function name="GetVehicleData" functionID="GetVehicleDataID" messagetype="request">
            :
    <param name="turnSignal" type="Boolean" mandatory="false">
        <description>See TurnSignal</description>
    </param>
</function>
<function name="GetVehicleData" functionID="GetVehicleDataID" messagetype="response">
            :
    <param name="turnSignal" type="TurnSignal" mandatory="false">
        <description>See TurnSignal</description>
    </param>
</function>

<function name="OnVehicleData" functionID="OnVehicleDataID" messagetype="notification">
            :
    <param name="turnSignal" type="TurnSignal" mandatory="false">
        <description>See TurnSignal</description>
    </param>
</function>

<enum name="TurnSignal">
    <description>Enumeration that describes the status of the turn light indicator.</description>
    <element name="OFF">
        <description>Turn signal is OFF</description>
    </element>
    <element name="LEFT">
        <description>Left turn signal is on</description>
    </element>
    <element name="RIGHT">
        <description>Right turn signal is on</description>
    </element>
    <element name="BOTH">
        <description>Both signals (left and right) are on.</description>
    </element>
</enum>
```

### Additions to HMI_API

Changes to enums and functions in the mobile API should also be applied to the HMI API. The newly added enum `TurnSignal` should be added to the `Common` interface.

### HMI

If the HMI can provide the turn signal it should read the CAN signals related to the turn signal and map it to the `TurnSignal` enum. Otherwise the HMI should reply with `VEHICLE_DATA_NOT_AVAILABLE` if the head unit cannot provide the turn signal.

## Potential downsides

NA

## Impact on existing code

The proposal

- requires changes on SDL core, both SDKs (Android, iOS) and APIs (mobile, HMI).
- would require a minor version change.

Existing head units of an older version replies with INVALID_DATA as expected if an app tries to subscribe to turn signal.

## Alternatives considered

NA
