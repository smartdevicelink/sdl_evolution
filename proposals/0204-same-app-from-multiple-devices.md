# Support running the same app from multiple devices at the same time

* Proposal: [SDL-0204](0204-same-app-from-multiple-devices.md)
* Author: [Zhimin Yang](https://github.com/yang1070)
* Status: **Accepted with Revisions**
* Impacted Platforms: [Core]

## Introduction

This proposal proposes that SDL shall support running the same app from multiple devices at the same time. Currently, SDL only allows one instance of the same app to register with SDL.  However, there are valid use cases for running the same app from two or more devices at the same time. 

For example, two `Pandora` apps are running on an iPhone and an android phone respectively. Both devices connected to the vehicle’s infotainment system. They are streaming music to front and rear audio respectively.

As another example, two climate-remote-control apps are running on two devices that both connected to the vehicle. One used by the front passenger, the other used by a passenger sitting in the rear seat. They control the front and rear climate features separately. 

## Motivation

SDL supports the following transport types, Bluetooth, USB-AOA, and TCP (WiFi) out of the box. OEMs can also extend that list to include iAP over BT or iAP over USB. For details, please see [link here](
https://smartdevicelink.com/en/docs/hmi/master/basiccommunication/updatedevicelist/). It is possible that multiple devices connect to SDL at the same time using either the same (TCP) or different transports. 

It is also possible that multiple devices have the same version of the SDL app installed. When connecting to SDL from different devices, the apps will have the same information regarding app name, app id assigned by policy, app icon, voice recognition name, etc. For details, please see definition of `HMIApplication` and `RegisterAppInterface`. 

RPC `UpdateDeviceList` defines that the device list array has 0-100 elements. This is big enough for any real world scenarios. The maximum number of devices connected at the same time depends on the hardware and software configurations of the system running SDL. 

## Proposed solution

This proposal proposes that SDL shall support running the same app from multiple devices at the same time. 
An application is associated with a device. In this proposal, we call applications across different devices that have the same app policy id (short or full) and/or same app name as the same app. We call an application running on a unique device as an instance of the application.

- SDL shall treat the same app from different connected devices as different app instances or different apps. Thus, they will be different applications on HMI and have different HMI application IDs.
- SDL shall treat the same app from the same device with multiple transport connections as the same app instance. This is existing function of SDL. For example, an application on the same iPhone device connected via BT and USB will be treated as one app, not two apps.
- SDL shall allow only one instance of the app from one device. I.e. SDL shall reject the app with same app name or the same app id from one device as before.
- As before, SDL assigns unique internal app id to each app instance. 
- It is up to HMI to differentiate the same app across different devices, for example each device has its own list of apps on different pages, or HMI shows app name together with device name, or HMI appends a number/letter or device name at the end of the `appName`. Another example is that HMI appends device name to `ttsName` or `vrSynonyms` to create voice commands, so that the user can say a voice command like "Launch Pandora on X's phone" or "Launch Pandora on Y's phone". However, it is out of the scope of this proposal. 

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
-        May not interfere with any name or synonym of previously registered applications and any predefined blacklist of words (global commands)
+        May not interfere with any name or synonym of previously registered applications from the same device and any predefined blacklist of words (global commands)
-        Needs to be unique over all applications. Applications with the same name will be rejected.
+        Additional applications with the same name from the same device will be rejected.
       Only characters from char set [@TODO: Create char set (character/hex value) for each ACM and refer to] are supported.
    </description>
</param>
```

```xml
<param name="ttsName" type="TTSChunk" minsize="1" maxsize="100" array="true" mandatory="false" since="2.0">
    <description>
        TTS string for VR recognition of the mobile application name, e.g. "Ford Drive Green".
        Meant to overcome any failing on speech engine in properly pronouncing / understanding app name.
-       Needs to be unique over all applications.
+       Needs to be unique over applications from the same device.
        May not be empty.
        May not start with a new line character.
        Only characters from char set [@TODO: Create char set (character/hex value) for each ACM and refer to] are supported.
    </description>
</param>
```

```xml
<param name="vrSynonyms" type="String" maxlength="40" minsize="1" maxsize="100" array="true" mandatory="false" since="1.0">
    <description>
        Defines an additional voice recognition command.
-        May not interfere with any app name of previously registered applications and any predefined blacklist of words (global commands)
+        May not interfere with any app name of previously registered applications from the same device and any predefined blacklist of words (global commands)
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
-        May not interfere with any name or synonym of any registered applications.
+        May not interfere with any name or synonym of any registered applications form the same device.
-        Applications with the same name will be rejected. (SDL makes all the checks)
+        Additional applications with the same name from the same device will be rejected.
    </description>
</param>
```

```xml
<param name="vrSynonyms" type="String" maxlength="40" minsize="1" maxsize="100" array="true" mandatory="false">
  <description>
	Request new VR synonyms registration
	Defines an additional voice recognition command.
-    Must not interfere with any name of previously registered applications(SDL makes check).
+    Must not interfere with any name of previously registered applications from the same device.
  </description>
</param>
```
## Potential downsides

None.

## Impact on existing code

SDL core code need updates. Currently, SDL only allows one instance of the same app to register with SDL. When an app registers app interface, SDL checks if there is any existing app that has the same `app_policy_id`, and rejects the request if there is one. We need update the logic here. SDL still need to check if there is any existing app that has the same `app_policy_id`. If the result is no, SDL continue as before (allow register). If the result is yes, SDL compares the device information to those of already registered apps that have the same `app_policy_id`. If it is not the same as any of those devices, SDL continues as before (allow register). If the device has been found, SDL rejects the request. 

In addition, SDL shall apply a policy update to all app instances that have the same policy_app_id. Applications that have the same policy_app_id on different device should share same [app usage statistics](https://www.smartdevicelink.com/en/guides/sdl-server/api-reference-documentation/policy-table/usage-and-errors/). There might be other code changes not aware by the author in order to support this feature.

The descriptions in Mobile and HMI API will need updates.

## Alternatives considered

None from the author.
