# SDL Remote Control Baseline (no zones, no driver/passenger, immediate control)

* Proposal: [SDL-0071](0071-remote-control-baseline.md)
* Author: [Zhimin Yang](https://github.com/yang1070)
* Status: **Accepted**
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
- Baseline only supports radio control module and climate control module.
The following table lists what control modules are defined in baseline.

| RC Module |
| --------- |
| Radio |
| Climate |

- Baseline defines a list of supported RC modules and specific (readable and or controllable) items within each module, and potentially value range of each item.

The following table lists what control items are considered in the each control module.

| RC Module | Control Item | Value Range |Type | Comments |
| ------------ | ------------ |------------ | ------------ | ------------ |
| Radio | Radio Enabled | true,false  | Get/Set/Notification| read only, all other radio control items need radio enabled to work|
|       | Radio Band | AM,FM,XM  | Get/Set/Notification| |
|       | Radio Frequency | | Get/Set/Notification | value range depends on band |
|       | Radio RDS Data | | Get/Notification | read only |
|       | Available HD Channel | 1-3 | Get/Notification | read only |
|       | Current HD Channel | 1-3 | Get/Set/Notification |
|       | Radio Signal Strength |  | Get/Notification | read only |
|       | Signal Change Threshold |  | Get/Notification | read only |
|       | Radio State | Acquiring, acquired, multicast, not_found | Get/Notification | read only |
| Climate | Current Cabin Temperature |  | Get/Notification | read only, value range depends on OEM |
|         | Desired Cabin Temperature |  | Get/Set/Notification | value range depends on OEM |
|         | AC Setting | on,off | Get/Set/Notification |  |
|         | AC MAX Setting | on,off  | Get/Set/Notification |  |
|         | Air Recirculation Setting | on,off  | Get/Set/Notification |  |
|         | Auto AC Mode Setting | on,off  | Get/Set/Notification |  |
|         | Defrost Zone Setting | front,rear,all,none  | Get/Set/Notification |  |
|         | Dual Mode Setting | on,off  | Get/Set/Notification |  |
|         | Fan Speed Setting | 0%-100% | Get/Set/Notification |  |
|         | Ventilation Mode Setting | upper,lower,both,none  | Get/Set/Notification |  |

In addition to the above RC data/settings, the SDL-RC can also allow mobile application to send button press event or long press event for the following common climate control buttons in vehicle.
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

- Extend GetSystemCapability RPC to get the RC capabilities (the list mentioned above, ButtonCapabilities is existing data structure),
```xml
<enum name="SystemCapabilityType">
         ....
    <element name="REMOTE_CONTROL"/>
</enum>

<struct name="SystemCapability">
    <description>
      The systemCapabilityType indicates which type of data should be changed and identifies which data object exists in this struct.
      For example, if the SystemCapability Type is NAVIGATION then a "navigationCapability" should exist
    </description>
    <param name="systemCapabilityType" type="SystemCapabilityType" mandatory="true">
    </param>
         ...
    <param name="remoteControlCapability" type="RemoteControlCapabilities" mandatory="false">
    </param>
</struct>

<struct name="RemoteControlCapabilities">
  <param name="climateControlCapabilities" type="ClimateControlCapabilities" mandatory="false" minsize="1" maxsize="100" array="true">
    <description>
      If included, the platform supports RC climate controls.
      For this baseline version, maxsize=1. i.e. only one climate control module is supported.
    </description >
  </param>
  <param name="radioControlCapabilities" type="RadioControlCapabilities" mandatory="false" minsize="1" maxsize="100" array="true">
    <description>
      If included, the platform supports RC radio controls.
      For this baseline version, maxsize=1. i.e. only one radio control module is supported.
    </description >
  </param>
  <param name="buttonCapabilities" type="ButtonCapabilities"  mandatory="false" minsize="1" maxsize="100" array="true" >
    <description>If included, the platform supports RC button controls with the included button names.</description >
  </param>  
</struct>
```

- A new appHMIType: REMOTE_CONTROL is added: all and any remote-control applications must register with this type. The appHMIType is not exclusive, if an app wants to change radio settings, it shall register as both a MEDIA and a REMOTE_CONTROL type application.

- The work flow of a remote control application is the same as existing applications. A RC application need to register with the system, be launched by driver via HMI or voice control. The app shall send a request for vehicle's RC capabilities to get a list of controllable RC modules available. Then it can start to read or change RC module settings.

- API to read RC module status data. A RC application needs to send one request per RC module to read data from multiple modules.
```xml
  <function name="GetInteriorVehicleData" functionID="GetInteriorVehicleDataID" messagetype="request">
    <param name="moduleType" type="ModuleType">
      <description>
        The type of a RC module to retrieve module data from the vehicle.
        In the future, this should be the Identification of a module.
      </description>
    </param>
    <param name="subscribe" type="Boolean" mandatory="false" defvalue="false">
      <description>
        If subscribe is true, the head unit will register onInteriorVehicleData notifications for the requested moduelType.
        If subscribe is false, the head unit will unregister onInteriorVehicleData notifications for the requested moduelType.
      </description>
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
    <param name="isSubscribed" type="Boolean" mandatory="false" >
      <description>
       It is a conditional-mandatory parameter: must be returned in case "subscribe" parameter was present in the related request.
       if "true" - the "moduleType" from request is successfully subscribed and the head unit will send onInteriorVehicleData notifications for the moduleType.
       if "false" - the "moduleType" from request is either unsubscribed or failed to subscribe.
     </description>
   </param>
  </function>
```

- API to change RC module settings.
```xml
  <function name="SetInteriorVehicleData" functionID="SetInteriorVehicleDataID" messagetype="request">
    <param name="moduleData" type="ModuleData">
      <description>The module data to set for the requested RC module.</description>
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

  <function name="ButtonPress" functionID="ButtonPressID" messagetype="request">
    <param name="moduleType" type="ModuleType">
      <description>The module where the button should be pressed</description>
    </param>
    <param name="buttonName" type="ButtonName">
      <description>The name of supported RC climate or radio button.</description>
    </param>
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
      </param>
      <param name="info" type="String" maxlength="1000" mandatory="false">
      </param>
      <param name="success" type="Boolean" platform="documentation">
      <description> true if successful; false, if failed </description>
    </param>
  </function>
```

- API to subscribe RC module status/setting change notifications. See parameter subscribe and isSubscribed in the above GetInteriorVehicleData RPC.

- API to unsubscribe RC module status/setting change notifications. See parameter subscribe and isSubscribed in the above GetInteriorVehicleData RPC.

- Basic app authorization support, i.e. the policy that control which app can access which type(s) of remote control module.
- RC applications can control all available RC modules of the vehicle if the policy allows.
- One connected mobile device.
- Assumption that the app want to perform the control immediately at the time when a control request is issued.
- Assumption that the app want to lock the RC module to control while the app is running. It is easy to extend the RPCs (SetInteriorVehicleData and ButtonPress) with an additional parameter to indicate the app does or does not want to lock the resource.

### The following features are not considered in this baseline proposal

- App authentication (SDL has it already for Mobile Navigation apps)
- Full app authorization policy control, i.e. which app can access which remote control module(s) and which control items within each module, the full RC app policy control relies on a good zone or location scheme to identify a module, which is not covered in this baseline proposal.
- Encryption
- RC status notifications (indicates whether an app has the control of a RC module, useful when the system revoke the access right and allow other apps to control the same module )
- Permission change notifications (due to policy update or driver grant/revoke permission for an app, SDL has it for generic apps)
- Additional RC modules (HMI settings, power seat control, windows control, lights control, etc.) or additional control items in climate and radio control
- RC resource management regarding how multiple apps access the same RC module with additional requirements, for example "add to queue mode". That should be another proposal.

### Compared to the current implementation in the RC feature branch, the following sub-features are removed/changed/added

- Remove the concept and the usage of resource zones, including the equipment configuration resource policy. The lack of zones and ID schemes implies that all RC modules belongs to 1 zone.
- Remove the concept and implementation of device location.
- Remove the concept and implementation of driver vs passenger device, and only allow one RC device.
- Continue group available controllable items into RC modules by functionality. Each module can have a short friendly name. However, this name shall not be used to parse and identify a module by mobile apps. It is just a friendly name. This proposal does not define how to ID a resource if there are multiple resource of the same type. This leaves the room for later zone related proposal to address the issue of how to identify of a RC module.
- Provide new RemoteControlCapabilities data structure, which includes specific controllable items in each module
- Add NONE to defrost zone.
- Remove ModuleDescription, since it (zone+moduleType) is the identification of a module.
- Remove OnDeviceLocationChanged notifications.
- Remove OnDeviceRankChanged notifications.
- OnHMIStatus does not contain deviceRank.
- Add basic policy support i.e. the policy that control which app can access which type(s) of remote control module.

SDL policy already supports the function group that configures which application can access which RPC and which vehicle data, such as gps, deviceStatus, tirePressure, fuelLevel and so on. Similarly, SDL policy shall support the configuration on which application can access which type(s) of remote control module and potentially which control items within the module in vehicle. For example, some applications can only control radio, some applications can only control climate, some applications can control both radio and climate and other applications cannot do RC at all. SDL shall check the policy configurations regarding which type(s) of remote control module can be accessed by a RC application.

- Keep and re-purpose GetInteriorVehicleDataConsent request and response to ask driver's permission of control a RC module.
- Change OnReverseAppsAllowing to OnRemoteControlSettings API. SDL shall support the feature to allow the driver to turn on/off remote control feature as a whole. By default SDL-RC allows RC application to use remote control feature. However, the driver can disable the feature via HMI. In the existing implementation, for passenger's device, this can be achieved by OnReverseAppsAllowing(allowed: true or false) API between SDL and the HMI. We rename OnReverseAppsAllowing to OnRemoteControlSettings, and add more parameters to this API to allow other driver configurable settings.
- 1. If the driver turns on or off the remote control, the HMI shall send OnRemoteControlSettings (allowed: true or false) system notification to SDL. The HMI shall also send a notification with initial value on system start. The default value in SDL is true.
- 2. If the driver changes remote control access mode settings via the HMI, the HMI shall send an OnRemoteControlSettings (“accessMode”) to SDL. Available setting options are: auto (always) allow, auto (always) deny, ask driver. The HMI shall also send a notification with initial value on system start. The default value in SDL is allow.

```xml
<function name="OnRemoteControlSettings" messagetype="notification">
  <description>Sender: vehicle -> RSDL. Notification about remote-control settings changed. Sent after user changes settings through HMI.</description>
  <param name="allowed" type="Boolean" mandatory="false" >
    <description>If "true" - RC is allowed; if "false" - RC is disallowed.</description>
  </param>
  <param name="accessMode" type="RCAccessMode" mandatory="false" >
    <description>The the remote control access mode specified by the driver via HMI. The default setting is "auto allow". </description>
  </param>
</function>
```


The first control request message (SetInteriorVehicleData and ButtonPress) with a specific RC module will trigger SDL to perform RC resource allocation process. SDL RC shall support re-allocate/revoke access right without the driver closing all the RC applications. The coding of this RC resource allocation process shall be upgradable in the future without major code infrastructure revision.

Similar to how the system manage media application accessing the audio streaming resource, a simple RC resource allocation rule can be "A foreground running RC app can obtain and lock the RC access right to a RC module until the app exits or the driver launches another RC app that controls the same RC module." In order to allow a background app be able to perform remote control, we add a user configurable RC settings - RCAccessMode and corresponding HMI-SDL API. Consider the case in which there is a running RC app that has the right to control a RC module type, another RC app wants to control the same RC module, depending on the RCAccessMode setting, the system will do differently.

```xml
<enum name="RCAccessMode">
  <description>Enumeration that describes possible remote control access mode the application might be in on HU.</description>
  <element name="AUTO_ALLOW">
    <description>
      The system shall revoke the RC access right of the current app,
      and allows the new app's request to access the same RC module to do the remote control.
      This is exactly how the system deal with media apps for audio streaming.
    </description>
  </element>
  <element name="AUTO_DENY">
    <description>
      The system keep the access right of the current app,
      and denies the new app's request to access the same RC module.
      This allows a background RC app keep controlling a RC module.
    </description>
  </element>
  <element name="ASK_DRIVER">
      <description>SDL shall send GetInteriorVehicleDataConsent to HMI to trigger a pop up and ask the driver's decision.</description>
  </element>
</enum>
```

The RC resource allocation/management rule is shown in the following table.

| Requesting Application state | Requested module status |  RC setting - Access mode | Expected SDL action  |
| ---------- | ------ | ---------- | -----------------------------------  |
| any        | free   | any        | **allow**      |
| background | in use | any        | **disallow**   |
| foreground | in use | auto allow | **allow**      |
| foreground | in use | auto deny  | **disallow**   |
| foreground | in use | ask driver | **ask driver** for permission |
| any        | busy   | any        | **disallow**   |

- "background" mean HMI level BACKGROUND or LIMITED.
- "free" means no applications currently hold the access to the requested resource.
- "in use" means the requested resource currently can be controlled/held by an application.
- "busy" means at least one RC RPC request is currently executing, and has not finished yet.
- This proposal assumes the RC app want to obtain the access to a RC module and hold it. It is easy to extend the RPC to indicate the app does not want to lock the resource, in that case the module status will change from free to busy when a SetInteriorVehicleData or ButtonPress with a RC button is in processing, and back to free when the processing is done.





### Mobile API changes

The changes are listed below.
```xml
<enum name="SystemCapabilityType">
         ....
    <element name="BUTTON"/>
    <element name="REMOTE_CONTROL"/>
</enum>

<struct name="SystemCapability">
    <description>
      The systemCapabilityType indicates which type of data should be changed and identifies which data object exists in this struct.
      For example, if the SystemCapability Type is NAVIGATION then a "navigationCapability" should exist
    </description>
    <param name="systemCapabilityType" type="SystemCapabilityType" mandatory="true">
    </param>
         ...
    <param name="remoteControlCapability" type="RemoteControlCapabilities" mandatory="false">
    </param>
    <param name="buttonCapability" type="ButtonCapabilities" mandatory="false">
    </param>
</struct>

<struct name="RemoteControlCapabilities">
  <param name="climateControlCapabilities" type="ClimateControlCapabilities" mandatory="false" minsize="1" maxsize="100" array="true">
    <description>
      If included, the platform supports RC climate controls.
      For this baseline version, maxsize=1. i.e. only one climate control module is supported.
    </description >
  </param>
  <param name="radioControlCapabilities" type="RadioControlCapabilities" mandatory="false" minsize="1" maxsize="100" array="true">
    <description>
      If included, the platform supports RC radio controls.
      For this baseline version, maxsize=1. i.e. only one radio control module is supported.
    </description >
  </param>
</struct>

<enum name="ButtonName">
      <description>Defines the hard (physical) and soft (touch screen) buttons available from SYNC</description>
        <!-- Existing Buttons not listed here -->
        ...
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
    <!-- need an ID in the future -->
    <param name="moduleName" type="String" maxlength="100">   
      <description>
        The short friendly name of the climate control module. 
        It should not be used to identify a module by mobile application.
      </description>
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
    <!-- need an ID in the future -->
    <param name="moduleName" type="String" maxlength="100">   
      <description>
        The short friendly name of the climate control module. 
        It should not be used to identify a module by mobile application.
      </description>
    </param> 
    <param name="radioEnableAvailable" type="Boolean" mandatory="false">
      <description>
        Availability of the control of enable/disable radio.
        True: Available, False: Not Available, Not present: Not Available.
      </description>
    </param>
    <param name="radioBandAvailable" type="Boolean" mandatory="false">
      <description>
        Availability of the control of radio band.
        True: Available, False: Not Available, Not present: Not Available.
      </description>
    </param>
    <param name="radioFrequencyAvailable" type="Boolean" mandatory="false">
      <description>
        Availability of the control of radio frequency.
        True: Available, False: Not Available, Not present: Not Available.
      </description>
    </param>
    <param name="hdChannelAvailable" type="Boolean" mandatory="false">
      <description>
        Availability of the control of HD radio channel.
        True: Available, False: Not Available, Not present: Not Available.
      </description>
    </param>
    <param name="rdsDataAvailable" type="Boolean" mandatory="false">
      <description>
        Availability of the getting Radio Data System (RDS) data.
        True: Available, False: Not Available, Not present: Not Available.
      </description>
    </param>
    <param name="availableHDsAvailable" type="Boolean" mandatory="false">
      <description>
        Availability of the getting the number of available HD channels.
        True: Available, False: Not Available, Not present: Not Available.
      </description>
    </param>
    <param name="stateAvailable" type="Boolean" mandatory="false">
      <description>
        Availability of the getting the Radio state.
        True: Available, False: Not Available, Not present: Not Available.
      </description>
    </param>
    <param name="signalStrengthAvailable" type="Boolean" mandatory="false">
      <description>
        Availability of the getting the signal strength.
        True: Available, False: Not Available, Not present: Not Available.
      </description>
    </param>
    <param name="signalChangeThresholdAvailable" type="Boolean" mandatory="false">
      <description>
        Availability of the getting the signal Change Threshold.
        True: Available, False: Not Available, Not present: Not Available.
      </description>
    </param>
  </struct>

  <struct name="ModuleDescription">
    <!-- module id is needed in the future -->
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
    <param name="value" type="Float">
      <description>Temperature Value in TemperatureUnit specified unit. Range depends on OEM and is not checked by SDL.</description>
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
    <param name="radioControlData" type="RadioControlData" mandatory="false">
    </param>
    <param name="climateControlData" type="ClimateControlData" mandatory="false">
    </param>
  </struct>


  <function name="GetInteriorVehicleData" functionID="GetInteriorVehicleDataID" messagetype="request">
    <param name="moduleType" type="ModuleType">
      <description>
        The type of a RC module to retrieve module data from the vehicle.
        In the future, this should be the Identification of a module.
      </description>
    </param>
    <param name="subscribe" type="Boolean" mandatory="false" defvalue="false">
      <description>
        If subscribe is true, the head unit will register onInteriorVehicleData notifications for the requested moduelType.
        If subscribe is false, the head unit will unregister onInteriorVehicleData notifications for the requested moduelType.
      </description>
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
    <param name="isSubscribed" type="Boolean" mandatory="false" >
      <description>
       It is a conditional-mandatory parameter: must be returned in case "subscribe" parameter was present in the related request.
       if "true" - the "moduleType" from request is successfully subscribed and the head unit will send onInteriorVehicleData notifications for the moduleType.
       if "false" - the "moduleType" from request is either unsubscribed or failed to subscribe.
     </description>
   </param>
  </function>

  <function name="SetInteriorVehicleData" functionID="SetInteriorVehicleDataID" messagetype="request">
    <param name="moduleData" type="ModuleData">
      <description>The module data to set for the requested RC module.</description>
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

  <function name="ButtonPress" functionID="ButtonPressID" messagetype="request">
    <param name="moduleType" type="ModuleType">
      <description>The module where the button should be pressed</description>
    </param>
    <param name="buttonName" type="ButtonName">
      <description>The name of supported RC climate or radio button.</description>
    </param>
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
          ...
    <!-- new additions -->
    <element name="REMOTE_CONTROL" />
  </enum>

```

### HMI  API changes

The changes are similar to mobile api changes, they are  listed here.
```xml
<!-- existing with updates -->
<!-- add whether buttons can be pressed via Buttons.GetCapabilities -->
<interface name="Buttons" >
    <function name="ButtonPress" messagetype="request">
      <description>Method is invoked when the application tries to press a button</description>

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

<interface name="Common">
  <enum name="ButtonName">
      <description>Defines the hard (physical) and soft (touchscreen) buttons available from SYNC</description>
       ...
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
      ...
    <element name="REMOTE_CONTROL" />
  </enum>

<!-- new additions -->

<enum name="ModuleType">
  <element name="CLIMATE"/>
  <element name="RADIO"/>
</enum>

<enum name="RadioBand">
  <element name="AM"/>
  <element name="FM"/>
  <element name="XM"/>
</enum>

<enum name="TemperatureUnit">
  <element name="FAHRENHEIT"/>
  <element name="CELSIUS"/>
</enum>

<struct name="Temperature">
  <param name="unit" type="TemperatureUnit">
      <description>Temperature Unit</description>
  </param>
  <param name="value" type="Float">
      <description>The temperature value is in TemperatureUnit specified unit.</description>
  </param>
</struct>

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
  <element name="NONE"/>
</enum>

<enum name="VentilationMode">
  <element name="UPPER"/>
  <element name="LOWER"/>
  <element name="BOTH"/>
  <element name="NONE"/>
</enum>

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
  <param name="moduleType" type="Common.ModuleType">
  </param>
  <param name="radioControlData" type="Common.RadioControlData" mandatory="false">
  </param>
  <param name="climateControlData" type="Common.ClimateControlData" mandatory="false">
  </param>
</struct>

<struct name="ClimateControlCapabilities">
    <description>Contains information about a climate control module's capabilities.</description>

    <!-- need an ID in the future -->
    <param name="moduleName" type="String" maxlength="100">   
      <description>
        The short friendly name of the climate control module. 
        It should not be used to identify a module by mobile application.
      </description>
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
  <struct name="RadioControlCapabilities">
    <description>Contains information about a radio control module's capabilities.</description>
    <!-- need an ID in the future -->
    <param name="moduleName" type="String" maxlength="100">   
      <description>
        The short friendly name of the climate control module. 
        It should not be used to identify a module by mobile application.
      </description>
    </param>
    <param name="radioEnableAvailable" type="Boolean" mandatory="false">
      <description>
        Availability of the control of enable/disable radio.
        True: Available, False: Not Available, Not present: Not Available.
      </description>
    </param>
    <param name="radioBandAvailable" type="Boolean" mandatory="false">
      <description>
        Availability of the control of radio band.
        True: Available, False: Not Available, Not present: Not Available.
      </description>
    </param>
    <param name="radioFrequencyAvailable" type="Boolean" mandatory="false">
      <description>
        Availability of the control of radio frequency.
        True: Available, False: Not Available, Not present: Not Available.
      </description>
    </param>
    <param name="hdChannelAvailable" type="Boolean" mandatory="false">
      <description>
        Availability of the control of HD radio channel.
        True: Available, False: Not Available, Not present: Not Available.
      </description>
    </param>
    <param name="rdsDataAvailable" type="Boolean" mandatory="false">
      <description>
        Availability of the getting Radio Data System (RDS) data.
        True: Available, False: Not Available, Not present: Not Available.
      </description>
    </param>
    <param name="availableHDsAvailable" type="Boolean" mandatory="false">
      <description>
        Availability of the getting the number of available HD channels.
        True: Available, False: Not Available, Not present: Not Available.
      </description>
    </param>
    <param name="stateAvailable" type="Boolean" mandatory="false">
      <description>
        Availability of the getting the Radio state.
        True: Available, False: Not Available, Not present: Not Available.
      </description>
    </param>
    <param name="signalStrengthAvailable" type="Boolean" mandatory="false">
      <description>
        Availability of the getting the signal strength.
        True: Available, False: Not Available, Not present: Not Available.
      </description>
    </param>
    <param name="signalChangeThresholdAvailable" type="Boolean" mandatory="false">
      <description>
        Availability of the getting the signal Change Threshold.
        True: Available, False: Not Available, Not present: Not Available.
      </description>
    </param>
  </struct>

  <struct name="RemoteControlCapabilities">
    <param name="climateControlCapabilities" type="ClimateControlCapabilities" mandatory="false" minsize="1" maxsize="100" array="true">
      <description>If included, the platform supports RC climate controls. For this baseline version, maxsize=1. i.e. only one climate control module is supported.</description >
    </param>
    <param name="radioControlCapabilities" type="RadioControlCapabilities" mandatory="false" minsize="1" maxsize="100" array="true">
      <description>If included, the platform supports RC radio controls. For this baseline version, maxsize=1. i.e. only one climate control module is supported.</description >
    </param>
    <param name="buttonCapabilities" type="ButtonCapabilities"  mandatory="false" minsize="1" maxsize="100" array="true" >
      <description>If included, the platform supports RC button controls with the included button names.</description >
    </param>
  </struct>
</interface>

<interface name="RC" >
  <function name="GetCapabilities" messagetype="request">
    <description>Method is invoked at system startup by SDL to request information about Remote Control capabilities of HMI.</description>
  </function>
  <function name="GetCapabilities" messagetype="response">
    <param name="remoteControlCapabilities" type="Common.RemoteControlCapabilities" mandatory="false">
      <description>See RemoteControlCapabilities, all available RC modules and buttons shall be returned.</description>
    </param>
  </function>

  <function name="SetInteriorVehicleData" functionID="SetInteriorVehicleDataID" messagetype="request">
    <param name="moduleData" type="Common.ModuleData">
      <description>The module type and data to set</description>
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
    <param name="moduleType" type="Common.ModuleType">
      <description>The module data to retrieve from the vehicle for that type</description>
    </param>
    <param name="subscribe" type="Boolean" mandatory="false" defvalue="false">
      <description>If subscribe is true, the head unit will send onInteriorVehicleData notifications for the module type</description>
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
      if "true" - the "moduleType" from request is successfully subscribed and  the head unit will send onInteriorVehicleData notifications for the moduleDescription.
      if "false" - the "moduleType" from request is either unsubscribed or failed to subscribe.</description>
    </param>
  </function>
  <function name="GetInteriorVehicleDataConsent" messagetype="request">
    <description>Sender: SDL->HMI. </description>
    <description>HMI is expected to display a permission prompt to the driver showing the RC module and app details (for example, app's name). The driver is expected to have an ability to grant or deny the permission.</description>
    <param name="moduleType" type="Common.ModuleType" mandatory="true">
      <description>The module type that the app requests to control.</description>
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

<enum name="RCAccessMode">
  <description>Enumeration that describes possible remote control access mode the application might be in on HU.</description>
  <element name="AUTO_ALLOW"/>
  <element name="AUTO_DENY"/>
  <element name="ASK_DRIVER"/>
</enum>

<function name="OnRemoteControlSettings" messagetype="notification">
  <description>Sender: vehicle -> RSDL. Notification about remote-control settings changed. Sent after User`s choice through HMI.</description>
  <param name="allowed" type="Boolean" mandatory="false" >
    <description>If "true" - RC is allowed; if "false" - RC is disallowed.</description>
  </param>
  <param name="accessMode" type="RCAccessMode" mandatory="false" >
    <description>The remote control access mode specified by the driver via HMI.</description>
  </param>
</function>

</interface>
```

## Potential downsides

- RPC messages are not encrypted. Attackers may try to eavesdrop and spoof wireless communication. For example in a replay attack, attackers record and then replay the “electro magnetic waves”.

- It can only subscribe to all radio or climate control data, cannot subscribe to individual item change notifications.

- How to ID a RC module is not defined.

- It lacks the fine policy control on which application can access which RC module(s) and which control item(s) within each module.

## Impact on existing code

SDL core code, android and iOS mobile libs and RPC need updates.

## Alternatives considered

None.
