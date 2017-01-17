# Communication app activation during active embedded audio source or navigation

* Proposal:0023-Communication-app-activation.md
* Author: Luxoft/FORD
* Status: Opened
* Impacted Platforms: Core

## Introduction
This proposal is to provide communication app activation during active embedded sources.

## Motivation
Covered cases:
voice-com app activation during embedded audio source
voice-com app activation during embedded navigation
 . MixingAudioSupported=true or false 

## Proposed solution

In case
communication app in LIMITED and AUDIBLE due to active embedded navigation and SDL receives SDL.ActivateApp (<appID_of_communication_app>) from HMI
SDL must: 
respond SDL.ActivateApp (SUCCESS) to HMI
send OnHMIStatus (FULL, AUDIBLE) to mobile app (embedded navigation is still active) 


In case communication app in FULL and AUDIBLE and embedded navigation is being switched on, 
SDL must: 
switch the mobile app to HMIStatus (LIMITED, AUDIBLE), HMI switches off embedded audio source.

In case communication app in LIMITED and AUDIBLE due to active embedded navigation
and "MixingAudioSupported" = true at .ini file
and SDL receives TTS.Started from HMI
SDL must: 
send OnHMIStatus (LIMITED, ATTENUATED) to mobile app
send OnHMIStatus (LIMITED, AUDIBLE) to mobile app right after embedded navigation stops streaming (SDL receives TTS.Stopped from HMI) 

In case communication app in BACKGROUND and NOT_AUDIBLE due to active embedded audio source () 
and user activates this communication app
and SDL receives from HMI:
a) OnEventChanged (AUDIO_SOURCE, isActive=false) 
b) SDL.ActivateApp (<appID_of_communication_app>) 
SDL must:
respond SDL.ActivateApp (SUCCESS) to HMI
send OnHMIStatus (FULL, AUDIBLE) to mobile app
Information: 
a. Communication app activation is the trigger for HMI to switch off embedded audio source
b. HMI switches off embedded audio source and sends OnEventChanged (AUDIO_SOURCE, isActive=false) to SDL 


In case voice-com app in LIMITED and AUDIBLE due to active embedded navigation and "MixingAudioSupported" = false at .ini file
and SDL receives TTS.Started from HMI
SDL must:
send OnHMIStatus (LIMITED, NOT_AUDIBLE) to mobile app
send OnHMIStatus (LIMITED, AUDIBLE) to mobile app right after embedded navigation stops streaming (SDL receives TTS.Stopped from HMI) 


## Detailed design
TBD
## Impact on existing code
TBD
## Alternatives considered
TBD
