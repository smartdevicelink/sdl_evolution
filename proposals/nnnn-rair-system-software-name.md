# Add System Software Name parameter to Register App Interface Response

* Proposal: [SDL-NNNN](NNNN-rair-system-software-name.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Awaiting review**
* Impacted Platforms: [Core / iOS / Android / RPC]

## Introduction

This proposal adds a new Register App Interface Response parameter called `systemSoftwareName` that pairs with the existing `systemSoftwareVersion` and `sdlVersion`.

## Motivation

Currently, information about the connected head unit is limited to the `vehicleType` (i.e. make / model / modelYear), the version of the system running, and the version of SDL that the system is running. This provides everything necessary for analytics and identifying a particular head unit. However, it's not as easy or as good as it could be. If an OEM has multiple head unit types, then the app developer would need to differentiate those based on a table of available Makes, Models, and Trims. This could be made easier by simply identifying the name of the system.

## Proposed solution

Add a new parameter to the `RegisterAppInterfaceResponse` called `systemSoftwareName` like so:

```xml
<function name="RegisterAppInterface" functionID="RegisterAppInterfaceID" messagetype="response" since="1.0">
    <!-- Everything already there -->
    <parameter name="systemSoftwareVersion" type="String" maxlength="100" mandatory="false" since="X.X">
        <description>The name of the head unit software, to be paired with the version in `systemSoftwareVersion`.</description>
    </parameter>
</function>
```

## Potential downsides

No downsides have been identified.

## Impact on existing code

This is a minor version change for all affected platforms.

## Alternatives considered

1. We can continue with the current system, but the ability for app developers to identify which head units are connected is hampered by the need to match Make / Model / Trim to head unit types.
