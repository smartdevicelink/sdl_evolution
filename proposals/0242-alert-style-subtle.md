# Subtle Alert Style

* Proposal: [SDL-0242](0242-alert-style-subtle.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Accepted with Revisions**
* Impacted Platforms: [Core / iOS / Java Suite / HMI / Policy Server / RPC]

## Introduction
This feature adds the `SubtleAlert` RPC, which presents a style of alert: the "subtle" alert. This is a "notification style" alert that does not take over the entire screen.

## Motivation
Competitive systems in this space often have "notification" style alerts, and user expectations are often set by mobile devices, which have notification alerts that don't take over the screen. To meet user and developer expectations, we should provide both prominent (modal) and subtle (notification) style alerts.

Subtle Alerts would be especially useful when the app is in the background. Places where subtle alerts may be useful include messaging apps that notify the user of a new message, a VOIP app notifying the user of an incoming call, or a navigation app notifying the user of an upcoming accident. These should have the ability to be presented outside of the current screen-takeover method.

## Proposed solution
The proposed solution is to create a new RPC `SubtleAlert` that can be sent by developers to show a less prominent kind of Alert.

### MOBILE_API Changes

#### Capabilities Updates
```xml
<enum name="TextFieldName" since="1.0">
    <!-- New Values -->
    <element name="subtleAlertText1">
        <description>The first line of the subtle alert text field; applies to `SubtleAlert` `alertText1`</description>
    </element>
    <element name="subtleAlertText2">
        <description>The second line of the subtle alert text field; applies to `SubtleAlert` `alertText2`</description>
    </element>
    <element name="subtleAlertSoftButtonText">
        <description>A text field in the soft button of a subtle alert; applies to `SubtleAlert` `softButtons`</description>
    </element>
</enum>

<enum name="ImageFieldName" since="1.0">
    <!-- New Values -->
    <element name="subtleAlertIcon">
        <description>The image of the subtle alert; applies to `SubtleAlert` `alertImage`</description>
    </element>
</enum>
```

#### Subtle Alert
```xml
<function name="SubtleAlert" functionID="SubtleAlertID" messagetype="request">
    <description>Shows an alert which typically consists of text-to-speech message and text on the display. At least either alertText1, alertText2 or TTSChunks need to be provided.</description>
        
     <param name="alertText1" type="String" maxlength="500" mandatory="false">
         <description>The first line of the alert text field</description>
     </param>
     
     <param name="alertText2" type="String" maxlength="500" mandatory="false">
         <description>The second line of the alert text field</description>
     </param>

    <param name="alertIcon" type="Image" mandatory="false">
        <description>
            Image to be displayed for the corresponding alert. See Image. 
            If omitted, no (or the default if applicable) icon should be displayed.
        </description>
    </param>
     
     <param name="ttsChunks" type="TTSChunk" minsize="1" maxsize="100" array="true" mandatory="false">
         <description>
            An array of text chunks of type TTSChunk. See TTSChunk.
            The array must have at least one item.
         </description>
     </param>
     
     <param name="duration" type="Integer" minvalue="3000" maxvalue="10000" defvalue="5000" mandatory="false">
         <description>
            Timeout in milliseconds.
            Typical timeouts are 3-5 seconds.
            If omitted, timeout is set to 5s.
         </description>
     </param>
     
     <param name="softButtons" type="SoftButton" minsize="0" maxsize="2" array="true" mandatory="false" since="2.0">
        <description>
            App defined SoftButtons.
            If omitted on supported displays, the displayed alert shall not have any SoftButtons.
        </description>
     </param>

     <param name="cancelID" type="Integer" mandatory="false">
        <description>
            An ID for this specific alert to allow cancellation through the `CancelInteraction` RPC.
        </description>
    </param>
</function>

<function name="OnSubtleAlertPressed" functionID="OnSubtleAlertPressedID" messagetype="notification">
    <description>
        Sent when the alert itself is touched (outside of a soft button). Touching (or otherwise selecting) the alert should open the app before sending this notification.
    </description>
</function>
```

#### Cancel Interaction
```xml
<function name="CancelInteraction" functionID="CancelInteractionID" messagetype="request" since="X.X.X">
  <!-- Changed -->
  <param name="functionID" type="Integer" mandatory="true">
    <description>
      The ID of the type of interaction the developer wants to dismiss. Only values 10 (PerformInteractionID), 12 (AlertID), 25 (ScrollableMessageID), 26 (SliderID), and XX (SubtleAlertID) are permitted.
    </description>
  </param>
</function>
```

### HMI_API Changes
```xml
<function name="UI.SubtleAlert" messagetype="request">
    <description>Request from SDL to show an alert message on the display.</description>
    <param name="alertStrings" type="Common.TextFieldStruct" mandatory="true" array="true" minsize="0" maxsize="2">
        <description>Array of lines of alert text fields. See TextFieldStruct. Uses subtleAlertText1, subtleAlertText2.</description>
    </param>
    <param name="alertIcon" type="Common.Image" mandatory="false">
        <description>
            Image to be displayed for the corresponding alert. See Image. 
            If omitted, no (or the default if applicable) icon should be displayed.
        </description>
    </param>
    <param name="duration" type="Integer" mandatory="false" minvalue="3000" maxvalue="10000">
        <description>Timeout in milliseconds. Omitted if SoftButtons are included.</description>
    </param>
    <param name="softButtons" type="Common.SoftButton" mandatory="false" minsize="0" maxsize="2" array="true">
        <description>App defined SoftButtons</description>
    </param>
    <param name="alertType" type="Common.AlertType" mandatory="true">
        <description>Defines if only UI or BOTH portions of the Alert request are being sent to HMI Side</description>
    </param>
    <param name="appID" type="Integer" mandatory="true">
        <description>ID of application requested this RPC.</description>
    </param>
    <param name="cancelID" type="Integer" mandatory="false">
        <description>
            An ID for this specific alert to allow cancellation through the `CancelInteraction` RPC.
        </description>
    </param>
</function>

<function name="UI.SubtleAlert" messagetype="response">
    <param name="tryAgainTime" type="Integer" mandatory="false" minvalue="0" maxvalue="2000000000">
        <description>Amount of time (in milliseconds) that SDL must wait before resending an alert. Must be provided if another system event or overlay currently has a higher priority than this alert.</description>
    </param>
</function>

<function name="UI.OnSubtleAlertPressed" messagetype="notification">
    <description>
        Sent when the alert itself is touched (outside of a soft button). Touching (or otherwise selecting) the alert should open the app before sending this notification.
    </description>
    <param name="appID" type="Integer" mandatory="true">
        <description>ID of application that is related to this RPC.</description>
    </param>
</function>
```

* Changes may need to be made to the above functions for `CancelInteraction` changes.
* Identical changes will also need to be made to `HMI_API` `TextFieldName` and `ImageFieldName` enums as in the `MOBILE_API` changes above.

### Policy Table Changes

Currently the `module_config` section of the policy table has fields to limit the rate at which `Alert` requests can be sent in the `BACKGROUND` hmi level (described as "notifications"). The same mechanism should be made available for `SubtleAlert` requests:
```
    "subtle_notifications_per_minute_by_priority": {
        "EMERGENCY": 60,
        "NAVIGATION": 20,
        "PROJECTION": 20,
        "VOICECOM": 30,
        "COMMUNICATION": 15,
        "NORMAL": 10,
        "NONE": 0
    }
```

This will allow OEMs to manage rate-limiting for subtle alerts separate from regular alerts.

### Example Mockup
![Subtle Alert Mockup](../assets/proposals/0242-alert-style-subtle/subtle-alert-mockup.png)

### Notes
* In most other ways, the subtle alert should function similarly to an `Alert`. Responses should be sent at the same time that current `Alert` responses are sent, for example.
* Touching outside of the subtle alert should close the alert.
* Touching (or otherwise selecting) the alert should open the app before sending the `OnSubtleAlertPressed` notification.
* The `softButtonImage` `ImageField` also affect the `SubtleAlert` soft buttons.
* Only one `SubtleAlert` can be active per app at a time. Apps can replace their active `SubtleAlert` by sending `CancelInteraction` followed by another `SubtleAlert`.

## Potential downsides
Because this is a new RPC and not an addition to `Alert`, this increases the API surface of the `MOBILE_API` and `HMI_API`.

## Impact on existing code
This would be a minor version change.

## Alternatives considered

### Alternative 1: Within the Same RPC
The original version of this proposal re-used the `Alert` RPC. It was determined that it would be better to make a new RPC in order to enforce policies separately.

#### Capabilities
```xml
<struct name="DisplayCapabilities" since="1.0">
    <!-- All existing params -->

    <param name="alertStylesAvailable" type="AlertStyle" array="true" minValue="1" maxValue="1000" mandatory="false" since="6.x">
        <description>An array of available alert styles. If this parameter is not provided, only the `PROMINENT` style is assumed to be available.</description>
    </param>
</struct>

<!-- Alternate -->
<struct name="WindowCapability" since="6.0">
    <!-- Existing params from SDL-0216 -->
    <param name="alertStylesAvailable" type="AlertStyle" array="true" minValue="1" maxValue="1000" mandatory="false" since="6.x">
        <description>An array of available alert styles. If this parameter is not provided, only the `PROMINENT` style is assumed to be available.</description>
    </param>
</struct>
```

#### Alert Changes
```xml
<enum name="AlertStyle" since="X.Y">
    <description>How the alert is laid out on screen</description>
    <element name="PROMINENT">
        <description>A modal alert style that requires interaction, blocking interaction with any other part of the display.</description>
    </element>
    <element name="SUBTLE">
        <description>A new alert style like a notification banner that doesn't take over the entire display and allows interaction with the current app. e.g. A navigation alert that lets the user know of an upcoming blockage on the road and asking the user if they wish to reroute.</description>
    </element>
</enum>

<function name="Alert" functionID="AlertID" messagetype="request">
    <description>Shows an alert which typically consists of text-to-speech message and text on the display. At least either alertText1, alertText2 or TTSChunks need to be provided.</description>
    
    ...
    <!-- Additions -->
    <param name="style" type="AlertStyle" defvalue="PROMINENT" mandatory="false" since="X.Y">
        <description>Sets the layout of the alert screen.</description>
    </param>
</function>
```
