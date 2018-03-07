# Template Improvements: Additional SubMenus

* Proposal: [SDL-0148](0148-template-additional-submenus.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **In Review**
* Impacted Platforms: [Core / iOS / Android / RPC / HMI]

## Introduction

This proposal is to enable deeper menu drilling via AddSubMenu requests and greater control for OEMs over menu length and depth.

## Motivation

Currently, SDL is by far the most restrictive among its competitors for drilling down into menus. It only allows the top menu and one submenu (additional submenus can be "faked" using Choice Sets). CarPlay, for example, allows at least 3 levels of drilling, this was the most I could find in the apps I use (in addition to tabs at the top, which is a kind-of 4th level). CarPlay allows as much drilling as desired by the user in the car, but prevents scrolling while moving. SDL, on the other hand, reverses those restrictions, allowing as much scrolling as desired, while restricting drilling. It should be in the OEMs hands what restrictions are used.

## Proposed solution

### HMI Driver Distraction

The proposed solution is a new set of restrictions that can be set by the OEM. This new set of restrictions should be the number of command items that are permissible in a list when the driver is distracted, and the second is the number of levels of submenus permitted when the driver is distracted. The number of scrolling items when distracted should default to 10, and number of levels of submenus will default to 3. This should be supported via the HMI, however, the author was unable to find a notification from Core to HMI of driver distraction. This would need to be provided, but then the HMI could handle hiding and showing list length and depth from there.

### SystemCapability

We would add a new SystemCapabilityType and additions to SystemCapability to help developers know that this change exists and allow them to update their UI when the driver is distracted to fit guidelines if desired.

```xml
<enum name="SystemCapabilityType">
...
    <element name="DRIVER_DISTRACTION"/>
...
</enum>
```

```xml
<struct name="SystemCapability">
...
    <param name="driverDistractionCapability" type="DriverDistractionCapability" mandatory="false">
        <description>Describes capabilities when the driver is distracted</description>
    </param>
...
</struct>
```

```xml
<struct name="DriverDistractionCapability">
    <param name="menuLength" type="Int" mandatory="false">
        <description>The number of items allowed in a Choice Set or Command menu while the driver is distracted</description>
    </param>
    <param name="subMenuDepth" type="Int" minValue="1" mandatory="false">
        <description>The depth of submenus allowed when the driver is distracted. e.g. 3 == top level menu -> submenu -> submenu; 1 == top level menu only</description>
    </param>
</struct>
```

### AddSubMenu

This change is paired with the ability to send an addSubMenu command with a parent ID.

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

If a version of Core does not support submenus at the level this submenu would enter, the RPC should be `REJECTED` with reason "Submenus are not permitted at this level of depth."

## Potential downsides

This would require some work on Core and / or HMI to provide configuration options and interface work for list length and menu depth when the driver is distracted. Alternately, this could be purely an HMI-level decision and configuration.

Backward compatibility may be an issue. The author is not aware of what may occur if a submenu command is passed with the `parentID` parameter but Core does not support that parameter. Ideally, the submenu should be rejected. The developer should check for the driver distraction system capability before attempting to send a submenu of a submenu.

## Impact on existing code

This should be a minor version change across platforms.

## Alternatives considered

The author could not think of any alternatives.
