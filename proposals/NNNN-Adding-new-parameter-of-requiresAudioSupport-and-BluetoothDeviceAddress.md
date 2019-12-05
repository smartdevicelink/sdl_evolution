# Adding new parameter of requiresAudioSupport and BluetoothDeviceAddress

* Proposal: [SDL-NNNN](NNNN-Adding-new-parameter-of-requiresAudioSupport-and-BluetoothDeviceAddress.md)
* Author: [Shohei Kawano](https://github.com/Shohei-Kawano)
* Status: Awaiting review
* Impacted Platforms: [ Core / iOS / Java Suite / RPC / HMI ]

## Introduction

In this proposal, by adding the `requiresAudioSupport` in `RegisterAppInterface` and the `BluetooothDeviceAddress` in `DeviceInfo`, when the device is connected via only USB, HU will connect to the SDL device's BT automatically or prompt the user requesting BT connection.  

## Motivation

Since Android recommends not supporting AOA2.0, Android will no longer be able to play audio using only USB, and it will be necessary to use BT A2DP to play audio.  
In the current SDL Java Suite library, if requiresAudioSupport is TRUE and BT A2DP is not connected,  
SDL activation will be cancelled. Users aren't notified why the SDL App doesn't start, so the UX needs to be improved.  
To solve this problem, add `BluetoothDeviceAddress` and `requiresAudioSupport` so that a new SDL device can be specified in RegisterAppInterface,
and prompt the user to connect the device via BT, or the HU will connect the device via BT automatically when connected via USB.  

## Proposed solution

Adding the new parameter `requiresAudioSupport` in `RegisterAppInterface` and `OnAppRegistered`, and `bluetoothDeviceAddress` in `DeviceInfo`.
If an SDL App such as MediaType requires AudioSupport (such as BT A2DP), sets `requireAudioSupport` to TRUE and sets the BT address of the device in `BluetoothDeviceAddress`.
HU checks BT connection if `rerequresAudioSupport` is TRUE,If BT is not connected, the user is prompted to connect,  
or the BT address information is used to connect automatically.  
( If requiresAudioSupport is not set, refer to AppType, and if it is MediaType, operate as TRUE. )  
  
Current Android library (java suite) when setting `requiresAudioSupport` is TRUE, and if the BT A2DP is not connected is to cancel the launch of SDL.  
However, with this modification, the SDL is always changed without depending on the connection status of BT A2DP.  


Mobile API:
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
...
    <function name="RegisterAppInterface" functionID="RegisterAppInterfaceID" messagetype="request" since="1.0">
        <description>
            Establishes an interface with a mobile application.
            Before registerAppInterface no other commands will be accepted/executed.
        </description>
        
        <param name="syncMsgVersion" type="SyncMsgVersion" mandatory="true" since="1.0">
            <description>See SyncMsgVersion</description>
        </param>
...
        <param name="hashID" type="String" maxlength="100" mandatory="false" since="3.0">
            <description>
                ID used to uniquely identify current state of all app data that can persist through connection cycles (e.g. ignition cycles).
                This registered data (commands, submenus, choice sets, etc.) can be reestablished without needing to explicitly reregister each piece.
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
...
        <param name="nightColorScheme" type="TemplateColorScheme" mandatory="false" since="5.0"/>
+        <param name="requiresAudioSupport" type="Boolean" mandatory="false" since="X.X">
+            <description>Set whether or not this app requires the use of an audio streaming output device.</description>
+        </param>
    </function>
```
  
Mobile API:
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
    <description>Sent by SDL in UpdateDeviceList. 'true' - if device is allowed for PolicyTable Exchange; 'false' - if device is NOT allowed for PolicyTable Exchange </description>
  </param>
+ <param name="bluetoothDeviceAddress" type="String" mandatory="true">
+   <description>Device BT Address - If cannot get it, set All-F.</description>
+ </param>
</struct>
...
<struct name="HMIApplication">
...
    <param name="deviceInfo" type="Common.DeviceInfo" mandatory="true">
       <description>The ID, serial number, and transport type by which the named app's device is connected to HU.</description>
    </param>
...
    <param name="cloudConnectionStatus" type="Common.CloudConnectionStatus" mandatory="false"></param>
+    <param name="requiresAudioSupport" type="Boolean" mandatory="false">
+        <description>Set whether or not this app requires the use of an audio streaming output device.</description>
+    </param>
</struct>
```

## Potential downsides

This proposal makes a major change to add Mandatory TRUE request.  
It is necessary to coordinate the operation with the old system that is not Mandatory TRUE.  


## Impact on existing code

Since new parameters are added, Core and  iOS, Android, RPC, HMI are affected.

## Alternatives considered

Nothing.  
