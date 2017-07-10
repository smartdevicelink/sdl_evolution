# New vehicle data - FuelRange

* Proposal: [SDL-0072](0072-New-vehicle-data-FuelRange.md)
* Author: [Robin Kurian](https://github.com/robinmk)
* Status: **Accepted with Revisions**
* Impacted Platforms: [Core/Android/iOS/RPC]

## Introduction

This proposal is about adding a new vehicle data to get the distance a vehicle can travel with the current level of fuel.

## Motivation

The Ford Owner application requires the fuel range data to provide related information to the user.
Other applications could also benefit from such a data. As an example, a Navigation application may use it to provide a more fuel-efficient route or to locate the nearest fuel station before the end of the fuel range.

## Proposed solution

The solution proposes adding the possibility to get and subscribe to the fuel range by making the following additions to the Mobile API and HMI API.

### Additions to Mobile_API

```xml
<enum name="FuelType">
    <element name="GASOLINE" />
    <element name="DIESEL" />
    <element name="CNG">
        <description>
            For vehicles using compressed natural gas.
        </description>
    </element>
    <element name="LPG">
        <description>
            For vehicles using liquefied petroleum gas.
        </description>
    </element>
    <element name="HYDROGEN">
        <description>For FCEV (fuel cell electric vehicle).</description>
    </element>
    <element name="BATTERY">
        <description>For BEV (Battery Electric Vehicle), PHEV (Plug-in Hybrid Electric Vehicle), solar vehicles and other vehicles which run on a battery.</description>
    </element>
</enum>

<struct name="FuelRange">
    <param name="type" type="FuelType" mandatory="false"/>
    <param name="range" type="Float" minvalue="0" maxvalue="10000" mandatory="false">
        <description>
            The estimate range in KM the vehicle can travel based on fuel level and consumption.
        </description>
    </param>
</struct>

<enum name="VehicleDataType">
            :
    <element name="VEHICLEDATA_FUELRANGE" />
</enum>

<function name="SubscribeVehicleData" functionID="SubscribeVehicleDataID" messagetype="request">
            :
    <param name="fuelRange" type="Boolean" mandatory="false">
        <description>The estimate range in KM the vehicle can travel based on fuel level and consumption</description>
    </param>
</function>
<function name="SubscribeVehicleData" functionID="SubscribeVehicleDataID" messagetype="response">
            :
    <param name="fuelRange" type="VehicleDataResult" mandatory="false">
        <description>The estimate range in KM the vehicle can travel based on fuel level and consumption</description>
    </param>
</function>

<function name="UnsubscribeVehicleData" functionID="UnsubscribeVehicleDataID" messagetype="request">
            :
    <param name="fuelRange" type="Boolean" mandatory="false">
        <description>The estimate range in KM the vehicle can travel based on fuel level and consumption</description>
    </param>
</function>
<function name="UnsubscribeVehicleData" functionID="UnsubscribeVehicleDataID" messagetype="response">
            :
    <param name="fuelRange" type="VehicleDataResult" mandatory="false">
        <description>The estimate range in KM the vehicle can travel based on fuel level and consumption</description>
    </param>
</function>
<param name="fuelRange" type="FuelRange" minsize="0" maxsize="100" array="true" mandatory="false">
<function name="GetVehicleData" functionID="GetVehicleDataID" messagetype="request">
            :
    <param name="fuelRange" type="Boolean" mandatory="false">
        <description>The estimate range in KM the vehicle can travel based on fuel level and consumption</description>
    </param>
</function>
<function name="GetVehicleData" functionID="GetVehicleDataID" messagetype="response">
            :
    <param name="fuelRange" type="FuelRange" minsize="0" maxsize="100" array="true" mandatory="false">
        <description>The estimate range in KM the vehicle can travel based on fuel level and consumption</description>
    </param>
</function>

<function name="OnVehicleData" functionID="OnVehicleDataID" messagetype="notification">
            :
    <param name="fuelRange" type="FuelRange" minsize="0" maxsize="100" array="true" mandatory="false">
        <description>The estimate range in KM the vehicle can travel based on fuel level and consumption</description>
    </param>
</function>
```

### Additions to HMI_API

Changes to enums and functions in the mobile API should also be applied to the HMI API.

### HMI

If the HMI can provide the fuel range it should read the CAN signals related to the fuel range and map it to the `fuelRange` parameter. Otherwise the HMI should reply with `VEHICLE_DATA_NOT_AVAILABLE` if the head unit cannot provide the fuel range.

## Potential downsides

NA

## Impact on existing code

- requires changes on SDL core, both SDKs (Android, iOS) and APIs (mobile, HMI).
- would require a minor version change.

Existing head units of an older version replies with INVALID_DATA as expected if an app tries to subscribe to fuelRange.

## Alternatives considered

NA
