# SetMediaClockTimer must be expanded with new _enableSeek_ param.

* Proposal: [SDL-NNNN](NNNN-enableSeek_at_SetMediaClockTimer.md)
* Author: [Melnyk Tetiana](https://github.com/TMelnyk)
* Status: **Awaiting review**
* Impacted Platforms: Core / Android / iOS / RPC

## Introduction

The proposal is to support new parameter _enableSeek_ and transfer _OnSeekMediaClockTimer_ notification from HMI to mobile application.

## Motivation

A notification will be provided if the user touches (or seeks) to a particular position on the HMI mediaclock timer. The notification will contain a starttime with the position the user has seeked to.

## Proposed solution

SDL transfers _OnSeekMediaClockTimer_ notification from HMI to mobile application independently on value of _enableSeek_ (true or false) parameter at _SetMediaClockTimer_request_.   

1. In case SDL receives OnSeekMediaClockTimer notification from HMI and this notification is valid and NOT allowed by Policies, _SDL must_:   
   - log corresponding error internally;
   - ignore this OnSeekMediaClockTimer notification;<br>   
_SDL must NOT_:
   - transfer OnSeekMediaClockTimer notification from HMI to mobile application. 

2. In case SDL receives OnSeekMediaClockTimer notification from HMI and this notification is valid and allowed by Policies, _SDL must_:
   - transfer OnSeekMediaClockTimer notification from HMI to mobile application. 

3. In case SDL receives SetMediaClockTimer_request with:
   - valid "enableSeek" parameter from mobile application;
   - other valid parameters related to this request;   
_SDL must_:
   - transfer this SetMediaClockTimer (params, \<enableSeek>) to HMI;
   - respond with \<received_resultCode_from_HMI> to mobile application.

4. In case HMI sends invalid notification that SDL should transfer to mobile app, SDL must log the issue and ignore this notification.   
_**Information:**_   
   4.1. Invalid notifications means the notification contains:
       - params out of bounds;
       - mandatory params are missing;
       - params of wrong type;
       - invalid json;
       - incorrect combination of parameters.    

   4.2. List of related HMI_API notifications:
       - Buttons.OnButtonEvent
       - Buttons.OnButtonPress
       - BasicCommunication.OnSystemRequest
       - VR.OnCommand
       - UI.OnCommand
       - UI.OnKeyboardInput
       - UI.OnTouchEvent
       - Navigation.OnTBTClientState
       - VehicleInfo.OnVehicleData
       - Navigation.OnWayPointChange

5. In case the request comes to SDL with wrong json syntax, _SDL must_ respond with resultCode "INVALID_DATA" and success:"false" value.

6. In case the request comes to SDL with wrong type parameters (including parameters of the structures), _SDL must_ respond with resultCode "INVALID_DATA" and success:"false" value.   
_**Exception**_: Sending enum values as "Integer" ones must be process successfully as the position number in the enum (in case not out of range, otherwise the rule above is applied).   
_**Example:**_ sending "String" type values instead of "Integer" ones.

7. In case the request comes without parameters defined as mandatory in mobile API, _SDL must_ respond with resultCode "INVALID_DATA" and success:"false" value.   
_**Exception:**_ For Show request which contains all parameters as mandatory=false, _SDL must_ return INVALID data if the request doesn't contain any parameters at all.

8. In case the request comes to SDL with out-of-bounds array ranges or out-of-bounds parameters values (including parameters of the structures) of any type, _SDL must_ respond with resultCode "INVALID_DATA" and success:"false" value.

9. In case HMI sends invalid response by any reason that SDL must transfer to mobile application, _SDL must_: 
   - log the error internally;
   - respond GENERIC_ERROR (success:false, info: "Invalid message received from vehicle") to mobile application.
_**Information:**_   
    9.1. Invalid response means the response contains:   
       - params out of bounds;   
       - mandatory params are missing;   
       - params of wrong type;   
       - invalid json;   
       - incorrect combination of params.<br>   
  9.2. Related requirements about notifications:   
        - In case HMI sends invalid notification that SDL should transfer to mobile app, _SDL must_ log the issue and ignore this notification.   _**Example:**_ OnLanguageChange with "hjksdhfkh" instead of "EN-EN".   
        - In case HMI sends invalid notification that SDL must use internally, _SDL can log_ the issue and just ignore the notification.   _**Example:**_ OnAppDeactivated with invalid appID, which must trigger OnHMIStatus to the application.

10. In case SDL cuts off fake parameters from response (request ) that SDL should transfer to mobile app AND this response (request) is invalid, _SDL must_:
   - respond GENERIC_ERROR (success:false, <info>) to mobile application. 

11. In case HMI sends request (response, notification) with fake parameters that SDL should transfer to mobile app, _SDL must_:
   - validate received response; 
   - cut off fake parameters; 
   - transfer this request (response or notification) to mobile application.

## Detailed design

TBD

## Impact on existing code

TBD

## Alternatives considered

TBD
