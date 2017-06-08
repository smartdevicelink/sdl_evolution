# Feature name

* Proposal: [SDL-NNNN](NNNN-filename.md)
* Author: [Timur Pulathaneli](https://github.com/tpulatha)
* Status: **Awaiting review**
* Impacted Platforms: [iOS]

## Introduction

The iOS Library uses the `hub strategy` to connect to the external accessory (sdl_core). This strategy allows multiple apps to connect to sdl_core at the same time. The `hub strategy` works as follows:
1. iOS App wakes up due to EAAccessory connected message (USB/BT connected)
2. The library waits a specific amount of time which is static per App but is created random based on the App Name (0-10 seconds) (Code [here](https://github.com/smartdevicelink/sdl_ios/blob/master/SmartDeviceLink/SDLIAPTransport.m#L449))
3. The library connects to `prot0`
4. sdl_core responds with a number between 0..29. 
5. The library disconnects and reconnects on `protN`
6. Connection is established

Some iOS limitations have to be clear to understand the need of this strategy: 
* On older iOS versions, if one App is using a protocol string to connect to sdl_core, another App trying to open the connection will disconnect the original App. -> This requires the random delay, to ensure that not two apps connect to the control accessory string (`prot0`) at the same time. 
* iOS suspends Apps that don't open the EAAccessory session inside of 10 seconds after receiving the notification.

## Motivation

We currently see failures of iOS Apps to connect to sdl_core, when plugged in. This happens for some Apps more often than others. We were able to root cause this to Apps, which have a random wait time that is close to the edges. (Close to 0 or close to 10).

## Proposed solution

* We propose to change the `min_value` wait time to 1.5 (seconds).
* We propose to change the `max_value` wait time to 9.5 (seconds).

These two changes significantly improve the connection reliability. 

## Potential downsides

This shrinks the total available connection window from 10 seconds to 8 seconds. This will decrease the theoretical spacing between Apps trying to connect. We have not found this to be a problem. 

## Impact on existing code

We need to change to variables [here](https://github.com/smartdevicelink/sdl_ios/blob/master/SmartDeviceLink/SDLIAPTransport.m#L450). There is no logic change and minimal risk. 

## Alternatives considered

We are investigating further improvements for future proposals, which will complement this change to create a even more robust connection strategy. These improvements include:

* Retry - Allowing a library to retry the connection if the first try failed
* Multisession - Since iOS 10 Apple allows multiple Apps to use the same protocol string (if the accessory is correctly configured). This was not possible previously. This would allow all apps to use one protocol string and allows for simplification of the connection strategy. 
