# Remote Control - OnRCStatus notification

* Proposal: [SDL-NNNN](nnnn-remote-control-onRcStatus-notification.md)
* Author: [Zhimin Yang](https://github.com/yang1070)
* Status: **Awaiting review**
* Impacted Platforms: [Core / iOS / Android / RPC ]

## Introduction
One simple resource allocation rule is that at any given time a RC module can be controlled by one and only one application. For example, if a climate control module is allocated to application ONE, any other applications get rejected if they try to change the settings of the same climate control module. The module is freed when application ONE exits, disconnects, goes to HMI level NONE or no longer has the right to control the module due to various reasons (for example, a policy update revokes the access right to a module from the app, or SDL re-allocates the module to another app). In this case, the mobile application does not aware the change.


A new notification originated from SDL is nice to have. If SDL allocates a module to an application or it deallocates a module from an application, SDL shall send OnRCStatus notifications to both the mobile application and the HMI. The notification shall contain an array of the RC modules allocated to the application, so that the mobile application can know it gains or loses control of a module before a failure request, and the HMI can update the status on which application controls which modules.

## Motivation

Mobile applications needs to know which remote control modules it can control. HMI needs to show which application controls which module or modules.

SDL core manages the remote control modules. It allocates a module to an application upon a successful `OnButtonPress` or `SetInteriorVehicleData` request to access a `free` module. The application knows whether it can control the module from the result code of the response message. If the result is `SUCCESS`, the application stays in control of the module and can send more control requests. If the result is anything other than `SUCCESS`, the application cannot control the requested module. It shall stop sending more requests to the same module unless it goes to HMI level `FULL`. 

SDL can free the allocatd resource for various reasons. In most of the cases, the application knows it no longer has the access to the module. But in some cases, the application does not know it loses the access right to the module. For example, a policy update can reovke the application's access to a module. In another example, when a foregroud application tries to access an allocatd resource, SDL can de-allocate the module from a background application and re-allocate the module to the foreground application. It happens either automatically (the `RCAccessMode` of RC settings is configured as `AUTO_ALLOW`) or manually with the driver's allowing the access right transfer via a popup (the `RCAccessMode` of RC settings is configured as `ASK_DRIVER`). However, in both examples, the application that previously controls the module does not know the change until it receives a failure response on next control request. The HMI also does not aware the change.

## Proposed solution

Add an `OnRCStatus` notification RPC to `Mobile_API.xml` and `HMI_API.xml`

SDL shall send OnRCStatus notifications to both the mobile application and the HMI whenever SDL allocates a module to an application or it deallocates a module from an application.

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
```

#### Additions to Mobile_API

```xml
<element name="OnRCStatusID" value="32784" hexvalue="801A" />

<function name="OnRCStatus" messagetype="notification">
  <description>Issued by SDL to notify the application about remote control status change on SDL</description>
  <param name="allocatedModules" type="ModuleType" minsize="0" maxsize="100" array="true" mandatory="true">
    <description>Contains a list (zero or more) of module types that allocatd to the application.</description>
  </param>
</function>
```
Due to there is no agreement on the ID/ZONE sheme of the resources, we use `MoudleType` here. We shall use the id of a resoure if we want to support multiple resources of the same type in the future.

#### Additions to HMI_API
```xml
<function name="OnRCStatus" messagetype="notification">
  <description>Issued by SDL to notify HMI about remote control status change on SDL</description>
  <param name="appID" type="Integer" mandatory="true">
    <description>ID of selected application.</description>
  </param>
  <param name="allocatedModules" type="ModuleType" minsize="0" maxsize="100" array="true" mandatory="true">
    <description>Contains a list (zero or more) of module types that allocatd to the application.</description>
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
In addition to the allocatedModules, we can add an array of free modules in the notification.
However, that means whenever there is a status change in modules, SDL shall send notifications to all connected RC applications (instead of just sending a notification to the affected application).

```xml<function name="OnRCStatus" messagetype="notification">
  <description>Issued by SDL to notify the application about remote control status change on SDL</description>
  <param name="allocatedModules" type="ModuleType" minsize="0" maxsize="100" array="true" mandatory="true">
    <description>Contains a list (zero or more) of module types that allocatd to the application.</description>
  </param>
  <param name="freeModules" type="ModuleType" minsize="0" maxsize="100" array="true" mandatory="true">
    <description>Contains a list (zero or more) of module types that are free to access for the application.</description>
  </param>  
</function>
```

Another approach is to extend `OnHMIStatus` notification to include new remote control status info. However, that is only for SDL -> Applictation. Still need a notification from SDL to HMI.
