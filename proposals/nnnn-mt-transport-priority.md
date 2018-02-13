# Configuring Transport Priority

* Proposal: [SDL-nnnn](nnnn-mt-transport-priority.md)
* Author: [Sho Amano](https://github.com/shoamano83)
* Status: **Awaiting review**
* Impacted Platforms: [Core / iOS / Android / Protocol]

## Introduction

This document is a sub-proposal of [SDL-nnnn: Supporting simultaneous multiple transports][multiple_transports]. It describes how Core and Proxy should choose an appropriate transport to communicate with each other when multiple transports are available.


## Motivation

As stated in [SDL-nnnn][multiple_transports], the motivation is to keep multiple transports between Core and Proxy. When communicating, they choose the most appropriate transport to send frames.

The basic idea of choosing the transport is to configure transport priority beforehand. An example of the priority is "Wi-Fi is most preferred transport, USB is second most, and Bluetooth is least." In this case, Core and Proxy choose Wi-Fi transport when it's available, if not then USB (iAP over USB and AOA) if it's available, and if not, then Bluetooth (iAP over Bluetooth and Bluetooth SPP).


## Proposed solution

In this document, it is proposed to make the transport priority configurable through smartDeviceLink.ini file so that different OEMs can choose different prioritization. Core reads it from the file and forwards it to Proxy during Version Negotiation, so that they both use same prioritization. For this purpose, a new parameter `transportPriority` is added in the payload of Start Service ACK frame of RPC service.

An issue with this approach is that on iOS, Proxy cannot know whether iAP transport is constructed over Bluetooth or USB. This is because iOS system doesn't offer such information to apps. In this document, it is proposed to employ a solution similar to [SDL-0070: Notification of iAP transport type][iap_transport_type]. That is, Core notifies the transport type to Proxy during Version Negotiation.


## Detailed design

### Extension of SDL Protocol

Add following tag in "3.1.3.2.2 Start Service ACK":

Tag Name          | Type             | Description
------------------|------------------|------------
transportType     | string           | (Optional) Notifies current type of transport to Proxy. This is mostly for iOS Proxy, but should also be sent for Android Proxy for consistency. Refer to the list below for the available strings.
transportPriority | Array of strings | (Optional) An array of strings indicating the transports. The first transport in the array has highest priority, and the last one has lowest priority. Refer to the list below for the available transport strings. <br> When sending frames, Proxy should choose the transport of highest priority that is currently available. <br> This value can be omitted if Core does not use/support multiple-transport feature.

Here is the list of transport strings:

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
UNKNOWN                | This indicates that SDL Protocol is running on a transport not listed above. This value is only used for `transportType`.

Note that unlike proposal SDL-0070, `transportType` field contains only one transport. This is because Version Negotiation is expected to happen on each transport in our multiple-transports proposal.

An example of `transportPriority` is shown below. In this case, Wi-Fi transport is most preferred, then USB (iAP or AOA), then Bluetooth.
```json
{
  "0": "TCP_WIFI",
  "1": "IAP_CARPLAY",
  "2": "IAP_USB_HOST_MODE",
  "3": "IAP_USB_DEVICE_MODE",
  "4": "IAP_USB",
  "5": "AOA_USB",
  "6": "IAP_BLUETOOTH",
  "7": "SPP_BLUETOOTH"
}
```

### Extension of iOS Proxy

`SDLProtocol` and related classes are updated to receive additional parameters in Start Service ACK frame of Version Negotiation. The transport type and priority information are notified to newly created `SDLProtocolSelector` class. (Please refer to proposal [SDL-nnnn][multiple_transports].)

### Extension of Android Proxy

`WiProProtocol` and related classes are updated to receive additional parameters in Start Service ACK frame of Version Negotiation. The transport type and priority information are notified to newly created `SdlConnectionSelector` class. (Please refer to proposal [SDL-nnnn][multiple_transports].)

### Extension of Core

`DeviceType` enum in transport\_adapter.h and `devicesType` map in transport\_adapter\_impl.cc are updated to include additional transport type. Subclasses of `TransportAdapterImpl` should implement GetDeviceType() to return current transport type.

`ProtocolHandlerImpl` and related classes are updated to include additional parameters in Start Service ACK frame of Version Negotiation.

`Profile` and `ProtocolHandlerImpl` classes include support to read transport priority information from smartDeviceLink.ini file and include it in Start Service ACK frame of Version Negotiation. Proposed entry and the default value in smartDeviceLink.ini is as follows:

```ini
[ConnectionSelector]  (Newly added section)
; Describes the priority of transports as a comma-separated string.
; First item is most preferred, last item is least preferred.
TransportPriority = TCP_WIFI, IAP_CARPLAY, IAP_USB_HOST_MODE, IAP_USB_DEVICE_MODE, IAP_USB, AOA_USB, IAP_BLUETOOTH, SPP_BLUETOOTH
```


## Potential downsides

- This proposal increases the size of Start Service ACK frame of RPC service.
- Protocol version is bumped.


## Impact on existing code

Impact should not be big since the newly added parameters are both optional. However, since a frame of Version Negotiation is modified, this proposal affects the basic sequence of app registration.


## Alternatives considered

- Use static (pre-configured) priority. This approach is simpler but lacks the flexibility of OEMs choosing their preferred transport priority.
- Proxy chooses a transport without priority information. For example, when Proxy receives a frame from Core on a different transport, it follows Core and switches to that transport.
An advantage of this approach is that we do not need notification of transport priority and thus we do not need to modify Start Service ACK frame. The disadvantage is that after a transport gets unavailable, Proxy cannot choose the next transport until Core sends some frames on a transport. So, switching between transports may not be smooth in some cases.
- Configure transport priority per services, so that we can spawn services to different transports (e.g. Video Service over Wi-Fi and RPC Service over Bluetooth.) Technically this is possible, but implementation will be more complicated. Right now, the author doesn't think such advanced feature is required.


## References

- [SDL-nnnn: Supporting simultaneous multiple transports][multiple_transports] (Parent proposal)


  [multiple_transports]: nnnn-multiple-transports.md  "Supporting simultaneous multiple transports"
  [iap_transport_type]:  https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0070-iap-transport-type-notification.md  "SDL-0070: Notification of iAP transport type"

