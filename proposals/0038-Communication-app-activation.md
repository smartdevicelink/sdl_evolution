# Communication app activation during active embedded audio source or navigation

* Proposal: [SDL-0038](0038-Communication-app-activation.md)
* Author: [Melnyk Tetiana](https://github.com/TMelnyk)
* Status: **Deferred**
* Impacted Platforms: Core

## Introduction
This proposal is to handle communication app activation during active embedded audio and navigation sources.

## Motivation  
Covered cases:  
voice-com app activation during embedded audio source  
voice-com app activation during embedded navigation  
. MixingAudioSupported=true or false 

## Proposed solution

1. In case communication app in LIMITED and AUDIBLE due to active embedded navigation 
and SDL receives SDL.ActivateApp (appID_of_communication_app) from HMI
SDL must: 
respond SDL.ActivateApp (SUCCESS) to HMI
send OnHMIStatus (FULL, AUDIBLE) to mobile app (embedded navigation is still active) 

2. In case communication app in FULL and AUDIBLE
and SDL receives OnEventChanged (EMBEDDED_NAVI, isActive=true) from HMI
SDL must:
send OnHMIStatus (LIMITED, AUDIBLE) to mobile app  

3. Communication app activation is the trigger for HMI to switch off embedded audio source,
HMI switches off embedded audio source and sends OnEventChanged (AUDIO_SOURCE, isActive=false) to SDL. 
	
4. In case communication app in LIMITED and AUDIBLE due to active embedded navigation
and "MixingAudioSupported" = true at .ini file
and SDL receives TTS.Started from HMI
SDL must: 
send OnHMIStatus (LIMITED, ATTENUATED) to mobile app
send OnHMIStatus (LIMITED, AUDIBLE) to mobile app right after embedded navigation stops streaming (SDL receives TTS.Stopped from HMI) 

5. In case communication app in BACKGROUND and NOT_AUDIBLE due to active embedded audio source () 
and user activates this communication app
and SDL receives from HMI:
a) OnEventChanged (AUDIO_SOURCE, isActive=false) 
b) SDL.ActivateApp (appID_of_communication_app) 
SDL must:
respond SDL.ActivateApp (SUCCESS) to HMI
send OnHMIStatus (FULL, AUDIBLE) to mobile app
Information: 
a. Communication app activation is the trigger for HMI to switch off embedded audio source
b. HMI switches off embedded audio source and sends OnEventChanged (AUDIO_SOURCE, isActive=false) to SDL 

6. In case voice-com app in LIMITED and AUDIBLE due to active embedded navigation and "MixingAudioSupported" = false at .ini file
and SDL receives TTS.Started from HMI
SDL must:
send OnHMIStatus (LIMITED, NOT_AUDIBLE) to mobile app
send OnHMIStatus (LIMITED, AUDIBLE) to mobile app right after embedded navigation stops streaming (SDL receives TTS.Stopped from HMI) 

## Detailed design

Approximately the neccesary changes loos like following:

###### Old
```c++
mobile_apis::HMILevel::eType EmbeddedNavi::hmi_level() const {
  using namespace mobile_apis;
  using namespace helpers;
  if (Compare<HMILevel::eType, EQ, ONE>(parent()->hmi_level(),
                                        HMILevel::HMI_BACKGROUND,
                                        HMILevel::HMI_NONE)) {
    return parent()->hmi_level();
  }
  if (is_media_app(app_id_)) {
    return HMILevel::HMI_LIMITED;
  }
  return HMILevel::HMI_BACKGROUND;
}
```
###### New
```c++
mobile_apis::HMILevel::eType EmbeddedNavi::hmi_level() const {
  using namespace mobile_apis;
  using namespace helpers;
  if (Compare<HMILevel::eType, EQ, ONE>(parent()->hmi_level(),
                                        HMILevel::HMI_BACKGROUND,
                                        HMILevel::HMI_NONE)) {
    return parent()->hmi_level();
  }
  if (is_media_app(app_id_) || is_voice_communication_app(app_id_)) {
    return HMILevel::HMI_LIMITED;
  }
  return HMILevel::HMI_BACKGROUND;
}
```

In other words SDL has some number of predefined handlers for every possible state. Those handlers have to be extended
using the sample above.

## Impact on existing code

The impact on the existing code is `StateController` class and `HMIState` class. Bith have to be extended with neccesary handlers
for the certain HMI type and audible state of application.

## Alternatives considered
There is no alternatives as current proposal defines rules for the proper processing of the applications with different types
during the changing of system states.

