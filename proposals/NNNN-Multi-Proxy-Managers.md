# Support for Multiple Proxy Managers

* Proposal: [SDL-NNNN](NNNN-Multi-Proxy-Managers.md)
* Author: [Kevin Burdette](https://github.com/khburdette), [Markos Rapitis](https://github.com/mrapitis)
* Status: **Awaiting review**
* Impacted Platforms: [Java Suite / iOS]

## Introduction

The ability to use multiple Sdl Proxy Managers to spin up and represent multiple SDL apps on the vehicle head unit for any given single mobile application.

## Motivation

OEM owner apps require the ability for a single mobile application on the phone to query a backend and dynamically connect several SDL apps based on availability on the vehicle head unit from a single mobile application. This can include availability based on market, region, language, SDL version, etc. This will also enable an app to add and remove SDL apps from the backend without requiring changes to the app itself.

Test tools would also benefit from the ability to dynamically spin up new SDL apps within a single mobile app. This capability is beneficial for the following needs:
* Load testing
* Possible interactions with apps
* Possibly discovering other issues

Currently there is no officially supported and documented mechanism for creating multiple SDL apps on a vehicle head unit via a single application on the mobile device that would support the capabilities required for both scenarios mentioned above.

OS Specific:
* Android
  * Current behavior on 4.8
    * Every SdlManager requires a unique service
    * Every SDL app will have it's own foreground service present in the notifications pull down
  * Regression
    * 4.5 allows you to start as many SdlProxyALM objects as you want withing a single service. 4.8 only allows you to start 1 SdlManager per service
  * Workaround
    * Include several services in the app and only use as many as you need SDL apps. Impact:
      * If you need more services than is included in the app, you have to modify the app to add more service and publish an update
      * Adds complication to maintaining such apps
* iOS
  * Current behavior on 6.2
    * When using multisession, a single app can only start 1 SDLManager per connection
  * Regression
    * When using the control channels, a single app can start multiple SDLManagers, but not when using multisession
    * When using the app on a head unit that doesn't support multisession, everything will work just fine, but when switching to a head unit that supports multisession, only 1 app will appear
  * Workaround
    * Modify SDLIAPTransport to only use control channels and not multisession channel

## Proposed solution

Recent mobile library releases for both iOS and Android make use of proxy manager classes that make it easier for developers to interact with the vehicle head unit via SDL.  We are proposing updates and enhancements to the existing SdlManagers and their supporting documentation to include the capability for supporting multiple apps on the vehicle head unit via a single mobile application and mobile library.

OS Specific:
* Android
  * The ability to use mutiple SdlManagers within a single service
* iOS
  * The ability to start multiple SDLManagers when using multisession

## Potential downsides

Some additional complexity is required to manage multiple proxies connected to the vehicle head unit via a single mobile library within the device side application.

## Impact on existing code

Sdl Proxy Managers would need to be updated and enhanced to handle connectivity for multiple apps.

## Alternatives considered

None
