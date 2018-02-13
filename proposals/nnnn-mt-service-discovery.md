# Add Service Discovery mechanism for TCP transport

* Proposal: [SDL-nnnn](nnnn-mt-service-discovery.md)
* Author: [Sho Amano](https://github.com/shoamano83)
* Status: **Awaiting review**
* Impacted Platforms: [Core / iOS / Android]

## Introduction

This document is related to proposal [SDL-nnnn: Supporting simultaneous multiple transports][multiple_transports]. To utilize TCP transport in production, Proxy needs a means to automatically configure IP address and TCP port number of SDL Core.


## Motivation

Currently, TCP (Wi-Fi) transport is used for debugging purpose, and developer has to specify IP address and port number to connect to SDL Core. We should not put burden on a user to manually configure them each time when s/he gets into a car and connects a SDL app. Instead, Proxy should automatically detect or acquire IP address and port number of SDL Core on a head unit.


## Proposed solution

This document proposes to introduce a service discovery mechanism. A head unit advertises SDL Core's IP address and TCP port number on its Wi-Fi network. Once an Android phone or iPhone joins to the network, SDL Proxy listens for the advertisement and automatically retrieves the information. Then it can initiate a TCP connection to SDL Core.

For the service discovery mechanism, this document proposes to employ DNS Service Discovery (DNS-SD) with multicast DNS (mDNS), also known as 'Bonjour'. The good thing with this mechanism is that its implementation is offered by both Android and iOS, so we do not need to include additional 3rd-party library into the Proxies. Also, there is a major open-source implementation (avahi-daemon) available for Linux platform.

It is possible that some head units integrate proprietary DNS-SD/mDNS service. Since we cannot support all of such implementations, this document proposes to add reference implementation in SDL Core which interacts with reference DNS-SD/mDNS service (avahi-daemon). OEMs should update the code to meet with their DNS-SD/mDNS services.

Since service discovery is expensive and may drain battery, it should not be running all the time on the phone.
* According to [Apple's official document][ios_background], it should be running only when the app is in foreground state.
* [Official Android document][android_nsd] also states that service discovery should be stopped when parent Activity is paused. However, since Android allows network communication in background, setting up Wi-Fi transport in background should improve user's experience. This document therefore proposes to run service discovery for a short time (e.g. 2 minutes) on Android even in background.
* Also, we should configure a reasonable timeout value (e.g. 2 minutes) and let Proxy stop service discovery automatically.


## Detailed design

### Service Discovery configuration

Define Service type as follows:
```
Service type: "_sdl._tcp"
```

Service name can be anything and OEMs are free to define it. It is recommended that each head unit has a different service name to distinguish it from others.

An example of a config file for avahi-daemon is shown below. Here, the service name is "sdl\_zeroconf\_abc123" and the TCP port number is 12345.

```xml
<?xml version="1.0" standalone='no'?><!--*-nxml-*-->
<!DOCTYPE service-group SYSTEM "avahi-service.dtd">

<service-group>

  <name replace-wildcards="yes">sdl_zeroconf_abc123</name>

  <service>
    <type>_sdl._tcp</type>
    <port>12345</port>
  </service>

</service-group>
```

### Modification of Proxies

**iOS:** A new transport class is added in iOS Proxy. Once its `connect` is called, it starts service discovery using `NSNetService` class. After retrieving IP address and port number information, it automatically initiates a TCP connection.

Part of existing `SDLTCPTransport` class can be reused or shared with the new class.

**Android:** A new transport class is added in Android Proxy, along with a new transport config class. Once its `openConnection` is called, it starts service discovery using the features from `android.net.nsd` package. After retrieving IP address and port number information, it automatically initiates a TCP connection.

Part of existing `TCPTransport` class can be reused or shared with the new class.

**Common to both iOS and Android:** Proxy may include additional entries in its preference to enable/disable service discovery feature and to filter head unit's information based on service name. The filtering may be useful for debugging in a lab, where more than one head units exist on a single Wi-Fi network and Proxy wants to connect to specific head unit.

As described in 'Proposed Solution' section, service discovery feature should be stopped when the app is not in foreground. Proxy should therefore detect app's state change and should control the feature accordingly.

Service discovery can be stopped after acquiring IP address and port number successfully.


### Modification of Core

A new class `TcpServiceAdvertiser` is added under `transport_adapter` namespace.

The class includes a reference implementation to start and stop advertising. When starting advertisement, it generates a config file under /etc/avahi/service/ directory and sends a SIGHUP signal to avahi-daemon. When stopping advertisement, it removes the config file and sends a SIGHUP signal again.

`TcpClientListener` class is extended to call the methods of `TcpServiceAdvertiser` during `StartListening()` and `StopListening()`.

smartDeviceLink.ini should have a new entry to enable/disable the advertisement feature. Also, it is preferable to add another entry to configure the service name. `TcpServiceAdvertiser` uses the service name and TCP port number written in the .ini file to set up the config file under /etc/avahi/service/ directory.


## Potential downsides

* This proposal does not offer a means to select a head unit when there are multiple head units on a Wi-Fi network. Proxy simply tries to connect the first head unit that has been discovered. The author thinks it is very uncommon that more than one head units are on a single Wi-Fi network, except for development/debugging in a lab.
* Head units have to add a service such as avahi-daemon for service discovery mechanism.
* Service discovery mechanism consumes a little bandwidth of Wi-Fi network.


## Impact on existing code

This proposal should have little impact on existing code since most of the codes are for newly added classes.


## Out of scope of this proposal

Automatic configuration of Wi-Fi network credential (SSID and passphrase) is not included in this proposal. It is assumed that the credential is configured and stored on the phone and/or on the head unit beforehand.

There are multiple types of Wi-Fi network topology; the head unit acts as an access point, the phone acts as an access point by using Wi-Fi tether feature, and the user brings a Wi-Fi hotspot device in the car. The service discovery mechanism should work in either case, so network topology discussion is out of scope of this proposal.


## Discussions

It is desirable that a SDL app automatically launches and starts service discovery once the phone is connected to a head unit over Wi-Fi. This sounds quite difficult:
- Starting from iOS 10, an app will be launched in background when an external iAP accessory (head unit in this case) is connected over Bluetooth or USB. Or, a head unit may have custom implementation to launch specific app using iAP's launch request. Either case, iAP connection is required before launching an app.
- Previously Android app could receive `WIFI_STATE_CHANGED_ACTION` (android.net.wifi.WIFI\_STATE\_CHANGED) broadcast intent, which is similar to `ACTION_ACL_CONNECTED` in the case of Bluetooth. Starting from Android O, apps are not able to register broadcast receivers for implicit broadcasts. `ACTION_ACL_CONNECTED` is an exception (see [here][android_bc_exception]) and apps can still receive it.


## Alternatives considered

- Using a Zeroconf mechanism other than DNS-SD/mDNS. A candidate is Universal Plug and Play (UPnP). In this proposal, DNS-SD/mDNS is chosen since: it concentrates on service discovery feature, and it is already supported by iOS and Android framework.
- Convey IP address and TCP port information using another transport, such as iAP or Bluetooth SPP. This approach requires at least a transport is established before setting up Wi-Fi (TCP) transport. Therefore, it cannot support a use-case that an Android app connect to a head unit solely using Wi-Fi transport.
- Instead of creating new transport classes, extend existing TCP transport classes in Proxies. This approach will have impacts on existing code, so if we choose it, we should be careful when implementing.
- Introduce "multiplex TCP transport" in Android Proxy. This approach prevents each SDL app running service discovery procedures and may reduce network usage/battery consumption. However, adding another multiplex service seems too much for this sub-proposal.


## References

- [Background Execution][apple_background] from App Programming Guide for iOS
- [Using Network Service Discovery][android_nsd] from Android Developers
- [Implicit Broadcast Exceptions][android_bc_exception] from Android Developers
- [SDL-nnnn: Supporting simultaneous multiple transports][multiple_transports]


  [ios_background]: https://developer.apple.com/library/content/documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/BackgroundExecution/BackgroundExecution.html  "Background Execution"
  [android_nsd]: https://developer.android.com/training/connect-devices-wirelessly/nsd.html  "Using Network Service Discovery"
  [android_bc_exception]: https://developer.android.com/guide/components/broadcast-exceptions.html  "Implicit Broadcast Exceptions"
  [multiple_transports]: nnnn-multiple-transports.md  "Supporting simultaneous multiple transports"

