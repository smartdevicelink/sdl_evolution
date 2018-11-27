# Secondary Transport Optimization

* Proposal: [SDL-NNNN](nnnn-secondary-transport-optimization.md)
* Author: [Joey Grover](https://github.com/joeygrover)
* Status: **Awaiting Review**
* Impacted Platforms: [Core / iOS / Android]

## Introduction

This proposal aims to optimize how secondary transports are connected and registered. The original proposal [SDL-0141](0141-multiple-transports.md) stated secondary transports should be connected to and registered on immediately when they are available. This proposal is to change that to connect and register on when necessary by the application.

## Motivation

The initial design had an oversight on transports optimization that would cause unnecessary battery drain and resource usage on the user's device. This is because an app would be required to connect a secondary transport like TCP immediately when the head unit sent a message that it was ready. In practical terms this was right after the app registered and was still in the HMI_NONE state. This meant, the app would create a TCP connection every time the user connected their phone via SDL even without any intention of using the app that connected the extra transport. This becomes increasingly irresponsible of the library when taking the example of a user that gets in and out of the vehicle multiple times over a short time span where each session a new TCP connection is established, maintained, and eventually torn down. The SDL library should not use resources that it doesn't fully intended on using. 

## Proposed solution

The SDL library should only start a connection when the app intends to use it. This would reduce the unnecessary resource usage and improve battery usage of apps that implement the SDL library. The new flow should be as follows:

1. App connects primary transport to Core
2. App sends `StartService` for an RPC service
3. If accepted, Core responds with a `StartServiceACK` that contains the potentially available secondary transports and which transports can be used for the audio and video service.
4. App starts the regular RPC service handshake and flow
5. During or after step 4, Core sends a `TransportEventUpdate` packet that contains the IP and port of a listening TCP connection in which the app can connect. The app caches this data.
6. App follows either Path A or B

#### Path A: App requires the secondary transport

1. App wishes to start either the video or audio service and Core has indicated that they are preferred to be started on the secondary transport.
2. App checks current connected transports: 
     - If a suitable transport is connected the app will move to the next step
     - If no suitable transport is connected: 
         1. The app will retrieve the previously cached IP and port of the module's listening TCP transport. 
         2. The app will attempt to request a TCP connection be established.
         3. Once a connection is made, the app will move to the next step 
3. The app sends a `RegisterSecondaryTransport` to Core over the connected secondary transport
4. If successful, Core responds with a `RegisterSecondaryTransportACK` on the same transport
5. The app then sends a `StartService` packet with the service type they wanted to start and the process resumes the standard flow


#### Path B: App does not require the secondary transport or the app is never moved past `HMI_NONE`

1. The app will continue to work in the normal flow
2. If the app never needs to start a service that requires a secondary transport connection, the app will never request one becomes established.



## Potential downsides

- This change introduces a potential lag in the time an app starts and connects over a secondary transport. However, it should be very minimal.


## Impact on existing code

* The Android library is already designed to work this way so no changes are necessary.
* The iOS library would need to alter it's code to implement this new logic. However, since an iOS app can't maintain a TCP connection if it is not in the foreground of the device the altered flow is less impactful.



## Alternatives considered

* Nothing beyond keeping the original design.
