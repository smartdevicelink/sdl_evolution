# Driver Distraction Improvements: Command List Limitations

* Proposal: [SDL-0152](0152-driver-distraction-list-limits.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Accepted**
* Impacted Platforms: [Core / iOS / Android / RPC / HMI]

## Introduction

This proposal is to enable greater control for OEMs over menu length and depth.

## Motivation

Currently, SDL is by far the most restrictive among its competitors for drilling down into menus. It only allows the top menu and one submenu (additional submenus can be "faked" using Choice Sets). CarPlay, for example, allows at least 3 levels of drilling, this was the most I could find in the apps I use (in addition to tabs at the top, which is a kind-of 4th level). CarPlay allows as much drilling as desired by the user in the car, but prevents scrolling while moving. SDL, on the other hand, reverses those restrictions, allowing as much scrolling as desired, while restricting drilling. It should be in the OEMs hands what restrictions are used.

## Proposed solution

### HMI Driver Distraction

The proposed solution is a new set of restrictions that can be set by the OEM. This new set of restrictions should be the number of command items that are permissible in a list when the driver is distracted, and the second is the number of levels of submenus permitted when the driver is distracted. The number of scrolling items when distracted should default to 10, and number of levels of submenus will default to 3. This should be supported via the HMI, however, the author was unable to find a notification from Core to HMI of driver distraction. This would need to be provided, but then the HMI could handle hiding and showing list length and depth from there.

### SystemCapability

We would add a new `SystemCapabilityType` and additions to `SystemCapability` to help developers know that this change exists and allow them to update their UI when the driver is distracted to fit guidelines if desired.

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

```xml
<struct name="HMICapabilities" since="3.0">
...
+    <param name="driverDistraction" type="Boolean" mandatory="false" since="7.0">
+        <description>Availability of driver distraction capability. True: Available, False: Not Available</description>
+    </param>
</struct>
```

## Potential downsides

This would require some work on Core and / or HMI to provide configuration options and interface work for list length and menu depth when the driver is distracted. Alternately, this could be purely an HMI-level decision and configuration.

## Impact on existing code

This should be a minor version change across platforms.

## Alternatives considered

The author could not think of any alternatives.
