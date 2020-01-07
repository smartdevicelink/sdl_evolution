# Add means to launch with optimum appHMIType

* Proposal: [SDL-0270](0270-Add-means-to-launch-with-optimum-appHMIType.md)
* Author: [Shohei Kawano](https://github.com/Shohei-Kawano)
* Status: **Returned for Revisions**
* Impacted Platforms: [ Core / iOS / Java Suite / RPC / HMI ]

## Introduction

This proposal provides a mechanism to notify SDL apps with multiple `appHMIType` which types are activated by the HMI.  
An SDL app can display and operate according to `appHMIType` by receiving notification from HMI.  


## Motivation

Currently, in the RPC specification, an SDL app can set multiple `appHMIType`.  
However, because there is no means to notify which `appHMIType` was started from HMI, it cannot be operated according to the application.  
For example, if the specification allows you to launch an SDL app with both Navigation / Media `appHMIType` by selecting an audio source, the SDL app can implement a specification that allows the audio function to be used immediately.  
In this way, it can be thought that it can contribute to the improvement of UX.  


## Proposed solution

Add a new parameter `launchAppHMIType` to the HMI / MOBILE RPC that is sent when activating the app.  

HMI API:  

Add `launchAppHMIType` to the RPC below.  
- BasicCommunication.OnAppActivated  
- SDL.ActivateApp  

```xml
     <interface name="BasicCommunication" version="2.1.0" date="2019-03-18">
...
    <function name="OnAppActivated" messagetype="notification">
        <description>Must be sent by HU system when the user clicks on app in the list of registered apps or on soft button with 'STEAL_FOCUS' action.</description>
        <param name="appID" type="Integer" mandatory="true">
            <description>ID of selected application.</description>
        </param>
        <param name="windowID" type="Integer" mandatory="false">
            <description>
               This is the unique ID assigned to the window that this RPC is intended. If this param is not included, it will be assumed that this request is specifically for the main window on the main display. See PredefinedWindows enum.
            </description>
        </param>
+       <param name="launchAppHMIType" type="AppHMIType" mandatory="false">
+           <description>
+              A parameter that instructs an app with multiple AppHMITypes to start with a specific AppHMIType
+           </description>
+       </param>
    </function>
...
    <interface name="SDL" version="1.2.0" date="2018-09-05">
...
    <function name="ActivateApp" messagetype="request">
        <param name="appID" type="Integer" mandatory="true">
        </param>
+       <param name="launchAppHMIType" type="AppHMIType" mandatory="false">
+           <description>
+               A parameter that instructs an app with multiple AppHMITypes to start with a specific AppHMIType
+           </description>
+       </param>
    </function>
```
  
Mobile API:  

Add `launchAppHMIType` to the RPC below.  
- OnHMIStatus  

```xml
    <function name="OnHMIStatus" functionID="OnHMIStatusID" messagetype="notification" since="1.0">
        <param name="hmiLevel" type="HMILevel" mandatory="true">
            <description>See HMILevel</description>
        </param>

        <param name="audioStreamingState" type="AudioStreamingState" mandatory="true">
            <description>See AudioStreamingState</description>
        </param>

        <param name="systemContext" type="SystemContext" mandatory="true">
            <description>See SystemContext</description>
        </param>

        <param name="videoStreamingState" type="VideoStreamingState" mandatory="false" defvalue="STREAMABLE" since="5.0">
            <description>
                See VideoStreamingState.
                If it is NOT_STREAMABLE, the app must stop streaming video to SDL Core(stop service).
            </description>
        </param>
        <param name="windowID" type="Integer" mandatory="false" since="6.0">
            <description>
                This is the unique ID assigned to the window that this RPC is intended. If this param is not included, it will be assumed that this request is specifically for the main window on the main display. See PredefinedWindows enum.
            </description>
        </param>

+       <param name="launchAppHMIType" type="AppHMIType" mandatory="false" since="X.X">
+           <description>A parameter that instructs an app with multiple AppHMITypes to start with a specific AppHMIType</description>
+       </param>
    </function>
```

The operation after SDL App receives launchAppHMIType is not specified.  

## Potential downsides

No downsides are expected by this proposal.  

## Impact on existing code

This would be a minor version change to all affected platforms.  

## Alternatives considered

Add a new API to notify AppHMIType to be launched.  
