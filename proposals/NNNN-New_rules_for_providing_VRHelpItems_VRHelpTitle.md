# Handling VR help requests when application does not send VR help prompt

* Proposal: [SDL-NNNN](NNNN-New_rules_for_providing_VRHelpItems_VRHelpTitle.md)
* Author: [Irina Getmanets](https://github.com/GetmanetsIrina)
* Status: **Awaiting review**
* Impacted Platforms: Core, RPC

## Introduction

"vrHelp" items are commands in Voice Recognition(VR) menu, "helpPrompt" is the message to speak by HMI that initiated by voice 'Help' command.
"vrHelp" items and "helpPrompt" are set by [SetGlobalProperties](https://github.com/smartdevicelink/sdl_core/blob/master/src/components/interfaces/MOBILE_API.xml#L3125) for helping user to make voice navigation over registered application, what is very useful in case your hands are busy with driving.
Safety requirements are very strong in automotive, so possibility to use Voice Recognition should be provided for driver all the time.

## Motivation

If there is no SetGlobalProperties issued, the help items list will be populated with command list sent to voice module or with default values from [smartDeviceLink.ini](https://github.com/smartdevicelink/sdl_core/blob/master/src/appMain/smartDeviceLink.ini#L122) file. If application issues a SetGlobalProperties with help item list, then this list will have precedence and it will be displayed on HMI.
But there is no guarantee that Application provide "vrHelp" and "helpPrompt", and possible situation when driver couldn't use Voice Recognition.
The purpose of proposal is to implement logic for values of "vrHelp" item and "helpPrompt" in case they are not provided by application.

## Proposed solution

The solution proposed here is to implement next items:
1. In case mobile application does NOT send SetGlobalProperties request with "vrHelp" and "helpPrompt" during 10 sec from its registration and this mobile application has NO registered AddCommand and/or DeleteCommand requests (resumed during data resumption).
SDL must provide the default values of "helpPrompt" and "vrHelp" to HMI.
SDL must start this 10 sec timer only once 
	* in case of application registration
	* after HMILevel resumption 
	* activation after registration.
2. In case mobile application successfully registers and gets any HMILevel other than NONE OR changes it's level from NONE to any other (in case of HMILevel resumption or activation).
SDL must:
	* create internal list with "vrHelp" and "helpPrompt" based on successfully registered AddCommand and/or DeleteCommand requests (resumed within data resumption process)
	* start 10 sec timer right after assigning HMI level different from NONE for registered application for waiting SetGlobalProperties request from mobile application.
SDL must start this 10 sec timer only once in case of application registration OR after HMILevel resumption OR activation after registration.
3. In case mobile application sends SetGlobalProperties request during 10 sec timer with: valid "helpPrompt" and "vrHelp" params, other valid params related to this RPC.
SDL must:
	* transfer TTS.SetGlobalProperties ("helpPrompts", params) with adding period of silence between each command "helpPrompt" to HMI
	* transfer UI.SetGlobalProperties ("vrHelp" params) to HMI respond with <resultCode_received_from_HMI> to mobile application.
4. In case SDL already transfers UI/TTS.SetGlobalProperties with "vrHelp" and "helpPrompt" received from mobile application to HMI and 10 sec timer is NOT expired yet and mobile application sends AddCommand and/or DeleteCommand requests to SDL.
SDL must update internal list with new values of "vrHelp" and "helpPrompt" params ONLY after successful response from HMI.
SDL must NOT send updated values of "vrHelp" and "helpPrompt" via TTS/UI.SetGlobalProperties requests to HMI.
5. In case mobile application does NOT send SetGlobalProperties with "vrHelp" and "helpPrompt" to SDL during 10 sec timer and SDL already sends by itself UI/TTS.SetGlobalProperties with values of "vrHelp" and "helpPrompt" to HMI and mobile application sends AddCommand and/or DeleteCommand requests to SDL.
SDL must:
 	* update internal list with new values of "vrHelp" and "helpPrompt" params ONLY after successful response from HMI
 	* send updated values of "vrHelp" and "helpPrompt" via TTS UI.SetGlobalProperties to HMI till mobile application sends SetGlobalProperties request with valid "vrHelp" and "helpPrompt" params to SDL.
6. In case mobile application has NO registered AddCommand and/or DeleteCommand requests (resumed within data resumption process).
SDL must use current appName as default value for "vrHelp" parameter, retrieve value of "helpPrompt" from .ini file ([\[GLOBAL PROPERTIES\] section -> "HelpPrompt" param](https://github.com/smartdevicelink/sdl_core/blob/master/src/appMain/smartDeviceLink.ini#L122)).
7. In case mobile application sends SetGlobalProperties request during 10 sec timer without "helpPrompt" and/or "vrHelp" params and with other valid params related to this RPC and this mobile application has successfully registered VR.AddCommand and/or VR.DeleteCommand requests (resumed during data resumption).
SDL must provide the value of "helpPrompt" and/or "vrHelp" from internal list based on registered VR.AddCommand and VR.DeleteCommand requests to HMI.
8. In case mobile application does NOT send SetGlobalProperties with "vrHelp" and "helpPrompt" to SDL during 10 sec timer and SDL already sends by itself UI/TTS.SetGlobalProperties with values of "vrHelp" and "helpPrompt" to HMI and SDL does NOT receive response from HMI at least to one TTS/UI.SetGlobalProperties during <DefaultTimeout> (the value defined at .ini file).
SDL must log corresponding error internally and continue work as assigned.
9. In case mobile application does NOT send SetGlobalProperties with "vrHelp" and "helpPrompt" to SDL during 10 sec timer and SDL already sends by itself UI/TTS.SetGlobalProperties with values of "vrHelp" and "helpPrompt" to HMI and SDL receives any <errorCode> in response from HMI at least to one TTS/UI.SetGlobalProperties.
SDL must log corresponding error internally and continue work as assigned.
10. In case mobile application does NOT send SetGlobalProperties request at all with "vrHelp" and "helpPrompt" during 10 sec timer and "vrHelp" and "helpPrompt" were NOT resumed within data resumption process (at SetGlobalProperties) and this mobile application has successfully registered AddCommand and/or DeleteCommand requests (resumed within data resumption).
SDL must provide the value of "helpPrompt" and "vrHelp" from internal list based on registered AddCommand and DeleteCommand requests to HMI.
11. In case SDL transfers AddCommand and/or DeleteCommand requests from mobile application to HMI and SDL receives any <errorCode> at response from HMI.
SDL must transfer received <errorCode> from HMI to mobile application.
SDL must NOT update internal list with "vrHelp" and "helpPrompt" params.
12. In case mobile application sends SetGlobalProperties request during 10 sec timer: without "helpPrompt" and/or "vrHelp" params, other valid params related to this RPC and this mobile application has NO registered VR.AddCommand and/or VR.DeleteCommand requests (resumed during data resumption).
SDL must provide the default values of "helpPrompt" and "vrHelp" to HMI.
13. In case mobile application sends ResetGlobalProperties_request to SDL.
SDL must:
	* send default values of "vrHelp" and "helpPrompt" param to HMI (via UI/TTS.SetGlobalProperties),
	* continue update internal list with "vrHelp" and "helpPrompt" parameters with new requested AddCommand and/or DeleteCommand till mobile application sends SetGlobalProperties request with valid "vrHelp" and "helpPrompt" params to SDL.
SDL must NOT send by itself UI/TTS.SetGlobalProperties request with updated "vrHelp" and "helpPrompt" to HMI.
14. In case SetGlobalProperties with "vrHelp" and "helpPrompt" params was successfully resumed within data resumption process and mobile application either does NOT send SetGlobalProperties request during 10 sec timer or sends SetGlobalProperties request without "vrHelp" AND "helpPrompt" params during 10 sec timer.
SDL must continue creating of internal list with "vrHelp" and "helpPrompt" based on successfully registered AddCommand and/or DeleteCommand requests.
SDL must NOT send SetGlobalProperties request with "vrHelp" and "helpPrompt" to HMI (with values from internal list OR default values) (meaning: HMI already received "vrHelp" and "helpPrompt" during data resumption and SDL should NOT re-write these values by sending SetGlobalProperties by itself).

## Potential downsides

N/A

## Impact on existing code

Application registration process, data resumption procedure.

## Alternatives considered

N/A
