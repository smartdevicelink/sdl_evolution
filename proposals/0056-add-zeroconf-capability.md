# Add zeroconf capability to WiFi transport

* Proposal: [SDL-0056](0056-add-zeroconf-capability.md)
* Author: Shinichi Watanabe
* Status: **In Review**
* Impacted Platforms: [Core / iOS / Android / RPC]

## Introduction

The aim of adding zeroconf capability is to facilitate users configuring WiFi transport settings. Specifying head unit's IP address manually in car does not make sense in terms of user experience.

## Motivation

Currently, WiFi Transport is used for debugging purpose, and developer has to specify IP address and port to connect to SDL HMI (on head unit). By adding zeroconf capability, we can extend WiFi transport for production use, rather than debugging purpose only.

## Proposed solution

The solution detailed in this proposal will introduce a new API in SDLProxyFactory as follows:
```
+ (SDLProxy *)buildSDLProxyWithListener:(SDLProxyListener *)delegate withServiceType:(NSString *)servicetype serviceName:(NSString *)serviceName
```

The api above takes service type and service name for zeroconf discovery. The application developer must know the service type and name where head unit's zeroconf service advertises.

Head unit that supports SDL over WiFi transport is supposed to implement zeroconf service and advertise the address and port. SDL proxy will discover the target service with pre-defined type and name.

The zeroconf service should be compatible with Apple's Bonjour service, which will utilize mDNS and/or DNS-SD.

## Detailed design

There are several scenarios where WiFi connection gets established between head unit and smart phone.
* The user turns on WiFi tethering on smart phone, and then head unit utilizes the smart phone as WiFi hot spot.
* The head unit is equipped with Data Communication Module (DCM) and it works as WiFi hot spot. The user's smart phone utilizes DCM as WiFi hot spot.
Either case, head unit's program should start advertising as soon as its WiFi IP address is resolved.

### zeroconf discovery sequence will be as follows:
0. (prerequisite) head unit and smart phone are in the same network.
1. Head unit starts zeroconf service, and starts advertising its IP address and port with predefined type (e.g. "_sdl._tcp"), and name (e.g. "sdl_zeroconf_xxxx")
2. Smart phone starts discovering the type and name.
3. If smart phone found the head unit's IP address and port, smart phone builds SDL proxy with the discovered IP address and port.

## Impact on existing code

HMI changes:
*	SDL Core Wifi transport needs to implement zeroconf service and advertise the IP address and port.

Mobile iOS/Android SDK changes:
*	requires new API
```
+ (SDLProxy *)buildSDLProxyWithListener:(SDLProxyListener *)delegate withServiceType:(NSString *)servicetype serviceName:(NSString *)serviceName
```

## Alternatives considered

This proposal is based upon a couple of assumptions:
* Head unit will keep advertising even after SDLProxy gets connected to head unit. We may need to consider the way where user can manually stop advertising and restart.
* We need to define the service type and name used for service discovery.
* What if head unit wants to advertise multiple service name for multiple SDL apps??
