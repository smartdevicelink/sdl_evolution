# Adding new parameters for transport switching

* Proposal: [SDL-XXXX](XXXX-Adding-new-parameters-for-transport-switching.md)
* Author: [Kazuki Sugimoto(Nexty)](https://github.com/Kazuki-Sugimoto)
* Status: **Awaiting Review**
* Impacted Platforms: [ Core / iOS / Java Suite / RPC / HMI ]

## Introduction

This proposal is to add USB information and Bluetooth (BT) information to `deviceInfo` that is notified by `RegisterAppInterface` and `OnAppRegistered`. The purpose is to enable transport switching during a multiple transport connection if it is determined that they are the same device.

## Motivation

Currently, if an Android device makes a USB connection during BT connection, the transport cannot be switched because the Head Unit (HU) cannot specify the device. For the HU to switch transports, it is necessary to determine whether or not they are the same device. Therefore, USB information and BT information are added to the device information to identify the device.

Note: BT information is related to[SDL-280](https://github.com/smartdevicelink/sdl_evolution/issues/941).

## Proposed solution

As a means to specify the device, USB information (for example, VID, PID, SERIAL) and BT information (BT device address) are added to deviceInfo notified by `RegisterAppInterface` and `OnAppRegistered`. When multiple transport connections are made, the HU identifies the device based on the notified USB information and BT information. If it is determined that they are the same device, the transport is switched according to the priority of the communication method.


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
+        <param name="bluetoothDeviceAddress" type="String"  minlength="0" maxlength="500" mandatory="false">
+            <description>Device BT Address</description>
+        </param>
+        <param name="vendorID" type="Integer" minvalue="0" maxvalue="65535" mandatory="false">
+            <description>Vendor ID</description>
+        </param>
+        <param name="productID" type="Integer" minvalue="0" maxvalue="65535" mandatory="false">
+            <description>Product ID</description>
+        </param>
+        <param name="serialNumber" type="Integer" mandatory="false">
+            <description>Index of string descriptor describing the device’s serial number</description>
+        </param>
    </struct>
```
  
HMI API:
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
+  <param name="bluetoothDeviceAddress" type="String" mandatory="false">
+     <description>Device BT Address</description>
+  </param>
+  <param name="vendorID" type="Integer" minvalue="0" maxvalue="65535" mandatory="false">
+      <description>Vendor ID</description>
+  </param>
+  <param name="productID" type="Integer" minvalue="0" maxvalue="65535" mandatory="false">
+      <description>Product ID</description>
+  </param>
+  <param name="serialNumber" type="Integer" mandatory="false">
+      <description>Index of string descriptor describing the device’s serial number</description>
+  </param>
</struct>
```
Note: bluetoothDeviceAddress is related to[SDL-280](https://github.com/smartdevicelink/sdl_evolution/issues/941).


### Use cases for identifying the same device

The following is an example of a use case for identifying the same device:
Note: The actual operation depends on the HU specifications.

- Identifying the same device using USB information
1. The HS USB information is notified to HU by SDL connection and app registration via BT.
2. USB connection is made with the same device. Then, the HU checks the newly connected USB information against the USB information acquired during BT connection.
3. Since it is determined to be the same device, the HU performs the transport switching as SDL connection via USB.

    Note: Transport switching is similar to iOS processing.

- Identifying the same device using BT information
1. BT information of HS is notified to HU by SDL connection via USB (and BT connection via A2DP) and application registration. The HS USB information is notified to HU by SDL connection and app registration via USB (and BT connection via A2DP).
2. The USB is removed and the HU checks the A2DP connection BT information against the BT information acquired during USB connection.
3. Since it is determined to be the same device, the HU performs the transport switching as SDL connection via BT.


## Potential downsides

There are no downsides because there is only the addition of parameters.


## Impact on existing code

Core, iOS, Java Suite, RPC, and HMI need to be updated to support the added parameters.


## Alternatives considered

None.
