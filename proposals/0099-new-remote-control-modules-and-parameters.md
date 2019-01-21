# New remote control modules (LIGHT, AUDIO, HMI_SETTINGS) and parameters (SIS Data)

* Proposal: [SDL-0099](0099-new-remote-control-modules-and-parameters.md)
* Author: [Zhimin Yang](https://github.com/yang1070)
* Status: **Accepted with Revisions**
* Impacted Platforms: [Core / iOS / Android / RPC]

## Introduction

SDL remote control provides the ability for mobile applications to control certain components of the vehicle, such as, tune the radio, set the desired temperature or change the fan speed. However, currently only `CLIMATE` and `RADIO` modules are available for remote-control. Mobile application developers need more than basic climate or radio control. To meet developers' requirements, we propose to add three new modules (`AUDIO`, `LIGHT`, `HMI_SETTINGS`) and some new parameters (heatedXXXEnable and radio sisData) to the existing `CLIMATE` and `RADIO` modules respectively. This proposal only defines new data types and new parameters added to the existing data types. It does not add or change any remote control RPCs.

## Motivation

Mobile application developers would like to develop applications that take full advantage of the capability that the vehicle provides. There are many cases that mobile application developers ask for new functions of SDL remote control. For example,

- Some mobile navigation applications would like to use the same distance unit and day/night display mode as the infotainment system does.

- Some climate control applications want to control more elements in climate control, such as heated windshield, heated rear window, heated steering wheel and heated mirrors if the vehicle has them installed.

- Some media applications want to use the existing radio/CD/DVD installed in vehicle, choose from the available audio sources, and switch audio source between in-vehicle radio and mobile application (internet radio) when necessary.

- Some light control applications want to change the ambient lights of the vehicle and/or turn on/off certain exterior lights (while the vehicle is in parking).

- Some radio control applications need more than the traditional RDS data, they need HD radio status data (especially the station id in the SIS data).


## Proposed solution

As usual, the remote control mobile applications use the following RPCs
- `GetSystemCapability` with `SystemCapabilityType=REMOTE_CONTROL` to read available control modules and available control items within each module;
- `GetInteriorVehicleData` to read the current status value of a remote-control module;
- `GetInteriorVehicleData` with `subscribe`=true/false to register/un-register a module's data change notifications;
- `SetInteriorVehicleData` to change the settings/status of a remote-control module;
- `OnInteriorVehicleData` to receive any remote-control module value change notifications;

In addition, in a GetInteriorVehicleData response or OnInteriorVehicleData notifications, an `xyzmoduleControlData` indicates the current value of the module status; in SetInteriorVehicleData request, an `xyzmoduleControlData` indicates the required target state of the module.

#### Add three new module types to the existing module list.
| RC Module |
| --------- |
| Audio |
| Light |
| HMI Settings |

#### For "AUDIO" remote-control mobile application will be able to READ and SET:

| Control Item | Value Range |Type | Comments |
| ------------ |------------ | ------------ | ------------ |
| Audio volume | 0%-100%| Get/Set/Notification | The audio source volume level |
| Audio Source | MOBILE_APP, RADIO_TUNER, CD, BLUETOOTH, USB, etc. see PrimaryAudioSource| Get/Set/Notification | defines one of the available audio sources |
| keep Context | true, false| Set only | control whether HMI shall keep current application context or switch to default media UI/APP associated with the audio source|
| Equilizer Settings | Struct {Channel ID as integer, Channel setting as 0%-100%} | Get/Set/Notification | Defines the list of supported channels (band) and their current/desired settings on HMI

Any remote control applications can read the current audio data. A RC and media application can set audio source to either itself (with target `MOBILE_APP`) or other system sources. It CANNOT set audio source to other mobile applications. When a mobile application sends a SetInteriorVehicleData request to change the audio source from MOBILE_APP to other types of audio source without `keepContext` parameter or with `keepContext=false`, after the system successfully executes the request, the application will go to HMI level 'BACKGROUND'. If in the same request `keepContext`=true, the system shall not change this application's HMI level.

We recommend that SDL does not block audio source changing requests depending on HMI level. However, we recommend that HMI disallow applications running in background change the audio source in order to (1) prevent the application from stealing the audio, and (2) reduce confusion to the driver.  This restriction means (media and remote control type) applications running in HMI level `FULL` or `LIMITED` (already has access to audio) can change the audio source. Applications in HMI level `NONE` or `BACKGROUND` are not allowed to change the audio source. Instead, if an application running in `BACKGROUND` wants to switch the audio source from others to itself, the application shall send an `alert` with at least "yes" and "no" soft buttons to notify the driver the intention to change the audio source, and set value `STEAL_FOCUS` (the system shall bring the application to foreground and set audio source to this media application) as the `SystemAction` of the "yes" soft button, so that the driver can click the soft button to confirm the switch.

If the target audio source is `RADIO_TUNER`, the system shall turn on the radio and start playing with the last used band (AM|FM|XM) and frequency or station. For an example, if a media and remote-control application running in `FULL` want to switch the audio source from itself to radio and tune to a specified band and frequency (not last used band and frequency), it shall do two SetInteriorVehicleData RPC calls. The first one has `AUDIO` as targeted module type, `RADIO_TUNER` as the new audio `source` and `keepContext`=true. The second one has `RADIO` as targeted module type, and include `band`=`AM|FM|XM` and corresponding desired frequency parameters.

#### For "HMI Setting" remote-control mobile application will be able to READ and SET:
| Control Item | Value Range |Type | Comments |
| ------------ |------------ | ------------ | ------------ |
| Display Mode | DAY, NIGHT, AUTO | Get/Set/Notification | Current display mode of the HMI display |
| Distance Unit | MILES, KILOMETERS | Get/Set/Notification | Distance Unit used in the HMI (for maps/tracking distances) |
| Temperature Unit | FAHRENHEIT, CELSIUS | Get/Set/Notification | Temperature Unit used in the HMI (for temperature measuring systems) |

`AUTO` display mode is set only. The driver can set the display mode as `DAY`, `NIGHT` or `AUTO` via HMI or a mobile application. However, the current mode used by the HMI is either `DAY` or `NIGHT`. GetInteriorVehicleData of HMI_SETTINGS module type shall return the current value of the display mode used in HMI, not the current settings. 

If the driver or other applications change the display mode in the HMI settings, the system shall send notifications with the current display mode to all mobile RC applications that are subscribed to the HMI settings. 

If the HMI changes the display mode (due to time, ambient light or any reasons), the system shall send notifications with the current display mode to all mobile RC applications that are subscribed to the HMI settings.

#### For "LIGHT" remote-control, mobile application will be able to READ and SET:
| Control Item | Value Range |Type | Comments |
| ------------ |------------ | ------------ | ------------ |
| Light Status | ON, OFF| Get/Set/Notification | turn on/off a single light or all lights in a group |
| Light Density | float 0.0-1.0| Get/Set/Notification | change the density/dim a single light or all lights in a group|
| Light Color | RGB color| Get/Set/Notification | change the color scheme of a single light or all lights in a group|

The basic idea is to divide vehicle lights into groups by common functions (or by locations). Please see LightName data type for possible supported lights. A mobile application can send a remote control command to turn on or off an individual light or turn on/off all the lights within a group. The application can also get the current status of each and every light group as well as receive notifications once the status of any light or light group changes. 

#### In addition to existing "RADIO" control items, remote-control mobile applications will be able to READ :
| Control Item | Value Range |Type | Comments |
| ------------ |------------ | ------------ | ------------ |
| HD radio SIS data | see sisData type| Get,Notification | read only HD radio SIS data |

Like Radio Data System (RDS) is a communications protocol standard for embedding small amounts of digital information in conventional FM radio broadcasts, Station Information Service (SIS) data (described in NRSC-5-C and NRSC-4-B and http://www.nrscstandards.org/documentArchive/NRSC-5-A%202005/1020sEb.pdf) provides basic information for HD radio about the station such as call sign, as well as information not displayable to the consumer such as the station identification number.

#### In addition to existing "CLIMATE" control items, remote-control mobile applications will be able to READ and SET :
| Control Item | Value Range |Type | Comments |
| ------------ |------------ | ------------ | ------------ |
| heated windshield | true, false| Get/Set/Notification | true means ON, false means OFF |
| heated rear window | true, false| Get/Set/Notification | true means ON, false means OFF |
| heated steering wheel | true, false| Get/Set/Notification | true means ON, false means OFF |
| heated mirrors | true, false| Get/Set/Notification | true means ON, false means OFF |

### Mobile API XML changes
The changes are listed below.
```xml
  <enum name="ModuleType">
    :
    :
    <element name="AUDIO"/>
    <element name="LIGHT"/>
    <element name="HMI_SETTINGS"/>
  </enum>
  
  <!-- PrimaryAudioSource is an existing data type-->
  <enum name="PrimaryAudioSource">
    <description>Reflects the current primary audio source (if selected).</description>
    <element name="NO_SOURCE_SELECTED">
    </element>
    <element name="CD">
    </element>
    <element name="BLUETOOTH_STEREO_BTST">
    </element>
    <element name="USB">
    </element>
    <element name="USB2">
    </element>
    <element name="LINE_IN">
    </element>
    <element name="IPOD">
    </element>
    <element name="MOBILE_APP">
    </element>
    <!--new addition--->
    <element name="RADIO_TUNER">
      <description>Radio may be on AM, FM or XM</description>
    </element>
    <!--new addition end--->
  </enum>
```
Add new parameters to CLIMATE.
```xml
  <struct name="ClimateControlCapabilities">
    :
    :
    <param name="heatedSteeringWheelAvailable" type="Boolean" mandatory="false">
      <description>
        Availability of the control (enable/disable) of heated Steering Wheel.
        True: Available, False: Not Available, Not present: Not Available.
      </description>
    </param>
    <param name="heatedWindshieldAvailable" type="Boolean" mandatory="false">
      <description>
        Availability of the control (enable/disable) of heated Windshield.
        True: Available, False: Not Available, Not present: Not Available.
      </description>
    </param>
    <param name="heatedRearWindowAvailable" type="Boolean" mandatory="false">
      <description>
        Availability of the control (enable/disable) of heated Rear Window.
        True: Available, False: Not Available, Not present: Not Available.
      </description>
    </param> 
    <param name="heatedMirrorsAvailable" type="Boolean" mandatory="false">
      <description>
        Availability of the control (enable/disable) of heated Mirrors.
        True: Available, False: Not Available, Not present: Not Available.
      </description>
    </param>      
  </struct>  

  <struct name="ClimateControlData">
    :
    :
    <param name="heatedSteeringWheelEnable" type="Boolean" mandatory="false">
      <description>value false means disabled/turn off, value true means enabled/turn on.</description>
    </param>
    <param name="heatedWindshieldEnable" type="Boolean" mandatory="false">
      <description>value false means disabled, value true means enabled.</description>
    </param>
    <param name="heatedRearWindowEnable" type="Boolean" mandatory="false">
      <description>value false means disabled, value true means enabled.</description>
    </param>    
    <param name="heatedMirrorsEnable" type="Boolean" mandatory="false">
      <description>value false means disabled, value true means enabled.</description>
    </param>
  </struct>
```
Add new a parameter to RADIO.
```xml
  <struct name="RadioControlCapabilities">
    :
    :
    <param name="sisDataAvailable" type="Boolean" mandatory="false">
      <description>
        Availability of the getting HD radio Station Information Service (SIS) data.
        True: Available, False: Not Available, Not present: Not Available.
      </description>
    </param>
  </struct> 
  
  <struct name="StationIDNumber">
    <param name="countryCode" type="Integer" minvalue="0" maxvalue="999"  mandatory="false">
      <description>Binary Representation of ITU Country Code. USA Code is 001.</description>
    </param>
    <param name="fccFacilityId" type="Integer" minvalue="0" maxvalue="999999"  mandatory="false">
      <description>Binary representation  of unique facility ID assigned by the FCC; FCC controlled for U.S. territory</description>
    </param>
  </struct>

  <struct name="SisData">
    <param name="stationShortName" type="String" minlength="4" maxlength="7"  mandatory="false">
      <description>Identifies the 4-alpha-character station call sign plus an optional (-FM) extension</description>
    </param>
    <param name="stationIDNumber" type="StationIDNumber"  mandatory="false">
      <description>Used for network Application. Consists of Country Code and FCC Facility ID.</description>
    </param>
    <param name="stationLongName" type="String" minlength="0" maxlength="56"  mandatory="false">
      <description>Identifies the station call sign or other identifying information in the long format.</description>
    </param>
    <param name="stationLocation" type="GPSData" mandatory="false">
      <description>Provides the 3-dimensional geographic station location.</description>
    </param>
    <param name="stationMessage" type="String" minlength="0" maxlength="56"  mandatory="false">
      <description>May be used to convey textual information of general interest to the consumer such as weather forecasts or public service announcements. Includes a high priority delivery feature to convey emergencies that may be in the listening area.</description>
    </param>
  </struct>

    
  <struct name="RadioControlData">
    :
    :
    <param name="sisData" type="SisData" mandatory="false">
      <description>Read-only Station Information Service (SIS) data provides basic information about the station such as call sign, as well as information not displayable to the consumer such as the station identification number</description>
    </param>
  </struct>
```
New AUDIO data types.
```xml
  <struct name="AudioControlCapabilities">
    <param name="moduleName" type="String" maxlength="100" mandatory="true">
      <description>
      The short friendly name of the light control module.
      It should not be used to identify a module by mobile application.
      </description>
    </param>
    <param name="sourceAvailable" type="Boolean" mandatory="false">
      <description>Availability of the control of audio source. </description>
    </param>
    <param name="keepContextAvailable" type="Boolean" mandatory="false"> 
      <description>Availability of the keepContext parameter. </description> 
    </param>
    <param name="volumeAvailable" type="Boolean" mandatory="false">
      <description>Availability of the control of audio volume.</description>
    </param>
    <param name="equalizerAvailable" type="Boolean" mandatory="false">
      <description>Availability of the control of Equalizer Settings.</description>
    </param>
    <param name="equalizerMaxChannelId" type="Integer" minvalue="1" maxvalue="100" mandatory="false">
      <description>Must be included if equalizerAvailable=true, and assume all IDs starting from 1 to this value are valid</description>
    </param>
  </struct>
  
  <struct name="EqualizerSettings">
    <description>Defines the each Equalizer channel settings.</description>
    <param name="channelId" type="Integer" minvalue="1" maxvalue="100" mandatory="true"></param>
    <param name="channelName" type="String" mandatory="false" maxlength="50">
            <description>Read-only channel / frequency name (e.i. "Treble, Midrange, Bass" or "125 Hz")</description>
    </param>
    <param name="channelSetting" type="Integer" minvalue="0" maxvalue="100" mandatory="true">
      <description>Reflects the setting, from 0%-100%.</description>
    </param>
  </struct>
    
  <struct name="AudioControlData">
    <param name="source" type="PrimaryAudioSource" mandatory="false">
      <description>
      In a getter response or a notification, it is the current primary audio source of the system.
      In a setter request, it is the target audio source that the system shall switch to.
      If the value is MOBILE_APP, the system shall switch to the mobile media app that issues the setter RPC.
      </description>
    </param>
    <param name="keepContext" type="Boolean" mandatory="false">
      <description>
      This parameter shall not be present in any getter responses or notifications.
      This parameter is optional in a setter request. The default value is false if it is not included.
      If it is false, the system not only changes the audio source but also brings the default application or
      system UI associated with the audio source to foreground.
      If it is true, the system only changes the audio source, but keeps the current application in foreground.
      </description>
    </param>
    <param name="volume" type="Integer" mandatory="false" minvalue="0" maxvalue="100">
      <description>Reflects the volume of audio, from 0%-100%.</description>
    </param>
    <param name="equalizerSettings" type="EqualizerSettings" minsize="1" maxsize="100" mandatory="false" array ="true">
        <description>Defines the list of supported channels (band) and their current/desired settings on HMI</description>
    </param>
  </struct>
```
New LIGHT data types.
```xml
  <enum name="LightName">
    <!-- Common Single Light 0~500 -->
    <element name="FRONT_LEFT_HIGH_BEAM" value="0"/>
    <element name="FRONT_RIGHT_HIGH_BEAM" value="1"/>
    <element name="FRONT_LEFT_LOW_BEAM" value="2"/>
    <element name="FRONT_RIGHT_LOW_BEAM" value="3"/>
    <element name="FRONT_LEFT_PARKING_LIGHT" value="4"/>
    <element name="FRONT_RIGHT_PARKING_LIGHT" value="5"/>
    <element name="FRONT_LEFT_FOG_LIGHT" value="6"/>
    <element name="FRONT_RIGHT_FOG_LIGHT" value="7"/>
    <element name="FRONT_LEFT_DAYTIME_RUNNING_LIGHT" value="8"/>
    <element name="FRONT_RIGHT_DAYTIME_RUNNING_LIGHT" value="9"/>
    <element name="FRONT_LEFT_TURN_LIGHT" value="10"/>
    <element name="FRONT_RIGHT_TURN_LIGHT" value="11"/>
    <element name="REAR_LEFT_FOG_LIGHT" value="12"/>
    <element name="REAR_RIGHT_FOG_LIGHT" value="13"/>
    <element name="REAR_LEFT_TAIL_LIGHT" value="14"/>
    <element name="REAR_RIGHT_TAIL_LIGHT" value="15"/>
    <element name="REAR_LEFT_BRAKE_LIGHT" value="16"/>
    <element name="REAR_RIGHT_BRAKE_LIGHT" value="17"/>
    <element name="REAR_LEFT_TURN_LIGHT" value="18"/>
    <element name="REAR_RIGHT_TURN_LIGHT" value="19"/>
    <element name="REAR_REGISTRATION_PLATE_LIGHT" value="20"/>

    <!-- Exterior Lights by common function groups 501~800 -->
    <element name="HIGH_BEAMS" value="501">
      <description>Include all high beam lights: front_left and front_right.</description>
    </element>
    <element name="LOW_BEAMS" value="502">
      <description>Include all low beam lights: front_left and front_right.</description>
    </element>
    <element name="FOG_LIGHTS" value="503">
      <description>Include all fog lights: front_left, front_right, rear_left and rear_right.</description>
    </element>
    <element name="RUNNING_LIGHTS" value="504">
      <description>Include all daytime running lights: front_left and front_right.</description>
    </element>
    <element name="PARKING_LIGHTS" value="505">
      <description>Include all parking lights: front_left and front_right.</description>
    </element>
    <element name="BRAKE_LIGHTS" value="506">
      <description>Include all brake lights: rear_left and rear_right.</description>
    </element>
    <element name="REAR_REVERSING_LIGHTS" value="507"/>
    <element name="SIDE_MARKER_LIGHTS" value="508"/>
    <element name="LEFT_TURN_LIGHTS" value="509">
      <description>Include all left turn signal lights: front_left, rear_left, left_side and mirror_mounted.</description>
    </element>
    <element name="RIGHT_TURN_LIGHTS" value="510">
      <description>Include all right turn signal lights: front_right, rear_right, right_side and mirror_mounted.</description>
    </element>
    <element name="HAZARD_LIGHTS" value="511">
      <description>Include all hazard lights: front_left, front_right, rear_left and rear_right.</description>
    </element>

    <!-- Interior Lights by common function groups 801~900 -->
    <element name="AMBIENT_LIGHTS" value="801"/>
    <element name="OVERHEAD_LIGHTS" value="802"/>
    <element name="READING_LIGHTS" value="803"/>
    <element name="TRUNK_LIGHTS" value="804"/>

    <!-- Lights by location 901~1000-->
    <element name="EXTERIOR_FRONT_LIGHTS" value="901">
      <description>Include exterior lights located in front of the vehicle. For example, fog lights and low beams.</description>
    </element>
    <element name="EXTERIOR_REAR_LIGHTS" value="902">
      <description>Include exterior lights located at the back of the vehicle. For example, license plate lights, reverse lights, cargo lights, bed lights an trailer assist lights.</description>
    </element>
    <element name="EXTERIOR_LEFT_LIGHTS" value="903">
      <description>Include exterior lights located at the left side of the vehicle. For example, left puddle lights and spot lights.</description>
    </element>
    <element name="EXTERIOR_RIGHT_LIGHTS" value="902">
      <description>Include exterior lights located at the right side of the vehicle. For example, right puddle lights and spot lights.</description>
    </element>
  </enum>
  
  <enum name="LightStatus">
    <element name="ON"/>
    <element name="OFF"/>
  </enum>

  <struct name="LightCapabilities">
    <param name="name" type="LightName" mandatory="true" />
    <!-- Assuming light ON/OFF status is always available -->
    <param name="densityAvailable" type="Boolean" mandatory="false">
      <description>
        Indicates if the light's density can be set remotely (similar to a dimmer).
      </description>
    </param>
    <param name="rgbColorSpaceAvailable" type="Boolean" mandatory="false">
      <description>
        Indicates if the light's color can be set remotely by using the sRGB color space.
      </description>
    </param>
  </struct>

  <struct name="LightControlCapabilities">
    <param name="moduleName" type="String" maxlength="100" mandatory="true">
      <description>
      The short friendly name of the light control module.
      It should not be used to identify a module by mobile application.
      </description>
    </param>
    <param name="supportedLights" type="LightCapabilities" minsize="1" maxsize="100" array="true" mandatory="true">
      <description> An array of available LightCapabilities that are controllable. </description>
    </param>      
  </struct> 

  <struct name="LightState">
    <param name="id" type="LightName" mandatory="true">
      <description>The name of a light or a group of lights. </description>
    </param>
    <param name="status" type="LightStatus" mandatory="true"/>
    <param name="density" type="Float" minvalue="0" maxvalue="1" mandatory="false" />
    <param name="color" type="RGBColor" mandatory="false" />      
  </struct>
    
  <struct name="LightControlData">
    <param name="lightState" type="LightState" mandatory="true" minsize="1" maxsize="100" array="true">
      <description>An array of LightNames and their current or desired status. Status of the LightNames that are not listed in the array shall remain unchanged.</description>
    </param>
  </struct>    
```


New HMI_SETTINGS data types.
```xml
  <struct name="HMISettingsControlCapabilities">
    <param name="moduleName" type="String" maxlength="100" mandatory="true">
      <description>
      The short friendly name of the hmi setting module.
      It should not be used to identify a module by mobile application.
      </description>
    </param>
    <param name="distanceUnitAvailable" type="Boolean" mandatory="false">
      <description>Availability of the control of distance unit. </description>
    </param>      
    <param name="temperatureUnitAvailable" type="Boolean" mandatory="false">
      <description>Availability of the control of temperature unit. </description>
    </param> 
    <param name="displayModeUnitAvailable" type="Boolean" mandatory="false">
      <description>Availability of the control of HMI display mode. </description>
    </param>      
  </struct> 
  
  <enum name="DisplayMode">
    <element name="DAY"/>
    <element name="NIGHT"/>
    <element name="AUTO"/>
  </enum>
  <enum name="DistanceUnit">
      <element name="MILES"/>
      <element name="KILOMETERS"/>
  </enum>
  
  <!-- TemperatureUnit is an existing data type -->
  
  <struct name="HMISettingsControlData">
    <description>Corresponds to "HMI_SETTINGS" ModuleType</description>
      <param name="displayMode" type="DisplayMode" mandatory="false"></param>
      <param name="temperatureUnit" type="TemperatureUnit" mandatory="false"></param>
      <param name="distanceUnit" type="DistanceUnit" mandatory="false"></param>
  </struct>
```

```xml
  <struct name="RemoteControlCapabilities">
    :
    :
    <param name="audioControlCapabilities" type="AudioControlCapabilities" mandatory="false" minsize="1" maxsize="100" array="true">
        <description> If included, the platform supports audio controls. </description >
    </param>
    <param name="hmiSettingsControlCapabilities" type="HMISettingsControlCapabilities" mandatory="false">
        <description> If included, the platform supports hmi setting controls. </description >
    </param>
    <param name="lightControlCapabilities" type="LightControlCapabilities" mandatory="false">
        <description> If included, the platform supports light controls. </description >
    </param>
  </struct>
  
  <struct name="ModuleData">
    :
    :
    <param name="audioControlData" type="AudioControlData" mandatory="false">
    </param>
    <param name="lightControlData" type="LightControlData" mandatory="false">
    </param>
    <param name="hmiSettingsControlData" type="HMISettingsControlData" mandatory="false">
    </param>
  </struct>
```


For full mobile API xml file, please see https://github.com/yang1070/sdl_core/blob/newRCModule/src/components/interfaces/MOBILE_API.xml

The changes can also be found here https://github.com/yang1070/sdl_core/commit/93c8c48565776fee2c73fd256c207f4fc1403833

### HMI API XML changes
The changes are similar to mobile api changes, they are not listed here.
For full HMI API xml file please see https://github.com/yang1070/sdl_core/blob/newRCModule/src/components/interfaces/HMI_API.xml


## Potential downsides

None

## Impact on existing code

RPC changes:
- Add new AUDIO, LIGHT, HMI_SETTINGS module and corresponding capabilities and control data types to RC APIs.
- The proposal has the impact on: SetInteriorVehicleData, GetInteriorVehicleData, OnInteriorVehicleData, GetSystemCapability

HMI changes:
- New HMI API parameters support
- SDL HMI shall support the emulation of new RC modules.

Mobile iOS/Android SDK changes:
- New Mobile API parameters support

SDL core changes:
- New API parameters support
- New remote control modules support

Mobile Apps:
- There is no impact on existing mobile applications or SDL integrations if they do not used the new module or new parameters.

Policy:
- Policies need to support new ModuleTypes ("LIGHT", "HMI_SETTINGS", "AUDIO")
- SDL need to transfer RPCs with new parameters to appropriate vehicle's module. The response resultCode depends on vehicle's result of processing.

## Alternatives considered

HD Radio and traditional radio have specification for broadcasting meta-data, but less broadcasters respect this specification. An Alternate solution to handle such issue is by dumping all the meta-data received from radio receiver to the application via SDL. That is without decoding and parsing the SIS block. In this case, mobile applications shall be responsible for decoding meta-data.
