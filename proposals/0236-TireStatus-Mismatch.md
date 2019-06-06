# Update mismatch in TireStatus structure

* Proposal: [SDL-0236](0236-TireStatus-Mismatch.md)
* Author: [Robin Kurian](https://github.com/robinmk)
* Status: **In Review**
* Impacted Platforms: [Core / RPC / iOS / Java Suite]

## Introduction

This proposal is about correcting a mismatch between HMI_API and MOBILE_API for the `TireStatus` structure.


## Motivation

In the MOBILE_API, all the parameters of the `TireStatus` structure is marked as `mandatory=true` while in the HMI_API, the same parameters are marked as `mandatory=false`. This mismatch creates confusion to the integrators. The motivation behind this proposal is to provide the necessary clarity by ensuring there is no mismatch between MOBILE_API and HMI_API.


## Proposed solution

Not all vehicles support all the parameters of the `TireStatus` structure. For example, sedans generally have only the left/right rear tires and not the left/right **inner** rear tires. Therefore, it is logical to mark the parameters of the `TireStatus` structure as not being mandatory in MOBILE_API.

### Changes to MOBILE_API



```xml
<struct name="TireStatus" since="2.0">
        <description>The status and pressure of the tires.</description>

        <param name="pressureTelltale" type="WarningLightStatus" mandatory="false" since="6.0">
            <description>Status of the Tire Pressure Telltale. See WarningLightStatus.</description>
            <history>
                <param name="pressureTelltale" type="WarningLightStatus" mandatory="true" since="2.0" until="6.0">
            </history>
        </param>
        <param name="leftFront" type="SingleTireStatus" mandatory="false" since="6.0">
            <description>The status of the left front tire.</description>
            <history>
                <param name="leftFront" type="SingleTireStatus" mandatory="true" since="2.0" until="6.0">
            </history>
        </param>
        <param name="rightFront" type="SingleTireStatus" mandatory="false" since="6.0">
            <description>The status of the right front tire.</description>
            <history>
                <param name="rightFront" type="SingleTireStatus" mandatory="true" since="2.0" until="6.0">
            </history>
        </param>
        <param name="leftRear" type="SingleTireStatus" mandatory="false" since="6.0">
            <description>The status of the left rear tire.</description>
            <history>
                <param name="leftRear" type="SingleTireStatus" mandatory="true" since="2.0" until="6.0">
            </history>
        </param>
        <param name="rightRear" type="SingleTireStatus" mandatory="false" since="6.0">
            <description>The status of the right rear tire.</description>
            <history>
                <param name="rightRear" type="SingleTireStatus" mandatory="true" since="2.0" until="6.0">
            </history>
        </param>
        <param name="innerLeftRear" type="SingleTireStatus" mandatory="false" since="6.0">
            <description>The status of the inner left rear.</description>
            <history>
                <param name="innerLeftRear" type="SingleTireStatus" mandatory="true" since="2.0" until="6.0">
            </history>
        </param>
        <param name="innerRightRear" type="SingleTireStatus" mandatory="false" since="6.0">
            <description>The status of the inner right rear.</description>
            <history>
                <param name="innerRightRear" type="SingleTireStatus" mandatory="true" since="2.0" until="6.0">
            </history>
        </param>
    </struct>
```

## Potential downsides

N/A

## Impact on existing code

* MOBILE_API needs to be updated.
* Since the update is to mark a previously mandatory field as non-mandatory for a structure which is sent from SDL Core to App, the author believes the change to not be a breaking one and therefore not require a major version change.


## Alternatives considered

The desired results of eliminating the mismatch between HMI_API and MOBILE_API could also be achieved by marking the parameters of the `TireStatus` as mandatory in the HMI_API. However, the author believes such an approach would be less than ideal because:
* It becomes a breaking change and integrators would need to ensure that they send values for all these parameters
* For vehicle's which do not support all the parameters, it does not seem appropriate to force the head unit to send a response for the unsupported parameters.

