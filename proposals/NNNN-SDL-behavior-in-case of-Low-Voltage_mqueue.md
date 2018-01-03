# SDL behavior in case of LOW_VOLTAGE event

* Proposal: [SDL-NNNN](NNNN-filename.md)
* Author: [Alexander Kutsan](https://github.com/LuxoftAKutsan)
* Status: **Awaiting review**
* Impacted Platforms: [Core / Web / RPC / Protocol]

## Introduction

This proposal defines SDL behavior in case of LOW_VOLTAGE event.
LOW_VOLTAGE scenario is triggered when the battery voltage hits below predifined by PowerManager threshold. 
In case of such event EMMC is turned off and all read/write operations are unavailable. After the voltage level is restored all oprations are resumed.

## Motivation

Implement logic that will allow SDL to resume after battery charge is restored or to start up correctly in the next ingnition cycle if SDL was shut down due to LOW VOLTAGE event. 

## Proposed solution

 When battery voltage hits below predifined by PowerManager threshold (e.g.7v) SDL will "freeze" all operation untill it will be switched off or resumed.  
 
 During LOW_VOLTAGE state proposed the following SDL behavior:
 
* In case SDL receives "SDL_LOW_VOLTAGE" message via mqueue, SDL must stop any read/write activities until getting "WAKE_UP" message via mqueue.
* SDL ignores all requests from mobile applications
* SDL ignores all responses and messages from HMI except messages for "WAKE_UP" or "IGNITION_OFF"
* SDL stops audio/video streaming
* During LOW_VOLTAGE all transports are unavailable for SDL
* SDL persists resumption related data stored before receiving LOW_VOLTAGE message
* After WAKE_UP application will be unregistered and device disconnected
* If LOW_VOLTAGE was received at the moment of writing to policies database, SDL and Policies Manager must keep policies database correct and working. After "WAKE_UP" policy database reflects the last known correct state.
* SDL and PoliciesManager must persist 'consumer data' (resumption-related + local PT) periodically and independently of the external events
* SDL resumes its regular work after receiving "WAKE_UP"
* SDL must be able to start up correctly in the next ignition cycle after it was powered off in low voltage state  


## Details of implementation  

Mqueue channel of communication between HMI and SDL must be added.

## Potential downsides  

Major requirements for OEM manufactures (additional channel of communication is needed) 

## Alternatives considered  

Using existing Web Socket transport  
adding new RPCs in HMI_API to implement new logic for triggering "frozen" mode

