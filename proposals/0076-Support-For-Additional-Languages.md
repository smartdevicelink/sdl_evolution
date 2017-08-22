# Support for Additional Languages

* Proposal: [SDL-0076](0076-Support-For-Additional-Languages.md)
* Author: [Scott Betts](https://github.com/Toyota-Sbetts)
* Status: **Accepted**
* Impacted Platforms: [Core / iOS / Android / RPC]

## Introduction

This proposal introduces additional languages for support by SDL.

## Motivation

To support Toyota's global roll out plan for SDL, additional languages need to be added to the list of supported languages.

## Proposed Solution

We should add the following to both the HMI and Mobile API.

```xml
<element name="EN-SA" internal_name="EN_SA">
  <description>English - Middle East</description>
</element>
<element name="HE-IL" internal_name="HE_IL">
  <description>Hebrew - Israel</description>
</element>
<element name="RO-RO" internal_name="RO_RO">
  <description>Romanian - Romania</description>
</element>
<element name="UK-UA" internal_name="UK_UA">
  <description>Ukrainian - Ukraine</description>
</element>
<element name="ID-ID" internal_name="ID_ID">
  <description>Indonesian - Indonesia</description>
</element>
<element name="VI-VN" internal_name="VI_VN">
  <description>Vietnamese - Vietnam</description>
</element>
<element name="MS-MY" internal_name="MS_MY">
  <description>Malay - Malaysia</description>
</element>
<element name="HI-IN" internal_name="HI_IN">
  <description>Hindi - India</description>
</element>
```

## Potential downsides

This further expands the already large enumeration of language support.  As additional language support is necessary this list will continue to grow.

## Impacts on existing code

This proposal will require changes to SDL Core, both SDKs and the Mobile and HMI APIs.

## Alternatives considered

If the current proposal for locale support [#179](https://github.com/smartdevicelink/sdl_evolution/issues/179) is passed, this proposal is unnecessary. 
