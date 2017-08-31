# AOA multiplexing similar to Android BT/SPP multiplexing

* Proposal: [SDL-NNNN](NNNN-AOA-multiplexing.md)
* Author: [Jennifer Hodges](https://github.com/jhodges55)
* Status: Awaiting review
* Impacted Platforms: [ Android ]


## Introduction

Add "multiplexing" to AOA transport. ![Overview](../assets/proposals/nnnn-AOA-multiplexing/nnnn-AOA-multiplexing_overview.png)
This change introduces a better user experience as followings:
- Multi navigation apps to be able to exchanged by user.
- None navigation apps can select not only BT/SPP but AOA. 
- In the future, projection will be applied to not only navigation but also other category application then, multi "projection apps" can be supported.

## Motivation

Currently, only one AOA app can connnect to SDL core because of AOA limitation. Before that, our assumption of AOA, only 1 navigation app can connect to SDL core. No more app is assumed. However, several navigation apps will come in the near future. And, projection functionality will be opened for not navi but other category apps which requires wide bandwidth such USB. So, for better and flexible UX, it should be valuable to support multiple app on AOA.
 
## Proposed solution

Implement multiplexing functionality to AOA transport of SDL Android library. This architecture is similar to existing BT/SPP multiplexing. However, in Android, SPP and AOA may exist in parallel. So, another multiplexing router for AOA should be added. If OEM using other protocol on AOA for none SDL service to be supported then, this architecture can be used for this purpose with customized SDL Android library which is special router service for other standard SDL apps.
SDL core is unnecessary to be changed. SDL core already supported multi session in single transport with using session id.
Optionally, if HU manufacture to support multiplexing AOA only then AOA parameter can be "SDL", "Core", __"1.1"__, (not "SDL", "Core", __"1.0"__). 
The spec must be written in Guide->Android->Getting Started->Using AOA protocol.

## Potential downsides

Downside:
backward compatibility
App vendor may worry AOA parameter setting and proxy version (don't worry to set both, new AOA parameter and old AOA parameter. old HU can connect multi AOA apps which are linked new sdl proxy).

## Impact on existing code

There will be similar inter-compatibility issue of BT/SPP multiplexing. If old sigle AOA SDL proxy is selected by user and Android OS then, new multiplexing AOA apps cannot connect to SDL core.

in the case of New AOA parameter "SDL","Core",__"1.1"__ 
- case "old app + new apps": "old app" cannot be activated because of different accessory parameter. only 1 new app can be router of AOA, other new apps can connect via router.
- case "old app" only: old app __cannot__ can connect.
- case "new apps, no old app": normal case

in the case of same AOA parameter "SDL","Core","1.0"
- case "old app + new apps": if end-user choose "old app" in Android user confirmation dialog "which app should be used for this accessory" then, only old app can connect to sdl core. If end-user choose 1 of "new app" then, all of "new apps" can connect to sdl core, and old app cannot connect.
- case "old app" only: old app __can__ connect.
- case "new apps, no old app": normal case

## Alternatives considered

Alternative #1: more transperancy transport architecture in Android similar to iAP. It may be better solution for app vendor because of no care which transport will/should be used. However, all apps should use the new library. It may be bad impact to SDL market launching.

Alternative #2: general protocol build on AOA to support multi session. SDL protocol (wipro protocol) already support the system. Issue is only AOA open and the file descriptor can be used by only 1 context in Android. So, the general protocol is not solution.

