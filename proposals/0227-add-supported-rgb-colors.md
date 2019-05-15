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

This proposal adds a new parameter `supportedRgbColors` which is an array of supported RGB colors to the `LightCapabilities`.

```xml
<struct name="LightCapabilities" since="5.0">
    <param name="name" type="LightName" mandatory="true" />
    <param name="statusAvailable" type="Boolean" mandatory="false">
      <description>
        Indicates if the status (ON/OFF) can be set remotely. App shall not use read-only values (RAMP_UP/RAMP_DOWN/UNKNOWN/INVALID) in a setInteriorVehicleData request.
      </description>
    </param>
    <param name="densityAvailable" type="Boolean" mandatory="false">
        <description>
            Indicates if the light's density can be set remotely (similar to a dimmer).
        </description>
    </param>
    <param name="rgbColorSpaceAvailable" type="Boolean" mandatory="false">
        <description>
            Indicates if the light's color can be set remotely by using the RGB color space.
        </description>
    </param>
+    <param name="supportedRgbColors" type="RGBColor" array="true" mandatory="false" since="5.x">
+        <description>
+            A list of RGB colors that are supported by the vehicle. Zero length array means support all possible combinations.
+        </description>
+    </param>
</struct>


<struct name="RGBColor" since="5.0">
    <param name="red" type="Integer" minvalue="0" maxvalue="255" mandatory="true" />
    <param name="green" type="Integer" minvalue="0" maxvalue="255" mandatory="true" />
    <param name="blue" type="Integer" minvalue="0" maxvalue="255" mandatory="true" />
</struct>
```

## Potential downsides

Only RGB colors will be supported. It does not support color name or color scheme id/label with dynamic change.

## Impact on existing code

Add a new parameter to both the mobile and the HMI interface.

Both sdl core and mobile proxies need to support the new parameter.

## Alternatives considered

None.
