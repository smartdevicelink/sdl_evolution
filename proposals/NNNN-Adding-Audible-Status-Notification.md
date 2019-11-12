# Adding Audible Status Notification

* Proposal: [SDL-NNNN](NNNN-Adding-Audible-Status-Notification.md)
* Author: [Shohei Kawano](https://github.com/Shohei-Kawano)
* Status: **Create**
* Impacted Platforms: [Core / iOS / Java Suite / RPC /HMI]

## Introduction

Currenlty, there is no way to independently notify the Audible status to applications that output audio such as SDL Media.  
This time, `OnAudibleStatus` is added as a new API so that the status of Audible can be notified.


## Motivation

As a means to notify the Audible status to applications that output audio.  
In the case of Mobile from Core, Audible without changing the HMI Level by using the parameters `audioStreamingState` and hmiLevel in RPC `OnHMIStatus` Can be notified.  
However, in the case of Core from HMI, there is no appropriate API to notify the Audible status by itself,  
so a new API to notify the audio status can be added to notify the audio status regardless of the screen status Like that.  
As a specific example, there is a specification that allows a user to display and receive an incoming call with Notification, Overlay or ONS without changing to the telephone screen when an incoming call is received.  
In this case, since there is no appropriate API to notify the Audible status independently, using `OnEventChanged (PHONE_CALL)` displays Music App on the screen, but the HMI Level becomes Background.  
As a response method, we propose to add a new API to notify the Audible status. 


## Proposed solution

A new API `OnAudibleStatus` that can be used with the HMI API is added.  
API parameters to be added are `appName` and `audibleState`, so that the target application and Audible status can be notified.  


HMI API  
```
<function name="OnAudibleStatus" messagetype="notification">	
    <description>	
        It can notify the Audible status independently of the screen status.	
    </description>	
    <param name="appName" type="String" maxlength="100" mandatory="true">	
        <description> Application Name </description>	
    </param>	
    <param name="audibleState" type="AudibleState" defvalue="AUDIBLE" mandatory="true">	
        <description> See AudibleState. If it is NOT_AUDIBLE, the app must stop voice to SDL Core(stop service). </description>	
    </param>	
</function>	
	
	
<enum name="AudibleState">	
    <description> Enumeration that describes possible states of audio output. </description>	
    <element name="AUDIBLE"/>	
    <element name="ATTENUATED"/>	
    <element name="NOT_AUDIBLE"/>	
</enum>	
```

## Potential downsides

Nothing.


## Impact on existing code

No Impact. Because, just add new API and enum.

## Alternatives considered

There is no alternative. 
There is idea to add only parameters to the existing API. However, there is no existing API that suits the purpose, and since the merit of being able to handle audio alone is losted, it seems not good.
