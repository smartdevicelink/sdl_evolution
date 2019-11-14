# Adding new parameter of Bluetooth Device Address

* Proposal: [SDL-NNNN](NNNN-Adding-new_parameter_of_Bluetooth_Device_Address.md)
* Author: [Shohei Kawano](https://github.com/Shohei-Kawano)
* Status: **Awaiting review**
* Impacted Platforms: [Core / iOS / Android / RPC / HMI]

## Introduction

In this proposal, by adding the BT address to `DeviceInfo` of `RegisterAppInterface`, when the device is connected via USB, HU will connect the SDL device via BT automatically or to prompt the user for needing to BT connection.  


## Motivation

Since Android recommends not supporting AOA2.0, Android will no longer be able to play audio using only USB, and it will be necessary to use BT A2DP to play audio.  
To solve this problem, add a BT address so that a new SDL device can be specified in `RegisterAppInterface`, and prompt the user to connect device via BT or HU will connect device via BT automatically when connected via USB.

## Proposed solution

Adding the new parameter `bluetoothDeviceAddress` to `DeviceInfo` of `RegisterAppInterface` and `OnAppRegistered`.  

MOBILE_API.xml  
```xml
    <struct name="DeviceInfo" since="3.0">
        <description>Various information about connecting device.</description>         
        <param name="hardware" type="String"  minlength="0" maxlength="500" mandatory="false">
            <description>Device model</description>
        </param>
        <param name="firmwareRev" type="String" minlength="0" maxlength="500" mandatory="false">
            <description>Device firmware revision</description>
        </param>
        <param name="os" type="String" minlength="0" maxlength="500" mandatory="false">
            <description>Device OS</description>
        </param>
        <param name="osVersion" type="String" minlength="0" maxlength="500" mandatory="false">
            <description>Device OS version</description>
        </param>
        <param name="carrier" type="String" minlength="0" maxlength="500" mandatory="false">
            <description>Device mobile carrier (if applicable)</description>
        </param>
        <param name="maxNumberRFCOMMPorts" type="Integer" minvalue="0" maxvalue="100" mandatory="false">
            <description>Omitted if connected not via BT.</description>
        </param>         
+       <param name="bluetoothDeviceAddress" type="String"  minlength="0" maxlength="500" mandatory="true">
+           <description>Device BT Address - If cannot get it, set All-F.</description>
+       </param>
    </struct>
Åc
    <function name="RegisterAppInterface" functionID="RegisterAppInterfaceID" messagetype="request" since="1.0">
        <description>
            Establishes an interface with a mobile application.
            Before registerAppInterface no other commands will be accepted/executed.
        </description>
        
        <param name="syncMsgVersion" type="SyncMsgVersion" mandatory="true" since="1.0">
            <description>See SyncMsgVersion</description>
        </param>
Åc
        <param name="hashID" type="String" maxlength="100" mandatory="false" since="3.0">
            <description>
                ID used to uniquely identify current state of all app data that can persist through connection cycles (e.g. ignition cycles).
                This registered data (commands, submenus, choie sets, etc.) can be reestablished without needing to explicitly reregister each piece.
                If omitted, then the previous state of an app's commands, etc. will not be restored.
                When sending hashID, all RegisterAppInterface parameters should still be provided (e.g. ttsName, etc.).
            </description>
        </param>
+       <param name="deviceInfo" type="DeviceInfo" mandatory="true" since="X.X">
-       <param name="deviceInfo" type="DeviceInfo" mandatory="false" since="3.0">
            <description>
                See DeviceInfo.
            </description>
+           <history>
+                <param name="deviceInfo" type="DeviceInfo" mandatory="false" since="3.0" until="X.X"/>
+           </history>
        </param>
        <param name="appID" type="String" maxlength="100" mandatory="true" since="2.0">
            <description>ID used to validate app with policy table entries</description>
        </param>
Åc
    </function>
```

HMI_API.xml  
```xml
<struct name="DeviceInfo">
    <param name="name" type="String" mandatory="true">
        <description>The name of the device connected.</description>
    </param>
    <param name="id" type="String" mandatory="true">
        <description>The ID of the device connectedi: either hash of device's USB serial number(in case of USB connection) or has of device's MAC address(in case of BlueTooth or WIFI connection</description>
    </param>
    <param name="transportType" type="Common.TransportType" mandatory="false">
        <description>The transport type the named-app's-device is connected over HU(BlueTooth, USB or WiFi). It must be provided in OnAppRegistered and in UpdateDeviceList</description>
    </param>
    <param name="isSDLAllowed" type="Boolean" mandatory="false">
        <description>Sent by SDL in UpdateDeviceList. 'true' - if device is allowed for PolicyTable Exchange; 'false' -  if device is NOT allowed for PolicyTable Exchange </description>
    </param>
+   <param name="bluetoothDeviceAddress" type="String" mandatory="true">
+       <description>Device BT Address - If cannot get it, set All-F.</description>
+   </param>
</struct>
```

## Potential downsides

Mandatory A major change to add a true parameter.  
Need to be consistent with the previous version.

## Impact on existing code

A new mandatory true parameter is added to affect all Core / iOS / Android / RPC / HMI.


## Alternatives considered

There is no alternative.
