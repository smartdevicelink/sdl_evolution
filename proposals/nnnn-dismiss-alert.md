# Dismiss Alert RPC

* Proposal: [SDL-NNNN](NNNN-dismiss-alert.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Awaiting review**
* Impacted Platforms: [Core / iOS / Android / RPC]

## Introduction

Add a new RPC that causes any current alert displayed by the app to be immediately dismissed.

## Motivation

There are some cases in which dismissing an alert immediately is desired. For example, if the app is using the `progressIndicator` on `Alert`, the app may wish to dismiss as soon as the content is loaded. Currently, the app cannot programmatically dismiss the `Alert` or `ScrollableMessage`.

## Proposed solution

A new RPC is required to fix this use case. I propose to add an RPC called `DismissAlert`. This would dismiss any of an app's programmatically displayed alerts without needing to wait for the timeout to complete.

```xml
<function name="DismissAlert" functionID="DismissAlertID" messagetype="request">

</function>

<function name="DismissAlert" functionID="DismissAlertID" messagetype="response">

</function>
```

## Potential downsides

1. If the developer is not tracking closely the views on-screen, they may not dismiss the view they expected.
2. If used poorly, the alert could dismiss without the user expecting it to. This should only be used with alerts that don't take user interaction (such as a "waiting for network").

## Impact on existing code

Android and iOS libraries would need to be updated for the new RPC, as well as Core. This would be a minor version change.

## Alternatives considered

More or fewer RPCs could be dismissed through this, such as by _only_ dismissing `Alert`s, and leaving other modal views as un-dismissable, or by allowing the dismissal of `Slider` and `PerformInteraction` programmatically.