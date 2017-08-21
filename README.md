# SDL Evolution
**Do not submit a proposal without reading this roadmap document.** Ideas should be discussed on the [SDL Slack][sdl_slack] [#sdl_evolution][sdl_evolution_channel] open channel before a proposal is created here.

For more information about SDL, go to [www.smartdevicelink.com](https://www.smartdevicelink.com).

This process and document is based on Apple's excellent [Swift Evolution](https://github.com/apple/swift-evolution) process.

This document tracks the ongoing evolution of SDL. Proposals should be made for any public API surface change, that is, any change that would necessitate a minor or major version change in any SDL mobile library. If a protocol or RPC change does not change any API surface, they must still be brought through the proposal process. In sum, the following changes must be proposed:

* Changes necessitating minor or major version updates to SDL Core, the mobile libraries, Manticore, SDL Policy Server, and SHAID according to [semantic versioning](http://www.semver.org), except those that are caused by a misspelling.
* **Any** change to the SDL Protocol.
* **Any** change to the SDL RPC spec.

Important documents:

* Goals for upcoming SDL releases – this document.
* The [SDL evolution proposal review schedule](https://smartdevicelink.github.io/sdl_evolution/) to see upcoming SDL evolution proposal reviews.
* The [SDL evolution review process](process.md) to see how to propose and review proposals.
* The [proposals versus issues document](proposals_versus_issues.md) to understand the differences between an SDL Evolution Proposal and an SDL Issue.

## Platforms
When entering a proposal, only one platform will be listed as impacted on the [proposal status page][proposal-status].  It's inherent that some platforms impact others, as described below:

#### Protocol
The SmartDeviceLink protocol specification describes the method for establishing communication between an application and head unit and registering the application for continued communication with the head unit. The protocol is used as the base formation of packets sent from one module to another.

All new SDL implementations should implement the newest version of the protocol.

**Repository**: [https://github.com/smartdevicelink/protocol_spec](https://github.com/smartdevicelink/protocol_spec)

**Changes to Protocol also impact the following platforms**:

- Core
- iOS
- Android

---

#### RPC Spec
Spec for RPC messages sent between mobile devices and hardware modules.

**Repository**: [https://github.com/smartdevicelink/rpc_spec](https://github.com/smartdevicelink/rpc_spec)

**Changes to RPC also impact the following platforms:**

- Core
- iOS
- Android

---

#### Core
The Core component is the software which Vehicle Manufacturers (OEMs) implement in their vehicle head units. Integrating this component into their head unit and HMI based on a set of guidelines and templates enables access to various smartphone applications.

**Repository**: [https://github.com/smartdevicelink/sdl_core] (https://github.com/smartdevicelink/sdl_core)

**Changes to Core also impact the following platforms:**

- Manticore

---

#### Android SDK
The Android library is implemented by Android app developers into their applications to enable command and control via the connected head unit.

**Repository**: [https://github.com/smartdevicelink/sdl_android](https://github.com/smartdevicelink/sdl_android)

---

#### iOS SDK
The iOS library is implemented by iOS app developers into their applications to enable command and control via the connected head unit.

**Repository**: [https://github.com/smartdevicelink/sdl_ios](https://github.com/smartdevicelink/sdl_ios)

---

#### Manticore 
Manticore is used to dynamically provision SDL Core and SDL HMI instances in the cloud.

**Repository**: [https://github.com/smartdevicelink/manticore](https://github.com/smartdevicelink/manticore)

**SDL hosted instance**: [https://smartdevicelink.com/resources/manticore/](https://smartdevicelink.com/resources/manticore/)

---

#### SDL Policy Server 
The SDL Policy Server handles authentication, data collection, and basic configurations for SDL connected vehicles.

**Repository**: [https://github.com/smartdevicelink/sdl_server](https://github.com/smartdevicelink/sdl_server)

---

#### SHAID 
SHAID is a centralized service designed to keep information about SDL-supported applications synchronized across the SmartDeviceLink (SDL) ecosystem.

**Repository**: [https://github.com/smartdevicelink/sdl_shaid](https://github.com/smartdevicelink/sdl_shaid)

## Recent and Upcoming Releases
You can see a detailed list of accepted and implemented proposals for upcoming versions on the [proposal status page][proposal-status].  Each proposal is listed as only impacting one platform, as it's inherent that some platforms impact others, as described above in the `Platforms` Section.

#### SHAID: 2.0.0
**Release Date**: August 15, 2017

**Contents**: This release enhances SHAID to allow application information (including name, description, default HMI level, RPCs required for integration, and ID) for SDLC-approved apps to be stored and accessible to "App Consumer" companies (OEMs and Suppliers).  SHAID will also send notifications to these App Consumer companies when an SDLC-approved application registered on SHAID has been modified.

---

#### iOS SDK: 4.7.0
**Expected Release Date**: August 31, 2017

**Contents**: Bug fixes and new features included on the [iOS 4.7.0 Project Page](https://github.com/smartdevicelink/sdl_ios/projects/5).

---

#### SDL Protocol: 5.0.0
**Expected Release Date**: October 30, 2017

**Contents**: Introducing control frame payloads and a revised version negotiation scheme.  See the current draft of the new version of the spec [here](https://github.com/smartdevicelink/protocol_spec/pull/9).

---

#### SDL RPC Spec: 4.5.0
**Expected Release Date**: October 30, 2017

**Contents**: See change log for alterations to the spec at a high level, and current draft of the new version of the spec [here](https://github.com/smartdevicelink/rpc_spec/pull/25).

---

#### Core: 4.4.0
**Expected Release Date**: October 30, 2017

**Contents**: Core stabilization fixes and introduction of new features included on the [Core 4.4.0 Project Page](https://github.com/smartdevicelink/sdl_core/projects/7).

---

#### Android SDK: 4.4.0
**Expected Release Date**: October 30, 2017

**Contents**: This release will focus on better continuous integration strategy, better video streaming APIs and various evolution items, described in detail on the [Android 4.4.0 Project Page](https://github.com/smartdevicelink/sdl_android/projects/4).

---

#### Manticore: 1.1.0
**Expected Release Date**: October 30, 2017

**Contents**: Include enhancements and update to the latest version of Core and the Generic HMI.




[sdl_slack]: http://slack.smartdevicelink.com "SDL Slack"
[sdl_evolution_channel]: https://smartdevicelink.slack.com/messages/sdl_evolution/ "sdl_evolution slack channel"
[proposal-status]: https://smartdevicelink.github.io/sdl_evolution/
