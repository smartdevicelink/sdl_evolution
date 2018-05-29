# Remote Control - Update OnRCStatus with a new allowed parameter

* Proposal: [SDL-NNNN]( NNNN-onRcStatus-allowed.md)
* Author: [Zhimin Yang](https://github.com/smartdevicelink/yang1070)
* Status: **Awaiting review**
* Impacted Platforms: [Core / iOS / Android / RPC ]

## Introduction

This proposal adds a new parameter `allowed` to mobile RPC `OnRCStatus` to indicate the status of remote control is enabled or disabled by the driver.

## Motivation

HMI allows a driver to change the settings of "Enable Remote Control". When the driver changes this setting on HMI, HMI will send an `OnRemoteControlSettings` notification with parameter `allowed`=`true`/`false` to SDL. However, SDL does not notify the RC apps about this change. RC apps can find out the change via future failed RPC requests, since SDL will reject all remote control related RPC requests (`GetInteriorVehicleData`, `SetInteriorVehicleData` and `ButtonPress`) with result code `USER_DISALLOWED` when RC is disabled. 
It is nice to have if SDL can notify the apps immediately when the change happens. 

## Proposed solution

This proposal adds a new parameter `allowed` to mobile RPC `OnRCStatus`. 

```xml
    <element name="OnRCStatusID" value="32785" hexvalue="8011" />

	....
    <function name="OnRCStatus" functionID="OnRCStatusID" messagetype="notification">
      <description>Issued by SDL to notify the application about remote control status change on SDL</description>
+     <param name="allowed" type="Boolean" mandatory="false" >
+       <description>If "true" - RC is allowed; if "false" - RC is disallowed.</description>
+     </param>
      <param name="allocatedModules" type="ModuleData" minsize="0" maxsize="100" array="true" mandatory="true">
        <description>Contains a list (zero or more) of module types that are allocated to the application.</description>
      </param>
      <param name="freeModules" type="ModuleData" minsize="0" maxsize="100" array="true" mandatory="true">
        <description>Contains a list (zero or more) of module types that are free to access for the application.</description>
      </param>
    </function>
```
	
Because the change originates from HMI, HMI API `OnRCStatus` does not need this parameter.
This is not a breaking change as the new parameter is not mandatory.

When parameter `allowed` is set to `false`, the `allocatedModules` array and the `freeModules` array shall NOT have any module specified (empty array). 

## Potential downsides

None

## Impact on existing code

- Mobile RPC needs to be updated with a new parameter.
- SDL core and mobile proxy lib need updates to support this new parameter.

## Alternatives considered


We may define parameter `allowed` as mandatory, and the other two parameters as not mandatory.
If `allowed` is false, app cannot use the remote control modules anyway, thus no need to include the other two parameters. SDL can include the other two parameters only when `allowed` is true. However, that will be a breaking change.

