
# Disabled Softbuttons

* Proposal: [SDL-0259](0259-DisabledSoftbuttons.md)
* Author: [Michael Crimando](https://github.com/MichaelCrimando)
* Status: **In Review**
* Impacted Platforms: [Core / iOS / Java Suite / RPC ]

## Introduction

This feature would allow apps to send custom softbuttons to display on screen but they would appear disabled.
Also this allows an app to subscribe to softbuttons that are disabled.

## Motivation
Some apps like iHeartRadio don't provide the same set of custom softbuttons for each home screen.
This would allow them to display that to the user, just like the native app on the phone.  Other apps like Pandora only support Seek Left and Repeat if the user has a premium account. This can let them show the buttons and let the user know it's available just not right now.

## Proposed solution

For custom softbuttons, add a parameter to `SoftButtonCapabilities` to let the app know that the ability is possible.
```xml
<struct name="SoftButtonCapabilities">
    .
    .
    .
    <param name="disabledButtonPossible" type="Boolean" mandatory="true">
        <description>The button supports being disabled. If the button is set to disabled, it will still show on the HMI but appear grayed out.
        </description>
    </param>
</struct>
```

Plus add an `isEnabled` flag to `SoftButton`. If the flag is true or missing, the softbutton must appear usable. If false, softbutton must appear as not usable. If the button is set to disabled, it will still show on the HMI but appear grayed out. Button press events will still be sent to the app.  Button press events would still be sent to the app so the app can enable experiences like "Repeat is for Premium customers only". Alternatively we could have the button not send any button events to match what Android and iOS do when a button is on screen but disabled.
```xml
<struct name="SoftButton">
.
.
.
    <param name="isEnabled" type="Boolean" mandatory="false">
      <description>If true or missing, softbutton must appear usable. If false, softbutton must appear as not usable.
      </description>
    </param>
 </struct>
```

For buttons that can be subscribed to, add a parameter to `ButtonCapabilities` to let the app know that the ability is possible.
```xml
<struct name="ButtonCapabilities">
    .
    .
    .
    <param name="disabledButtonPossible" type="Boolean" mandatory="true">
        <description>The button supports being disabled. If the button is set to disabled, it will still show on the HMI but appear grayed out.
        </description>
    </param>
</struct>

```

Plus add an `isEnabled` flag to the `SubscribeButton` RPC.  If the button is set to disabled, it will still show on the HMI but appear grayed out. Button press events would still be sent to the app so the app can enable experiences like "Seek Left is for Premium customers only". Alternatively we could have the button not send any button events to match what Android and iOS do when a button is on screen but disabled.

```xml
    <function name="SubscribeButton" functionID="SubscribeButtonID" messagetype="request" since="1.0">
        <description>
            Subscribes to built-in HMI buttons.
            The application will be notified by the OnButtonEvent and OnButtonPress.
            To unsubscribe the notifications, use unsubscribeButton.
        </description>
        .
        .
        .
            <param name="isEnabled" type="Boolean" mandatory="false">
      <description>If true or missing, subscribed button must appear on screen (if applicable) and usable. If false, softbutton must appear on screen (if applicable) and not usable.  Button press events will still be sent to the app.
      </description>
    </function>
    
```

## Potential downsides

Adds HMI complexity

## Impact on existing code

It's a new parameter so this wouldn't block usability on older headunits. However, apps would have to know that on older headunits the functionality to disable a button isn't possible. Otherwise they would try to request a disabled softbutton but a regular softbutton would show up on screen.

## Alternatives considered

For custom softbuttons, an app could send a graphic that appears disabled, but it usually doesn't grant the same effect as having the whole softbutton looking disabled.
