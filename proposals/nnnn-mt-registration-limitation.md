# Add capability to disable or reject an app based on app type, transport type and OS type

* Proposal: [SDL-nnnn](nnnn-mt-registration-limitation.md)
* Author: [Sho Amano](https://github.com/shoamano83), [Robin Kurian](https://github.com/robinmk)
* Status: **Awaiting review**
* Impacted Platforms: [Core / iOS / Android / RPC]

## Introduction

This document proposes to add an advanced feature to limit app's registration based on AppHMIType, transport type and OS type. This is related to the proposal [SDL-nnnn: Supporting simultaneous multiple transports][multiple_transports].


## Motivation

According to [Apple's document][ios_background], iOS may close network sockets when an iOS app goes to background. This means, the Wi-Fi (TCP) transport of an iOS SDL app can be suddenly disconnected while the app is in background. Since most of the users are not aware of such OS limitation, this app's behavior looks very confusing.

A possible solution for this issue is to prevent the user from using SDL app while the app is connected only through Wi-Fi (TCP) transport. For example, registration of an app is rejected when the app does not establish iAP transport yet. Or, the registration can succeed but Core prevents the app from being started on HMI.

Typical use-case is as follows. An OEM wants to allow using Wi-Fi transport only for navigation and mobile projection apps on iOS. It wants to allow only iAP transport for other types of apps to avoid user's confusion.
- When a navigation or mobile projection iOS app is connected to Core only with Wi-Fi transport, Core grants the registration but keeps its HMI level to NONE. No resumption is triggered, and Core won't notify BC.OnAppRegistered to HMI. Once the app adds a connection through iAP transport, resumption and BC.OnAppRegistered notification will be triggered.
- When other types of iOS apps are connected to Core only with Wi-Fi transport, Core rejects their registrations. Proxy will use another transport (iAP) to try the registration.
- When an iOS app is connected and registered through iAP transport, then Wi-Fi transport is established, then these restrictions will not apply.


## Proposed solution

The proposed solution is to add an advanced feature in Core to:
- Reject an app's registration based on its AppHMIType, the transport type and/or OS type.
  * Core will also unregister an app after certain timeout if above condition is met while the app is running. (For example, the mandatory transport is disconnected and does not recover within the timeout.)
- Prevent an app being launched based on its AppHMIType, the transport type and/or OS type.
  * After the app is registered, Core keeps its HMI level to NONE, it will not trigger resumption, and it will not notify BC.OnAppRegistered to HMI.
  * Core will also put the app's HMI level to NONE and notify BC.OnAppUnregistered to HMI after certain timeout if above condition is met while the app is running. (For example, the mandatory transport is disconnected and does not recover within the timeout.)

These features can be configured through smartDeviceLink.ini so that OEMs can enable, disable or customize their behavior.


## Detailed design

### Modification of MOBILE\_API.xml

Add `UNAUTHORIZED_TRANSPORT_REGISTRATION` error enum. This value is used by RegisterAppInterface response, so `resultCode` param of RegisterAppInterface response should be updated as well.

```xml
    <enum name="Result" internal_scope="base">

        :

        <element name="UNAUTHORIZED_TRANSPORT_REGISTRATION">
            <description>Core doesn't accept registration based on the app's transport type, AppHMIType and OS type. Try registration using another transport.</description>
        </element>
```

### Modification of Core

smartDeviceLink.ini includes following new sections. (Note: the default values are provided as an example.)

```ini
[AcceptedAppHMITypeTable]
; This section is used to filter apps that can be registered.
; Apps with AppHMITypes specified in this section are allowed to register.
; AppHMITypes are specified per transport and OS type. OEM can, for example, reject registration request from specific transport.
; The AppHMIType(s) is/are specified as comma-separated list. If the list should be empty, specify 'none'.
; 'empty' is a special word indicating apps that do not specify AppHMIType.
; '*' indicates all apps, including those that do not have AppHMIType specified.
WiFi-iOS = none
WiFi-Android = *
iAP = *
Bluetooth-SPP = *
AOA = *

[DisabledAppHMITypeTable]
; This section is used to specify apps that can be registered but not allowed to launch.
; Apps with AppHMITypes specified in this section are allowed to register. However, they will be kept in HMILevel NONE and
; will not be notified to HMI.
; AppHMITypes are specified per transport and OS type. OEM can, for example, disable specific type(s) of apps which are connected
; through specific transport.
; The AppHMIType(s) is/are specified as comma-separated list. If the list should be empty, specify 'none'.
; 'empty' is a special word indicating apps that do not specify AppHMIType.
; '*' indicates all apps, including those that do not have AppHMIType specified.
; If same AppHMIType is specified in both AcceptedAppHMITypeTable and DisabledAppHMITypeTable, the entry in DisabledAppHMITypeTable is
; ignored and apps with the AppHMIType are launched as usual.
; also, if an app has multiple AppHMITypes, and they are listed in both AcceptedAppHMITypeTable and DisabledAppHMITypeTable, then the
; app is launched as usual.
; If an AppHMIType is not specified to neither AcceptedAppHMITypeTable nor DisabledAppHMITypeTable, then apps with the AppHMIType
; are rejected for registration through the transport. WiFi-iOS = NAVIGATION, PROJECTION
WiFi-Android = none
iAP = none
Bluetooth-SPP = none
AOA = none
```

In these sections, `WiFi-iOS` entry is for registration from iOS app through Wi-Fi transport. `WiFi-Android` is for registration from Android app through Wi-Fi transport. `iAP` is for iOS apps. `Bluetooth-SPP` and `AOA` are for Android apps.

For backward compatibility, these features should be disabled when the sections do not exist in smartDeviceLink.ini file.

Core is updated to include following implementations:
- `Profile` class is updated to read and parse the new configuration sections
- `ApplicationManagerImpl` class includes additional implementation to reject RegisterAppInterface request based on the given condition, or accept it but prevents resumption and BC.OnAppRegistered notification.
- `ApplicationManagerImpl` class includes additional implementation to start a timer when given condition are not met (due to transport disconnection). When the timer is fired, the class either puts the app's HMI level to NONE and notify BC.OnAppUnregistered notification, or unregister the app.

### Modifications of Proxies

iOS and Android Proxies should handle the new RegisterAppInterface response error `UNAUTHORIZED_TRANSPORT_REGISTRATION`. Proxy should continue trying to connect to Core and register through another transport. Also, once registration is successful with a transport, it should retry establishing the transport in which RegisterAppInterface has failed.


## Potential downsides

* App registration sequence, especially the retry logic in Proxy, gets more complicated.
* Since smartDeviceLink.ini file is not visible to mobile application developers, they may be confused that some apps are allowed to use a transport (such as Wi-Fi) but others aren't. They may also be confused that an app may be kept in HMI level NONE under a condition that is not open to them.


## Impact on existing code

This proposal impacts the basic app registration sequence in Core.


## Alternatives considered

* Instead of adding the features in Core, update iOS Proxy to meet the basic requirement. That is, iOS Proxy always tries iAP connection before starting Wi-Fi transport (unless the app specifies to use TCP transport for debugging). When the Proxy uses both iAP and Wi-Fi transports, and iAP gets disconnected, Proxy closes Wi-Fi transport after certain time.<br>
This approach should have less impact to the system since we do not update Core implementation. The disadvantage is that it is not a generic solution and is not flexible. Also, OEMs cannot choose to enable or disable the feature.
* Instead of adding logic in Core, add it in HMI. The issue with this approach is that HMI cannot control app launching completely, since Core may launch an app using resumption.
* Instead of rejecting RegisterAppInterface, send Start Service NACK during Version Negotiation. In this approach, Proxy's implementation can get more complex since it should initiate Start Service again after RegisterAppInterface is succeeded and another transport is established on it.


## References

- [Background Execution][ios_background] from App Programming Guide for iOS
- [SDL-nnnn: Supporting simultaneous multiple transports][multiple_transports]


  [ios_background]:  https://developer.apple.com/library/content/documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/BackgroundExecution/BackgroundExecution.html  "Background Execution"
  [multiple_transports]: nnnn-multiple-transports.md  "Supporting simultaneous multiple transports"

