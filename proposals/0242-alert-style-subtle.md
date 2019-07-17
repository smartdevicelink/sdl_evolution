# Subtle Alert Style

* Proposal: [SDL-0242](0242-alert-style-subtle.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Accepted with Revisions**
* Impacted Platforms: [Core / iOS / Java Suite / HMI / RPC]

## Introduction
This feature adds a new style of alert: the "subtle" alert, which does not take over the entire screen. The current alerts are moved to a style called "prominent."

## Motivation
Competitive systems in this space often have "notification" style alerts, and user expectations are often set by mobile devices, which have notification alerts that don't take over the screen. To meet user and developer expectations, we should provide both prominent (modal) and subtle (notification) style alerts.

Places where subtle alerts may be useful include messaging apps that notify the user of a new message, a VOIP app notifying the user of an incoming call, or a navigation app notifying the user of an upcoming accident. These should have the ability to be presented outside of the current screen-takeover method.

## Proposed solution
The proposed solution is to create a new `AlertStyle` enum that can be sent along with the `Alert` RPC.

### Functionality
Functionally, this would be identical to the prominent alert style with the following exceptions:

1. It may support a different number of text lines or soft buttons.
2. `progressIndicator` parameter should do nothing.
3. Touching (or otherwise selecting) the alert should open the app.
4. Touching outside of the subtle alert should close the alert.

### MOBILE_API and HMI_API Changes

#### Capabilities
```xml
<struct name="DisplayCapabilities" since="1.0">
    <!-- All existing params -->

    <param name="alertStylesAvailable" type="AlertStyle" array="true" minValue="1" maxValue="1000" mandatory="false" since="6.x">
        <description>An array of available alert styles. If this parameter is not provided, only the `PROMINENT` style is assumed to be available.</description>
    </param>
</struct>
```

Alternatively, if this proposal is implemented in a release simultaneously with, or after, [SDL-0216 Widget Support](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md), then the `alertStylesAvailable` parameter should be placed within the new `WindowCapabilities` struct, and not the `DisplayCapabilities` struct above. See Alternative 2.

#### Alert
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

Also note that if [Cancel Interaction](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0184-cancel-interaction.md) is implemented, this would be affected as well.

### Mockup
![Subtle Alert Mockup](../assets/proposals/0242-alert-style-subtle/subtle-alert-mockup.png)

## Potential downsides
Because this is an addition to the `Alert` RPC and not a new separate RPC, policies cannot allow an app to send a "subtle" notification while preventing them from sending a "prominent" notification. This is a significant downside and almost caused the author to change the approach. The author ultimately determined that adding a new non-mandatory parameter was better due to the API similarity, but if the SDLC decides to use Alternative 1 below, that would be acceptable by the author.

## Impact on existing code
This would be a minor version change.

## Alternatives considered

### Alternative 1: Separate RPC
Using a separate RPC allows us to (1) control this alert style separately from `Alert` in policies, and (2) to provide a callback for when the notification is touched. This would permit better control for the app developers than simply opening the app.

```xml
<function name="SubtleAlert" functionID="SubtleAlertID" messagetype="request">
    <description>Shows an alert which typically consists of text-to-speech message and text on the display. At least either alertText1, alertText2 or TTSChunks need to be provided.</description>
        
        <param name="alertText1" type="String" maxlength="500" mandatory="false">
            <description>The first line of the alert text field</description>
        </param>
        
        <param name="alertText2" type="String" maxlength="500" mandatory="false">
            <description>The second line of the alert text field</description>
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
</function>

<function name="OnSubtleAlertPressed" functionID="OnSubtleAlertPressedID" messagetype="notification">
</function>
```

If [Cancel Interaction](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0184-cancel-interaction.md) is implemented, this would need to be modified to work with that as well.

### Alternative 2: Using `WindowCapabilities` instead of `DisplayCapabilities`
```xml
<struct name="WindowCapability" since="6.0">
    <!-- Existing params from SDL-0216 -->
    <param name="alertStylesAvailable" type="AlertStyle" array="true" minValue="1" maxValue="1000" mandatory="false" since="6.x">
        <description>An array of available alert styles. If this parameter is not provided, only the `PROMINENT` style is assumed to be available.</description>
    </param>
</struct>
```
