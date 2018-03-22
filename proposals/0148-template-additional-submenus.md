# Template Improvements: Additional Sub-Menus

* Proposal: [SDL-NNNN](nnnn-template-additional-submenus.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Awaiting review**
* Impacted Platforms: [Core / iOS / Android / RPC / HMI]

## Introduction

This proposal is to enable deeper menu drilling via AddSubMenu requests.

## Motivation

Currently, SDL is by far the most restrictive among its competitors for drilling down into menus. It only allows the top menu and one submenu (additional submenus can be "faked" using Choice Sets). CarPlay, for example, allows at least 3 levels of drilling, this was the most I could find in the apps I use (in addition to tabs at the top, which is a kind-of 4th level). CarPlay allows as much drilling as desired by the user in the car, but prevents scrolling while moving. For future updates, we should allow further menu depth. For driver distraction reasons, a later proposal will allow restriction of menu depth while driving to replicate current restrictions if desired.

### AddSubMenu

This change is the ability to send an addSubMenu command with a parent id.

```xml
<function name="AddSubMenu" functionID="AddSubMenuID" messagetype="request">
...
    <param name="parentID" type="Integer" minvalue="0" maxvalue="2000000000" defvalue="0" mandatory="false">
        <description>
            unique ID of the sub menu, the command will be added to.
            If not provided, it will be provided to the top level of the in application menu.
        </description>
    </param>
...
</function>
```

### Backwards Compatibility

Backwards compatibility is an issue on Core because Core will currently simply drop the parentID parameter on older head units. This will cause unexpected behavior, most likely the addition of submenus to the top level menu.

To mitigate this behavior, several possible checks may be introduced:

1. Originally this proposal was linked to the `Driver Distraction Improvements: Truncating Lists` proposal. That proposal has since been broken out and will be submitted as a second proposal. This second proposal includes a new `SystemCapabilityType`: `DRIVER_DISTRACTION`. The availablity of this system capability could be the basis for whether or not to use sub-sub menus. These proposals would need to be implemented into the same Core version.

2. The proxy-side implementations can provide checks based upon either (1) above, or the negotiated SDL RPC version. This would cause runtime failures if the API is used when not on a version allowing it.

3. An upcoming expansion of the iOS ScreenManager will provide a "Menu Manager" API which can automatically translate those sub-submenus into Choice Sets (of the appropriate driver distraction depth allowed, see (1)).

## Potential downsides

See the above discussion of backwards compatibility.

## Impact on existing code

This should be a minor version change across platforms.

## Alternatives considered

The author could not think of any alternatives.