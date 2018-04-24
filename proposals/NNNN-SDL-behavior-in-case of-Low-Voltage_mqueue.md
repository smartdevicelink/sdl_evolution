# SDL behavior in case of LOW_VOLTAGE event

* Proposal: [SDL-NNNN](NNNN-filename.md)
* Author: [Alexander Kutsan](https://github.com/LuxoftAKutsan)
* Status: **Awaiting review**
* Impacted Platforms: [Core / Web / RPC]

## Introduction

This proposal defines SDL behavior when HMI requires SDL's services to be suspended due to a low voltage event.  
A low voltage scenario is triggered when the battery voltage hits below a certain predefined threshold set by the system.  
In case of such an event, the EMMC is turned off and all read/write operations are unavailable.  
After the voltage level is restored all oprations are resumed.

## Motivation

Implement logic that will allow SDL to resume after battery charge is restored or to start up correctly in the next ingnition cycle if SDL was shut down due to LOW VOLTAGE event.  
When battery voltage hits below the predefined threshold set by the system (e.g.7v) SDL will "freeze" all operations until it will be switched off or resumed.

## Proposed solution

Since SDL operations are to be halted including receiving and processing of normal RPC messages from HMI, it is proposed to setup a separate communication medium such as a message queue between HMI and SDL to exchange shutdown and wakeup signals.
In case SDL receives "LOW_VOLTAGE" message via message queue, SDL must stop any read/write activities until SDL receives a "WAKE_UP" message via the message queue.  

During LOW_VOLTAGE state the following behavior is proposed:
* SDL drops off all the requests from mobile applications withough providing any kind of response
* SDL ignores all responses and messages from HMI except messages for "WAKE_UP" or "IGNITION_OFF"
* SDL stops audio/video streaming services
* All transports are unavailable for SDL
* SDL persists resumption related data stored before receiving LOW_VOLTAGE message
* SDL and PoliciesManager must persist 'consumer data' (resumption-related + local PT) periodically and independently of the external events

SDL resumes its regular work after receiving a "WAKE_UP" message:
* After receiving a WAKE_UP message, all applications will be unregistered and the device disconnected
* If LOW_VOLTAGE was received at the moment of writing to policies database, SDL and Policies Manager must keep policies database correct and working. After "WAKE_UP" policy database reflects the last known correct state.
* SDL must be able to start up correctly in the next ignition cycle after it was powered off in low voltage state  


## Details of implementation  

To implement changes in SDL regarding LOW_VOLTAGE event it is proposed to add a message queue channel of communication between HMI and SDL.

Mqueue name can be specified in smartdevicelink.ini file:
```
[MAIN] 
; Message queue name used by SDL for handling LOW VOLTAGE functionality
SDLMessageQueueName = /SDLMQ

```  
By default mqueue name for handling LOW VOLTAGE functionality is: /SDLMQ

Message queue signals value:  

|Signal name|Value(string)|
|:---|:---| 
|LOW_VOLTAGE|"LOW_VOLTAGE"|
|WAKE_UP|"WAKE_UP"|
|IGNITION_OFF|"IGNITION_OFF"|

## Potential downsides  

Major requirements for OEM manufactures (additional channel of communication is needed) 

## Alternatives considered  

Using existing Web Socket transport, adding new RPCs in HMI_API to implement new logic for triggering "frozen" mode.

