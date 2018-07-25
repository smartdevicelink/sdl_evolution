# SDL behavior in case of LOW_VOLTAGE event

* Proposal: [SDL-0170](0170-sdl-behavior-in-case-of-Low-Voltage.md)
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

Since SDL operations are to be halted including receiving and processing of normal RPC messages from HMI, it is proposed to use system signals to exchange shutdown and wake-up signals between HMI and SDL Core.
In case SDL receives a "LOW_VOLTAGE" signal, SDL must stop any read/write activities until SDL receives a "WAKE_UP" signal.

During LOW_VOLTAGE state the following behavior is proposed:
* SDL ignores all the requests from mobile applications without providing any kind of response
* SDL ignores all responses and messages from HMI except signals for "WAKE_UP" or "IGNITION_OFF"
* SDL stops audio/video streaming services
* All transports are unavailable for SDL
* SDL persists resumption related data stored before receiving a "LOW_VOLTAGE" signal
* SDL and the PoliciesManager must persist 'consumer data' (resumption-related + local PT) periodically and independently of the external events

SDL resumes its regular work after receiving a "WAKE_UP" signal:
* After receiving a "WAKE_UP" signal, all applications will be unregistered and the device disconnected
* If "LOW_VOLTAGE" was received at the moment of writing to policies database, SDL and Policies Manager must keep policies database correct and working. After "WAKE_UP" policy database reflects the last known correct state.
* SDL must be able to start up correctly in the next ignition cycle after it was powered off in low voltage state


## Details of implementation

### Details on Signal Handling
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

### Details on Resumption
Since SDL operations are to be halted including receiving and processing of normal RPC messages from HMI, it is proposed to use the last correct saved applicaton data before LOW VOLTAGE event occurred for resumption.
The resumption flow proposed here is similar to the normal resumption flow performed after an ignition cycle.

* During LOW VOLTAGE state, SDL persists the resumption related data that was stored before the receipt of the "LOW_VOLTAGE" signal.
* If the `LOW_VOLTAGE` signal was received at the moment of writing to policies database, SDL and Policies Manager must keep the policies database correct by completing the write operation.
After the `WAKE_UP` signal is received the policy database reflects the last known correct state.
* Similarly, if the `LOW_VOLTAGE` signal was received at the moment of saving application's state to file system, SDL must keep resumption storage correct by completing the write operation.
* Since after a LOW_VOLTAGE event SDL cannot save any data; in the next ignition cycle, SDL can only perform resumption based on the data saved prior to the occurrence of the LOW_VOLTAGE event.
* SDL resumes its regular work after receiving a `WAKE_UP` signal.
* After receiving the `WAKE_UP` signal, SDL will attempt to restore the applications to the same HMI level that they were in within `ResumptionDelayBeforeIgn` seconds before the receipt of the `LOW_VOLTAGE` signal.
This is provided that the same applications register within `ResumptionDelayAfterIgn` seconds of receipt of the `WAKE_UP` signal and also provided that the user does not launch another application to FULL/LIMITED.

Note: `ResumptionDelayBeforeIgn` and `ResumptionDelayAfterIgn` are defined in SmartDeviceLink.ini.
* HMI levels of applications that do not register within `ResumptionDelayAfterIgn` seconds of the receipt of the `WAKE_UP` signal are not resumed.
* After SDL receives a `LOW_VOLTAGE` signal, if the system shuts down without providing a `WAKE_UP` signal; then on the next ignition cycle
SDL will attempt to restore the applications to the same HMI level that they were in prior to the LOW_VOLTAGE event provided the same applications
register within `ResumptionDelayAfterIgn` seconds of IGNITION ON and provided that the user does not launch another application to FULL/LIMITED.
* If during re-registration the `hashID` provided by the application in the RAI request matches the `hashID` stored by the system, then SDL will attempt to also resume the application's data.

NOTE: SDL can not guarantee correct policy data base and resumption data saving in case LOW VOLTAGE event triggers restrictions to file system from OS side.


## Potential downsides

No ability to get response from SDL using this communication type.

## Alternatives considered

 - Using existing Web Socket transport, adding new RPC's in HMI_API to implement new logic for triggering "frozen" mode, but in this case SDL should not freeze listening and processing messaged from HMI, that cause high power usage.
 - Using additional lightweight transport (mqueue) for sending `LOW_VOLTAGE`, `WAKE_UP`, `IGNITION_OFF` notifications, but it significantly increase complexity of porting SDL on custom OEM platforms and adds additional requirement for OEM manufacturer.
 - Using SIGSTOP/SIGCONT standard UNIX signals for `LOW_VOLTAGE`, `WAKE_UP` notifications, but there is no way to Send IGNITION notification after SIGSTOP.

