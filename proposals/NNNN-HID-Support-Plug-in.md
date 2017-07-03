# OEM specific Human Interface Device support as Plug-in architecture in SDL proxy

* Proposal: [SDL-NNNN](NNNN-HID-Support-Plug-in.md)
* Author: [Jennifer Hodges](https://github.com/jhodges55)
+ Status: Awaiting review
* Impacted Platforms: [ iOS / Android ]

## Introduction

Many OEM head units (ex. Lexus Remote Touch, Mazda Commander Control, BMW Gesture Control, Audi MMI) do not support direct touch interaction, but rather support a focus and select model driven by physical controls. This proposal describes a proxy plug-in interface that models the physical controls as HID devices with OEM-specific plug-in implementations.

## Motivation

OEMs have invested in branded, usability and safety tested user interfaces for their head units, including physical control design, visual and haptic feedback. For proprietary head unit and handset applications, OEMs can implement custom support for their interface. For SDL applications that use the standard UI templates, the SDL HMI can determine which template control has focus and render appropriate visual, audible and haptic feedback. However, for video streaming applications that use the NAV_FULLSCREEN_MAP template, the SDL HMI does not know which focusable elements exist in the projected window. It can only generate and send OnTouchEvent RPCs that the handset application needs to interpret. While OEMs could map their physical control events to touch events, this approach does not allow for consistent focusing and selection feedback.

It's not realistic to add new SDL RPCs to support every OEM user interface because of the complex SDL core version management and ISV effort to support every custom spec. This proposal uses a plug-in architecture to represent the OEM controls as a HID device with corresponding device support module. OEMs can provide their support module quickly using this architecture and ISVs do not need to do OEM-specific integration work, even for video streaming.

## Proposed solution

This solution assumes the iOS and Android proxies expose a video streaming manager that traverses the application control hierarchy and renders the hierarchy as a video stream. On iOS, the Ford developed SDLCarWindow class is a prototype for the video streaming manager. On Android, VirtualDisplayEncoder class is also a prototype which is base point to extended to include this logic rather than forcing Android app developers to roll their own.

The video streaming manager exposes a remote HID device plug-in interface. The video streaming manager will load the correct plug-in by inspecting the VehicleType properties. The plug-in may provide the following functions, depending on the OEM’s requirements:

1. For OEM head units that render their own focus and selection feedback, communication of the focusable element rectangles to the head unit. This information may be used for haptic feedback and/or focus management by the head unit, superimposing information on the video stream. (ex. cursor, focus highlight).

2. Conversion of head unit control events to "OnTouchEvent"(RPC) or to native platform events if "OnTouchEvent"(RPC) is not sufficient

No new RPCs are added to support the plug-in interface. Rather, SystemRequest and other existing RPCs will be repurposed. However, since the custom behaviors will be encapsulated in the plug-in and will only work in the repurposed way with the OEM head unit, there is no impact on other SDL implementations.

## Potential downsides

Downside: OEMs will need to implement plug-ins for their head unit physical control and interface versions. If they do not, a default bypass plug-in contemplated by this proposal will handle the events. So, if all events can be mapped to an existing RPC (e.g. OnTouchEvent), applications can run without any specific plug-in. OEMs can disclose their plug-in specs and applications can customize to use plug-in features directly. It is possible that some specific device behaviors cannot be mapped to existing RPCs, and so new RPCs may be required.

## Impact on existing code

There will be significant code changes required in the iOS and Android proxies, specifically in the video streaming manager. There is no application code impact beyond adopting the video streaming manager.

## Alternatives considered

Alternative #1: Add new RPCs (ex. OnPointerMove) to support an OEM specific physical control set. Clearly this can lead to a proliferation of new RPCs as OEMs want to support new physical devices.

Alternative #2: Leverage the USB HID spec by adding a HID Report RPC or session service to support existing and future HID device classes and reports. The HID device specification and standard is common in consumer devices, but not in automotive. OEMs and their suppliers may not have the resources to adapt their devices to the HID format, and may not be able to keep pace with the consumer device market.

Alternative #3: OEMs disclose their specific device specs to ISVs. This forces the ISVs to do custom work for each OEM.
