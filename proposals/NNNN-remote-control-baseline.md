# SDL Remote Control Baseline (no zones, no driver/passenger, immediate control)

* Proposal: [SDL-NNNN](NNNN-remote-control-baseline.md)
* Author: [Zhimin Yang](https://github.com/yang1070)
* Status: **Awaiting review**
* Impacted Platforms: [Core / iOS / Android / RPC ]

## Introduction

SmartDeviceLink provides a framework that connects in-vehicle infotainment system to mobile phone applications. SDL enables a driver to interact with their mobile phone applications using common in-vehicle interfaces such as a touch screen display, embedded voice recognition, steering wheel controls and various vehicle knobs and buttons. Although SDL provides some RPCs to allow mobile applications to obtain some vehicle status information, it does not allow a mobile application to change the vehicle settings, i.e. to control the vehicle. SDL remote control (or previously known as reverse SDL) provides the ability for mobile applications to control certain settings of the vehicle, such as, radio and climate.

## Motivation

There are many cases that mobile application developers ask for new functions of SDL. For example,

- A radio application wants to use the in-vehicle radio. It needs the RPC function to select the radio band (AM/FM/XM/HD/DAB), tune the radio frequency or change the radio station, as well as obtain general radio information for decision making.

- A climate control application needs to turn on the AC, control the air circulation mode, change the fan speed and set the desired cabin temperature.

- A user profile application wants to remember user's favorite settings and apply it later automatically when the users get into the same/another vehicle.

- A navigation application wants to set the application's display mode same as the vehicle's display mode and vice versa.

The common problem is that a mobile application needs the ability to control certain settings of the vehicle. This proposal (SDL remote control or SDL-RC) tries to address this problem. This proposal describes the baseline requirements of RC.

## Proposed solution

### Baseline features of SDL remote control in this proposal

- A list of supported RC modules and specific (readable and or controllable) items within each module, and potentially value range of each item
- Baseline only supports radio control module and climate control module
- API to get the RC capabilities (the list mentioned above)
- API to read RC module status data
- API to change RC module settings
- API to subscribe RC module status/setting change notifications
- API to unsubscribe RC module status/setting change notifications
- RC Module status/data/setting change notifications
- Basic app authorization support, the policy that control which app can access which type(s) of remote control module
- Applications can control all available RC modules of the vehicle if the policy allows
- One connected mobile device
- Assumption that the app want to perform the control immediately at the time when a control request is issued.

### The following features are not considered in this baseline proposal

- app authentication (SDL has it already for Mobile Navigation apps, not for generic or remote control apps)
- app authorization (policy control, which app can access which remote control module(s) or which control items)
- encryption
- RC status notifications (indicates whether an app has the control of a RC module)
- Permission change notifications (due to policy update or driver grant/revoke permission for an app, SDL has it for generic apps)
- Additional RC modules (HMI settings, power seat control, windows control, lights control, etc.) or additional control items in climate and radio control
- RC resource management regarding how multiple apps access the same RC module with additional requirements, for example "add to queue mode". That should be another proposal. 

### Compared to the current implementation in the RC feature branch, the following sub-features are removed/changed/added

- Remove the concept and the usage of resource zones, including the resource policy. The lack of zones implies that the “primary zone” in the vehicle will be used, defined by OEM, (such as the driver’s zone, or all the vehicle being 1 zone).
- Remove the device location (device is in one of the zones)
- Continue divide available controllable items into RC modules by functionality, give each module a unique short name defined by OEM. This name string is not used to identify and classify modules. It should only be used as a user “friendly” name or a “readable” description of the module, not for parsing the modules. Zones or other similar schemes shall be in a seperate proposal.
- Provide new RemoteControlCapabilities data structure, which includes specific controllable items in each module
- Change ModuleDescription structure from using module zone to module name 
- Keep concept of driver vs passenger device, but treat all devices as driver's device, and only allow one device
- Add NONE to defrost zone
- Remove OnDeviceLocationChanged notifications
- Keep but disable OnDeviceRankChanged notifications
- Keep but disable OnReverseAppsAllowing API
- Keep GetInteriorVehicleDataConsent request and response
- OnHMIStatus does not contain deviceRank.
- Add basic policy support



### Details

The following table lists what control modules are defined in baseline 

| RC Module |
| --------- |
| Radio |
| Climate |

The following table lists what control items are considered in the each control module.


| RC Module | Control Item | Value Range |Type | Comments |
| ------------ | ------------ |------------ | ------------ | ------------ |
| Radio | Radio Enabled | true,false  | Get/Notification| read only, all other radio control items need radio enabled to work|
|       | Radio Band | AM,FM,XM  | Get/Set/Notification| |
|       | Radio Frequency | | Get/Set/Notification | value range depends on band |
|       | Radio RDS Data | | Get/Notification | read only |
|       | Available HD Channel | 1-3 | Get/Notification | read only |
|       | Current HD Channel | 1-3 | Get/Set/Notification |
|       | Radio Signal Strength |  | Get/Notification | read only |
|       | Signal Change Threshold |  | Get/Notification | read only |
|       | Radio State | Acquiring, acquired, multicast, not_found | Get/Notification | read only |
| Climate | Current Cabin Temperature | -30 to 40C or -22 to 104F| Get/Notification | read only |
|         | Desired Cabin Temperature | 14 to 30C or 60 to 90F  | Get/Set/Notification |  |
|         | AC Setting | on,off | Get/Set/Notification |  |
|         | AC MAX Setting | on,off  | Get/Set/Notification |  |
|         | Air Recirculation Setting | on,off  | Get/Set/Notification |  |
|         | Auto AC Mode Setting | on,off  | Get/Set/Notification |  |
|         | Defrost Zone Setting | front,rear,all,none  | Get/Set/Notification |  |
|         | Dual Mode Setting | on,off  | Get/Set/Notification |  |
|         | Fan Speed Setting | 0%-100% | Get/Set/Notification |  |
|         | Ventilation Mode Setting | upper,lower,both,none  | Get/Set/Notification |  |

In addition to the above RC data/settings, the SDL-RC can also allow mobile application to send button press event or long press event for the follow common climate control buttons in vehicle.
The system shall list all available RC radio buttons and RC climate buttons in the existing ButtonCapabilities list.

| RC Module | Control Button |
| ------------ | ------------ |
| Climate | AC Button |
|         | AC MAX Button |
|         | RECIRCULATE Button |
|         | FAN UP Button |
|         | FAN DOWN Button |
|         | TEMPERATURE UP Button |
|         | TEMPERATURE DOWN Button |
|         | DEFROST Button |
|         | DEFROST REAR Button |
|         | DEFROST MAX Button |
|         | UPPER VENT Button |
|         | LOWER WENT Button |
| Radio   | VOLUME UP Button |
|         | VOLUME DOWN Button |
|         | EJECT Button |
|         | SOURCE Button |
|         | SHUFFLE Button |
|         | REPEAT Button |

Each RC module shall have a short name (or a label) in order to uniquely identify the module in case there are multiple modules of the same type. SDL does not standardize the name for the modules. The name may or may not related to the location of the module within the vehicle. It is the OEM's choice to name each individual module. 


A new appHMIType: REMOTE_CONTROL is added: all and any remote-control applications must register with this type. 

The work flow of a remote control application on driver's device is simple. Like the existing applications, a RC application need to register with the system, be launched by driver via HMI or voice control. The app shall send a request for vehicle's RC capabilities to get a list of controllable RC modules available. Then it can start to read or change RC module settings. 

The first control message (setter request) with a specific RC module will trigger SDL to perform RC resource allocation process. The coding of this RC resource allocation process shall be upgradable in the future without major code infrastructure revision. 

One simple resource allocation process can be at any given time a RC module can be controlled by one and only one application. For example, if a climate control module is allocated to application ONE, any other applications will get rejected if they try to change the climate control settings. The climate control resource is freed when application ONE exits or disconnects. Until climate control resource gets free, no other application can perform climate control actions. RC resource allocation is first come, first serve.

By default SDL-RC allows RC application to use remote control feature. However, the driver can disable the feature via HMI by sending OnReverseAppsAllowing(false) message to SDL.

SDL policy already supports the function group that configures which application can access which RPC and which vehicle data, such as gps, deviceStatus, tirePressure, fuelLevel and so on. Similarly, SDL policy shall support the configuration on which application can access which type(s) of remote control resource in vehicle. For example, some applications can only control radio, some applications can only control climate, some applications can control both radio and climate. SDL shall check the policy configurations regarding which type(s) of remote control module can be accessed by a RC application.

Please see attached documents for detailed design of existing implementation. [HMI Guideline](../assets/proposals/0065-remote-control/0065_SDLRC_HMI_Guidelines_v1.1.pdf) and [Mobile API Guideline](../assets/proposals/0065-remote-control/0065_SDLRC_Mobile_API_Guidelines_v1.0.pdf)

### Mobile API changes
Full Mobile API can be found here:
https://github.com/smartdevicelink/sdl_core/blob/feature/sdl_rc_functionality/src/components/interfaces/MOBILE_API.xml

The changes are listed below.
```xml
<enum name="ButtonName">
      <description>Defines the hard (physical) and soft (touch screen) buttons available from SYNC</description>
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
  <enum name="ModuleType">
    <element name="CLIMATE"/>
    <element name="RADIO"/>
  </enum>

      
  <struct name="ClimateControlCapabilities">
    <description>Contains information about a climate control module's capabilities.</description>
    <param name="name" type="String" maxlength="50">
      <description>The short name or a short description of the climate control module.</description>
    </param>
    <param name="fanSpeedAvailable" type="Boolean" mandatory="false">
      <description>
        Availability of the control of fan speed. 
        True: Available, False: Not Available, Not present: Not Available.
      </description>
    </param>
    <param name="desiredTemperatureAvailable" type="Boolean" mandatory="false">
      <description>
        Availability of the control of desired temperature. 
        True: Available, False: Not Available, Not present: Not Available.
      </description>
    </param>
    <param name="acEnableAvailable" type="Boolean" mandatory="false">
      <description>
        Availability of the control of turn on/off AC. 
        True: Available, False: Not Available, Not present: Not Available.
      </description>
    </param>
    <param name="acMaxEnableAvailable" type="Boolean" mandatory="false">
      <description>
        Availability of the control of enable/disable air conditioning is ON on the maximum level. 
        True: Available, False: Not Available, Not present: Not Available.
      </description>
    </param>
    <param name="circulateAirEnableAvailable" type="Boolean" mandatory="false">
      <description>
        Availability of the control of enable/disable circulate Air mode. 
        True: Available, False: Not Available, Not present: Not Available.
      </description>
    </param>
    <param name="autoModeEnableAvailable" type="Boolean" mandatory="false">
      <description>
        Availability of the control of enable/disable auto mode. 
        True: Available, False: Not Available, Not present: Not Available.
      </description>
    </param>
    <param name="dualModeEnableAvailable" type="Boolean" mandatory="false">
      <description>
        Availability of the control of enable/disable dual mode. 
        True: Available, False: Not Available, Not present: Not Available.
      </description>
    </param>
    <param name="defrostZoneAvailable" type="Boolean" mandatory="false">
      <description>
        Availability of the control of defrost zones. 
        True: Available, False: Not Available, Not present: Not Available.
      </description>
    </param>
    <param name="defrostZone" type="DefrostZone" minsize="1" maxsize="100" array="true" mandatory="false">
      <description>
        A set of all defrost zones that are controllable. 
      </description>
    </param>
    <param name="ventilationModeAvailable" type="Boolean" mandatory="false">
      <description>
        Availability of the control of air ventilation mode. 
        True: Available, False: Not Available, Not present: Not Available.
      </description>
    </param>
    <param name="ventilationMode" type="VentilationMode" minsize="1" maxsize="100" array="true" mandatory="false">
      <description>
        A set of all ventilation modes that are controllable. 
      </description>
    </param>
  </struct>
  
  <enum name="DefrostZone">
    <element name="FRONT"/>
    <element name="REAR"/>
    <element name="ALL"/>
    <element name="NONE"/>
  </enum>
  <enum name="VentilationMode">
    <element name="UPPER"/>
    <element name="LOWER"/>
    <element name="BOTH"/>
    <element name="NONE"/>
  </enum>
  
  <struct name="RadioControlCapabilities">
    <description>Contains information about a radio control module's capabilities.</description>
    <param name="name" type="String" maxlength="50">
      <description>The short name or a short description of the radio control module.</description>
    </param>
    <param name="radioEnableAvailable" type="Boolean" mandatory="false">
      <description>
        Availability of the control of enable/disable radio. 
        True: Available, False: Not Available, Not present: Not Available.
      </description>
    </param>
    <param name="radioBandAvailable" type="Boolean">
      <description>
        Availability of the control of radio band. 
        True: Available, False: Not Available, Not present: Not Available.
      </description>
    </param>
    <param name="radioFrequencyAvailable" type="Boolean">
      <description>
        Availability of the control of radio frequency. 
        True: Available, False: Not Available, Not present: Not Available.
      </description>
    </param>
    <param name="hdChannelAvailable" type="Boolean">
      <description>
        Availability of the control of HD radio channel. 
        True: Available, False: Not Available, Not present: Not Available.
      </description>
    </param>
    <param name="rdsDataAvailable" type="Boolean">
      <description>
        Availability of the getting Radio Data System (RDS) data. 
        True: Available, False: Not Available, Not present: Not Available.
      </description>
    </param>
    <param name="availableHDsAvailable" type="Boolean">
      <description>
        Availability of the getting the number of available HD channels. 
        True: Available, False: Not Available, Not present: Not Available.
      </description>
    </param>
    <param name="stateAvailable" type="Boolean">
      <description>
        Availability of the getting the Radio state. 
        True: Available, False: Not Available, Not present: Not Available.
      </description>
    </param>
    <param name="signalStrengthAvailable" type="Boolean">
      <description>
        Availability of the getting the signal strength. 
        True: Available, False: Not Available, Not present: Not Available.
      </description>
    </param>
    <param name="signalChangeThresholdAvailable" type="Boolean">
      <description>
        Availability of the getting the signal Change Threshold. 
        True: Available, False: Not Available, Not present: Not Available.
      </description>
    </param>
  </struct>
  
  <struct name="RemoteControlCapabilities">
    <param name="climateControlCapabilities" type="ClimateControlCapabilities" mandatory="false" minsize="1" maxsize="100" array="true">
      <description>If included, the platform supports RC climate controls.</description >
    </param>

    <param name="radioControlCapabilities" type="RadioControlCapabilities" mandatory="false" minsize="1" maxsize="100" array="true">
      <description>If included, the platform supports RC radio controls.</description >
    </param>
  </struct>
  
  <struct name="ModuleDescription">
    <param name="moduleName" type="String">
        <description>The short name or a short description of the remote control module, which is returned in the capabilities.</description>
    </param>
    <param name="moduleType" type="Common.ModuleType">
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

  <enum name="TemperatureUnit">
    <element name="FAHRENHEIT"/>
    <element name="CELSIUS"/>
  </enum>

  <struct name="Temperature">
    <param name="unit" type="TemperatureUnit">
      <description>Temperature Unit</description>
    </param>
    <param name="valueC" type="Float" minvalue="14.0" maxvalue="30.0" mandatory=”false”>
      <description>Temperature Value in Celsius, the value range is for setter only</description>
    </param>
    <param name="valueF" type="Float" minvalue="60.0" maxvalue="90.0" mandatory=”false”>
      <description>Temperature Value in Fahrenheit, the value range is for setter only</description>
    </param>
  </struct>
 
  <struct name="ClimateControlData">
    <param name="fanSpeed" type="Integer" minvalue="0" maxvalue="100" mandatory="false">
    </param>
    <param name="currentTemperature" type="Temperature" mandatory="false">
    </param>
    <param name="desiredTemperature" type="Temperature" mandatory="false">
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
    <param name="acMaxEnable" type="Boolean" mandatory="false">
    </param>
    <param name="ventilationMode" type="VentilationMode" mandatory="false">
    </param>
  </struct>

  <struct name="ModuleData">
    <description>The moduleType indicates which type of data should be changed and identifies which data object exists in this struct. For example, if the moduleType is CLIMATE then a "climateControlData" should exist</description>
    <param name="moduleType" type="ModuleType">
    </param>
    <param name="moduleName" type="String">
    </param>
    <param name="radioControlData" type="RadioControlData" mandatory="false">
    </param>
    <param name="climateControlData" type="ClimateControlData" mandatory="false">
    </param>
  </struct>


  <!-- existing with updates -->
  <function name="ButtonPress" functionID="ButtonPressID" messagetype="request">
    <param name="moduleName" type="String">
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
    <param name="moduleTypes" type="ModuleType" array="true" mandatory="false" minsize="1" maxsize="1000">
        <description>If included, only the corresponding type of modules a will be sent back. If not included, all module types will be returned.</description>
    </param>
  </function>

  <function name="GetInteriorVehicleDataCapabilities" functionID="GetInteriorVehicleDataCapabilitiesID" messagetype="response">
    <param name="interiorVehicleDataCapabilities" type="RemoteControlCapabilities">
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
      <description>The name and module data to retrieve from the vehicle for that name</description>
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
      <description>The name, module, and data to set for the (name, module) pair</description>
    </param>
  </function>

  <function name="SetInteriorVehicleData" functionID="SetInteriorVehicleDataID" messagetype="response">
    <description>Used to set the values of one remote control module </description>
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

### HMI  API changes
Full HMI API can be found here:
https://github.com/smartdevicelink/sdl_core/blob/feature/sdl_rc_functionality/src/components/interfaces/HMI_API.xml

The changes are similar to mobile api changes, they are not listed here.

## Potential downsides

- The driver must exit current controlling application before using another application to control the same RC module. There is no indication of which application is currently control the RC module. Driver doesn't know which application to close. This makes application switching cumbersome.

- It lacks the fine policy control on which application can access which RC module(s) and which control item(s) within each module.

- RPC messages are not encrypted. Attackers may try to eavesdrop and spoof wireless communication. For example in a replay attack, attackers record and then replay the “electro magnetic waves”.

- It can only subscribe to all radio or climate control data, cannot subscribe to individual item change notifications.


## Impact on existing code

SDL core code, android and iOS mobile libs and RPC need updates.

## Alternatives considered

None.
