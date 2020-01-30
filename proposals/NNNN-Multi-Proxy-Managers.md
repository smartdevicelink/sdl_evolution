# Support for Multiple Proxy Managers

* Proposal: [SDL-NNNN](https://github.com/smartdevicelink/sdl_evolution/pull/771)
* Author: [Kevin Burdette](https://github.com/khburdette), [Markos Rapitis](https://github.com/mrapitis), [Yurii Lokhmatov](https://github.com/yoooriii), [Kostiantyn Boskin](https://github.com/kostyaBoss),
* Status: **Waiting for a review**
* Impacted Platforms: [**iOS, Android**]

## Introduction

Once implemented it gives an opportunity to use multiple **Sdl Proxy Managers** to spin up and represent multiple **SDL** apps on the vehicle head unit for any given single mobile application.

## Motivation

OEM owner apps require an ability for a single mobile application on a smartphone to query the backend and dynamically connect several SDL apps based on availability on the vehicle head unit from a single mobile application. This can include availability based on market, region, language, SDL version, etc. This will also enable an app to add and remove **SDL** apps from the backend without requiring changes to the app itself.

Test tools would also benefit from the ability to dynamically spin up new **SDL** apps within a single mobile app. This capability is beneficial for the following needs:
* Load testing
* Possible interactions with apps
* Possibly discovering other issues

Currently there is no officially supported and documented mechanism for creating multiple SDL apps on a vehicle head unit via a single application on the mobile device that would support the capabilities required for both scenarios mentioned above.

**iOS** Specific:

* Current behavior on 6.2
  * When using multisession, a single app can only start 1 SDLManager per connection
  * Regression
  * When using the control channels, a single app can start multiple SDLManagers, but not when using multisession
    * When using the app on a head unit that doesn't support multisession, everything will work just fine, but when switching to a head unit that supports multisession, only 1 app will appear
  * Workaround
    * Modify SDLIAPTransport to only use control channels and not multisession channel

## Proposed solution

#### iOS platform

The main task at hand is to handle (manage) session id's and sort (route) messages between **SDL** apps and the head unit. In following steps provide analysis with explanations and solution proposition.

1. Only one transport must be in use across all the **SDL** apps. It can be an instance of either `SDLIAPTransport` or `SDLTCPTransport` class.

0. The transport must be implemented as a singleton and it should be created once the 1st app launches and destroyed (shut down) when the last app finishes.

0. All communication between the mobile device and the head unit goes through `SDLProtocol`.
 
0. Every single **SDL** app must possess its own instance of `SDLManager` and this manager internally has an instance of `SDLProtocol` which must communicate with the head unit through the shared transport (the singleton, see the previous point).

0. Every **SDL** app has its own unique **session-id** and when a UI app needs to send or receive a message the message header has its **session-id**.

0. We need to implement a `Router` class that will multiplex/demultiplex messsages to/from proper **SDL** apps from/to the head unit (**SDL Core**).

0. The `Router` will keep one instance of `SDLManager` for every running **SDL** app in a map where the key is the session id.

0. When a **SDL** app needs to send a message to the head unit it does it through the router, and the router then takes the app unique id and using this information finds a proper `SDLManager` in the map and then sends the message through the `SDLManager`.

0. When a message comes from the head unit the router checks its **session id** and finds a proper **SDL** app and bound with it `SDLManager` and routs the message to this manager which handles the message and passes it to a proper UI app.

## Potential downsides

Additional code is required to manage multiple proxies connected to the vehicle head unit via a single mobile library in the device side application. Also the library public interface may change or will require an update to support the old (current) behaviour (single app) and new multy app logic. We should take care of backward compatibility and make sure old (already existing) apps work properly with this functionality implemented.

## Impact on existing code

**Sdl Proxy Managers** will need to be updated and enhanced to handle connectivity for multiple apps.

1. Add a singleton to hold **TCP** or **iAP** transport 

0. Implement a `Router` class that will multiplex/demultiplex messsages to/from proper **SDL** apps from/to head unit.

0. Update the example application.

0. Update current tests and add new ones.

## Alternatives considered

none

## Restrictions
Only as many as **255** app instances can run at a time. If we need to run more (256 and above) mobile applications simultaneously then a protocol header change will be required. If for some reason an application needs to use more than one session then the whole applications number will decrease.
