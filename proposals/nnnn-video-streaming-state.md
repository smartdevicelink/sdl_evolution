# Enhancing onHMIStatus with a New Parameter for Video Streaming State

* Proposal: [SDL-NNNN](nnnn-video-streaming-state.md)
* Author: [Zhimin Yang](https://github.com/smartdevicelink/yang1070)
* Status: **Awaiting review**
* Impacted Platforms: [Core / iOS / Android / RPC]

## Introduction

This proposal adds a new parameter `videoStreamingState` to `onHMIStatus` notification so that the SDL can notify an app stop video streaming. This helps SDL handle the use cases of the coexistence of a navigation app and a projection app or multiple navigation/projection apps.

## Motivation

Currently, without Projection apps, a mobile navigation app can start video streaming in HMI level `FULL` and can continue streaming while in HMI level `LIMITED` in order to have a good user experience. The app must stop video streaming after receiving `onHMIStatus` with HMI level `NONE` or `BACKGROUND`. If the app does not stop streaming after certain time, SDL will send a `StopService` Control Frame to the app in protocol layer. Therefore, the HMI level implies when a navigation app shall stop video streaming or not. There is no dedicate RPC message or parameter from SDL to mobile app to say ‘stop video streaming’ in application layer. 

With the new projection apps coming, HMI level itself is not enough to tell when a navigation app or a projection app shall stop video streaming. For example, a driver launches a navigation app first, launches a non-media projection app next. The driver shall still be able to hear turn-by-turn instructions. The navigation app is in HMI level `LIMITED` with `audioStreamingState`=`AUDIBLE`. Because the projection app is streaming, the navigation app shall stop video streaming while it is still in `LIMITED`. (Compare to the case that the driver launches a navigation app and a media app in sequence. The navigation app is in HMI level `LIMITED` with `audioStreamingState`=` ATTENUATED`. It continues streaming video.)

## Proposed solution

We propose to add a new parameter `videoStreamingState` to `onHMIStatus` to explicitly notify the app that it must stop video streaming.
SDL maintains which app can do video streaming or equivalently we say which app is a video source. If the driver launches a SDL app, SDL knows whether the app uses video service or not depending on the `AppHMIType`. Currently only `NAVIGATION` and `PROJECTION` app use video service. Other types cannot not use video service. Note, an app can have multiple `AppHMIType`s.

Assume there is at most one app that can do video streaming at any time, the following table shows how SDL shall do in different cases.


| Case# | Current Video source | SDL App2 comes to FULL | Results | SDL Actions regarding videoStreamingState | 
| -- | --- | --- | --- | --- |
| 1 | NONE |  App2 does not use video | no app is the video source | send onHMIStatus to app2 with NOT_STREAMABLE|
| 2 | NONE |  App2 uses video | App2 is the video source |  send onHMIStatus to app2 with STREAMABLE|
| 3 | App1 |  App2 does not use video | App1 is **still** the video source | send onHMIStatus to  app2 with NOT_STREAMABLE|
| 4 | App1 |  App2 uses video | App2 is the **new** video source | send onHMIStatus to app1 with NOT_STREAMABLE & app2 with STREAMABLE|
| 5 | App1 |  CarPlay/Android Auto is the acitve screen | no SDL app is the video source | send onHMIStatus to app1 with NOT_STREAMABLE |

As before, if the app does not stop video service after receiving `onHMIStatus` with `videoStreamingState`=`NOT_STREAMABLE` for certain time, SDL shall send stop service control frame to the app.


The transition of videoStreamingState is independent of the transition of hmiLevel. However, the transition of hmiLevel depends on both audioStreamingState and videoStreamingState. SDL shall move a meida/project/navigation app which is not `AUDIBLE` and not `STREAMABLE` to `BACKGROUND` HMI level. There are multiple meida/project/navigation apps (to be exact at most 2) can be placed in HMI level `LIMITED`. In `LIMITED` level, an app can be either `AUDIBLE` or `STREAMABLE` or both.

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
    <param name="videoStreamingState" type="VideoStreamingState" mandatory="true">
        <description>See VideoStreamingState. 
        If it is NOT_STREAMABLE, the app must stop streaming video to SDL (stop service).
        </description>
    </param>
</function>

<enum name="VideoStreamingState">
    <description>Enumeration that describes possible states of video streaming. </description>
    <element name="STREAMABLE" />
    <element name="NOT_STREAMABLE" />
</enum>
```

#### HMI PI
This proposal also add a new enum value `PROJECTION` to data type `EventTypes`.
HMI shall send a `OnEventChanged` notification with `EventTypes`=`PROJECTION` to SDL when HMI brings a projection app to foreground (`isActive`=`true`) or HMI switches from the foreground projection app (`isActive`=`false`).


```xml
<enum name="EventTypes">
  <description>Reflects the current active event</description>
  <element name="AUDIO_SOURCE">
    <description>Navigated to audio(radio, etc)</description>
  </element>
  <element name="EMBEDDED_NAVI">
    <description>Navigated to navigation screen</description>
  </element>
  <element name="PHONE_CALL">
    <description>Phone call is active</description>
  </element>
  <element name="EMERGENCY_EVENT">
    <description>Active emergency event, active parking event</description>
  </element>
  <element name="DEACTIVATE_HMI">
    <description> GAL/DIO is active </description>
  </element>
  
  <!-- new additions-->
  <element name="PROJECTION">
    <description>Projection app is shown in HMI</description>
  </element>
</enum>
```

#### Compatibility
- New apps on old HUs: Old HUs do not support new projection type app. Since old HUs does not send the new videoStreamingState parameter, on mobile proxy, we can give default value as *streamable* to  the parameter and make sure app does not do streaming in `BACKGROUND` or `NONE`  to make new navigation apps work with old HUs.
- Old apps on new HUs: the old navigation app does not recognize the new parameter, thus ignores it. Since there are navigation apps only (no old projection apps), the app use HMI level as an indication to stop video streaming as it current does. If a new non-media projection app is launched, the old Nav app moves to LIMITED and continues to stream its video. SDL shall send stop service control frame to the app.


## Potential downsides
On iOS devices, we still lack an effective way to bring a background Navigation/Projection app to foreground so that the app can restart/resume video streaming when the driver brings the app back to `FULL` in HMI.


## Impact on existing code

- RPC need get updated with new parameter. 
- SDL core and mobile proxy lib need updates to support this new parameter. 
- App's HMI level transition logic in SDL core need updates.


## Alternatives considered

- Instead of using a new enum data type `VideoStreamingState`, we can use just `Boolean` type and rename `videoStreamingState` to `isVideoSource` as the following.

```xml
<function name="OnHMIStatus" functionID="OnHMIStatusID" messagetype="notification">
    ...
    
    <!-- new additions-->
    <param name="isVideoSource" type="Boolean" mandatory="true">
        <description>Indicates whehter an app can use video service or not.
        If it is true, the mobile app can use video service.
        If it is false, the mobile app must stop streaming video to SDL.        
        </description>
    </param>
</function>
```

- Another alternative is that we can seperate one `STREAMABLE` state into two sub-states : `STREAMABLE_VISIBLE` and `STREAMABLE_NOT_VISIBLE`. However, this makes videoStreamingState coupled with HMI level. `VISIBLE` must be with `FULL` and `NOT_VISIBLE` must be with `LIMITED`.

```xml
<enum name="VideoStreamingState">
    <description>Enumeration that describes possible states of video streaming. </description>
    <element name="STREAMABLE_VISIBLE" />
    <element name="STREAMABLE_NOT_VISIBLE" />
    <element name="NOT_STREAMABLE" />
</enum>
```

- With the navigation apps, paramter `audioStreamingState` was extened from the original design purpose (an indicator just for A2DP BT audio service) to include new binary audio service. Along the same line of this proposal, add a new paratmer `isAudioSource` for binary audio service only and make existing `audioStreamingState` just for A2DP aduio. This makes things clear but needs more modifications to the existing code.

```xml
<function name="OnHMIStatus" functionID="OnHMIStatusID" messagetype="notification">
    ...
    
    <!-- new additions-->
    <param name="isAudioSource" type="Boolean" mandatory="true">
        <description>Indicates whehter an app can use binary audio service or not.
        If it is true, the mobile app can use binary aduio service.
        If it is false, the mobile app must stop streaming binary audio to SDL.        
        </description>
    </param>
    <param name="isVideoSource" type="Boolean" mandatory="true">
        <description>Indicates whehter an app can use video service or not.
        If it is true, the mobile app can use video service.
        If it is false, the mobile app must stop streaming video to SDL.        
        </description>
    </param>
</function>
```
