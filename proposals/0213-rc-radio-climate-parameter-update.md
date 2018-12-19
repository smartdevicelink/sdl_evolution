# Remote Control - Radio and Climate Parameter Update

* Proposal: [SDL-0213](0213-rc-radio-climate-parameter-update.md)
* Author: [Zhimin Yang](https://github.com/smartdevicelink/yang1070)
* Status: **Accepted with Revisions**
* Impacted Platforms: [Core / iOS / Android / RPC]

## Introduction

Currently, SDL only tells an application the total number of HD channels that are available for a given frequency via parameter `availableHDs` in `RadioControlData`. The application knows the maximum HD channel index is 7. However, it does not know exactly which HD sub-channel index has a valid broadcasting signal. This proposal adds a new read-only parameter `availableHdChannels`, which is a list of HD sub-channel indexes with HD radio broadcasting, to `RadioControlData` data structure. This proposal also adds a new parameter `availableHdChannelsAvailable` to `RadioControlCapabilities` data structure to indicate whether the vehicle supports the new parameter `availableHdChannels`.

This proposal changes the minimum index of HD radio sub-channels from 1 to 0.

In addition, we propose to add a new parameter `climateEnable` to `ClimateControlData` which will allow an application to power climate control on or off.

## Motivation

SDL remote control shall allow a mobile application to know which HD sub-channel index has a signal, so that the app can tune the HD radio to that sub-channel successfully.

SDL remote control shall allow a mobile application to turn the climate control on or off if the vehicle supports it.



## Proposed solution

Add a new parameter `availableHdChannels` to `RadioControlData` to allow an application to know what HD radio channel indexes are available.

Add a new parameter `climateEnable` to `ClimateControlData` to allow an application to power on or off climate control.

In addition, the minimum index of HD radio sub-channels will need to be changed from 1 to 0.

#### Mobile and HMI API

```xml
<struct name="RadioControlData" since="4.5">
...
<!-- new additions or changes -->
-   <param name="availableHDs" type="Integer" minvalue="1 maxvalue="7" mandatory="false" since="5.0">
+   <param name="availableHDs" type="Integer" minvalue="0" maxvalue="7" mandatory="false" since="5.1">
        <description>number of HD sub-channels if available</description>
        <history>
            <param name="availableHDs" type="Integer" minvalue="1" maxvalue="3" mandatory="false" since="4.5" until="5.0"/>
+           <param name="availableHDs" type="Integer" minvalue="1" maxvalue="7" mandatory="false" since="5.0" until="5.1"/>
        </history>
    </param>
	
+   <param name="availableHdChannels" type="Integer" minvalue="0" maxvalue="7" mandatory="false" minsize="1" maxsize="8" array="true" since="5.1">
+       <description>the list of hd sub-channel indexes if available, read-only </description>
+   </param>
	
-    <param name="hdChannel" type="Integer" minvalue="1" maxvalue="7" mandatory="false" since="5.0">
+    <param name="hdChannel" type="Integer" minvalue="0" maxvalue="7" mandatory="false" since="5.1">
        <description>Current HD sub-channel if available</description>
        <history>
            <param name="hdChannel" type="Integer" minvalue="1" maxvalue="3" mandatory="false" since="4.5" until="5.0"/>
+           <param name="hdChannel" type="Integer" minvalue="1" maxvalue="7" mandatory="false" since="5.0" until="5.1"/>
        </history>
    </param>
...
</struct>

<struct name="RadioControlCapabilities" since="4.5">
...
+   <param name="availableHdChannelsAvailable" type="Boolean" mandatory="false" since="5.1">
+       <description>
+           Availability of the list of available HD sub-channel indexes.
+           True: Available, False: Not Available, Not present: Not Available.
+       </description>
+   </param>
...
</struct>



<struct name="ClimateControlCapabilities" since="4.5">
...
+   <param name="climateEnableAvailable" type="Boolean" mandatory="false" since="5.1">
+       <description>
+           Availability of the control of enable/disable climate control.
+           True: Available, False: Not Available, Not present: Not Available.
+       </description>
+   </param>
...
</struct>

<struct name="ClimateControlData" since="4.5">
+    <param name="climateEnable" type="Boolean" mandatory="false" since="5.1">
+     </param>
...
</struct>
```




## Potential downsides

None

## Impacts on existing code

- New parameters will need to be updated within the RPC.
- SDL core and the mobile proxies will need updates to support the new parameters.


## Alternatives considered

None
