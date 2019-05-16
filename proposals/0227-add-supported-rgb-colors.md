# Add Supported RGB Colors to Light Capabilities

* Proposal: [SDL-0227](0227-add-supported-rgb-colors.md)
* Author: [Zhimin Yang](https://github.com/yang1070)
* Status: **Accepted with Revisions**
* Impacted Platforms: [Core / iOS / Java Suite / RPC]

## Introduction

Currently, RC feature `LIGHT` module type has a parameter called `rgbColorSpaceAvailable` in `LightCapabilities` data structure to indicate whether the specified light with `name` supports changing color or not. However, the capability does not have any information about what RGB colors are supported by the vehicle. Mobile applications must obtain valid RGB colors by a trial and error process or other means. This proposal adds a supported RGB color array to the `LightCapabilities` so that an application can know and/or show supported colors to the user and use a valid RGB color in a `setInteriorVehicleData` request to change the color of a light.

## Motivation

To avoid trial and error and allow mobile apps to know what RGB colors are supported by the vehicle.

## Proposed solution

This proposal adds a new parameter `supportedRGBColorRanges` which is an array of supported `RGBColorRange` to the `LightCapabilities`.

The mobile API needs the following changes.

```xml
<struct name="LightCapabilities" since="5.0">
: 
: 
   <param name="supportedRGBColorRanges" type="RGBColorRange" array="true" minsize="1" maxSize="999999" mandatory="false" since="x.x"/>

</struct>


<struct name="RGBColorRange" since="x.x">
    <description>
        Indicate a color or a color range, include the following cases:
        If only minimums are included for R, G, and B, it is a single color;
        If a max is included on any R, G, B color, it is a range of color;
        If two or more color elements contain both min and max, those two colors can be shaded together within the ranges supplied.
    </description>
    <param name="redMin" type="Integer" minvalue="0" maxvalue="255" mandatory="true" />
    <param name="redMax" type="Integer" minvalue="0" maxvalue="255" mandatory="false" />
    <param name="greenMin" type="Integer" minvalue="0" maxvalue="255" mandatory="true" />
    <param name="greenMax" type="Integer" minvalue="0" maxvalue="255" mandatory="false" />
    <param name="blueMin" type="Integer" minvalue="0" maxvalue="255" mandatory="true" />
    <param name="blueMax" type="Integer" minvalue="0" maxvalue="255" mandatory="false" />
</struct>
```

The changes to the HMI API are similar to those in the mobile API.

## Potential downsides

Only RGB colors will be supported. It does not support color name or color scheme id/label with dynamic change. The list can be big if too many discrete colors are supported.

## Impact on existing code

Add a new parameter to both the mobile and the HMI interface.

Both sdl core and mobile proxies need to support the new parameter.

## Alternatives considered

None.
