# "Push To Talk" key support

* Proposal: [SDL-0135](0135-PushToTalk-hardkey-support.md)
* Author: [Tomoya Suzuki](https://github.com/tsuzuki-uie)
* Status: **Deferred**
* Impacted Platforms: [ Core / iOS / Android / RPC ]


## Introduction

Add "PUSH\_TO\_TALK" as ButtonName. Its purpose is to provide voice agent apps (such as Amazon Alexa and LINE Clova) a trigger for voice recognition and improve their user experience.


## Motivation

SDL already supports head unit's native Voice Recognition (VR) via AddCommand/PerformInteraction with vrCommands.
On the other hands, some voice agent apps such as Alexa and Clova have VR feature by themselves.
These apps hope to use some kind of trigger to start their VR, either using AudioPassThru or mobile phone's microphone.
 
## Proposed solution

Add "PUSH\_TO\_TALK" as ButtonName.

When the Push-to-Talk (PTT) hard key is pressed by a user, HMI performs one of the following scenarios:

* HMI will consume PTT hard key event to start SDL VR (=head unit's native VR) to select AddCommands with vrCommands. In this case, button event will not be sent to SDL app.
* HMI will notify "PUSH\_TO\_TALK" event as OnButtonEvent/Press/Release to SDL app.

Note: PerformInteraction is triggered by handset app, so it is not related to "PUSH\_TO\_TALK" event.


## Detailed design

### HMI & Mobile API

```xml
    <enum name="ButtonName">
        <description>Defines the hard (physical) and soft (touchscreen) buttons available from the module</description>
(snip)
        <element name="PUSH_TO_TALK">
            <description>
                If an app subscribes this button name then, AddCommand-vrCommands may be ignored.
            </description>
        </element>
    </enum>
```

If an app subscribes to "PUSH\_TO\_TALK", HMI MUST send "PUSH\_TO\_TALK" button event to the app through SDL Core.

Guideline for app developers:

If a voice agent app would like to receive "PUSH\_TO\_TALK" event, it SHOULD NOT add vrCommands.


## Out of scope of this proposal

* Wake up word

  * This is app-launching feature with certain keyword. It MAY already available to use RegisterApp(vrSynonym).

* Mapping PTT key to specific app

  * HMI can launch a specific app (either pre-defined one, or one of the apps with AppHMIType being COMMUNICATION) when the hard key is pressed. This is similar to launching a navigation app when "MAP" or "NAVI" hard key is pressed. Such feature is vendor specific, and coordination with "PUSH\_TO\_TALK" button event handling is out of scope.


## Potential downsides

* Voice agent app should consider two cases where the head unit can and cannot support subscription to PTT hard key.

* If HMI has a preset command (e.g. "help") associated with PTT hard key, it cannot send the button event to an app before it subscribes the button event.


## Impact on existing code

Backward compatibility: Old apps will not subscribe to "PUSH\_TO\_TALK" key. So, all behavior in old apps are not affected.
Old head units will not return success to subscribeButton("PUSH\_TO\_TALK"). App can select using AddCommand(vrCommand) or other softbutton/hardkey to trigger its own VR.

Core: Add 1 enum to ButtonName

Proxy: Add 1 enum to ButtonName

HMI: Add exclusive logic to handle PTT button.


## Alternatives considered

Add a new AppHMIType "VOICE\_AGENT". When PTT hard key is pressed, send an event to one of the apps with AppHMIType being VOICE\_AGENT.
* We already have COMMUNICATION type and the difference between VOICE\_AGENT is not clear.
* AppHMIType is sent during RegisterAppInterface request, so when connected with an old head unit, registration fails. This is big backward compatibility issue for old head units.

