# Aligning HMI and MOBILE API for pcmStreamCapabilities

* Proposal: [SDL-0252](0252-Aligning-HMI-and-MOBILE-API-for-pcmStreamCapabilities.md)
* Author: [Heather Williams](https://github.com/hwilli88/), [Ankur Tiwari](https://github.com/atiwari9/)
* Status: **In Review**
* Impacted Platforms: [Core / HMI]

## Introduction

This proposal is to add param `pcmStreamCapabilities` in `UI.GetCapabilities` response in HMI API.

## Motivation

`pcmStreamCapabilities` was introduced by PR: https://github.com/smartdevicelink/sdl_core/pull/472 , but this PR missed adding implementation for HMI API. `pcmStreamCapabilities` is present in MOBILE API, but HMI has no way to provide this information to SDL Core. As a result, SDL Core always uses default `hmi_capabilities.json` for `pcmStreamCapabilities` in `RAI` response to MOBILE.

## Proposed Solution 

Align HMI API with MOBILE API for `pcmStreamCapabilities` by adding this param to HMI API in `UI.GetCapabilities` response.

```xml
<function name="GetCapabilities" messagetype="response">
	<param name="displayCapabilities" type="Common.DisplayCapabilities" mandatory="true">
		<description>Information about the capabilities of the display: its type, text field supported, etc. See DisplayCapabilities. </description>
	</param>
	<param name="audioPassThruCapabilities" type="Common.AudioPassThruCapabilities" mandatory="true"/>
	<param name="hmiZoneCapabilities" type="Common.HmiZoneCapabilities" mandatory="true"/>
	<param name="softButtonCapabilities" type="Common.SoftButtonCapabilities" minsize="1" maxsize="100" array="true" mandatory="false">
		<description>Must be returned if the platform supports on-screen SoftButtons.</description>
	</param>
	<param name="hmiCapabilities" type="Common.HMICapabilities" mandatory="false">
		<description>Specifies the HMI’s capabilities. See HMICapabilities.</description>
	</param>
	<param name="systemCapabilities" type="Common.SystemCapabilities" mandatory="false">
		<description>Specifies system capabilities. See SystemCapabilities</description>
	</param>
+	<param name="pcmStreamCapabilities" type="Common.AudioPassThruCapabilities" mandatory="true"/>
</function>
```

## Potential downsides

Author is not aware of any downsides to proposed solution.

## Impact on existing code

* HMI needs to be updated to provide `pcmStreamCapabilities`.
* SDL Core needs to be updated to read `pcmStreamCapabilities` from HMI in `UI.GetCapabilities` response.

## Alternatives considered

* None
