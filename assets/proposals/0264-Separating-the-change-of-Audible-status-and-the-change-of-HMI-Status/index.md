## OnEventChanged

Type
: Notification

Sender
: HMI

Purpose
: Notify SDL that an event becomes active or inactive

SDL uses `OnEventChanged` notification to appropriately manage the hmiLevel and audioStreamingState of each application during an active event.

##### PHONE_CALL

!!! MUST
1. Change audioStreamingState to NOT_AUDIBLE for all apps (keep hmiLevel) when active call on HMI has been started.

2. Send notification with appropriate parameter value when the event ends.
!!!

!!! NOTE
- SDL does not send BC.ActivateApp or BC.OnResumeAudioSource to HMI after the phone call is ended.

- If HU wants to switch the screen (HMIStatus) during PHONE_CALL, they can use API `BC.OnAppDeactivated (AppID)` and `BC.OnAppActivated (AppID)`.
!!!

Upon receiving `OnEventChanged(PHONE_CALL)`, SDL will:

|isActive|Result|
|:-------|:-----|
|true|Keep the HMI state of all applications but change audible state of all applications to NOT_AUDIBLE|
|false|Return applications to the same HMI state they had prior to the event|

##### EMERGENCY_EVENT

EMERGENCY_EVENT is an HMI-specific event used when "Emergency event" or "Rear view camera" are active. The main idea of this from the SDL<->HMI point of view is that navigation/audio streaming mustn't interfere with Rear Camera View mode. The HMI is responsible for managing audio/video data while EMERGENCY_EVENT is active.

!!! MUST
1. Send a notification with the appropriate parameter value when EMERGENCY_EVENT becomes active or inactive.
!!!

Upon receiving `OnEventChanged(EMERGENCY_EVENT)`, SDL will:

|isActive|Result|
|:-------|:-----|
|true|Move all apps with audioStreamingState AUDIBLE to NOT_AUDIBLE|
|false|Return applications to the same HMI state they had prior to the event|

!!! NOTE
While the event is active, the app is not allowed to stream audio and it will not be heard by the user (due to other audio and/or system events blocking it).
!!!

##### DEACTIVATE_HMI

!!! MUST
1. Send notification with appropriate parameter value when all apps should be deactivated/restored.
2. Send `OnEventChanged(DEACTIVATE_HMI, isActive: false)` before activating an app.
!!!

Upon receiving `OnEventChanged(DEACTIVATE_HMI)`, SDL will:

|isActive|Result|
|:-------|:-----|
|true|Change the hmiLevel of all applications currently in (FULL/LIMITED) to (BACKGROUND, NOT_AUDIBLE)|
|false|Return applications to the same HMI state they had prior to the event|

!!! NOTE
When this event is active, SDL **rejects** all app activation requests from the HMI.
!!!

##### AUDIO_SOURCE/EMBEDDED_NAVI

!!! MUST
1. Send notification to SDL with appropriate parameter value when embedded navigation or audio source is activated/deactivated.
2. Send `SDL.ActivateApp(appID)` in case of app activation or `BC.OnAppDeactivated(appID)` in case of app deactivation.
3. Switch off embedded source before app activation, when the type of activating app and embedded source are the same:
    - The HMI must deactivate the AUDIO_SOURCE event if a media app is activated.
    - The HMI must deactivate the EMBEDDED_NAVI event if a navigation app is activated.
4. When the system supports audio mixing and embedded navigation starts streaming
    - Send TTS.Started to SDL to change media app currently in (LIMITED, AUDIBLE) to (LIMITED, ATTENUATED) due to active embedded navigation.
    - Send TTS.Stopped to SDL right after embedded navigation stops streaming to change application's HMIStatus to the same state it had prior to the event.
!!!

!!! NOTE
- When app is successfully registered and SDL receives `OnEventChanged(AUDIO_SOURCE, isActive:true)` or `OnEventChanged(EMBEDDED_NAVI, isActive:true)`, SDL changes hmiLevel and audioStreamingState of this application.
    - See the table _HMI Status of apps when AUDIO_SOURCE or EMBEDDED_NAVI event is activated_

- When app is activated during an active EMBEDDED_NAVI or AUDIO_SOURCE event, SDL sets the appropriate hmiLevel and audioStreamingState for the app.
    - See the table _Activating apps during active AUDIO_SOURCE or EMBEDDED_NAVI event_

- Given that a system supports audio mixing ("MixingAudioSupported" = true at .ini file), then:
    - If there is a navigation app in (FULL/LIMITED, AUDIBLE) and SDL receives `OnEventChanged(AUDIO_SOURCE, isActive=true)`, then SDL will change the navigation app's state to (LIMITED, AUDIBLE)
    - If there is a navigation app that is in (LIMITED, AUDIBLE) due to an active AUDIO_SOURCE event, and SDL receives `SDL.ActivateApp(appID_of_navigation_app)`, then SDL will change the navigation app's state to (FULL, AUDIBLE).
    - If SDL receives `OnEventChanged(EMBEDDED_NAVI, isActive=true)`, SDL changes any media app in (LIMITED, AUDIBLE) to (LIMITED, ATTENUATED). After the EMBEDDED_NAVI event ends, SDL changes the media app's state to (LIMITED, AUDIBLE).
!!!

##### HMI Status of apps when `AUDIO_SOURCE` or `EMBEDDED_NAVI` event is activated
|appHMIType|Event|HMI State before|HMI State after|
|:---------|:----|:---------------|:--------------|
|Media|AUDIO_SOURCE|(FULL/LIMITED, AUDIBLE)|(BACKGROUND, NOT_AUDIBLE)|
|Navigation|AUDIO_SOURCE|(FULL/LIMITED, AUDIBLE)|(LIMITED, AUDIBLE)|
|Non-media|AUDIO_SOURCE|(FULL/LIMITED, AUDIBLE)|(BACKGROUND, NOT_AUDIBLE)|
|Media|EMBEDDED_NAVI|(FULL/LIMITED, AUDIBLE)|(LIMITED, AUDIBLE)|
|Navigation|EMBEDDED_NAVI|(FULL/LIMITED, AUDIBLE)|(BACKGROUND, NOT_AUDIBLE)|
|Non-media|EMBEDDED_NAVI|(FULL/LIMITED, AUDIBLE)|(BACKGROUND, NOT_AUDIBLE)|

##### Activating apps during active `AUDIO_SOURCE` or `EMBEDDED_NAVI` event
|appHMIType|Event|New HMI State|Keep event active|
|:---------|:----|:------------|:----------------|
|Media|AUDIO_SOURCE|(FULL, AUDIBLE)|false|
|Navigation|AUDIO_SOURCE|(FULL, AUDIBLE)|true|
|Non-media|AUDIO_SOURCE|(FULL, NOT_AUDIBLE)|true|
|Media|EMBEDDED_NAVI|(FULL, AUDIBLE)|true|
|Navigation|EMBEDDED_NAVI|(FULL, AUDIBLE)|false|
|Non-media|EMBEDDED_NAVI|(FULL, NOT_AUDIBLE)|true|

#### Parameters

|Name|Type|Mandatory|Additional|Description|
|:---|:---|:--------|:--------|:---------|
|eventName|[Common.EventTypes](../../common/enums/#eventtypes)|true||Specifies the types of active events|
|isActive|Boolean|true||Must be 'true' when the event is started on HMI. Must be 'false' when the event is ended on HMI|

### Sequence Diagrams
|||
PHONE_CALL, media app is active
![OnEventChanged](./assets/PHONE_CALL1.png)
|||

|||
PHONE_CALL, non-media app is active
![OnEventChanged](./assets/PHONE_CALL2.png)
|||

|||
EMERGENCY_EVENT
![OnEventChanged](./assets/EMERGENCY_EVENT.png)
|||

|||
DEACTIVATE_HMI
![OnEventChanged](./assets/DEACTIVATE_HMI.png)
|||

|||
EMBEDDED_NAVI or AUDIO_SOURCE
![OnEventChanged](./assets/EMBEDDED_NAVI_or_AUDIO_SOURCE.png)
|||

|||
App activation during active audio source
![OnEventChanged](./assets/App_activation_during_active_audio_source.png)
|||

|||
App activation during active embedded navigation
![OnEventChanged](./assets/App_activation_during_active_navi_source.png)
|||

|||
Correlation between audioStreamingState of media app and embedded navigation in case "MixingAudioSupported" = true/false
![OnEventChanged](./assets/Correlation_audioStreamingState_of_media_app_and_embedded_navigation.png)
|||

|||
Multiple apps activation during active embedded navigation or audio source
![OnEventChanged](./assets/Multiple_apps_activation_during_active_embedded_navigation_or_audio_source.png)
|||

#### JSON Example Notification
```json
{
  "jsonrpc" : "2.0",
  "method" : "OnEventChanged",
  "params" :
  {
    "eventName" : "PHONE_CALL",
    "isActive" : true
  }

}
```