# SDL Remote Control

* Proposal: [SDL-0065](0065-remote-control.md)
* Author: [Zhimin Yang](https://github.com/yang1070)
* Status: **Deferred**
* Impacted Platforms: [Core / iOS / Android / RPC ]

## Introduction

SmartDeviceLink provides a framework that connects in-vehicle infotainment system to mobile phone applications. SDL  enables a driver to interact with their mobile phone applications using common in-vehicle interfaces such as a touch screen display, embedded voice recognition, steering wheel controls and various vehicle knobs and buttons. Although SDL provides some RPCs to allow mobile applications to obtain some vehicle status information, it does not allow a mobile application to change the vehicle settings, i.e. to control the vehicle. SDL remote control (or previously known as reverse SDL) provides the ability for mobile applications to control certain settings of the vehicle, such as, radio and climate.

## Motivation

There are many cases that mobile application developers ask for new functions of SDL. For example,

- A radio application wants to use the in-vehicle radio. It needs the RPC function to select the radio band (AM/FM/XM/HD/DAB), tune the radio frequency or change the radio station, as well as obtain general radio information for decision making.

- A climate control application needs to turn on the AC, control the air circulation mode, change the fan speed and set the desired cabin temperature.

- A user profile application wants to remember user's favorite settings and apply it later automatically when the users get into the same/another vehicle.

- A navigation application wants to set the application's display mode same as the vehicle's display mode and vice versa.

The common problem is that a mobile application needs the ability to control certain settings of the vehicle. This proposal (SDL remote control or SDL-RC) tries to address this problem. This proposal describes the design of current implementation of SDL-RC feature branch.

## Proposed solution

### Current solution in RC branch


SDL-RC provides common RPC messages and functions to allow a mobile application to (1) read current vehicle RC data/settings, (2) subscribe and un-subscribe certain or all vehicle RC data/setting change notifications, (3) send notifications to subscribed applications when the monitored RC data/settings changes, (4) change vehicle RC settings, and (5) get vehicle RC capability, i.e. what are available for remote control in the vehicle. The following table lists what control module and what control items are considered in the current implementation.


| RC Module | Control Item | Value Range |Type | Comments |
| ------------ | ------------ |------------ | ------------ | ------------ |
| Radio | Radio Enabled | true,false  | Get/Notification| read only, all other radio control items need radio enabled to work|
| Radio | Radio Band | AM,FM,XM  | Get/Set/Notification| |
| Radio | Radio Frequency | | Get/Set/Notification | value range depends on band |
| Radio | Radio RDS Data | | Get/Notification | read only |
| Radio | Available HD Channel | 1-3 | Get/Notification | read only |
| Radio | Current HD Channel | 1-3 | Get/Set/Notification |
| Radio | Radio Signal Strength |  | Get/Notification | read only |
| Radio | Signal Change Threshold |  | Get/Notification | read only |
| Radio | Radio State | Acquiring, acquired, multicast, not_found | Get/Notification | read only |
| Climate | Current Cabin Temperature |  | Get/Notification | read only |
| Climate | Desired Cabin Temperature |  | Get/Set/Notification |  |
| Climate | AC Setting | on,off | Get/Set/Notification |  |
| Climate | AC MAX Setting | on,off  | Get/Set/Notification |  |
| Climate | Air Recirculation Setting | on,off  | Get/Set/Notification |  |
| Climate | Auto AC Mode Setting | on,off  | Get/Set/Notification |  |
| Climate | Defrost Zone Setting | front,rear,all  | Get/Set/Notification |  |
| Climate | Dual Mode Setting | on,off  | Get/Set/Notification |  |
| Climate | Fan Speed Setting | 0%-100% | Get/Set/Notification |  |

In addition to the above RC data/settings, the SDL-RC can also allow mobile application to send button press event or long press event for the follow common climate control buttons in vehicle.


| RC Module | Control Button |
| ------------ | ------------ |
| Climate | AC Button |
| Climate | AC MAX Button |
| Climate | RECIRCULATE Button |
| Climate | FAN UP Button |
| Climate | FAN DOWN Button |
| Climate | TEMPERATURE UP Button |
| Climate | TEMPERATURE DOWN Button |
| Climate | DEFROST Button |
| Climate | DEFROST REAR Button |
| Climate | DEFROST MAX Button |
| Climate | UPPER VENT Button |
| Climate | LOWER WENT Button |
| Radio   | VOLUME UP Button |
| Radio   | VOLUME DOWN Button |
| Radio   | EJECT Button |
| Radio   | SOURCE Button |
| Radio   | SHUFFLE Button |
| Radio   | REPEAT Button |

The interior of a vehicle is divided into zones or locations, for example, driver zone, front passenger zone, rear right/left/all passenger zone, etc. Zones are defined by three coordinates: row, column, level and their spans. A RC module is associated with a zone. For example, a seat control module can be driver's seat or front passenger's seat. Dual climate control can control driver side or passenger side. RC capability response message tells the mobile application what RC modules are located in which zone.


A new appHMIType: REMOTE_CONTROL is added: all and any remote-control applications must register with this type. The work flow of a remote control application on driver's device is simple. Like the existing applications, a RC application need to register with the system, be launched by driver via HMI or voice control. Usually it shall send a request for vehicle's RC capabilities to get a list of controllable RC modules available. Then it can start to read or change RC module settings. The first control message (setter request) with a specific RC module will trigger SDL to perform RC resource allocation process, which in general says at any time a RC module can be controlled by one and only one application. For example, if a climate control module is allocated to application ONE, any other applications will get rejected if they try to change the climate control settings. The climate control resource is freed when application ONE exits or disconnects. Until climate control resource gets free, no other application can perform climate control actions. RC resource allocation is first come, first serve.


Things get complicated when passengers are allowed to control. The current implementation allows multiple (two to be exact) devices get connected at the same time. By default when a device connects to the system, it is treated as a passenger's device. The driver can change the rank of a device from PASSENGER to DRIVER or vice versa via HMI. SDL-RC allows only one device to be "DRIVER's" at a time. In this document, we refer an application running on a device marked as DRIVER as a driver's application, an application running on a device not marked as DRIVER as a passenger's application.


Driver's applications can access/control all available RC modules no matter where the RC module is. Policy rules control what RC modules and how a RC module can be accessed by a passenger's application. Depending on policy configuration, the system can automatically allow, deny or ask driver's permission to grant the access of a passenger's application.

Unlike a driver's application, which must be launched by the driver on mobile phone and activated on vehicle HMI (HMI level from NONE to FULL), a passenger's application can be launched from a connected phone and automatically activated to HMI level BACKGROUND/LIMITED without HMI touch or voice command after GetIneriorVehicleDataConsent get a successful allowed response (may need driver's permission if configured so).

By default SDL-RC allows passenger's application to use remote control feature. However, the driver can disable the feature via HMI by sending OnReverseAppsAllowing(false) message to SDL.

Please see attached documents for detailed design. [HMI Guideline](../assets/proposals/0065-remote-control/0065_SDLRC_HMI_Guidelines_v1.1.pdf) and [Mobile API Guideline](../assets/proposals/0065-remote-control/0065_SDLRC_Mobile_API_Guidelines_v1.0.pdf)

### Mobile API changes
Full Mobile API can be found here:
https://github.com/smartdevicelink/sdl_core/blob/feature/sdl_rc_functionality/src/components/interfaces/MOBILE_API.xml

The changes are listed below.
```xml
  <enum name="ButtonName">
      <description>Defines the hard (physical) and soft (touchscreen) buttons available from SYNC</description>
        <!-- Existing Buttons not listed here -->
        <!-- Climate Buttons -->
      <element name="AC_MAX" />
      <element name="AC" />
      <element name="RECIRCULATE" />
      <element name="FAN_UP" />
      <element name="FAN_DOWN" />
      <element name="TEMP_UP" />
      <element name="TEMP_DOWN" />
      <element name="DEFROST_MAX" />
      <element name="DEFROST" />
      <element name="DEFROST_REAR" />
      <element name="UPPER_VENT" />
      <element name="LOWER_VENT" />

      <!-- Radio Buttons -->
      <element name="VOLUME_UP" />
      <element name="VOLUME_DOWN" />
      <element name="EJECT" />
      <element name="SOURCE" />
      <element name="SHUFFLE" />
      <element name="REPEAT" />
  </enum>

  <!-- new additions -->
  <struct name="InteriorZone">
    <description>Describes the origin and span of a zone in the vehicle. Vehicle zones can be overlapping</description>
    <param name="col" type="Integer" minvalue="0" maxvalue="100">
    </param>
    <param name="row" type="Integer" minvalue="0" maxvalue="100">
    </param>
    <param name="level" type="Integer" minvalue="0" maxvalue="100">
    </param>
    <param name="colspan" type="Integer" minvalue="0" maxvalue="100">
    </param>
    <param name="rowspan" type="Integer" minvalue="0" maxvalue="100">
    </param>
    <param name="levelspan" type="Integer" minvalue="0" maxvalue="100">
    </param>
  </struct>

  <enum name="ModuleType">
    <element name="CLIMATE"/>
    <element name="RADIO"/>
  </enum>

  <struct name="ModuleDescription">
    <param name="moduleZone" type="InteriorZone">
    </param>
    <param name="moduleType" type="ModuleType">
    </param>
  </struct>

  <enum name="RadioBand">
    <element name="AM"/>
    <element name="FM"/>
    <element name="XM"/>
  </enum>

<struct name="RdsData">
    <param name="PS" type="String" minlength="0" maxlength="8" mandatory="false">
      <description>Program Service Name</description>
    </param>
    <param name="RT" type="String" minlength="0" maxlength="64" mandatory="false">
      <description>Radio Text</description>
    </param>
    <param name="CT" type="String" minlength="24" maxlength="24" mandatory="false">
      <description>The clock text in UTC format as YYYY-MM-DDThh:mm:ss.sTZD</description>
    </param>
    <param name="PI" type="String" minlength="0" maxlength="6" mandatory="false">
      <description>Program Identification - the call sign for the radio station</description>
    </param>
    <param name="PTY" type="Integer" minvalue="0" maxvalue="31" mandatory="false">
      <description>The program type - The region should be used to differentiate between EU and North America program types</description>
    </param>
    <param name="TP" type="Boolean" mandatory="false">
      <description>Traffic Program Identification - Identifies a station that offers traffic</description>
    </param>
    <param name="TA" type="Boolean" mandatory="false">
      <description>Traffic Announcement Identification - Indicates an ongoing traffic announcement</description>
    </param>
    <param name="REG" type="String" mandatory="false">
      <description>Region</description>
    </param>
  </struct>

  <enum name="RadioState">
    <element name="ACQUIRING"/>
    <element name="ACQUIRED"/>
    <element name="MULTICAST"/>
    <element name="NOT_FOUND"/>
  </enum>

  <struct name="RadioControlData">
    <param name="frequencyInteger" type="Integer" minvalue="0" maxvalue="1710" mandatory="false">
      <description>The integer part of the frequency ie for 101.7 this value should be 101</description>
    </param>
    <param name="frequencyFraction" type="Integer" minvalue="0" maxvalue="9" mandatory="false">
      <description>The fractional part of the frequency for 101.7 is 7</description>
    </param>
    <param name="band" type="RadioBand" mandatory="false">
    </param>
    <param name="rdsData" type="RdsData" mandatory="false">
    </param>
    <param name="availableHDs" type="Integer" minvalue="1" maxvalue="3" mandatory="false">
      <description>number of HD sub-channels if available</description>
    </param>
    <param name="hdChannel" type="Integer" minvalue="1" maxvalue="3" mandatory="false">
      <description>Current HD sub-channel if available</description>
    </param>
    <param name="signalStrength" type="Integer" minvalue="0" maxvalue="100" mandatory="false">
    </param>
    <param name="signalChangeThreshold" type="Integer" minvalue="0" maxvalue="100" mandatory="false">
      <description>If the signal strength falls below the set value for this parameter, the radio will tune to an alternative frequency</description>
    </param>
    <param name="radioEnable" type="Boolean" mandatory="false">
      <description> True if the radio is on, false is the radio is off</description>
    </param>
    <param name="state" type="RadioState" mandatory="false">
    </param>
  </struct>

  <enum name="DefrostZone">
    <element name="FRONT"/>
    <element name="REAR"/>
    <element name="ALL"/>
  </enum>

  <enum name="TemperatureUnit">
    <element name="KELVIN"/>
    <element name="FAHRENHEIT"/>
    <element name="CELSIUS"/>
  </enum>

  <struct name="ClimateControlData">
    <param name="fanSpeed" type="Integer" minvalue="0" maxvalue="100" mandatory="false">
    </param>
    <param name="currentTemperature" type="Integer" minvalue="0" maxvalue="100" mandatory="false">
    </param>
    <param name="desiredTemperature" type="Integer" minvalue="0" maxvalue="100" mandatory="false">
    </param>
    <param name="temperatureUnit" type="TemperatureUnit" mandatory="false">
      <description> must be present if either currentTemperature or desiredTemperature exists</description>
    </param>
    <param name="acEnable" type="Boolean" mandatory="false">
    </param>
    <param name="circulateAirEnable" type="Boolean" mandatory="false">
    </param>
    <param name="autoModeEnable" type="Boolean" mandatory="false">
    </param>
    <param name="defrostZone" type="DefrostZone" mandatory="false">
    </param>
    <param name="dualModeEnable" type="Boolean" mandatory="false">
    </param>
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
  </struct>

  <enum name="DeviceRank">
   <element name="DRIVER">
    <description>The device is ranked as driver's</description>
   </element>
   <element name="PASSENGER">
    <description>The device is ranked as passenger's</description>
   </element>
  </enum>

  <!-- existing with updates -->
  <function name="ButtonPress" functionID="ButtonPressID" messagetype="request">
    <param name="zone" type="InteriorZone">
        <description>The zone where the button press should occur.</description>
    </param>
    <param name="moduleType" type="ModuleType">
        <description>The module where the button should be pressed</description>
    </param>
    <param name="buttonName" type="ButtonName"/>

    <param name="buttonPressMode" type="ButtonPressMode">
        <description>Indicates whether this is a LONG or SHORT button press event.</description>
    </param>
  </function>

  <function name="ButtonPress" functionID="ButtonPressID" messagetype="response">
    <param name="resultCode" type="Result" platform="documentation">
        <description>See Result</description>
        <element name="SUCCESS"/>
        <element name="OUT_OF_MEMORY"/>
        <element name="TOO_MANY_PENDING_REQUESTS"/>
        <element name="APPLICATION_NOT_REGISTERED"/>
        <element name="GENERIC_ERROR"/>
        <element name="REJECTED"/>
        <element name="IGNORED"/>
        <element name="DISALLOWED"/>
        <element name="USER_DISALLOWED"/>
      <element name="UNSUPPORTED_RESOURCE"/>
    </param>
        <param name="info" type="String" maxlength="1000" mandatory="false">
    </param>
    <param name="success" type="Boolean" platform="documentation">
        <description> true if successful; false, if failed </description>
    </param>
  </function>

  <!-- new additions -->
  <function name="GetInteriorVehicleDataCapabilities" functionID="GetInteriorVehicleDataCapabilitiesID" messagetype="request">
    <description>Called to retrieve the available zones and supported control types</description>
    <param name="zone" type="InteriorZone" mandatory="false">
        <description>If included, only the corresponding modules able to be controlled by that zone will be sent back. If not included, all modules will be returned regardless of their ability to be controlled by specific zones.</description>
    </param>
    <param name="moduleTypes" type="ModuleType" array="true" mandatory="false" minsize="1" maxsize="1000">
        <description>If included, only the corresponding type of modules a will be sent back. If not included, all module types will be returned.</description>
    </param>
  </function>

  <function name="GetInteriorVehicleDataCapabilities" functionID="GetInteriorVehicleDataCapabilitiesID" messagetype="response">
    <param name="interiorVehicleDataCapabilities" type="ModuleDescription" array="true" minsize="1" maxsize="1000">
    </param>

    <param name="resultCode" type="Result" platform="documentation">
        <description>See Result</description>
        <element name="SUCCESS"/>
        <element name="OUT_OF_MEMORY"/>
        <element name="TOO_MANY_PENDING_REQUESTS"/>
        <element name="APPLICATION_NOT_REGISTERED"/>
        <element name="GENERIC_ERROR"/>
        <element name="REJECTED"/>
        <element name="IGNORED"/>
        <element name="DISALLOWED"/>
        <element name="USER_DISALLOWED"/>
      <element name="UNSUPPORTED_RESOURCE"/>
    </param>
    <param name="info" type="String" maxlength="1000" mandatory="false">
    </param>
    <param name="success" type="Boolean" platform="documentation">
        <description> true if successful; false, if failed </description>
    </param>
  </function>

  <function name="GetInteriorVehicleData" functionID="GetInteriorVehicleDataID" messagetype="request">
    <param name="moduleDescription" type="ModuleDescription">
      <description>The zone and module data to retrieve from the vehicle for that zone</description>
    </param>
    <param name="subscribe" type="Boolean" mandatory="false" defvalue="false">
      <description>If subscribe is true, the head unit will send onInteriorVehicleData notifications for the moduleDescription</description>
    </param>
  </function>

  <function name="GetInteriorVehicleData" functionID="GetInteriorVehicleDataID" messagetype="response">
    <param name="moduleData" type="ModuleData">    
    </param>
      <param name="resultCode" type="Result" platform="documentation">
      <description>See Result</description>
      <element name="SUCCESS"/>
      <element name="INVALID_DATA"/>
      <element name="OUT_OF_MEMORY"/>
      <element name="TOO_MANY_PENDING_REQUESTS"/>
      <element name="APPLICATION_NOT_REGISTERED"/>
      <element name="GENERIC_ERROR"/>
      <element name="REJECTED"/>
      <element name="IGNORED"/>
      <element name="DISALLOWED"/>
      <element name="USER_DISALLOWED"/>
      <element name="UNSUPPORTED_RESOURCE"/>
    </param>
    <param name="info" type="String" maxlength="1000" mandatory="false">
    </param>
    <param name="success" type="Boolean" platform="documentation">
        <description> true if successful; false, if failed </description>
    </param>
  </function>

  <function name="SetInteriorVehicleData" functionID="SetInteriorVehicleDataID" messagetype="request">
    <param name="moduleData" type="ModuleData">
      <description>The zone, module, and data to set for the (zone, module) pair</description>
    </param>
  </function>

  <function name="SetInteriorVehicleData" functionID="SetInteriorVehicleDataID" messagetype="response">
    <description>Used to set the values of one zone and one data type within that zone</description>
    <param name="moduleData" type="ModuleData">
    </param>
    <param name="resultCode" type="Result" platform="documentation">
      <description>See Result</description>
      <element name="SUCCESS"/>
      <element name="INVALID_DATA"/>
      <element name="OUT_OF_MEMORY"/>
      <element name="TOO_MANY_PENDING_REQUESTS"/>
      <element name="APPLICATION_NOT_REGISTERED"/>
      <element name="GENERIC_ERROR"/>
      <element name="REJECTED"/>
      <element name="IGNORED"/>
      <element name="DISALLOWED"/>
      <element name="USER_DISALLOWED"/>
      <element name="READ_ONLY"/>
      <element name="UNSUPPORTED_RESOURCE"/>
    </param>
    <param name="info" type="String" maxlength="1000" mandatory="false">
    </param>
    <param name="success" type="Boolean" platform="documentation">
        <description> true if successful; false, if failed </description>
    </param>
  </function>

  <function name="OnInteriorVehicleData" functionID="OnInteriorVehicleDataID" messagetype="notification">
    <param name="moduleData" type="ModuleData">
    </param>
  </function>

  <!-- existing with updates -->
  <function name="OnHMIStatus" functionID="OnHMIStatusID" messagetype="notification">
    <param name="hmiLevel" type="HMILevel">
      <description>See HMILevel</description>
    </param>

    <param name="audioStreamingState" type="AudioStreamingState">
      <description>See AudioStreamingState</description>
    </param>

    <param name="systemContext" type="SystemContext">
      <description>See SystemContext</description>
    </param>

    <!-- new additions -->
    <param name="deviceRank" type="DeviceRank" mandatory="false">
     <description>If "DRIVER" - the application is running on device ranked as driver's. If "PASSENGER" - the application is running on device ranked as passenger's. </description>
    </param>
  </function>

  <enum name="AppHMIType">
    <description>Enumeration listing possible app types.</description>
    <element name="DEFAULT" />
    <element name="COMMUNICATION" />
    <element name="MEDIA" />
    <element name="MESSAGING" />
    <element name="NAVIGATION" />
    <element name="INFORMATION" />
    <element name="SOCIAL" />
    <element name="BACKGROUND_PROCESS" />
    <element name="TESTING" />
    <element name="SYSTEM" />
    <!-- new additions -->
    <element name="REMOTE_CONTROL" />
  </enum>
```

### HMI API changes
Full HMI API can be found here:
https://github.com/smartdevicelink/sdl_core/blob/feature/sdl_rc_functionality/src/components/interfaces/HMI_API.xml

The changes are listed below.
```xml
<!-- existing with updates -->
<!-- add whether buttons can be pressed via Buttons.GetCapabilities -->
<interface name="Buttons" version="1.1" date="2016-08-18">
    <function name="ButtonPress" messagetype="request">
      <description>Method is invoked when the application tries to press a button</description>
      <param name="zone" type="Common.InteriorZone">
        <description>The zone where the button press should occur.</description>
      </param>
      <param name="moduleType" type="Common.ModuleType">
        <description>The module where the button should be pressed</description>
      </param>
      <param name="buttonName" type="Common.ButtonName"/>
      <param name="buttonPressMode" type="Common.ButtonPressMode">
        <description>Indicates whether this is a LONG or SHORT button press event.</description>
      </param>
      <param name="appID" type="Integer" mandatory="true">
        <description>ID of the application that triggers the permission prompt.</description>
      </param>
    </function>
</interface>

<interface name="Common" version="1.5" date="2015-10-13">
  <enum name="ButtonName">
      <description>Defines the hard (physical) and soft (touchscreen) buttons available from SYNC</description>
      <element name="OK"/>
      <element name="SEEKLEFT"/>
      <element name="SEEKRIGHT"/>
      <element name="TUNEUP"/>
      <element name="TUNEDOWN"/>
      <element name="PRESET_0"/>
      <element name="PRESET_1"/>
      <element name="PRESET_2"/>
      <element name="PRESET_3"/>
      <element name="PRESET_4"/>
      <element name="PRESET_5"/>
      <element name="PRESET_6"/>
      <element name="PRESET_7"/>
      <element name="PRESET_8"/>
      <element name="PRESET_9"/>
      <element name="CUSTOM_BUTTON"/>
      <element name="SEARCH"/>

      <!-- new additions -->
      <!-- Climate Buttons -->
      <element name="AC_MAX" />
      <element name="AC" />
      <element name="RECIRCULATE" />
      <element name="FAN_UP" />
      <element name="FAN_DOWN" />
      <element name="TEMP_UP" />
      <element name="TEMP_DOWN" />
      <element name="DEFROST_MAX" />
      <element name="DEFROST" />
      <element name="DEFROST_REAR" />
      <element name="UPPER_VENT" />
      <element name="LOWER_VENT" />

      <!-- Radio Buttons -->
      <element name="VOLUME_UP" />
      <element name="VOLUME_DOWN" />
      <element name="EJECT" />
      <element name="SOURCE" />
      <element name="SHUFFLE" />
      <element name="REPEAT" />
  </enum>

  <enum name="AppHMIType">
    <description>Enumeration listing possible app types.</description>
    <element name="DEFAULT" />
    <element name="COMMUNICATION" />
    <element name="MEDIA" />
    <element name="MESSAGING" />
    <element name="NAVIGATION" />
    <element name="INFORMATION" />
    <element name="SOCIAL" />
    <element name="BACKGROUND_PROCESS" />
    <element name="TESTING" />
    <element name="SYSTEM" />
    <element name="REMOTE_CONTROL" />
  </enum>

<!-- new additions -->
<struct name="InteriorZone">
  <description>Describes the origin and span of a zone in the vehicle. Vehicle zones can be overlapping</description>
  <param name="col" type="Integer" minvalue="0" maxvalue="100">
  </param>
  <param name="row" type="Integer" minvalue="0" maxvalue="100">
  </param>
  <param name="level" type="Integer" minvalue="0" maxvalue="100">
  </param>
  <param name="colspan" type="Integer" minvalue="0" maxvalue="100">
  </param>
  <param name="rowspan" type="Integer" minvalue="0" maxvalue="100">
  </param>
  <param name="levelspan" type="Integer" minvalue="0" maxvalue="100">
  </param>
</struct>

<enum name="ModuleType">
  <element name="CLIMATE"/>
  <element name="RADIO"/>
</enum>

<struct name="ModuleDescription">
  <param name="moduleZone" type="Common.InteriorZone">
  </param>
  <param name="moduleType" type="Common.ModuleType">
  </param>
</struct>

<enum name="RadioBand">
  <element name="AM"/>
  <element name="FM"/>
  <element name="XM"/>
</enum>

<enum name="TemperatureUnit">
  <element name="KELVIN"/>
  <element name="FAHRENHEIT"/>
  <element name="CELSIUS"/>
</enum>

<enum name="DeviceRank">
  <element name="DRIVER">
    <description>The device is ranked as driver's</description>
  </element>
  <element name="PASSENGER">
    <description>The device is ranked as passenger's</description>
  </element>
</enum>

<struct name="RdsData">
  <param name="PS" type="String" minlength="0" maxlength="8">
    <description>Program Service Name</description>
  </param>
  <param name="RT" type="String" minlength="0" maxlength="64">
    <description>Radio Text</description>
  </param>
  <param name="CT" type="String" minlength="24" maxlength="24">
    <description>The clock text in UTC format as YYYY-MM-DDThh:mm:ss.sTZD</description>
  </param>
  <param name="PI" type="String" minlength="0" maxlength="6">
    <description>Program Identification - the call sign for the radio station</description>
  </param>
  <param name="PTY" type="Integer" minvalue="0" maxvalue="31">
    <description>The program type - The region should be used to differentiate between EU and North America program types</description>
  </param>
  <param name="TP" type="Boolean">
    <description>Traffic Program Identification - Identifies a station that offers traffic</description>
  </param>
  <param name="TA" type="Boolean">
    <description>Traffic Announcement Identification - Indicates an ongoing traffic announcement</description>
  </param>
  <param name="REG" type="String">
    <description>Region</description>
  </param>
</struct>

<enum name="RadioState">
  <element name="ACQUIRING"/>
  <element name="ACQUIRED"/>
  <element name="MULTICAST"/>
  <element name="NOT_FOUND"/>
</enum>

<struct name="RadioControlData">
  <param name="frequencyInteger" type="Integer" minvalue="0" maxvalue="1710" mandatory="false">
    <description>The integer part of the frequency ie for 101.7 this value should be 101</description>
  </param>
  <param name="frequencyFraction" type="Integer" minvalue="0" maxvalue="9" mandatory="false">
    <description>The fractional part of the frequency for 101.7 is 7</description>
  </param>
  <param name="band" type="Common.RadioBand" mandatory="false">
  </param>
  <param name="rdsData" type="Common.RdsData" mandatory="false">
  </param>
  <param name="availableHDs" type="Integer" minvalue="1" maxvalue="3" mandatory="false">
    <description>number of HD sub-channels if available</description>
  </param>
  <param name="hdChannel" type="Integer" minvalue="1" maxvalue="3" mandatory="false">
    <description>Current HD sub-channel if available</description>
  </param>
  <param name="signalStrength" type="Integer" minvalue="0" maxvalue="100" mandatory="false">
  </param>
  <param name="signalChangeThreshold" type="Integer" minvalue="0" maxvalue="100" mandatory="false">
    <description>If the signal strength falls below the set value for this parameter, the radio will tune to an alternative frequency</description>
  </param>
  <param name="radioEnable" type="Boolean" mandatory="false">
    <description> True if the radio is on, false is the radio is off</description>
  </param>
  <param name="state" type="Common.RadioState" mandatory="false">
  </param>
</struct>

<enum name="DefrostZone">
  <element name="FRONT"/>
  <element name="REAR"/>
  <element name="ALL"/>
</enum>

<struct name="ClimateControlData">
  <param name="fanSpeed" type="Integer" minvalue="0" maxvalue="100" mandatory="false">
  </param>
  <param name="currentTemp" type="Integer" minvalue="0" maxvalue="100" mandatory="false">
  </param>
  <param name="desiredTemp" type="Integer" minvalue="0" maxvalue="100" mandatory="false">
  </param>
  <param name="temperatureUnit" type="Common.TemperatureUnit" mandatory="false">
  </param>
  <param name="acEnable" type="Boolean" mandatory="false">
  </param>
  <param name="circulateAirEnable" type="Boolean" mandatory="false">
  </param>
  <param name="autoModeEnable" type="Boolean" mandatory="false">
  </param>
  <param name="defrostZone" type="Common.DefrostZone" mandatory="false">
  </param>
  <param name="dualModeEnable" type="Boolean" mandatory="false">
  </param>
</struct>

<struct name="ModuleData">
  <description>The moduleType indicates which type of data should be changed and identifies which data object exists in this struct. For example, if the moduleType is CLIMATE then a "climateControlData" should exist</description>
  <param name="moduleType" type="Common.ModuleType">
  </param>
  <param name="moduleZone" type="Common.InteriorZone">
  </param>
  <param name="radioControlData" type="Common.RadioControlData" mandatory="false">
  </param>
  <param name="climateControlData" type="Common.ClimateControlData" mandatory="false">
  </param>
</struct>  
</interface>

<interface name="RC" version="1.0" date="2015-10-13">
  <function name="GetInteriorVehicleDataCapabilities" messagetype="request">
    <description>Called to retrieve the available zones and supported control types</description>
    <param name="zone" type="Common.InteriorZone" mandatory="false">
      <description>If included, only the corresponding modules able to be controlled by that zone will be sent back. If not included, all modules will be returned regardless of their ability to be controlled by specifc zones.</description>
    </param>
    <param name="moduleTypes" type="Common.ModuleType" array="true" mandatory="false" minsize="1" maxsize="1000">
      <description>If included, only the corresponding type of modules a will be sent back. If not included, all module types will be returned.</description>
    </param>
    <param name="appID" type="Integer" mandatory="true">
      <description>Internal SDL-assigned ID of the related application</description>
    </param>
  </function>
  <function name="GetInteriorVehicleDataCapabilities" messagetype="response">
    <param name="interiorVehicleDataCapabilities" type="Common.ModuleDescription" array="true" minsize="1" maxsize="1000">
  </param>
  </function>
  <function name="SetInteriorVehicleData" functionID="SetInteriorVehicleDataID" messagetype="request">
    <param name="moduleData" type="Common.ModuleData">
      <description>The zone, module, and data to set for the (zone, module) pair</description>
    </param>
    <param name="appID" type="Integer" mandatory="true">
      <description>Internal SDL-assigned ID of the related application</description>
    </param>
  </function>
  <function name="SetInteriorVehicleData" functionID="SetInteriorVehicleDataID" messagetype="response">
    <description>Used to set the values of one zone and one data type within that zone</description>
    <param name="moduleData" type="Common.ModuleData">
    </param>
  </function>
  <function name="GetInteriorVehicleData" functionID="GetInteriorVehicleDataID" messagetype="request">
    <param name="moduleDescription" type="Common.ModuleDescription">
      <description>The zone and module data to retrieve from the vehicle for that zone</description>
    </param>
    <param name="subscribe" type="Boolean" mandatory="false" defvalue="false">
      <description>If subscribe is true, the head unit will send onInteriorVehicleData notifications for the moduleDescription</description>
    </param>
    <param name="appID" type="Integer" mandatory="true">
      <description>Internal SDL-assigned ID of the related application</description>
    </param>
  </function>
  <function name="GetInteriorVehicleData" functionID="GetInteriorVehicleDataID" messagetype="response">
    <param name="moduleData" type="Common.ModuleData">
    </param>
    <param name="isSubscribed" type="Boolean" mandatory="false" >
      <description>Is a conditional-mandatory parameter: must be returned in case "subscribe" parameter was present in the related request.
      if "true" - the "moduleDescription" from request is successfully subscribed and  the head unit will send onInteriorVehicleData notifications for the moduleDescription.
      if "false" - the "moduleDescription" from request is either unsubscribed or failed to subscribe.</description>
    </param>
  </function>
  <function name="GetInteriorVehicleDataConsent" messagetype="request">
    <description>Sender: SDL->HMI. </description>
    <description>HMI is expected to display a permission prompt to the driver showing the module, zone, and app details (for example, app's name). The driver is expected to have an ability to grant or deny the permission.</description>
    <param name="moduleType" type="Common.ModuleType" mandatory="true">
      <description>The module that the app requests to control.</description>
    </param>
    <param name="zone" type="Common.InteriorZone" mandatory="true">
      <description>A zone from which the app requests to control the named module.</description>
    </param>
    <param name="appID" type="Integer" mandatory="true">
      <description>ID of the application that triggers the permission prompt.</description>
    </param>
  </function>
  <function name="GetInteriorVehicleDataConsent" messagetype="response">
    <param name="allowed" type="Boolean" mandatory="true">
      <description>"true" - if the driver grants the permission for controlling to the named app; "false" - in case the driver denies the permission for controlling to the named app.</description>
    </param>
  </function>

  <function name="OnInteriorVehicleData" functionID="OnInteriorVehicleDataID" messagetype="notification">
    <param name="moduleData" type="Common.ModuleData">
    </param>
  </function>
  <function name="OnReverseAppsAllowing" messagetype="notification">
    <description>Sender: vehicle -> RSDL. Notification about remote-control for passenger`s applications must be either turned off or turned on. Sent after User`s choice through HMI.</description>
    <param name="allowed" type="Boolean" mandatory="true" >
      <description>If "true" - RC for passengers is allowed; if "false" - disallowed.</description>
    </param>
  </function>
  <function name="OnDeviceRankChanged" messagetype="notification">
    <description>Sender: vehicle->RSDL. Purpose: inform about the device is set either as driver`s or as passenger`s  device by the HMI settings or by the HMI User through the appropriate menu.</description>
    <param name="deviceRank" type="Common.DeviceRank" mandatory="true">
      <description>If "DRIVER" - the named by "DeviceInfo" device is set as driver`s. If "PASSENGER" -  the named by "DeviceInfo" device is set as passenger`s. </description>
    </param>
    <param name="device" type="Common.DeviceInfo" mandatory="true">
      <description>The device info: name and ID. Initially is sent by SDL via UpdateDeviceList to the vehicle.</description>
    </param>
  </function>
  <function name="OnDeviceLocationChanged" messagetype="notification">
    <description>Sender: vehicle->RSDL. Purpose: inform about the device location in the vehicle interior.</description>
    <param name="deviceLocation" type="Common.InteriorZone" mandatory="true">
      <description>Defines the vehicle zone where the named device is located. </description>
    </param>
    <param name="device" type="Common.DeviceInfo" mandatory="true">
      <description>The device info: name and ID. Initially is sent by SDL via UpdateDeviceList to HMI.</description>
    </param>
  </function>
</interface>
```

## Potential downsides

- The driver distraction rules and regional regulations are getting more stringent on driver's using mobile phones while driving. Current design cannot prevent a driver mark a phone as PASSENGER and use it while driving.

- The driver must exit current controlling application before using another application to control the same RC module. There is no indication of which application is currently control the RC module. Driver doesn't know which application to close. This makes application switching cumbersome.

- It lacks the policy control on which application can access which RC resource.

- RPC messages are not encrypted. Attackers may try to evesdrop and spoof wireless communication.

- It can only subscribe to all radio or climate control data, cannot subscribe to individual item change notifications.

- RC capabilities does not include detailed control item, it contains only moduleDescription (zone + type).

- DeviceRank is in OnHMIStatus notification, preferred to be in a new separate notification.


## Impact on existing code

SDL core code, android and iOS mobile libs and RPC need updates.

## Alternatives considered

None.
