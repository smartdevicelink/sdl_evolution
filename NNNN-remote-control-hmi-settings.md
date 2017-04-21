# Remote Control HMI Settings

* Proposal: [SDL-NNNN](NNNN-remote-control-hmi-settings.md)
* Author: [Zhimin Yang](https://github.com/zyang46)
* Status: **Awaiting review**
* Impacted Platforms: [Core / iOS / Android / RPC]

## Introduction

SDL remote control provides the ability for mobile applications to control certain components of the vehicle, such as, tune the radio, set the desired temperature or change the fan speed.

## Motivation

A mobile navigation application would like to use the same units as the infotainment system in vehicle does. Additionally, navigation applications would like to use the same day/night display mode as the infotainment system. SDL remote control makes it possible.

## Proposed solution

Add a new module type to the existing module list.

- RC applications can get the current HMI settings regarding temperature unit, distance unit and display mode.
- RC applications can set the current HMI settings regarding temperature unit, distance unit and display mode.
- If the driver or other applications change the temperature unit in the HMI settings, the system shall send notifications with the current temperature unit to all mobile RC applications that are subscribed to the HMI settings.
- If the driver or other applications change the distance unit in the HMI settings, the system shall send notifications with the current distance unit to all mobile RC applications that are subscribed to the HMI settings.
- If the driver or other applications change the display mode in the HMI settings, the system shall send notifications with the current display mode to all mobile RC applications that are subscribed to the HMI settings. Note: the driver can set the display mode as DAY, NIGHT or AUTO. However, the current mode used by the HMI is either DAY or NIGHT.
- If the HMI changes the display mode (due to time, ambient light or any reasons), the system shall send notifications with the current display mode to all mobile RC applications that are subscribed to the HMI settings.


### Additions/Changes to Mobile_API

No new APIs added. Just new module types and new enums.

```xml
  <enum name="ModuleType">
    <element name="CLIMATE"/>
    <element name="RADIO"/>
    <element name="HMI_SETTING">
  </enum>

  <enum name="DisplayMode">
    <description>Reflects the current status of  HMI display mode.</description>
    <element name="DAY" />
    <element name="NIGHT" />
    <element name="AUTO">
      <description>Auto is only for setter, not for getter. When the system receives a valid RPC request for display mode, the system shall return a response with the current value of display mode used in the HMI. Even the display mode can be set as AUTO by user via the HMI, the system shall not response mode as AUTO. The system shall give the current value used by HMI, either DAY or NIGHT.</description>
  </enum>

  <enum name="DistanceUnit">
    <description>Reflects the current HMI setting for distance unit.</description>
    <element name="KILOMETERS" />
    <element name="MILES" />
  </enum>

  <enum name="TemperatureUnit">
    <element name="FAHRENHEIT"/>
    <element name="CELSIUS"/>
    <!-- removed element KELVIN -->
  </enum>

  <struct name="SettingsData">
    <param name="displayMode" type="DisplayMode" mandatory="false">
      <description>Reflects the current status of  HMI display mode.</description>
    </param>
    <param name="distanceUnit" type="DistanceUnit" mandatory="false">
      <description>Reflects the current HMI setting for distance unit.</description>
    </param>
    <param name="temperatureUnit" type="TemperatureUnit" mandatory="false">
      <description>Reflects the current HMI setting for temperature unit.</description>
  </struct>

    <struct name="ModuleData">
      <description>The moduleType indicates which type of data should be changed and identifies which data object exists in this struct. For example, if the moduleType is CLIMATE then a "climateControlData" should exist</description>
    <param name="moduleType" type="ModuleType">
    </param>
    <param name="moduleZone" type="InteriorZone">
    </param>
    <param name="radioControlData" type="RadioControlData" mandatory="false">
    </param>
    <param name="climateControlData" type="ClimateControlData" mandatory="false">
    </param>
    <!--new additions--->
    <param name="hmiSettingsData" type="SettingsData" mandatory="false">
    </param>
  </struct>  
```

### Additions/Changes to HMI_API

No new APIs added. Just new module types and new enums.

```xml
  <enum name="ModuleType">
    <element name="CLIMATE"/>
    <element name="RADIO"/>
    <element name="HMI_SETTING">
  </enum>

  <enum name="DisplayMode">
    <description>Reflects the current status of  HMI display mode.</description>
    <element name="DAY" />
    <element name="NIGHT" />
    <element name="AUTO">
      <description>Auto is only for setter, not for getter. When the system receives a valid RPC request for display mode, the system shall return a response with the current value of display mode used in the HMI. Even the display mode can be set as AUTO by user via the HMI, the system shall not response mode as AUTO. The system shall give the current value used by HMI, either DAY or NIGHT.</description>
    </element>
  </enum>

  <enum name="DistanceUnit">
    <description>Reflects the current HMI setting for distance unit.</description>
    <element name="KILOMETERS" />
    <element name="MILES" />
  </enum>

  <enum name="TemperatureUnit">
    <element name="FAHRENHEIT"/>
    <element name="CELSIUS"/>
    <!-- removed element KELVIN -->
  </enum>

  <struct name="SettingsData">
    <param name="displayMode" type="DisplayMode" mandatory="false">
      <description>Reflects the current status of  HMI display mode.</description>
    </param>
    <param name="distanceUnit" type="DistanceUnit" mandatory="false">
      <description>Reflects the current HMI setting for distance unit.</description>
    </param>
    <param name="temperatureUnit" type="TemperatureUnit" mandatory="false">
      <description>Reflects the current HMI setting for temperature unit.</description>
  </struct>

    <struct name="ModuleData">
      <description>The moduleType indicates which type of data should be changed and identifies which data object exists in this struct. For example, if the moduleType is CLIMATE then a "climateControlData" should exist</description>
    <param name="moduleType" type="ModuleType">
    </param>
    <param name="moduleZone" type="InteriorZone">
    </param>
    <param name="radioControlData" type="RadioControlData" mandatory="false">
    </param>
    <param name="climateControlData" type="ClimateControlData" mandatory="false">
    </param>
    <!--new additions--->
    <param name="hmiSettingsData" type="SettingsData" mandatory="false">
    </param>
  </struct>  
```

## Impact on existing code

RPC changes:
- add enums and a module type.

HMI changes:
- New HMI APIs support

Mobile iOS/Android SDK changes:
- New Mobile APIs support
