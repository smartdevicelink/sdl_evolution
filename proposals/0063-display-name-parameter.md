# Display name parameter

* Proposal: [SDL-0063](0063-display-name-parameter.md)
* Author: [Kujtim Shala](https://github.com/kshala-ford)
* Status: **In Review**
* Impacted Platforms: [Core / iOS / Android / RPC]

## Introduction

This proposal is about deprecating the parameter `displayType` and replace it with `displayName`.

## Motivation

The parameter `displayType` is of type `DisplayType` which is an enum of many old/legacy displays. The enum would need to be changed for every new head unit with a new display. The enum should be deprecated.

## Proposed solution

The proposed solution is to deprecate the `DisplayType` enum and the `DisplayCapabilities.displayType` parameter in the APIs and SDKs. As a replacement a new (optional) string parameter called `displayName` should be added to the `DisplayCapabilities` struct.

### API (mobile and HMI)

```xml
<struct name="DisplayCapabilities">
    <element name="displayName" type="String" mandatory="false">
        <description>The name of the display the app is connected to.</description>
    </element>
</struct>
```

### SDK

Depending on the JSON data the SDK should use the `displayName` parameter for the corresponding property by default. If the JSON data does not contain a `displayName` parameter the SDK should use the `displayType` parameter as string for backwards compatibility.

## Potential downsides

The downside is that displays are not known anymore. Any string can be provided by the head unit. Depending on the importance a list of displays can be provided through the website's documentation.

## Impact on existing code

All areas would need to be addressed (HMI, core, RPC and SDKs). Fortunately the existing code is basically just forwarding a string that comes from the HMI. Therefore the impact is expected to be small.

## Alternatives considered

This proposal is quite careful to not remove but replace a feature. As an alternative the display type can be deprecated without a replacement if knowing the display is not important.
