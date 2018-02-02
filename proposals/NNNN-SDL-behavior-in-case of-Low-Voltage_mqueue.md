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

Implement logic that will allow SDL to resume after battery charge is restored or to start up correctly in the next ingnition cycle if SDL was shut down due to LOW VOLTAGE event. When battery voltage hits below predifined by PowerManager threshold (e.g.7v) SDL will "freeze" all operation untill it will be switched off or resumed.

## Proposed solution

In case SDL receives "SDL_LOW_VOLTAGE" message via mqueue, SDL must stop any read/write activities until getting "WAKE_UP" message via mqueue.  

During LOW_VOLTAGE state proposed the following SDL behavior:
* SDL drops off all the requests from mobile applications withough providing any kind of response
* SDL ignores all responses and messages from HMI except messages for "WAKE_UP" or "IGNITION_OFF"
* SDL stops audio/video streaming
* All transports are unavailable for SDL
* SDL persists resumption related data stored before receiving LOW_VOLTAGE message
* SDL and PoliciesManager must persist 'consumer data' (resumption-related + local PT) periodically and independently of the external events

SDL resumes its regular work after receiving "WAKE_UP":

* After WAKE_UP application will be unregistered and device disconnected
* If LOW_VOLTAGE was received at the moment of writing to policies database, SDL and Policies Manager must keep policies database correct and working. After "WAKE_UP" policy database reflects the last known correct state.
* SDL must be able to start up correctly in the next ignition cycle after it was powered off in low voltage state  


## Details of implementation  

To implement changes in SDL regarding LOW_VOLTAGE event it is proposed to add mqueue channel of communication between HMI and SDL.

## Potential downsides  

Major requirements for OEM manufactures (additional channel of communication is needed) 

## Alternatives considered  

Using existing Web Socket transport, adding new RPCs in HMI_API to implement new logic for triggering "frozen" mode.

