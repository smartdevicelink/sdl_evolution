#OEM specific Humain Interface Device support as Plug-in architecture in SDL proxy

* Proposal: [SDL-NNNN](NNNN-HID-Support-Plug-in.md)
* Author: [Jennifer HOdges](https://github.com/jhodges55)
+ Status: Awaiting review
* Impacted Platforms: [ iOS / Android ]

##Introduction

To support OEM specific HID (ex. Lexus Remote Touch, Mazda Commander Control, BMW Gesture Control, and etc) without new RPC. In the mobile library, plugin architecture + OEM specific plugin module enable OEM specific HID.

##Motivation

Each OEM consider their original UX for safety driving, branding, and easy to operation. In such trend, some OEMs created and will create original specific Human Interface Device (HID). In the past before SDL, proprietary HU applications are implemented by each. And also SDL template architecture can support such specific HID in pre-defined layout properly, because SDL HMI has responsiblity to support HID event to control UI. However, video streaming application which uses NAV_FULLSCREEN_MAP cannot handle such specific HID properly, because there is only OnTouchEvent as RPC. Some devices require not only touch event but also other device specific in/out information. (ex. Haptic feedback, not absolute coordinates but relative, or widget level focus control)
And, it's not realstic to add new RPC to support every OEM special device (exiting device and future device) because SDL core version management and Application vendor effort to support every spec. This proposal is "plugin architecture" to solve "OEM's specific device" without deep discussion to Commonization and Generalization of HID. Each OEM can provide their special device support module quickly with using this architecture. And, it's unnecessary Application vendors to customize for each OEM's specific device. On the other words, Application vendors can avoid customization for each OEM's specific device not only in pre-defined layout (as template) but also in video streaming.

##Proposed solution

Premise condition: "High level UI/Widget library" which support Android/iOS widget for rendering video streaming application in SDL proxy. ex. Android:Virtual Display Encoder, iPhone:XXXX This library can retrieve High level UI/Widget layout information and create High level UI/Widget event.
This proposal architecture: Adding "Remote Human Interface Device manager" to SDL proxy (Android/iPhone). This module will provide following functionalities.
dynamic selection of proper plugin for connected HU. This functionalitiy will be implemented with using VehicleType and reflection of Android Java and iOS ObjectiveC/Swift.
bridge from/to "High-level UI/Widget library" to/from "plug-in module" which is proxy of HU special device.
Adding "Plug-in for each OEM's specific device" which will be provided by each OEMs. This module may realize following functionalities.
converting low level event which is sent from HU driver as OnTouchEvent(existing RPC) and/or OnSytemRequest(existing RPC, if OnTouchEvent's information is not enough to realize special event), to High level UI/Widget event, if required.
sharing High level UI/Widget layout information with HU driver with using OnSystemRequest and/or other RPCs (existing RPC). This information may be used for haptic feedback and/or focus management in HU.
superimposing information on application rendering image. (ex. cursor, focus highlight). These features requirements depend on each specific device features and OEM's UI/UX policy. NOTE) These feature may not be implemented in plugin. NOTE) Some features may be implemented in HU. NOTE) In some case of OEM specific plug-in, existing RPC may be used for not original purpose. However, this is closed spec between specific device and specific plug-in. So, it's not be affect to SDL general spec.

##Potential downsides

Downside:
OEM should prepare specific plug-in module for their specific device. If not prepared then, downside imapct is only "the special device will not be applicable use. Full functionality of the device cannot be realized". However, this proposal includes by-pass plug-in which pass thru event. So, if all of event can be mapped to existing RPC (OnTouchEvent) then, applications can be run as minimum without specific plug-in. Of course, no special device and only touch-panel I/F then application behavior is not different.
The applications not to use High-level UI/Widget library but to use application's UI library, cannot take benefit of this architecture. However, OEM can disclose each plug-in spec and such application may be able to customize to use plug-in feature directly.
If some specific device behavior cannot be mapped existing RPCs then, still new RPC may be required.

##Impact on existing code

Will be modified and new source code is not small to support this architecture. However, impact range is limited in "encoder" part. And, from perspective of Application, this architecture is behind "High-level UI/Widget library". So, it's unnecessary to modify Application logic.

##Alternatives considered

Another approach #1: Add some RPC (ex. OnPointerMove) to support a part of existing specifc device. Demerit of this approach: This solution may not cover future devices. In the case, we should consider next "new RPC" continuously. It may cause "flood of un-organized RPCs".
Another approach #2: Add general RPC or session service to support general existing and future HID. Not in vehicle but in PC/Set-top-box, already existed standard HID spec. If the spec can be migrate to SDL then, it may be enough solution. However, this requires much modification in not only mobile library but also SDL core. And, "in vehicle" is special environment. So, in the future, something new devices which is not considered in other industry may be created. In that time, HID (and RPC) should be considerd again. And, OEM must always worry how to map new devices to general HID spec when new device comes in.
Another approach #3: OEM will disclose specific device spec to Application vendors. Each Application vendors will customize their app to support each devices. This cause much effort in each Application vendors.
