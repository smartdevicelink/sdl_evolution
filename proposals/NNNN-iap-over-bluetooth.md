# Support of iAP over Bluetooth

* Proposal: [SDL-NNNN](NNNN-iap-over-bluetooth.md)
* Author: [SDL Developer](https://github.com/smartdevicelink/)
* Status: **Awaiting review**
* Impacted Platforms: Core

## Introduction

This feature introduces the ability for a user having an iOS device to connect with the Head Unit via Bluetooth and not requiring the wired USB connection for registering media and non-media apps.

## Motivation

One of the biggest pain points for AppLink user’s having an iOS device is the need to plug the iOS device into the Head Unit’s USB port. On the other hand, Android users are able to register their apps on the Head Unit wirelessly using BlueTooth. This is also one of the reasons of having lesser number of AppLink users connecting using an iOS device as compared to Android device.
    
The main motivation for this proposal is to lower this entry barrier by making apps register from an iOS device via BlueTooth.

## Proposed solution

A big concern for this feature is the impact to the user when an iOS device connected via BT is also connected via USB. Since Apple requires that only one transport should be connected (priority should be for wired transport) to the same device and since an iAP session over both transports are needed to determine if the same device is connected over both the transports, the head unit should be able to disconnect the app connection over the wireless transport and restore the connection back over the wired transport within a very short period of time – to provide a seamless experience to the user. But the seamless experience is also dependent on how fast an app can reconnect with the Head Unit via the alternate transport.
  
The proposed solution provides the ability to switch connection during new Application registration. In case of Registering the same application from the same device it could be determined as the same application. SDL core Application layer switches BT and USB connections due to Mobile Register Application Interface Request. This switching is hidden for HMI.
  
**Pros:**
  
* Following SDL Protocol way with an Application responsibility for (re)connection to HU
* No additional iAP changes
* Could cover any type of device (ex. Android, iOS)
* No Application disconnection for HMI side
  
**Cons:**
  
* The longest reconnection procedure, which mostly affects User reconnection experience
* A lot of SDL Core changes
  
## Detailed design

TBD

## Impact on existing code

* SDL Core - Transport layer
  * Adding timeouts for waiting device re-connection
  * Adding limitation for the outcome data during waiting timeout
  * Updating DeviceUpdate and ApplicationListUpdate notifications
* SDL Core - Protocol Handler
  * Secure session reestablishing for new session
  * Update Heartbeat restricts (to avoid disconnection due to HB timeout)
  * Update Waiting Consecutive Frames timeout restricts (to avoid disconnection due to HB timeout)
* SDL Core - Application Manager
  * Implementation of connection switching mechanism
  * Update Waiting timeout for reconnecting procedure
* SDL Core - Policy
  * Updating info
* SDL Core - Resumption
  * Updating device type information
* SDL Core - Security
  * Secure session reestablishing for new sessions

## Alternatives considered

N/A
