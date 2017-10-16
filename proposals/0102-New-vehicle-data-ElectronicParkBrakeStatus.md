# New vehicle data - ElectronicParkBrakeStatus

* Proposal: [SDL-0102](0102-New-vehicle-data-ElectronicParkBrakeStatus.md)
* Author: [Robin Kurian](https://github.com/robinmk)
* Status: **Accepted**
* Impacted Platforms: [Core/Android/iOS/RPC]

## Introduction

This proposal is about adding a new vehicle data to get the status of the Park Brake from the Electric Park Brake (EPB) system.

## Motivation

The Ford Owner application requires the Park Brake status for diagnostic purposes to provide related information to the user.

## Proposed solution

The solution proposes adding the possibility to subscribe and get the Park Brake status by making the following additions to the Mobile API and HMI API.

### Additions to Mobile_API

```xml
<enum name="ElectronicParkBrakeStatus">
  <element name="CLOSED" />
    <description>
      Park brake actuators have been fully applied.
    </description>		
    </element>
  <element name="TRANSITION">
    <description>
      Park brake actuators are transitioning to either Apply/Closed or Release/Open state.
    </description>
  </element>
  <element name="OPEN">
    <description>
      Park brake actuators are released.
    </description>		
  </element>
  <element name="DRIVE_ACTIVE">
    <description>
      When driver pulls the Electronic Park Brake switch while driving "at speed".
    </description>
  </element>
 <element name="FAULT">
    <description>
      When system has a fault or is under maintenance.
    </description>
 </element>
</enum>

<enum name="VehicleDataType">
            :
    <element name="VEHICLEDATA_ELECTRONICPARKBRAKESTATUS" />
</enum>

<function name="SubscribeVehicleData" functionID="SubscribeVehicleDataID" messagetype="request">
            :
    <param name="electronicParkBrakeStatus" type="Boolean" mandatory="false">
        <description>The status of the park brake as provided by Electric Park Brake (EPB) system.</description>
    </param>
</function>

<function name="SubscribeVehicleData" functionID="SubscribeVehicleDataID" messagetype="response">
            :
    <param name="electronicParkBrakeStatus" type="VehicleDataResult" mandatory="false">
        <description>The status of the park brake as provided by Electric Park Brake (EPB) system.</description>
    </param>
</function>

<function name="UnsubscribeVehicleData" functionID="UnsubscribeVehicleDataID" messagetype="request">
            :
    <param name="electronicParkBrakeStatus" type="Boolean" mandatory="false">
        <description>The status of the park brake as provided by Electric Park Brake (EPB) system.</description>
    </param>
</function>

<function name="UnsubscribeVehicleData" functionID="UnsubscribeVehicleDataID" messagetype="response">
            :
    <param name="electronicParkBrakeStatus" type="VehicleDataResult" mandatory="false">
        <description>The status of the park brake as provided by Electric Park Brake (EPB) system.</description>
    </param>
</function>

<function name="GetVehicleData" functionID="GetVehicleDataID" messagetype="request">
            :
    <param name="electronicParkBrakeStatus" type="Boolean" mandatory="false">
        <description>The status of the park brake as provided by Electric Park Brake (EPB) system.</description>
    </param>
</function>
<function name="GetVehicleData" functionID="GetVehicleDataID" messagetype="response">
            :
    <param name="electronicParkBrakeStatus" type="EletronicParkBrakeStatus" mandatory="false">
        <description>The status of the park brake as provided by Electric Park Brake (EPB) system.</description>
    </param>
</function>

<function name="OnVehicleData" functionID="OnVehicleDataID" messagetype="notification">
            :
    <param name="electronicParkBrakeStatus" type="EletronicParkBrakeStatus" mandatory="false">
        <description>The status of the park brake as provided by Electric Park Brake (EPB) system.</description>
    </param>
</function>
```
### Additions to HMI_API

Changes to enums and functions in the mobile API should also be applied to the HMI API.

### HMI

If the HMI can provide the park brake status it should read the related CAN signals and map it to the `electronicParkBrakeStatus` parameter. Otherwise the HMI should reply with `VEHICLE_DATA_NOT_AVAILABLE` if the head unit cannot provide the park brake status.

## Potential downsides

NA

## Impact on existing code

- requires changes on SDL core, both SDKs (Android, iOS) and APIs (mobile, HMI).
- would require a minor version change.

Existing head units of an older version replies with INVALID_DATA as expected if an app tries to get/subscribe to parkBrakeStatus.

## Alternatives considered

NA
