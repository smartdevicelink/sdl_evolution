# Add zeroconf capability to WiFi transport

* Proposal: [SDL-0057](0057-add-zeroconf-capability.md)
* Author: Shinichi Watanabe, [Sho Amano](https://github.com/shoamano83/)
* Status: **In Review**
* Impacted Platforms: [iOS / Android]

## Introduction

The aim of adding zeroconf capability is to facilitate users configuring WiFi transport settings. Specifying head unit's IP address manually in car does not make sense in terms of user experience.

## Motivation

Currently, WiFi Transport is used for debugging purpose. A developer has to specify IP address and port to connect to SDL core (on head unit). By adding zeroconf capability, we can extend WiFi transport for production use, rather than debugging purpose only.

## Proposed solution

A head unit advertises its IP address and TCP port number over network using zeroconf. The zeroconf service should be compatible with Apple's Bonjour service, which utilizes mDNS and DNS-SD. The head unit uses predefined type and name for advertising.

SDL proxy discovers a head unit using the predefined type and name, and automatically initiates a TCP connection. When multiple head units are discovered (this is unlikely for a production use-case but is possible during development phase in a lab), SDL proxy will initiate a connection to the one which is discovered first. Also, SDL app can explicitly specify the type and name so that SDL proxy will initiate a connection only to a specific head unit - which is useful during development phase.

This proposal is to extend the usage of WiFi (TCP) transport. Advanced features like automatic transport selection is not included.

## Detailed design

### Sequence

Zeroconf discovery sequence is as follows:

0. (prerequisite) head unit and smart phone are in the same network.
1. Head unit starts zeroconf service, and starts advertising its IP address and port number.
2. SDL proxy starts discovering the service type and name.
3. If SDL proxy discovers the head unit's IP address and port, it initiates a TCP connection.

### Zeroconf configuration

A head unit shall configure the service type as "\_sdl.\_tcp". Also, it shall add "sdl\_zeroconf\_" prefix in the service name.

### Head unit

This proposal assumes that zeroconf advertiser is installed on a head unit system and SDL core does not need to care for it. This is because:
* the advertiser may be used for another purpose of the head unit, hence it is not a good idea that SDL core owns and controls it.
* the advertiser is often implemented as a daemon in Linux system, so it should be separated from SDL core program.

There are several scenarios where WiFi connection gets established between head unit and smart phone.
* The user turns on WiFi tethering on smart phone, and then head unit utilizes the smart phone as WiFi hot spot.
* The head unit is equipped with Data Communication Module (DCM) and it works as WiFi hot spot. The user's smart phone utilizes DCM as WiFi hot spot.

Either case, head unit's advertiser program should start advertising as soon as its WiFi IP address is resolved.

It is recommended that each head unit uses a unique service name. This is to avoid confusion when multiple head units exist on a single network.

### Android proxy

Service discovery feature is implemented using android.net.nsd package. TCPTransport can be extended to include support for the service discovery.

Two constructors are added to TCPTransportConfig class. SDL apps may use existing constructor to use ordinal TCPTransport, or use either of the new constructors to enable service discovery.

```java
    // this is to use service discovery with pre-defined service type and service name prefix
    public TCPTransportConfig(boolean autoReconnect) {
        :
    }

    // this is for a case that SDL app wants to specify service type and service name prefix
    public TCPTransportConfig(String serviceType, String serviceNamePrefix, boolean autoReconnect) {
        :
    }
```

The service discovery feature should be running only when the SDL app is in foreground state. (Please refer to this document https://developer.android.com/training/connect-devices-wirelessly/nsd.html) SDL proxy needs to listen to app's lifecycle using registerActivityLifecycleCallbacks() mechanism and control the feature accordingly.

In future, a new multiplex transport based on TCP can be added and SdlRouterService can be extended to support it. This approach has two advantages: 1) SdlRouterService runs as a foreground service and it will not be terminated easily, 2) network bandwidth can be lowered since this approach avoids each SDL app running the service discovery.

### iOS proxy

Service discovery feature is implemented using NSNetService class. The feature can be added to SDLTCPTransport class, or a new transport class may be added instead.

Preference class is extended to include information on whether service discovery feature is used, service type string and service name prefix. Service type and name prefix will have the pre-defined values as default, so that SDL apps do not need to configure them. ProxyManager class will forward these information to SDLLifecycleConfiguration during -startTCP call.

The service discovery feature should be running only when the SDL app is in foreground state. (Please refer to this document https://developer.apple.com/library/content/documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/BackgroundExecution/BackgroundExecution.html) SDL proxy should detect state change events using UIApplicationDidBecomeActiveNotification / UIApplicationWillResignActiveNotification / UIApplicationDidEnterBackgroundNotification and control the feature accordingly.

## Impact on existing code

Android and iOS proxies require additional implementation to support the discovery and connection sequence. Existing TCP transports may be updated during implementation. However, since they are new features, they should have no impact on current features.

A head unit system needs to support service advertising feature. Note that this is outside the scope of SDL core and HMI.

## Potential downsides

Service discovery is an expensive operation. It may give some impact on network bandwidth while running. Also, it may consume more battery on the phone compared to Bluetooth.

## Alternatives considered

This proposal is based upon a couple of assumptions:
* A head unit will keep advertising even after SDLProxy gets connected to head unit. We may need to consider the way where user can manually stop advertising and restart.
* A head unit uses single service name for all SDL apps.

In Android proxy, 3rd party library called JmDNS can be used instead of android.net.nsd package. This may avoid the issues described in "Notes on implementation" section. On the other hand, it will introduce a dependency on 3rd party library.

## Notes

### Limitation with TCP transports (not related to zeroconf)

TCP transports lack the mechanism of a head unit starting SDL apps on an iPhone / Android phone. A user needs to manually start a SDL app on his/her phone to start using SDL features.
* On iPhone using iOS 9.2 and iOS 10.x, SDL apps will be automatically launched in background when iAP connection (either over Bluetooth or USB) is established between a head unit. This mechanism enables SDL apps to run the start-up sequence like RegisterAppInterface.
* On Android phone, SDL apps can be woken up by android.bluetooth.device.action.ACL_CONNECTED broadcast when a Bluetooth low-level connection is established between a head unit.

On iPhone, a background app may not maintain sockets for a long time. (Please refer to the section "Being a Responsible Background App" in this document https://developer.apple.com/library/content/documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/BackgroundExecution/BackgroundExecution.html) Eventually, a user needs to put the SDL app foreground while using its features on HMI.

### Notes on implementation

There are several crash issues in android.net.nsd package reported on Android 4.x devices. (e.g. https://issuetracker.google.com/issues/36952181) It might be a good idea to limit the feature to Android 5 and onwards.
