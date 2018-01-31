# Handling VR help requests when application does not send VR help prompt

* Proposal: [SDL-0122](0122-New_rules_for_providing_VRHelpItems_VRHelpTitle.md)
* Author: [Irina Getmanets](https://github.com/GetmanetsIrina)
* Status: **Ready for review**
* Impacted Platforms: Core, RPC

## Introduction
When the user asks for "help" regarding an application, the help prompt that is played and the help menu that is displayed for that application is based on the information provided by the application through the [SetGlobalProperties RPC](https://github.com/smartdevicelink/sdl_core/blob/master/src/components/interfaces/MOBILE_API.xml#L3125).
Through this proposal we propose a mechanism for handling "help" requests by the user when the application does not provide any such information.

## Motivation
One of the simplest (and intuitive) ways to find out information about how to use an application is to ask for "help" through the voice recognition system. The system then plays the help prompt and displays the help items provided by that application. However if an application does not provide this information, then the system does not provide any kind of useful response to the user. Most users are likely to view this as a problem with the infotainment system or with the SDL technology.


## Proposed solution

The `vrHelp` parameter of the `SetGlobalProperties` RPC is used by the system to display the help items on the screen and the `helpPrompt` parameter is used by the system for playing out the associated TTS help prompt.

The proposed mechanism is detailed below:
1. When an application registers on the HU and moves to any HMIState other than NONE, then SDL Core shall start a **10 second** timer waiting for the application to send a `SetGlobalProperties` RPC with the `vrHelp` and `helpPrompt` parameters.
2. While the timer is running, if the application sends any `AddCommand` with the `vrCommands` parameter then SDL Core shall create a list of the added `vrCommands`.
3. While the timer is running, if the application sends any `DeleteCommand` requests then SDL Core shall remove the added `vrCommands` from its list.
4. If the timer times out then SDL Core shall:
	1. construct the `vrHelp` parameter using the data from the list SDL Core internally created.
  	2. construct the `helpPrompt` parameter using the data from the list SDL Core internally created.
  	3. then send these parameters to the HMI via the `SetGlobalProperties` RPC.
5. If after SDL Core sends the `SetGlobalProperties` RPC, applications sends further AddCommmand/DeleteCommand requests then SDL Core shall send `SetGlobalProperties` with the updated parameters.(The full list of parameters needs to be sent and not just the recently added one).
6. If at any point in time, the applications sends `SetGlobalProperties` RPC with the `vrHelp` **and** `helpPrompt` parameters, then SDL Core shall continue with the existing behavior of forwarding such requests to HMI and SDL Core shall delete its internal list and stop sending `SetGlobalProperties` RPC to HMI after each AddCommmand/DeleteCommand requests received from mobile.

7. If at any point in time, the applications sends `SetGlobalProperties` RPC with **either** of `vrHelp` **or** `helpPrompt` parameters, then SDL Core shall continue with the existing behavior of forwarding such requests to HMI and SDL Core shall not delete its internal list and shall continue to update the parameter which was not provided by the application.
8. The same process shall be followed during application resumption as well.

Note:
10 second timer:
  - When an application moves from HMI state of NONE, then applications send a bunch of `AddCommand` requests. This timer helps to buffer the requests so that SDL Core can send a single `SetGlobalProperties` request to HMI instead of several.
  - The value of 10 seconds is chosen to give sufficient time for buffering and before the user is likely to trigger a "help" request. This is based on a subjective analysis.

### Design approach:
Create HelpPromptManager with folowing interface:
 - OnVrCommandAdd (command) : Adds command to constructed values, and send SetGlobalProperties if required
 - OnVrCommandDeleted (command) : Removes command from constructed values, and send SetGlobalProperties if required
 - OnTimeoutExpired () : Send SetGlobalProperties with constructed `vrHelp` **and/or** `helpPrompt` parameters
 - OnSetGlobalPropertiesReceived (message) : Stop constructing `vrHelp` **and/or** `helpPrompt` if they are presend in message
 ![Class diagramm](/assets/proposals/0122-new_rules_for_providing_vr_help_items_vr_help_title/0122-New_rules_for_providing_VRHelpItems_VRHelpTitl.png)
## Potential downsides

N/A

## Impact on existing code

SDL Core logic alone has to be modified according to the proposed design.
## Alternatives considered

N/A

