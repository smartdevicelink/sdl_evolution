# Support running the same app from multiple devices at the same time

* Proposal: [SDL-NNNN](NNNN-same-app-from-multiple-devices.md)
* Author: [Zhimin Yang](https://github.com/yang1070)
* Status: **Awaiting review**
* Impacted Platforms: [Core]

## Introduction

This proposal proposes that SDL shall support running the same app from multiple devices at the same time. Currently, SDL only allows one instance of the same app to register with SDL.  However, there are valid use cases for running the same app from two or more devices at the same time. 

For example, two `Pandora` apps are running on an iPhone and an android phone respectively. Both devices connected to the vehicle’s infotainment system. They are streaming music to front and rear audio respectively.

As another example, two climate-remote-control apps are running on two devices that both connected to the vehicle. One used by the front passenger, the other used by a passenger sitting in the rear seat. They control the front and rear climate features separately. 

## Motivation

SDL supports the following transport types, Bluetooth, USB-AOA, and TCP (WiFi) out of the box. OEMs can also extend that list to include iAP over BT or iAP over USB. For details, please see link 
https://smartdevicelink.com/en/docs/hmi/master/basiccommunication/updatedevicelist/ . It is possible that multiple devices connect to SDL at the same time using either the same (TCP) or different transports. 

It is also possible that multiple devices have the same version of the SDL app installed. When connecting to SDL from different devices, the apps will have the same information regarding app name, app id assigned by policy, app icon, voice recognition name, etc. For details, please see definition of `HMIApplication` and `RegisterAppInterface`. 

RPC `UpdateDeviceList` defines that the device list array has 0-100 elements. This is big enough for any real world scenarios. The maximum number of devices connected at the same time depends on the hardware and software configurations of the system running SDL. 

## Proposed solution

This proposal proposes that SDL shall support running the same app from multiple devices at the same time. 
An application is associated with a device. In this proposal, we call applications across different devices that have the same app policy id (short or full) and/or same app name as the same app. We call an application running on a unique device as an instance of the application.

- SDL shall treat the same app from different connected devices as different app instances or different apps. 
- SDL shall treat the same app from the same device with multiple transport connections as the same app instance. 
- SDL shall allow only one instance of the app from one device. I.e. SDL shall reject the app with same app name or the same app id from one device as before.
- As before, SDL assigns unique internal app id to each app instance.
- It is up to HMI to differentiate the same app across different devices, for example each device has its own list of apps on different pages, or HMI shows app name together with device name, or HMI appends a number/letter at the end of the `appName`. It is out of the scope of this proposal. 

Mobile API update.
There is no API change. Just updates some descriptions.
```xml
<param name="appName" type="String" maxlength="100" mandatory="true" since="1.0">
    <description>
        The mobile application name, e.g. "Ford Drive Green".
-        Needs to be unique over all applications.
+        Needs to be unique over all applications from the same device.
        May not be empty.
        May not start with a new line character.
        May not interfere with any name or synonym of previously registered applications and any predefined blacklist of words (global commands)
-        Needs to be unique over all applications. Applications with the same name will be rejected.
+        Additional applications with the same name from the same device will be rejected.
       Only characters from char set [@TODO: Create char set (character/hex value) for each ACM and refer to] are supported.
    </description>
</param>
```

HMI API update
```xml
<param name="appName" type="String" maxlength="100" mandatory="false">
    <description>
        Request new app name registration
-        Needs to be unique over all applications.
+        Needs to be unique over all applications from the same device.
        May not be empty. May not start with a new line character.
        May not interfere with any name or synonym of any registered applications.
-        Applications with the same name will be rejected. (SDL makes all the checks)
+        Additional applications with the same name from the same device will be rejected.
    </description>
</param>
```
## Potential downsides

None.

## Impact on existing code

SDL core code need updates. Currently, SDL only allows one instance of the same app to register with SDL. When an app registers app interface, SDL checks if there is any existing app that has the same `app_policy_id`, and rejects the request if there is one. This needs a change. There might be other code changes not aware by the author in order to support this feature.

The descriptions in Mobile and HMI API will need updates.

## Alternatives considered

None from the author.
