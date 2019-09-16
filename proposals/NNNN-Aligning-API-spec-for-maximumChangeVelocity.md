# Aligning API spec for maximumChangeVelocity

* Proposal: [SDL-NNNN](NNNN-Aligning-API-spec-for-maximumChangeVelocity.md)
* Author: [Ankur Tiwari](https://github.com/atiwari9)
* Status: **Awaiting Review**
* Impacted Platforms: [Core][HMI]

## Introduction

This proposal is to align HMI API spec with MOBILE API spec for `maximumChangeVelocity`.

## Motivation
HMI API spec is incorrrect for `maximumChangeVelocity`, this impacts the apps using this RPC. We should correct the HMI API using MOBILE API as reference because MOBILE API is correct.


## Proposed solution

`maximumChangeVelocity` param for `EmergencyEvent` data type is mismatched between HMI and Mobile API. HMI API has data type as VehicleDataEventStatus(**Incorrect**) and Mobile API has data type Integer (**Correct**) as `maximumChangeVelocity` is a number which ranges from 0-255

#### HMI API (**Incorrect**):
```
<param name="maximumChangeVelocity" type="Common.VehicleDataEventStatus" mandatory="true">
    <description>References signal "VedsMaxDeltaV_D_Ltchd". See VehicleDataEventStatus.</description>
</param>
```
Ref: https://github.com/smartdevicelink/sdl_core/blob/master/src/components/interfaces/HMI_API.xml#L3154

#### Mobile API(**Correct**):
```
<param name="maximumChangeVelocity" type="Integer" minvalue="0" maxvalue="255" mandatory="true">
    <description>References signal "VedsMaxDeltaV_D_Ltchd". Change in velocity in KPH.  Additional reserved values:
        0x00 No event
        0xFE Not supported
        0xFF Fault
    </description>
</param>
```
Ref: https://github.com/smartdevicelink/sdl_core/blob/develop/src/components/interfaces/MOBILE_API.xml#L1859

Please refer to [SDL Core bug](https://github.com/smartdevicelink/sdl_core/issues/2735)

## Potential downsides

Theoratically it is a breaking change, but it should not be considered so given that app anyways does not get this data back today due to mismatch in data types between HMI and MOBILE APIs.

## Impact on existing code

* SDL Core would need to update data type checks.
* HMI would need to updates to provide correct values.

## Alternatives considered

None

