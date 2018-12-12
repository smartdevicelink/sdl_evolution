# Static Icon Capability

* Proposal: [SDL-0209](0209-static-icon-capability.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Accepted with Revisions**
* Impacted Platforms: [RPC / HMI]

## Introduction

Add a capability for app developers to know if static icons are available on a connected head unit.

## Motivation

Currently, any app developer building their app with static icons has no way to know if a connected head unit supports those static icons. We should add a capability for the developer to know if static icons exist or not.

## Proposed solution

The proposed solution is to add a new RPC boolean describing whether or not static icons are supported. This capability therefore means to the app developer that they can assume that all static icons are supported.

### Mobile HMI Changes
```xml
<struct name="DisplayCapabilities" since="1.0">
    <!--  -->
    <param name="staticIconsSupported" type="Boolean" mandatory="false" since="X.X">
        <description>Static icons are supported by the head unit HMI.</description>
    </param>
</struct>
```

### HMI API Changes
```xml
<struct name="DisplayCapabilities">
    <!--  -->
    <param name="staticIconsSupported" type="Boolean" mandatory="false">
        <description>Static icons are supported by the head unit HMI.</description>
    </param>
</struct>
```

## Potential downsides

In this proposal there is no room for granular support of some icons but not others. 

If a future set of icons were ever enabled, however, then we could add a new capability, e.g. `staticIconsSetV2Supported`.

## Impact on existing code

This would be a minor version change to all affected platforms.

## Alternatives considered

1. We could change the name of the parameter to `staticIconsSetV1Supported` for additional future-proofing.
