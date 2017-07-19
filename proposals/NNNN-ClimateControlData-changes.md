# "ClimateControlData" structure changes in Mobile and HMI APIs

* Proposal: [SDL-NNNN](NNNN-filename.md)
* Author: [Olesia Vasylieva](https://github.com/smartdevicelink)
* Status: **Awaiting review**
* Impacted Platforms: [Core / iOS / Android / RPC]

## Introduction

"ClimateControlData" structure defines the available remote-control options of the "CLIMATE" vehicle module for remote-control mobile application.

## Motivation

Proposed to optimize temperature settings in Climate Control with defined minimum and maximum temperature settings for different temperature units (Celsius or Farenheit).
New parameters will also allow user to set ventialtion mode of the vehicle and receive information if the AC is on the maximum level.


## Proposed solution

Proposed to modify the existing parameters of  the "ClimateControlData" structure:

1. Move "TemperatureUnit" from "ClimateControlData" structure to "Temperature" structure and define minimum and maximum values for TemperatureUnit
"currentTemp" and "desiredTemp" in "ClimateControlData" structure must be specified by "Temperature" structure.

| TemperatureUnit | MinimumValue | MaximumValue |
| ------------ | ------------ |------------ |
| CELSIUS | 14 | 30 |
| FAHRENHEIT | 60 | 90 |

Note: Conversion of "desiredTemp" value to the appropriate temperature unit is performed on HMI side

2. Add new parameters "acMaxEnable" and "ventilationMode" to "ClimateControlData" structure

 | Parameter name |Value | Description |
 | ------------ | ------------ |------------ |
 | acMaxEnable | Boolean | If "true" - air conditioning is ON on the max level |
 | VentilationMode | UPPER, LOWER, BOTH | Defines the mode for air ventialtion |


##### Detailed design

HMI and Mobile APIs changes:

```xml
<struct name="ClimateControlData">
    <param name="fanSpeed" type="Integer" minvalue="0" maxvalue="100" mandatory="false">
    </param>
  <param name="currentTemp" type="Temperature" mandatory="false">
    </param>
    <param name="desiredTemp" type="Temperature" mandatory="false">
    </param>
    <param name="acEnable" type="Boolean" mandatory="false">
    </param>
    <param name="acMaxEnable" type="Boolean" mandatory="false">
    </param>
    <param name="circulateAirEnable" type="Boolean" mandatory="false">
    </param>
    <param name="autoModeEnable" type="Boolean" mandatory="false">
    </param>
    <param name="defrostZone" type="DefrostZone" mandatory="false">
    </param>
    <param name="dualModeEnable" type="Boolean" mandatory="false">
    </param>
     <param name="ventilationMode" type="VentilationMode" mandatory="false">
    </param>
  </struct>
   <enum name="VentilationMode">
    <element name="UPPER"/>
    <element name="LOWER"/>
    <element name="BOTH"/>
  </enum>
  <struct name="Temperature">
      <param name="unit" type="TemperatureUnit">
         <description>Temperature Unit</description>
      </param>
      <param name="valueC" type="Float" minvalue="14.0" maxvalue="30" mandatory=”false”>
         <description>Temperature Value in Celsius</description>
      </param>
      <param name="valueF" type="Float" minvalue="60" maxvalue="90" mandatory=”false”>
         <description>Temperature Value in Farenheit</description>
      </param>
   </struct>
   <enum name="TemperatureUnit">
      <element name="FAHRENHEIT" />
      <element name="CELSIUS" />
   </enum>
```

## Potential downsides

N/A

## Impact on existing code

- Impacted RPCs: ButtonPress, GetInteriorVehicleData, GetInteriorVehicleDataCapabilities, OnInteriorVehicleData, SetInteriorVehicleData
- Mobile remote-control applications need to support new parameters 
- RSDL need to support the updated "ClimateControlData" structure with new parameters and new "Temperature" structure

## Alternatives considered

N/A
