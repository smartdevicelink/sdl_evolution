# Enhancing onHMIStatus with a New Parameter for Video Streaming State

* Proposal: [SDL-0150](0150-video-streaming-state.md)
* Author: [Zhimin Yang](https://github.com/smartdevicelink/yang1070)
* Status: **Accepted**
* Impacted Platforms: [Core / iOS / Android / RPC]

## Introduction

This proposal adds a new parameter `videoStreamingState` to `onHMIStatus` notification so that SDL core can notify an app to stop video streaming. This helps SDL Core handle the use cases of the coexistence of a navigation app and a projection app or multiple navigation/projection apps.

## Motivation

Currently, without Projection apps, a mobile navigation app can start video streaming in HMI level `FULL` and can continue streaming while in HMI level `LIMITED` in order to have a good user experience. The app must stop video streaming after receiving `onHMIStatus` with HMI level `NONE` or `BACKGROUND`. If the app does not stop streaming after certain amount of time, SDL Core will send a `StopService` Control Frame to the app in protocol layer. Therefore, the HMI level implies when a navigation app shall stop video streaming or not. There is no dedicated RPC message or parameter from SDL Core to mobile app to say ‘stop video streaming’ in application layer. 

With the new projection apps coming, HMI level itself is not enough to tell when a navigation app or a projection app shall stop video streaming. For example, a driver launches a navigation app first, launches a non-media projection app next. The driver shall still be able to hear turn-by-turn instructions. The navigation app is in HMI level `LIMITED` with `audioStreamingState`=`AUDIBLE`. Because the projection app is streaming, the navigation app shall stop video streaming while it is still in `LIMITED`. (Compare to the case that the driver launches a navigation app and a media non-projection app in sequence. The navigation app is in HMI level `LIMITED` with `audioStreamingState`=`AUDIBLE`. It continues streaming video.)

## Proposed solution

We propose to add a new parameter `videoStreamingState` to `onHMIStatus` to explicitly notify the app that it must stop video streaming.
SDL Core maintains which app can do video streaming or equivalently we say which app is a video source. If the driver launches a SDL app, SDL Core knows whether the app uses video service or not depending on the `AppHMIType`. Currently only `NAVIGATION` and `PROJECTION` app use video service. Other types cannot use video service. Note, an app can have multiple `AppHMIType`s.
However, an application cannot have AppHMIType=PROJECTION and AppHMIType=NAVIGATION at the same time. In general, projection/navigation applications may not have any other HMI types to support video/audio streaming.


Assume there is at most one app that can do video streaming at any time, the following table shows how SDL Core shall act regarding videoStreamingState in different cases.


| Case | Current video source | SDL app2 comes to FULL | Results | OnHMIStatus videoStreamingState to app1 | OnHMIStatus videoStreamingState to app2 | 
| -- | --- | --- | --- | --- | --- |
| 1 | NONE | app2 does not use video | no app is the video source | NA | NOT_STREAMABLE|
| 2 | NONE | app2 uses video | app2 is the video source | NA | STREAMABLE|
| 3 | app1 | app2 does not use video | app1 is **still** the video source | No Change | NOT_STREAMABLE|
| 4 | app1 | app2 uses video | app2 is the **new** video source | NOT_STREAMABLE | STREAMABLE|
| 5 | app1 | CarPlay/Android Auto is the active screen | no SDL app is the video source | NOT_STREAMABLE | NA|

As before, if the app does not stop video service after receiving `onHMIStatus` with `videoStreamingState`=`NOT_STREAMABLE` for certain time, SDL Core shall send stop service control frame to the app.


As before, the bool parameter `isMediaApplication` in the register app interface should control if an application supports AUDIBLE streaming state.

There are two types of projection applications. If AppHMIType=PROJECTION and isMediaApplication=false, we call it a non-media projection application. If AppHMIType=PROJECTION and isMediaApplication=true or AppHMIType=PROJECTION & MEDIA, we call it a media projection application. 

We assume that media projection applications stream audio data via either Bluetooth A2DP (for android) or iAP (for iOS) as regular media applications do. We also assume projection applications do not use binary audio service. The following table shows how SDL Core shall act regarding audioStreamingState in different cases. 


| Case | Current audio source (appHMIType) | SDL app2 activated or system event | app2 appHMIType | app2 is media | Results | OnHMIStatus audioStreamingState to app1 | OnHMIStatus audioStreamingState to App2 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | none | app2 does not use audio | any | false | no app is the audio source | NA | NOT_AUDIBLE |
| 2.1 | none | app2 uses audio | NAVIGATION | false | app2 is the audio source | NA | AUDIBLE |
| 2.2 | none | app2 uses audio | any | true | app2 is the audio source | NA | AUDIBLE |
| 3 | app1 (any) | app2 does not use audio | any | false | app1 is the audio source | No Change | NOT_AUDIBLE |
| 4.1 | app1 (NAVIGATION or COMMUNICATION) | app2 uses audio | same as app1 | false | app2 is the audio source | NOT_AUDIBLE | AUDIBLE |
| 4.2 | app1 (NAVIGATION or COMMUNICATION) | app2 uses audio | others | true | app1 and app2 are the audio sources | AUDIBLE | AUDIBLE / ATTENTUATED or NOT_AUDIBLE * |
| 4.3 | app1 (Non-NAVIGATION, NON-COMMUNICATION) | app2 uses audio | NAVIGATION or COMMUNICATION | false | app1 and app2 are the audio sources | AUDIBLE / ATTENTUATED or NOT_AUDIBLE * | AUDIBLE |
| 4.4 | app1 (Non-NAVIGATION, NON-COMMUNICATION) | app2 uses audio | others | true | app2 is the audio source | NOT_AUDIBLE | AUDIBLE |
| 5.1 | app1 (any) | PHONE_CALL / EMERGENCY_EVENT / AUDIO_SOURCE / EMBEDDED_NAVI | NA | NA | app1 is not the audio source, system set the audio source | NOT_AUDIBLE | NA |
| 5.2 | app1 (any) | TTS Start | NA | NA | depending on mixing audio support, app1 can be audio source | NOT_AUDIBLE / ATTENUATED | NA |
| 5.3 | app1 (any) | CarPlay/Android Auto is the active screen (DEACTIVATE_HMI) | NA | NA | no SDL app is the video source | NOT_AUDIBLE | NA |


 *In the case of co-existence of a NAVIGATION app and a MEDIA or COMMUNICATION app, when the NAVIGATION app does not start audio steaming service, the MEDIA/COMMUNICATION app is AUDIBLE; When the NAVIGATION app starts audio streaming service, the MEDIA/COMMUNICATION app is either `ATTENUATED` if the system supports mixing or `NOT_AUDIBLE` if the system does not support mixing.

The transition of videoStreamingState and audioStreamingState is independent of the transition of hmiLevel. However, the transition of hmiLevel depends on both audioStreamingState and videoStreamingState. SDL Core shall move a `LIMITED` level media/projection/navigation app which is `NOT_AUDIBLE` and `NOT_STREAMABLE` to `BACKGROUND` HMI level. There are at most two media/projection/navigation apps which can be placed in HMI level `LIMITED`. In `LIMITED` level, an app can be either `AUDIBLE` (including `ATTENTUATED`) or `STREAMABLE` or both.

#### Mobile API
```xml
<function name="OnHMIStatus" functionID="OnHMIStatusID" messagetype="notification">
    <param name="hmiLevel" type="HMILevel" mandatory="true">
        <description>See HMILevel</description>
    </param>
    
    <param name="audioStreamingState" type="AudioStreamingState" mandatory="true">
        <description>See AudioStreamingState</description>
    </param>
    
    <param name="systemContext" type="SystemContext" mandatory="true">
        <description>See SystemContext</description>
    </param>
    
    <!-- new additions-->
    <param name="videoStreamingState" type="VideoStreamingState" mandatory="false">
        <description>See VideoStreamingState. 
        If it is NOT_STREAMABLE, the app must stop streaming video to SDL Core(stop service).
        </description>
    </param>
</function>

<enum name="VideoStreamingState">
    <description>Enumeration that describes possible states of video streaming. </description>
    <element name="STREAMABLE" />
    <element name="NOT_STREAMABLE" />
</enum>
```

#### HMI API

We don't need to add enum values `PROJECTION` and/or `NAVIGATION` to data type `EventTypes` for the `OnEventChanged` notification, because HMI shall send `OnAppActivated` and `OnAppDeactivated` event to SDL. SDL knows whether a NAVIGATION/PROJECTION app is shown in HMI since it knows the appHMIType of the target application.


#### Compatibility
- New apps on old HUs: Old HUs do not support new projection type app. Since old HUs do not send the new videoStreamingState parameter, on mobile proxy, we can give default value as *streamable* to  the parameter and make sure app does not do streaming in `BACKGROUND` or `NONE`  to make new navigation apps work with old HUs.
- Old apps on new HUs: the old navigation app does not recognize the new parameter, thus ignores it. Since there are navigation apps only (no old projection apps), the app uses HMI level as an indication to stop video streaming as it current does. If a new non-media projection app is launched, the old Nav app moves to `LIMITED` and continues to stream its video. SDL Core shall send stop service control frame to the app.


## Potential downsides
On iOS devices, we still lack an effective way to bring a background Navigation/Projection app to foreground so that the app can restart/resume video streaming when the driver brings the app back to `FULL` in HMI.


## Impact on existing code

- RPC needs to be updated with new parameter. 
- SDL core and mobile proxy lib need updates to support this new parameter. 
- App's HMI level transition logic in SDL core needs updates.


## Alternatives considered

- Instead of using a new enum data type `VideoStreamingState`, we can use just `Boolean` type and rename `videoStreamingState` to `isVideoSource` as the following.

```xml
<function name="OnHMIStatus" functionID="OnHMIStatusID" messagetype="notification">
    ...
    
    <!-- new additions-->
    <param name="isVideoSource" type="Boolean" mandatory="true">
        <description>Indicates whether an app can use video service or not.
        If it is true, the mobile app can use video service.
        If it is false, the mobile app must stop streaming video to SDL Core.        
        </description>
    </param>
</function>
```

- Another alternative is that we can separate one `STREAMABLE` state into two sub-states : `STREAMABLE_VISIBLE` and `STREAMABLE_NOT_VISIBLE`. However, this makes videoStreamingState coupled with HMI level. `VISIBLE` must be with `FULL` and `NOT_VISIBLE` must be with `LIMITED`.

```xml
<enum name="VideoStreamingState">
    <description>Enumeration that describes possible states of video streaming. </description>
    <element name="STREAMABLE_VISIBLE" />
    <element name="STREAMABLE_NOT_VISIBLE" />
    <element name="NOT_STREAMABLE" />
</enum>
```

- With the navigation apps, parameter `audioStreamingState` was extended from the original design purpose (an indicator just for A2DP BT audio service for android and iAP audio for iOS) to include new binary audio service. Along the same lines of this proposal, add a new parameter `isAudioSource` for binary audio service only and make existing `audioStreamingState` just for A2DP/iAP audio. This makes things clear but needs more modifications to the existing code.

```xml
<function name="OnHMIStatus" functionID="OnHMIStatusID" messagetype="notification">
    ...
    
    <!-- new additions-->
    <param name="isAudioSource" type="Boolean" mandatory="true">
        <description>Indicates whether an app can use binary audio service or not.
        If it is true, the mobile app can use binary audio service.
        If it is false, the mobile app must stop streaming binary audio to SDL Core.        
        </description>
    </param>
    <param name="isVideoSource" type="Boolean" mandatory="true">
        <description>Indicates whether an app can use video service or not.
        If it is true, the mobile app can use video service.
        If it is false, the mobile app must stop streaming video to SDL Core.        
        </description>
    </param>
</function>
```
