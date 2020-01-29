# Separating the change of Audible status and the change of HMI Status

* Proposal: [SDL-0264](0264-Separating-the-change-of-Audible-status-and-the-change-of-HMI-Status.md)
* Author: [Shohei Kawano](https://github.com/Shohei-Kawano)
* Status: **Accepted with Revisions**
* Impacted Platforms: [Core / HMI]

## Introduction

Currently, there is no way to independently notify the Audible status to applications that output audio such as SDL Media.  
By changing the behavior of the existing API, the Audible state can be switched while maintaining the screen.  

## Motivation

The motivation for this proposal is to allow the ability to set an Audible status to applications that output audio.  
Currently, the `OnHMIStatus` notification from Core to Mobile can set an Audible state without changing the hmiLevel by using the parameters audioStreamingState and hmiLevel. However, there is currently no notification from HMI to Core to set the Audible status, so a new API to notify the audio status can be added regardless of the screen status.  
As a specific example, there is a specification that allows a user to display and receive an incoming call with Notification, Overlay or ONS without changing to the telephone screen when an incoming call is received.  
In this case, since there is no appropriate API to notify the Audible status independently, using `OnEventChanged (PHONE_CALL)` displays Music App on the screen, but the HMI Level becomes Background.  
As a response method, we propose to avoid the problem by clearly separating the change of Audible status and the change of HMI Status.  

## Proposed solution

Change [OnEventChanged (PHONE_CALL, active: true)](https://github.com/smartdevicelink/sdl_hmi_integration_guidelines/blob/master/docs/BasicCommunication/OnEventChanged/index.md#phone_call%7D) behavior as follows:  
  
**Table 1** Behavior of `OnEventChanged (PHONE_CALL, active: true)`  

|state|result|
|----|----|
|Current|Change the HMI state of all applications currently either in FULL or LIMITED to (BACKGROUND, NOT_AUDIBLE)|
|Changed|Keep the HMI state of all applications but change audible state of all applications to NOT_AUDIBLE|

If HU wants to switch the screen (HMI Status) during PHONE_CALL, they can use API `BC.OnAppDeactivated (AppID)` and `BC.OnAppActivated (AppID)`.  

## Potential downsides

It is considered that there is an impact by continuing to display the SDL app screen when calling `OnEventChanged (PHONE_CALL, active: true)`.  
However, many HUs display the PHONE_CALL screen in full screen, so there is no particular impact.  

## Impact on existing code

SDL Core needs updated behavior of `OnEventChanged (PHONE_CALL, active: true)`.  
HMI may need to call `BC.OnAppDeactivated (AppID)` for explicit control of HMI State.  

## Alternatives considered

An alternative is to add a new API.  
However, it should be avoided due to the large amount of change.  
