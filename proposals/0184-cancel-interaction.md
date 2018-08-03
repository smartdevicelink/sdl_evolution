# Cancel Interaction RPC

* Proposal: [SDL-0184](0184-dismiss-alert.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Returned for Revisions**
* Impacted Platforms: [Core / iOS / Android / RPC]

## Introduction

Add the ability to allow interaction alerts to be canceled.

## Motivation

There are some cases in which dismissing an alert or interaction immediately may be desired. For example, if the app is using the `progressIndicator` on `Alert`, the app may wish to dismiss as soon as the content is loaded. Currently, the app cannot programmatically dismiss the `Alert` or `ScrollableMessage`.

## Proposed solution

A new RPC is required to fix this use case. I propose to add an RPC called `CancelInteraction`. This would dismiss any of an app's programmatically displayed alerts without needing to wait for the timeout to complete. This would affect `Alert`, `ScrollableMessage`, `Slider`, and `PerformInteraction`.

```xml
<function name="CancelInteraction" functionID="DismissAlertID" messagetype="request" since="X.X.X">
  <param name="cancelID" type="Integer" mandatory="false">
    <description>
      The ID of the specific interaction you want to dismiss. If not set, the most recent of the RPC type set in functionID will be dismissed.
    </description>
  </param>
  <param name="functionID" type="Integer" mandatory="true">
    <description>
      The ID of the type of interaction the developer wants to dismiss. Only values 10, (PerformInteractionID), 12 (AlertID), 25 (ScrollableMessageID), and 26 (SliderID) are permitted.
    </description>
  </param>
</function>

<function name="CancelInteraction" functionID="DismissAlertID" messagetype="response">
    <description>
      If no applicable request can be dismissed, the result will be IGNORED.
    </description>

    <param name="success" type="Boolean" platform="documentation" mandatory="true">
        <description> true if successful; false, if failed </description>
    </param>
        
    <param name="resultCode" type="Result" platform="documentation" mandatory="true">
        <description>See Result</description>
        <element name="SUCCESS"/>
        <element name="IGNORED"/>
        <element name="INVALID_DATA"/>
        <element name="OUT_OF_MEMORY"/>
        <element name="TOO_MANY_PENDING_REQUESTS"/>
        <element name="APPLICATION_NOT_REGISTERED"/>
        <element name="GENERIC_ERROR"/>
        <element name="REJECTED"/>
        <element name="DISALLOWED"/>
        <element name="UNSUPPORTED_RESOURCE"/>
        <element name="WARNINGS"/>
        <element name="ABORTED"/>
    </param>
        
    <param name="info" type="String" maxlength="1000" mandatory="false" platform="documentation">
        <description>Provides additional human readable info regarding the result.</description>
    </param>
</function>
```

Additional Changes:

```xml
<function name="PerformInteraction" functionID="PerformInteractionID" messagetype="request">
    <description>Triggers an interaction (e.g. "Permit GPS?" - Yes, no, Always Allow).</description>
    
    ...
    <!-- New Changes -->
    <param name="cancelID" type="Integer" mandatory="false">
        <description>
        An ID for this specific alert to allow cancellation through the `CancelInteraction` RPC.
        </description>
    </param>
    
</function>
```

```xml
<function name="Alert" functionID="AlertID" messagetype="request">
    <description>Shows an alert which typically consists of text-to-speech message and text on the display. At least either alertText1, alertText2 or TTSChunks need to be provided.</description>
    
    ...
    <!-- New Changes -->
    <param name="cancelID" type="Integer" mandatory="false">
        <description>
        An ID for this specific alert to allow cancellation through the `CancelInteraction` RPC.
        </description>
    </param>
</function>
```

```xml
<function name="ScrollableMessage" functionID="ScrollableMessageID" messagetype="request">
    <description>Creates a full screen overlay containing a large block of formatted text that can be scrolled with up to 8 SoftButtons defined</description>
    
    ...
    <!-- New Changes -->
    <param name="cancelID" type="Integer" mandatory="false">
        <description>
        An ID for this specific alert to allow cancellation through the `CancelInteraction` RPC.
        </description>
    </param>
</function>
```

```xml
<function name="Slider" functionID="SliderID" messagetype="request">
    <description>Creates a full screen or pop-up overlay (depending on platform) with a single user controlled slider.</description>
    ...
    <!-- New Changes -->
    <param name="cancelID" type="Integer" mandatory="false">
        <description>
        An ID for this specific alert to allow cancellation through the `CancelInteraction` RPC.
        </description>
    </param>
</function>
```

## Potential downsides

1. The developer has to track dismiss IDs or may end up dismissing an interaction they didn't intend to
2. If used poorly, the alert could dismiss without the user expecting it to. This should be used judiciously. The primary use case is for alerts that don't take user interaction (such as a "waiting for network" `Alert` using the `progressIndicator` Boolean).

## Impact on existing code

Android and iOS libraries would need to be updated for the new RPC, as well as Core. This would be a minor version change.

## Alternatives considered

Fewer RPCs could be dismissed through this, such as by _only_ dismissing `Alert`s, and leaving other modal views as un-dismissable.
