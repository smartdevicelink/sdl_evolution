# Remote Control - OnRCStatus notification

* Proposal: [SDL-0106](0106-remote-control-onRcStatus-notification.md)
* Author: [Zhimin Yang](https://github.com/yang1070)
* Status: **In Review**
* Impacted Platforms: [Core / iOS / Android / RPC ]

## Introduction
One simple resource allocation rule is that at any given time only one application controls a RC module. For example, if SDL allocates a climate control module to application ONE, SDL rejects other applications to change the settings of the same climate control module. The module is freed when application ONE exits, disconnects, goes to HMI level NONE or no longer has the right to control the module due to various reasons (for example, a policy update revokes the access right to the module from the app, or SDL re-allocates the module to another app). In the last case, the mobile application is not aware of the change.


A new notification originated from SDL is nice to have. If SDL allocates a module to an application or it de-allocates a module from an application, SDL shall send OnRCStatus notifications to both the mobile application and the HMI. The notification shall contain an array of the RC modules allocated to the application, so that the mobile application can know it gains or loses control of a module before a failure request, and the HMI can update the status on which application controls which modules.

## Motivation

Mobile applications need to know which remote control modules it can control. HMI needs to show which application controls which module or modules.

SDL core manages the remote control modules. It allocates a module to an application upon a successful `OnButtonPress` or `SetInteriorVehicleData` request to access a `free` module. The application knows whether it can control the module from the result code of the response message. If the result is `SUCCESS`, the application stays in control of the module and can send more control requests. If the result is anything other than `SUCCESS`, the application cannot control the requested module. It shall stop sending more requests to the same module unless it goes to HMI level `FULL`. 

SDL can free the allocated resource for various reasons. In most of the cases, the application knows it no longer has the control of the module. However, in some cases, the application does not know it loses the control of the module. For example, a policy update can revoke the application's access to a module. In another example, when a foreground application tries to access an allocated resource, SDL can de-allocate the module from a background application and re-allocate the module to the foreground application. It happens either automatically (the `RCAccessMode` of RC settings is configured as `AUTO_ALLOW`) or manually with the driver's allowing the control right transfer via a popup (the `RCAccessMode` of RC settings is configured as `ASK_DRIVER`). However, in both examples, the application that previously controls the module is not aware of the change until it receives a failure response on next control request. The HMI is also not aware of the change.

## Proposed solution

Add an `OnRCStatus` notification RPC to `Mobile_API.xml` and `HMI_API.xml`

SDL shall send OnRCStatus notifications to all registered mobile applications and the HMI whenever SDL allocates a module to an application or it de-allocates a module from an application.

#### Existing data related to the change
```
<enum name="ModuleType">
  <element name="CLIMATE"/>
  <element name="RADIO"/>
  <element name="AUDIO"/>
  <element name="LIGHT">
  <element name="HMI_SETTINGS">
  <element name="SEAT">
</enum>

    <struct name="ModuleData">
        <description>The moduleType indicates which type of data should be changed and identifies which data object exists in this struct. For example, if the moduleType is CLIMATE then a "climateControlData" should exist</description>
        <param name="moduleType" type="ModuleType" mandatory="true">
        </param>
        <param name="radioControlData" type="RadioControlData" mandatory="false">
        </param>
        <param name="climateControlData" type="ClimateControlData" mandatory="false">
        </param>
        ...
    </struct>
```

#### Additions to Mobile_API

```xml
<element name="OnRCStatusID" value="32784" hexvalue="801A" />

<function name="OnRCStatus" messagetype="notification">
  <description>Issued by SDL to notify the application about remote control status change on SDL</description>
  <param name="allocatedModules" type="ModuleData" minsize="0" maxsize="100" array="true" mandatory="true">
    <description>Contains a list (zero or more) of module types that are allocated to the application.</description>
  </param>
  <param name="freeModules" type="ModuleData" minsize="0" maxsize="100" array="true" mandatory="true">
    <description>Contains a list (zero or more) of module types that are free to access for the application.</description>
  </param>    
</function>
```
In theory, ```allocatedModules``` and ```freeModules``` shall be two module ID arrays. Since there is not currently agreement on the ID/ZONE scheme of the resources, we use `ModuleData` here. All the optional control data inside of `ModuleData` shall not be included in the notifications. In the future, when we define an ID for a module, we can extend `ModuleData` to include the module ID, without a breaking change.

#### Additions to HMI_API
```xml
<function name="OnRCStatus" messagetype="notification">
  <description>Issued by SDL to notify HMI about remote control status change on SDL</description>
  <param name="appID" type="Integer" mandatory="true">
    <description>ID of selected application.</description>
  </param>
  <param name="allocatedModules" type="ModuleData" minsize="0" maxsize="100" array="true" mandatory="true">
    <description>Contains a list (zero or more) of module types that are allocated to the application.</description>
  </param>
  <param name="freeModules" type="ModuleData" minsize="0" maxsize="100" array="true" mandatory="true">
    <description>Contains a list (zero or more) of module types that are free to access for the application.</description>
  </param>    
</function>
```

## Potential downsides
None.

## Impact on existing code
RPC and Mobile iOS/Android SDK changes:
- New mobile API parameters support

SDL core changes:
- Send notifications when a module is allocated/de-allocated to an application.

## Alternatives considered
We can remove the array of free modules in the notification. The difference is that without free module list SDL shall send notifications to the affected application instead of to all applications.

```xml<function name="OnRCStatus" messagetype="notification">
  <description>Issued by SDL to notify the application about remote control status change on SDL</description>
  <param name="allocatedModules" type="ModuleData" minsize="0" maxsize="100" array="true" mandatory="true">
    <description>Contains a list (zero or more) of module types that are allocated to the application.</description>
  </param>
</function>
```

Another approach is to extend `OnHMIStatus` notification to include new remote control status info. However, that is only for SDL -> Application. We still need a notification from SDL to HMI.
