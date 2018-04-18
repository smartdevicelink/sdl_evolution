# Remote Control Radio Parameter Update

* Proposal: [SDL-NNNN](NNNN-rc-radio-parameter-update.md)
* Author: [Zhimin Yang](https://github.com/smartdevicelink/yang1070)
* Status: **Awaiting review**
* Impacted Platforms: [Core / iOS / Android / RPC]

## Introduction

This proposal adds a new parameter `hdRadioEnable` to `RadioControlData` data structure, adds new parameters `hdRadioEnableAvailable` and `siriusxmRadioAvailable` to `RadioControlCapabilities` data structure, and changes the maximum number of HD radio sub-channels from 3 to 7.


## Motivation

SDL remote control shall allow the mobile application to turn on/off the HD radio if the tuner supports it.
Some HD radio receivers support up to 7 multicast channels on a given station. The available number depends on how many multicast channels a radio broadcaster wants to broadcast.


## Proposed solution

We propose to add a new parameter `hdRadioEnable` to `RadioControlData` to allow an application to query or control the HD radio state.
We add a new parameter `siriusxmRadioAvailable` to `RadioControlCapabilities` to allow an application to know whether the HU supports sirius XM Radio.
We also change the maximum number of HD radio sub-channels from 3 to 7.

#### Mobile API
```xml
<struct name="RadioControlData">
    ...
    <!-- new additions or changes -->
+   <param name="hdRadioEnable" type="Boolean" mandatory="false">
+       <description> True if the hd radio is on, false is the radio is off</description>
+   </param>
-   <param name="availableHDs" type="Integer" minvalue="1" maxvalue="3" mandatory="false">
+   <param name="availableHDs" type="Integer" minvalue="1" maxvalue="7" mandatory="false">
        <description>number of HD sub-channels if available</description>
    </param>
-   <param name="hdChannel" type="Integer" minvalue="1" maxvalue="7" mandatory="false">
+   <param name="hdChannel" type="Integer" minvalue="1" maxvalue="7" mandatory="false">
        <description>Current HD sub-channel if available</description>
    </param>
</struct>

<struct name="RadioControlCapabilities">
    ...
    <!-- new additions -->
    <param name="hdRadioEnableAvailable" type="Boolean" mandatory="false">
        <description>
            Availability of the control of enable/disable HD radio.
            True: Available, False: Not Available, Not present: Not Available.
        </description>
    </param>
    <param name="siriusxmRadioAvailable" type="Boolean" mandatory="false">
        <description>
            Availability of sirius XM radio.
            True: Available, False: Not Available, Not present: Not Available.
        </description>
    </param>
</struct>
```

#### HMI API
The changes are similar to that of the mobile API.

```xml
<struct name="RadioControlData">
    ...
    <!-- new addition or changes -->
+   <param name="hdRadioEnable" type="Boolean" mandatory="false">
+       <description> True if the hd radio is on, false is the radio is off</description>
+   </param>
-   <param name="availableHDs" type="Integer" minvalue="1" maxvalue="3" mandatory="false">
+   <param name="availableHDs" type="Integer" minvalue="1" maxvalue="7" mandatory="false">
        <description>number of HD sub-channels if available</description>
    </param>
-   <param name="hdChannel" type="Integer" minvalue="1" maxvalue="3" mandatory="false">
+   <param name="hdChannel" type="Integer" minvalue="1" maxvalue="7" mandatory="false">
        <description>Current HD sub-channel if available</description>
    </param>
</struct>

<struct name="RadioControlCapabilities">
    ...
    <!-- new additions -->
    <param name="hdRadioEnableAvailable" type="Boolean" mandatory="false">
        <description>
            Availability of the control of enable/disable HD radio.
            True: Available, False: Not Available, Not present: Not Available.
        </description>
    </param>
    <param name="siriusxmRadioAvailable" type="Boolean" mandatory="false">
        <description>
            Availability of sirius XM radio.
            True: Available, False: Not Available, Not present: Not Available.
        </description>
    </param>
</struct>
```


## Potential downsides

None

## Impacts on existing code

- New parameters and the range of two old parameters need to be updated within the RPC.
- SDL core and mobile proxy lib need updates to support this new parameter.


## Alternatives considered

None
