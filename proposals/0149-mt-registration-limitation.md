# Add capability to disable resumption based on app type and transport type

* Proposal: [SDL-0149](0149-mt-registration-limitation.md)
* Author: [Sho Amano](https://github.com/shoamano83), [Robin Kurian](https://github.com/robinmk)
* Status: **In Review**
* Impacted Platforms: [Core]

## Introduction

This document proposes to add an advanced feature to disable or limit resumption feature based on AppHMIType and transport type. This is related to proposal [SDL-0141: Supporting simultaneous multiple transports][multiple_transports].


## Motivation

With the feature discussed in [SDL-0141: Supporting simultaneous multiple transports][multiple_transports], a mobile projection app will be able to utilize an additional high-bandwidth transport (called `Secondary Transport`) for video and audio streaming. However, the Secondary Transport may not always be available. For example, Wi-Fi functionality may be disabled on a head unit through user's configuration. Or the functionality can take time to initialize right after ignition on.

In such cases, it is possible that the mobile projection app will connect through Bluetooth transport, will receive HMILevel FULL and will not start video streaming according to configuration provided by Core (please refer to the proposal [SDL-0141][multiple_transports] for the configuration). HMI will show nothing on the screen since the streaming isn't started. This will lead to user's confusion.

This document proposes to disable resumption feature in such case, so that HMI will not show the app until Secondary Transport is connected (and video streaming is eventually started.) HMI will stay on another screen, for example app selection list. Also, HMI may implement an error message stating that Wi-Fi or USB transport is required for a mobile projection app to work.

In addition, this document also proposes to add another configuration to resume video streaming and media apps to a particular HMI level when the high-bandwidth transport isn't available. This will be useful for OEMs who want to let a navigation app run in LIMITED HMILevel before a Wi-Fi transport is established, while avoiding an empty screen being shown on HMI.

Note: the author thinks the resumption procedure has two stages. The first stage is that Core restores an app's HMILevel to non-NONE after the app is registered. The second stage is that Core restores the app's data based on stored information and Hash ID sent by the app. We discuss the first stage in this document. The term "disable resumption" means that Core doesn't restore an app's HMILevel after registration.


## Proposed solution

The proposed solution is to make the resumption feature configurable based on app's AppHMIType and transport type. The use-case in mind is to keep HMILevel of navigation and mobile projection apps to non-FULL (for example, LIMITED or NONE) until they are also connected through a high-bandwidth transport. The solution can be also used to specify AppHMIType that are allowed to receive non-NONE HMILevel after registration. For example, we can specify that only `MEDIA` apps receive non-NONE level.

The solution can be configured through smartDeviceLink.ini so that each OEM can customize the behavior.


## Detailed design

### Modification of Core

smartDeviceLink.ini includes following new sections. (Note: the default values are provided as an example.)

```ini
[TransportRequiredForResumption]
; This section specifies transport types that are required to trigger resumption for each AppHMIType.
; App has to be connected through at least one of the transports listed (either as the Primary
; Transport or Secondary Transport) to trigger resumption. If the app is not connected with any of
; the transports listed, its HMIlevel will be kept in NONE and the state stays in NOT_AUDIBLE.
; In case an app has multiple AppHMIType, requirements of all of the AppHMITypes are applied.
;
; Possible AppHMITypes: Default, Communication, Media, Messaging, Navigation, Information, Social,
;                       BackgroundProcess, Testing, System, Projection, RemoteControl, EmptyApp
; Possible transport types: TCP_WIFI, IAP_CARPLAY, IAP_USB_HOST_MODE, IAP_USB_DEVICE_MODE, IAP_USB,
;                           AOA_USB, IAP_BLUETOOTH, SPP_BLUETOOTH
;
; The default behavior is to always enable resumption. If an AppHMIType is not listed in this
; section, resumption is enabled for an app with the AppHMIType.
; On the other hand, if you want to disable resumption and always keep an app in NONE and
; NOT_AUDIBLE state after registration, specify an empty value for the AppHMIType.
;
; NAVIGATION apps, PROJECTION apps and apps that declare themselves as media apps have a special
; exception. When these apps do not have any of the transports listed here, they will be still
; resumed into particular HMIlevel defined in LowBandwidthTransportResumptionLevel section.

; DefaultTransportRequiredForResumption =
; CommunicationTransportRequiredForResumption =
; MediaTransportRequiredForResumption =
; MessagingTransportRequiredForResumption =
NavigationTransportRequiredForResumption = TCP_WIFI, IAP_CARPLAY, IAP_USB_HOST_MODE, IAP_USB_DEVICE_MODE, IAP_USB, AOA_USB
; InformationTransportRequiredForResumption =
; SocialTransportRequiredForResumption =
; BackgroundProcessTransportRequiredForResumption =
; TestingTransportRequiredForResumption =
; SystemTransportRequiredForResumption =
ProjectionTransportRequiredForResumption = TCP_WIFI, IAP_CARPLAY, IAP_USB_HOST_MODE, IAP_USB_DEVICE_MODE, IAP_USB, AOA_USB
; RemoteControlTransportRequiredForResumption =
; "EmptyAppTransportRequiredForResumption" applies to apps that don't specify any AppHMIType
; EmptyAppTransportRequiredForResumption =

[LowBandwidthTransportResumptionLevel]
; The HMI Level that an app will resume to if no high bandwidth connection is active.
; High bandwidth connections for each app type are defined under "TransportRequiredForResumption"
; section.
; Possible values: NONE, BACKGROUND, LIMITED and FULL
; this is for NAVIGATION apps
NavigationLowBandwidthResumptionLevel = LIMITED
; this is for PROJECTION apps
ProjectionLowBandwidthResumptionLevel = NONE
; this is for apps who declare themselves as media apps. (Don't be confused with AppHMIType=MEDIA.)
MediaLowBandwidthResumptionLevel = FULL
```

In the example shown above, the first section indicates that `NAVIGATION` and `PROJECTION` apps require either Wi-Fi or USB transports to fully enable resumption (i.e. resuming into FULL level). If the apps are connected only with Bluetooth transport, then the behavior is defined in the next section. Other AppHMITypes do not have restriction, so resumption will always be enabled for them.

Resumption for an app with an AppHMIType should always be enabled if the AppHMIType is not listed in the section of the smartDeviceLink.ini file. This is to keep compatibility with existing file.

The transport type strings are described by Table 1 in [SDL-0141][multiple_transports]. The table is also copied below for convenience:

String                 | Description
-----------------------|------------
IAP\_BLUETOOTH         | iAP over Bluetooth
IAP\_USB               | iAP over USB, and Core cannot distinguish between Host Mode and Device Mode.
IAP\_USB\_HOST\_MODE   | iAP over USB, and the phone is running as host
IAP\_USB\_DEVICE\_MODE | iAP over USB, and the phone is running as device
IAP\_CARPLAY           | iAP over Carplay wireless
SPP\_BLUETOOTH         | Bluetooth SPP. Either legacy SPP or SPP multiplexing.
AOA\_USB               | Android Open Accessory
TCP\_WIFI              | TCP connection over Wi-Fi


The second section is for `NAVIGATION`, `PROJECTION` and media apps. If none of the transports specified in `TransportRequiredForResumption` section are available, then the apps will resume into the HMI level specified in this section. In the example above, `NAVIGATION` apps will resume into LIMITED level when neither Wi-Fi nor USB transport is available. `PROJECTION` apps will be put in NONE level and in NOT\_AUDIBLE state. Media apps will resume into FULL level, which means resumption is fully enabled. If an app has multiple types then it will receive the highest level of all types. For example, if an app has `NAVIGATION` type and also declares itself as a media app, and when a high-bandwidth transport isn't available, then it will receive FULL level (highest among LIMITED and FULL) in the example configuration shown above.


Core is updated to include following implementations:
- `ApplicationManagerImpl` class includes additional logic to disable or limit resumption based on the configuration and app's transport when processing RegisterAppInterface request.
- `ApplicationManagerImpl` class detects a connection of Secondary Transport through `OnSecondaryTransportStartedCallback` callback (please refer to the proposal [SDL-0141][multiple_transports]) and triggers a resumption procedure if the condition is met.
- `Profile` class is updated to read and parse the new configuration sections


## Potential downsides

* The resumption sequence in Core will be more complicated.
* Since smartDeviceLink.ini file is not visible to mobile application developers, they may be confused that apps with certain AppHMITypes are launched automatically while other apps aren't. Or, they may also be confused that an app is automatically launched on a head unit from an OEM while it isn't on a head unit from another OEM.


## Impact on existing code

* This proposal impacts resumption sequence in Core that runs after app's registration.
* This proposal will not affect Proxy, HMI and RPC.


## Out of scope of this proposal

When a mobile projection app is connected through Bluetooth and Wi-Fi transports then the Wi-Fi transport is disconnected, HMI may want to terminate the app instead of showing a frozen screen. Since this proposal only changes the behavior of resumption, such use-case is not covered. OEMs may implement logic in HMI to terminate the app (using `BC.OnExitApplication` with `reason` being `USER_EXIT`) when the Secondary Transport is disconnected.


## Alternatives considered

* Instead of adding logic in Core, add it in HMI. The issue with this approach is that an app will be shown on HMI for a short time until HMI terminates it. Such behavior may lead to additional user confusion. Also, the author thinks that logic to manage and control apps' states should be implemented in Core, not in HMI.


## References

- [SDL-0141: Supporting simultaneous multiple transports][multiple_transports]


  [multiple_transports]: 0141-multiple-transports.md  "Supporting simultaneous multiple transports"

