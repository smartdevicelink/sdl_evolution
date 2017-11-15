# Remote Control - Seat

* Proposal: [SDL-0105](0105-remote-control-seat.md)
* Author: [Zhimin Yang](https://github.com/yang1070)
* Status: **Accepted**
* Impacted Platforms: [Core / iOS / Android / RPC ]

## Introduction

This proposal allows mobile applications to control powered seats within a vehicle (while the vehicle is in parking). A mobile application can send a remote control command to adjust seat positions, turn on or off cooled/heated seat, or change massage settings. The application can also get the status of each seat as well as receive notifications once the status of any seat changes.

## Motivation

To extend SDL-RC functionality and add a "SEAT" remote-control module of the vehicle. 

## Proposed solution

Add a `SEAT` RC module, the capabilities of each seat, and the related control data type to `Mobile_API.xml` and `HMI_API.xml`

| Control Item | Value Range |Type | Comments |
| ------------ |------------ | ------------ | ------------ |
| Seat Heating Enabled | true, false | Get/Set/Notification | Indicates whether heating is enabled for a seat |
| Seat Cooling Enabled | true, false | Get/Set/Notification | Indicates whether cooling is enabled for a seat |
| Seat Heating  level | 0-100% | Get/Set/Notification | Level of the seat heating |
| Seat Cooling  level | 0-100% | Get/Set/Notification | Level of the seat cooling |
| Seat Horizontal Positon | 0-100% | Get/Set/Notification | Adjust a seat forward/backward, 0 means the nearest position to the steering wheel, 100% means the furthest position from the steering wheel |
| Seat Vertical Position | 0-100% | Get/Set/Notification | Adjust seat height (up or down) in case there is only one actuator for seat height, 0 means the lowest position, 100% means the highest position|
| Seat-Front Vertical Position | 0-100% | Get/Set/Notification | Adjust seat front height (in case there are two actuators for seat height), 0 means the lowest position, 100% means the highest position|
| Seat-Back Vertical Position | 0-100% | Get/Set/Notification | Adjust seat back height (in case there are two actuators for seat height), 0 means the lowest position, 100% means the highest position|
| Seat Back Tilt Angle | 0-100% | Get/Set/Notification | Backrest recline, 0 means the angle that back top is nearest to the steering wheel, 100% means the angle that back top is furthest from the steering wheel|
| Head Support Horizontal Positon | 0-100% | Get/Set/Notification | Adjust head support forward/backward, 0 means the nearest position to the front, 100% means the furthest position from the front |
| Head Support Vertical Position | 0-100% | Get/Set/Notification | Adjust head support height (up or down), 0 means the lowest position, 100% means the highest position|
| Seat Massaging Enabled | true, false | Get/Set/Notification | Indicates whether massage is enabled for a seat |
| Massage Mode | List of Struct {MassageZone, MassageMode} | Get/Set/Notification | list of massage mode of each zone |
| Massage Cushion Firmness | List of Struct {Cushion, 0-100%} | Get/Set/Notification | list of firmness of each massage cushion|
| Seat memory | Struct{ id, label, action (SAVE/RESTORE/NONE)} | Get/Set/Notification | seat memory |


#### Additions to Mobile_API
```xml
<enum name="ModuleType">
  :
  :
  <element name="SEAT"/>
</enum>

<enum name="MassageZone">
  <description>List possible zones of a multi-contour massage seat.</description>
  <element name="LUMBAR">
    <description>The back of a multi-contour massage seat. or SEAT_BACK</description>
  </element>
  <element name="SEAT_CUSHION">
    <description>The bottom a multi-contour massage seat. or SEAT_BOTTOM </description>
  </element>
</enum>

<enum name="MassageMode">
  <description>List possible modes of a massage zone.</description>
  <element name="OFF"/>
  <element name="LOW"/>
  <element name="HIGH"/>
</enum>

<struct name="MassageModeData">
  <description>Specify the mode of a massage zone.</description>
  <param name="massageZone" type="MassageZone" mandatory="true"></param>
  <param name="massageMode" type="MassageMode" mandatory="true"></param>
</struct>

<enum name="MassageCushion">
  <description>List possible cushions of a multi-contour massage seat.</description>
  <element name="TOP_LUMBAR"/>
  <element name="MIDDLE_LUMBAR"/>
  <element name="BOTTOM_LUMBAR"/>
  <element name="BACK_BOLSTERS"/>
  <element name="SEAT_BOLSTERS"/>
</enum>

<struct name="MassageCushionFirmness">
  <description>The intensity or firmness of a cushion.</description>
  <param name="cushion" type="MassageCushion" mandatory="true"></param>
  <param name="firmness" type="Integer" minvalue="0" maxvalue="100" mandatory="true"></param>
</struct>

<enum name="SeatMemoryActionType">
  <element name="SAVE">
    <description>Save current seat postions and settings to seat memory.</description>
  </element>
  <element name="RESTORE">
    <description>Restore / apply the seat memory settings to the current seat. </description>
  </element>
  <element name="NONE">
    <description>No action to be performed.</description>
  </element>
</enum>

<struct name="SeatMemoryAction">
  <param name="id" type="Integer" minvalue="1" maxvalue="10" mandatory="true"/>
  <param name="label" type="String" maxlength="100" mandatory="false"/>
  <param name="action" type="SeatMemoryActionType" mandatory="true"/>
</struct>

<enum name="SupportedSeat">
  <description>List possible seats that is a remote controllable seat.</description>
  <element name="DRIVER"/>
  <element name="FRONT_PASSENGER"/>
</enum>

<struct name="SeatControlData">
  <description>Seat control data corresponds to "SEAT" ModuleType. </description>
  <param name="id" type="SupportedSeat" mandatory="true">
  
  <param name="heatingEnabled" type="Boolean" mandatory="false"></param>
  <param name="coolingEnabled" type="Boolean" mandatory="false"></param>
  <param name="heatingLevel" type="Integer" minvalue="0" maxvalue="100" mandatory="false"></param>
  <param name="coolingLevel" type="Integer" minvalue="0" maxvalue="100" mandatory="false"></param>

  <param name="horizontalPosition" type="Integer" minvalue="0" maxvalue="100" mandatory="false"></param>
  <param name="verticalPosition" type="Integer" minvalue="0" maxvalue="100" mandatory="false"></param>
  <param name="frontVerticalPosition" type="Integer" minvalue="0" maxvalue="100" mandatory="false"></param>
  <param name="backVerticalPosition" type="Integer" minvalue="0" maxvalue="100" mandatory="false"></param>
  <param name="backTiltAngle" type="Integer" minvalue="0" maxvalue="100" mandatory="false"></param>
  
  <param name="headSupportHorizontalPosition" type="Integer" minvalue="0" maxvalue="100" mandatory="false"></param>
  <param name="headSupportVerticalPosition" type="Integer" minvalue="0" maxvalue="100" mandatory="false"></param>
  
  <param name="massageEnabled" type="Boolean" mandatory="false"></param>
  <param name="massageMode" type="MassageModeData" minsize="1" maxsize="2" array="true" mandatory="false"></param>
  <param name="massageCushionFirmness" type="MassageCushionFirmness" minsize="1" maxsize="5" array="true" mandatory="false"></param>
  
  <param name="memory" type="SeatMemoryAction" mandatory="false"></param>
</struct>

<struct name="SeatControlCapabilities">
  <param name="moduleName" type="String" maxlength="100"  mandatory="true">
    <description>
    The short friendly name of the light control module.
    It should not be used to identify a module by mobile application.
    </description>
  </param>
  <param name="heatingEnabledAvailable" type="Boolean" mandatory="false">
  </param>
  <param name="coolingEnabledAvailable" type="Boolean" mandatory="false">
  </param>
  <param name="heatingLevelAvailable" type="Boolean" mandatory="false">
  </param>
  <param name="coolingLevelAvailable" type="Boolean" mandatory="false">
  </param>
  <param name="horizontalPositionAvailable" type="Boolean" mandatory="false">
  </param> 
  <param name="verticalPositionAvailable" type="Boolean" mandatory="false">
  </param> 
  <param name="frontVerticalPositionAvailable" type="Boolean" mandatory="false">
  </param> 
  <param name="backVerticalPositionAvailable" type="Boolean" mandatory="false">
  </param> 
  <param name="backTiltAngleAvailable" type="Boolean" mandatory="false">
  </param>
  <param name="headSupportHorizontalPositionAvailable" type="Boolean" mandatory="false">
  </param> 
  <param name="headSupportVerticalPositionAvailable" type="Boolean" mandatory="false">
  </param> 
  <param name="massageEnabledAvailable" type="Boolean" mandatory="false">
  </param> 
  <param name="massageModeAvailable" type="Boolean" mandatory="false">
  </param> 
  <param name="massageCushionFirmnessAvailable" type="Boolean" mandatory="false">
  </param>
  <param name="memoryAvailable" type="Boolean" mandatory="false">
  </param> 
</struct> 

<struct name="RemoteControlCapabilities">
  :
  :
  <param name="seatControlCapabilities" type="SeatControlCapabilities" mandatory="false" minsize="1" maxsize="100" array="true">
    <description>
      If included, the platform supports seat controls.
    </description >
  </param>
</struct>

<struct name="ModuleData">
  :
  :
  <param name="seatControlData" type="SeatControlData" mandatory="false">
  </param>
</struct>
```
#### Additions to HMI_API
The changes are the same as mobile api changes, they are not duplicated here. 

## Potential downsides

Due to the lack of an agreed control resource ID/Zone scheme, we define `SupportedSeat` enum as a work around to allow control of both driver seat and front passenger seat.
We shall have a global remote-control-resource ID/Zone scheme, that assigns an ID to each remote controllable resource within a vehicle.

## Impact on existing code

The proposal has the impact on:

RPC changes:

- Add new `SEAT` module and corresponding capabilities and control data types to RC APIs.
- The proposal has the impact on: `SetInteriorVehicleData`, `GetInteriorVehicleData`, `OnInteriorVehicleData`, `GetSystemCapability`

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

- Policies need to support new ModuleTypes (`SEAT`)
- SDL need to transfer RPCs with new parameters to appropriate vehicle modules. The response resultCode depends on vehicle's result of processing.

## Alternatives considered

None

