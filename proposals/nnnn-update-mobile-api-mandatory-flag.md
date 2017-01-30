# Update Mobile API to Include Mandatory Flag on Parameters

* Proposal: [SDL-NNNN](NNNN-filename.md)
* Author: [Alex Muller](https://github.com/asm09fsu)
* Status: **Awaiting review**
* Impacted Platforms: Core

## Introduction
Currently within the spec that is used by core ([MOBILE_API.xml](https://github.com/smartdevicelink/sdl_core/blob/master/src/components/interfaces/MOBILE_API.xml) ), there is a lack of consistency among structs and functions relating to their parameters not stating whether they are all mandatory or not.

## Motivation

This proposal seeks to address the issues relating to readability and understand of the spec in its current state relating to whether or not a parameter of a request, response, or struct is mandatory.

## Proposed solution

Solution is to update the mobile_api.xml to include mandatory flags for all struct & function objects.

## Detailed design

Example is for SoftButton (with descriptions stripped):
```xml
<struct name="SoftButton">
    <param name="type" type="SoftButtonType">
    </param>
    <param name="text" minlength="0" maxlength="500" type="String" mandatory="false">
    </param>
    <param name="image" type="Image" mandatory="false">
    </param>
    <param name="isHighlighted" type="Boolean" defvalue="false" mandatory="false">
    </param>
    <param name="softButtonID" type="Integer" minvalue="0" maxvalue="65535">
    </param>
    <param name="systemAction" type="SystemAction" defvalue="DEFAULT_ACTION" mandatory="false">
    </param>
  </struct>
```
to 
```xml
<struct name="SoftButton">
    <param name="type" type="SoftButtonType" mandatory="true">
    </param>
    <param name="text" minlength="0" maxlength="500" type="String" mandatory="false">
    </param>
    <param name="image" type="Image" mandatory="false">
    </param>
    <param name="isHighlighted" type="Boolean" defvalue="false" mandatory="false">
    </param>
    <param name="softButtonID" type="Integer" minvalue="0" maxvalue="65535" mandatory="true">
    </param>
    <param name="systemAction" type="SystemAction" defvalue="DEFAULT_ACTION" mandatory="false">
    </param>
  </struct>
```

## Impact on existing code

This will not change any code, only add clarity to the spec for potential new partners.

## Alternatives considered

No alternatives considered.
