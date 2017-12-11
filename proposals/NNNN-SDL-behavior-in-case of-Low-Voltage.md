# SDL behavior in case of LOW_VOLTAGE event

* Proposal: [SDL-NNNN](NNNN-filename.md)
* Author: [Alexander Kutsan](https://github.com/LuxoftAKutsan)
* Status: **Awaiting review**
* Impacted Platforms: [Core / Web / RPC / Protocol]

## Introduction

This proposal defines SDL behavior in case of LOW_VOLTAGE event.
LOW_VOLTAGE scenario is triggered when the battery voltage hits below 7v. In case of such event EMMC is turned off and all read/write operations are unavailable. After the voltage level is restored all oprations are resumed.

## Motivation

Implement logic that will allow SDL to resume after battery charge is restored or to start up correctly in the next ingnition cycle if SDL was shut down due to LOW VOLTAGE event. 

## Proposed solution

When battery voltage hits below predifined by PowerManager threshold (e.g.7v) SDL will "freeze" all operation untill it will be switched off or resumed. During LOW_VOLTAGE state proposed the following SDL behavior:

- SDL ignores all requests from mobile applications
- SDL ignores all responses and messages from HMI except messages for "WAKE_UP" or "IGNITION_OFF"
- SDL stops audio/video streaming
- During LOW_VOLTAGE all transports are unavailable for SDL
- SDL persists resumption related data stored before receiving LOW_VOLTAGE message
- After WAKE_UP application will be unregistered and device disconnected
- If LOW_VOLTAGE was received at the moment of writing to policies database, SDL and Policies Manager must keep policies database correct and working. After "WAKE_UP" policy database reflects the last known correct state.
- SDL and PoliciesManager must persist 'consumer data' (resumption-related + local PT) periodically and independently of the external events
- SDL resumes its regular work after receiving "WAKE_UP"
- SDL must be able to start up correctly in the next ignition cycle after it was powered off in low voltage state

## Details of implementation

To implement changes in SDL regarding LOW_VOLTAGE event it is proposed to add new element to <"ApplicationsCloseReason"> enum in HMI_API:

```xml
<enum name="ApplicationsCloseReason">
  <description>Describes the reasons for exiting all of applications.</description>
  <element name="IGNITION_OFF" />
  <element name="MASTER_RESET" />
  <element name="FACTORY_DEFAULTS" />
  <element name="SUSPEND" />
  <element name="LOW_VOLTAGE" />
</enum>
```

On getting "OnExitAllApplications(LOW_VOLTAGE)", SDL must:
  - stop all read write activities
  - ignore all RPC from mobile side
  - ignore all RPCs from HMI side, except "OnAppInterfaceUnregistered(IGNITION_OFF)" or "OnAwakeSDL"

It is expected that in case LOW_VOLTAGE state will be during 10 seconds VMCU shall power off the CCPU and HMI will send "OnAppInterfaceUnregistered(IGNITION_OFF)" to SDL and SDL will finish its work.

SDL must to start up correctly in the next ignition cycle after LOW_VOLTAGE event

When battery voltage recovers, HMI will send "OnAwakeSDL", disconnected application will re-register, SDL must resume its regular behavior.
SDL must resume HMILevel of re-registred applications according to HMILevel resumption requirements

## Potential downsides

During LOW_VOLTAGE event SDL won't be able to notify or unregister applictions due to unavailable transports. Data that was transferred during LOW_VOLTAGE will be lost sinse SDL won't be able to perform any read/write activities. Applications may unregister during LOW_VOLTAGE state on HeartBeat timeout expiration.

## Impact on existing code

* SDL core must be able to support new element in "ApplicationsCloseReason" enum  
* Policies and resumption writing to database process


## Alternatives considered

Due to possible delays between HMI and SDL in case of LOW_VOLTAGE event it is proposed to implement json notification of SDL via mqueue:

In case SDL receives "SDL_LOW_VOLTAGE" message via mqueue, SDL must stop any read/write activities 
SDL continues to listen to mqueue for "WAKE_UP" or "SHUT_DOWN" message via mqueue.

Such solution does not require any changes in HMI_API and will eliminate delays on RPCs handling
