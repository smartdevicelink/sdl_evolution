# Notification of iAP transport type

* Proposal: [SDL-nnnn](nnnn-iap-transport-type-notification.md)
* Author: [Sho Amano](https://github.com/shoamano83/)
* Status: **Awaiting review**
* Impacted Platforms: [Core / iOS / Protocol]

## Introduction

This proposal aims to notify underlying transport type to iOS SDL apps. The apps can use such notification to control, for example, the bitrate of video stream when running navigation.

## Motivation

On an iOS device, connection between a head unit and the iOS device is called iAP and maintained by iOS system. It uses two underlying transports - USB and Bluetooth, and it automatically chooses an appropriate one. An iOS App does not need to care which transport is chosen. At the same time, it *cannot* know which transport is chosen.

There are some cases when an SDL app wants to know the underlying transport type. One of such case is SDL video streaming. Since USB has much higher bandwidth compared to Bluetooth, a SDL navigation app may want to use high bitrate for the video when USB transport is used, and lower the bitrate after the transport switches to Bluetooth.

Since an iOS app cannot detect underlying transport type by itself, this proposal lets SDL core to detect it and forward such information to SDL proxy.


## Proposed solution

This proposal appends an extra value in `Start Service ACK` Control Frame of the Version Negotiation. The value contains underlying transport types. It uses "Constructed Payloads" scheme proposed by [SDL-0052](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0052-constructed-payloads.md).

iOS Proxy receives the value and updates its property, so that SDL app can know the transport type by inspecting it.

**Note:** this proposal is based on an assumption that when iAP's transport type (USB / Bluetooth) is changed, SDL proxy will initiate `Start Service` Control Frame each time.


## Detailed design

### Addition to Protocol

When SDL core sends `Start Service ACK` Control Frame for the Version Negotiation, it adds following BSON document:

```json
{
    "transportTypes": transport-types
}
```

Where `transport-types` is a list of strings indicating transport(s) connected between SDL core and SDL proxy. The string shall be one of below:

- "IAP_BLUETOOTH"
  - SDL protocol is running on iAP over Bluetooth. This is for iOS SDL apps.
- "IAP_USB"
  - SDL protocol is running on iAP over USB, and SDL core cannot distinguish between Host Mode and Device Mode. This is for iOS SDL apps.
- "IAP_USB_IN_HOST_MODE"
  - SDL protocol is running on iAP over USB, and the phone is running as the host. This is for iOS SDL apps.
- "IAP_USB_IN_DEVICE_MODE"
  - SDL protocol is running on iAP over USB, and the phone is running as a device. This is for iOS SDL apps.
- "BLUETOOTH_SPP"
  - SDL protocol is running on Bluetooth SPP transport. This is for Android SDL apps.
- "USB_AOA"
  - SDL protocol is running on AOA (Android Open Accessory). This is for Android SDL apps.
- "TCP"
  - SDL protocol is running on a generic TCP connection such as Wi-Fi. This is for both iOS and Android SDL apps.
- "UNKNOWN"
  - This indicates that SDL protocol is running on a transport not listed above.

Although this proposal is for iAP, the strings also include values for Android proxy for completeness.

`transport-types` is defined as a list because we may have multiple transports connected between the Core and Proxy in future.


### Changes for iOS Proxy

In SDLProxy, read out the BSON document after it receives `Start Session ACK` frame for RPC. SDLProxy class keeps the transport type as a property.

In SDLManager, add a public read-only property to provide the transport type to the app. This property will be tied to the property of underlying SDLProxy.


### Changes for SDL core

- In transport_adapter.h, append necessary values in `DeviceType` enum
- In TransportManager class, add `GetTransportType()` method. It receives a ConnectionUID and returns corresponding string (e.g. "IAP_BLUETOOTH")
- In ProtocolHandlerImpl class, append BSON document when sending `Start Session ACK` frame.

Also, OEMs should update transport adapter's GetDeviceType() implementation to return updated `DeviceType` value.


## Potential downsides

The BSON document in `Start Service ACK` frame might look confusing since transport type information is not related to protocol or service.


## Impact on existing code

The impact on existing code should be small since only the code related to `Start Service ACK` frame and `DeviceType` enum are updated.


## Alternatives considered

__Alternative #1:__ Extend control stream of iAP (com.smartdevicelink.proto0) to include additional information such as transport type.

Currently the control stream includes one byte data which indicates the ID of data stream. It is possible that some more data is added in the control stream to notify iAP transport type. The issue with this approach is that the proxy cannot know whether SDL core's iAP transport implementation (which is specific to each OEM) supports this feature or not, so the proxy cannot know how many bytes it should read from the control stream.


__Alternative #2:__ Add a RPC notification to notify transport type after transport is switched.

The notification is issued by SDL core and sent to proxy, typically after RegisterAppInterface response. Our understanding is that adding a new RPC for dedicated purpose should be avoided, for it will increase complexity in SDL core and proxy implementation.

__Alternative #3:__ Extend RegisterAppInterface response to include the transport type.

A new parameter is added in RegisterAppInterface response which notifies the transport type. This approach is simplest and should be easiest to implement. However, it is not sure whether RegisterAppInterface request is issued every time after iAP transport type is switched. Currently it is, but not sure after we introduce transport switch enhancement like proposal [SDL-0053](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0053-Connectivity-via-iAP-BT-and-Transport-Switch.md). Also, it is not considered to be a good idea to extend RegisterAppInterface since it lacks scalability, see proposal [SDL-0055](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0055-system_capabilities_query.md).


## Discussion

This proposal does not update `TransportType` enum in HMI\_API.xml. If HMI needs detailed transport information like iAP Host mode and Device mode, then this enum should be updated as well.
