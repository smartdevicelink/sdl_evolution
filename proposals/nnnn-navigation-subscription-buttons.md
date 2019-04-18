# Navigation Subscription Buttons

* Proposal: [SDL-NNNN](NNNN-navigation-subscription-buttons.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Awaiting review**
* Impacted Platforms: [Core / iOS / Android / Cloud Proxy / HMI / RPC]

## Introduction
This proposal adds support for new subscription buttons (like the existing Play/Pause, Next, Previous, etc.) specifically designed for navigation scenarios.

## Motivation
SDL currently primarily supports touch screen interaction for video streaming navigation apps. However, some OEMs provide haptic (hard button) input that can and should correspond to the streamed navigation map. This should be made easier than it currently is.

## Proposed solution
The proposed solution is to add new subscription buttons specifically for these navigation use cases.

### MOBILE_API / HMI_API
```xml
<enum name="ButtonName">
    <!-- New options -->
    <element name="NAV_CENTER_LOCATION" />
    <element name="NAV_ZOOM_IN" />
    <element name="NAV_ZOOM_OUT" />
    <element name="NAV_PAN_UP" />
    <element name="NAV_PAN_UP_RIGHT" />
    <element name="NAV_PAN_RIGHT" />
    <element name="NAV_PAN_DOWN_RIGHT" />
    <element name="NAV_PAN_DOWN" />
    <element name="NAV_PAN_DOWN_LEFT" />
    <element name="NAV_PAN_LEFT" />
    <element name="NAV_PAN_UP_LEFT" />
</enum>
```

### Implementation Notes
* These buttons should either be unsupported on touch screen head units (i.e. if these buttons can not be implemented as hard buttons in the vehicle), or if they are implemented on the touch screen head unit, they should not overlay the map at all times. Because the OEMs could place them on the screen in different locations, this would prevent the app developer from knowing what areas of the screen are accessible for them to place buttons. Instead, they should be hidden behind, for example, tapping the map, or a button that doesn't overlay the map.
* This should be considered an _alternate_ way to interact with a map, while touches, pans, and pinches are the primary way to interact.

## Potential downsides
1. Poor implementations of this feature could lead to poor app developer experience and poor UX, but that doesn't mean we shouldn't implement the feature at all.

## Impact on existing code
This would be a minor version change for the proxy libraries, core, and the specs. This should be fairly light to implement in SDL.

## Alternatives considered
* No alternatives were considered.