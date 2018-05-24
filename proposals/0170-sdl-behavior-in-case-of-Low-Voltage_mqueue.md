# SDL behavior in case of LOW_VOLTAGE event

* Proposal: [SDL-0170](0170-sdl-behavior-in-case-of-Low-Voltage_mqueue.md)
* Author: [Alexander Kutsan](https://github.com/LuxoftAKutsan)
* Status: **Accepted with Revisions**
* Impacted Platforms: [Core / Web / RPC]

## Introduction

This proposal defines SDL behavior when HMI requires SDL's services to be suspended due to a low voltage event.  
A low voltage scenario is triggered when the battery voltage hits below a certain predefined threshold set by the system.  
In case of such an event, the EMMC is turned off and all read/write operations are unavailable.  
After the voltage level is restored all operations are resumed.

## Motivation

Implement logic that will allow SDL to resume after battery charge is restored or to start up correctly in the next ignition cycle if SDL was shut down due to a LOW_VOLTAGE event.  
When battery voltage hits below the predefined threshold set by the system (e.g.7v) SDL will "freeze" all operations until it will be switched off or resumed.

## Proposed solution

Since SDL operations are to be halted including receiving and processing of normal RPC messages from HMI, it is proposed to setup a separate communication medium such as a message queue between HMI and SDL to exchange shutdown and wake-up signals.
In case SDL receives a "LOW_VOLTAGE" message via message queue, SDL must stop any read/write activities until SDL receives a "WAKE_UP" message via the message queue.  

During LOW_VOLTAGE state the following behavior is proposed:
* SDL ignores all the requests from mobile applications without providing any kind of response
* SDL ignores all responses and messages from HMI except messages for "WAKE_UP" or "IGNITION_OFF"
* SDL stops audio/video streaming services
* All transports are unavailable for SDL
* SDL persists resumption related data stored before receiving a "LOW_VOLTAGE" message
* SDL and the PoliciesManager must persist 'consumer data' (resumption-related + local PT) periodically and independently of the external events

SDL resumes its regular work after receiving a "WAKE_UP" message:
* After receiving a "WAKE_UP" message, all applications will be unregistered and the device disconnected
* If "LOW_VOLTAGE" was received at the moment of writing to policies database, SDL and Policies Manager must keep policies database correct and working. After "WAKE_UP" policy database reflects the last known correct state.
* SDL must be able to start up correctly in the next ignition cycle after it was powered off in low voltage state  


## Details of implementation  

To implement changes in SDL regarding LOW_VOLTAGE event it is proposed to use UNIX signals for communication between HU system and SDL.
Unix signals provide ability to use signals from SIGRTMIN to SIGRTMAX for custom needs. SDL may use this range for handling
 `LOW_VOLTAGE`, `WAKE_UP`, `IGNITION_OFF` notifications. 

In ini file may be defined offset for from SIGRTMIN from this notifications : 
```
[MAIN] 
LowVoltageSignal = 1 ; Offset for from SIGRTMIN
WakeUpSignal = 2 ; Offset for from SIGRTMIN
IgnitionOffSignal = 2 ; Offset for from SIGRTMIN
```

OEM manufacturer may redefine this signals or expand it for custom needs.

## Potential downsides  

No ability to get response from SDL using this communication type.

## Alternatives considered  

 - Using existing Web Socket transport, adding new RPC's in HMI_API to implement new logic for triggering "frozen" mode, but in this case SDL should not freeze listening and processing messaged from HMI, that cause high power usage.
 - Using additional lightweight transport (mqueue) for sending `LOW_VOLTAGE`, `WAKE_UP`, `IGNITION_OFF` notifications, but it significantly increase complexity of porting SDL on custom OEM platforms and adds additional requirement for OEM manufacturer.
 - Using SIGSTOP/SIGCONT standard UNIX signals for `LOW_VOLTAGE`, `WAKE_UP` notifications, but there is no way to Send IGNITION notification after SIGSTOP. 


