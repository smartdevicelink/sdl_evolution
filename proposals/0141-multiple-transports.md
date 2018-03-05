# Supporting simultaneous multiple transports

* Proposal: [SDL-0141](0141-multiple-transports.md)
* Author: [Sho Amano](https://github.com/shoamano83), [Robin Kurian](https://github.com/robinmk)
* Status: **Returned for Revisions**
* Impacted Platforms: [Core / iOS / Android / RPC / Protocol]

## Introduction

This proposal aims to support multiple transports between Core and Proxy.

## Motivation

The initial motivation was to utilize Wi-Fi transport for apps that require high bandwidth, such as video projection apps. After discussions in SDLC workshop, it turned out that using Wi-Fi transport has a few limitations. For example, Wi-Fi transport may be disabled when an iOS app goes background or the iPhone's screen is locked. The app will be then unregistered from Core, so it will significantly decrease user's experience.

This proposal aims to address such limitations by utilizing multiple transports, for example iAP and Wi-Fi, at the same time. The app will start off with establishing iAP connection. Then, it will also open a TCP connection on Wi-Fi transport if it's available. iAP connection will be kept for RPC messaging and TCP connection is used for video/audio streaming. Even if Wi-Fi transport becomes unavailable, the app will not be unregistered as long as iAP connection is sustained.


## Proposed solution

The basic idea is that:
- After Proxy is connected to Core, it initiates another connection over a different transport. (Hereafter, the transport used by the first connection is called `Primary Transport`. The transport used by the additional connection is called `Secondary Transport`.)
- Core tells Proxy which transport can be used as Secondary Transport.
- Core and Proxy run some of the services on Secondary Transport. The services that are allowed on the Secondary Transport are specified by Core. Note that RPC and Hybrid services always run on Primary Transport.
- Core notifies Proxy of the information that is necessary to establish a TCP connection.
- Core's behavior on generating Session ID is changed, so that a unique Session ID is assigned to each app.

Following sections will describe the idea in more detail.

### Starting Secondary Transport

Proxy should set up Secondary Transport as soon as it is notified of available transport types for Secondary Transport and information that is necessary to set up the transport becomes available.

During Version Negotiation, Core includes additional information in Start Service ACK frame to notify Proxy of the available transport types for Secondary Transport. At this point, Proxy can initiate setting up Secondary Transport. Because the additional information is conveyed in Start Service ACK, Secondary Transport is always set up after RPC service is started on Primary Transport.

The available transport type for Secondary Transport can be configured through smartDeviceLink.ini file.

Note that some transports require additional information for configuration (for example, TCP transport requires IP address and TCP port number of Core). In such case, Proxy waits until the necessary information becomes available then initiates Secondary Transport.

After Secondary Transport is established, Proxy sends a Start Service frame for RPC service on it. Note that Proxy and Core don't run RPC service on Secondary Transport. This procedure is just for Core to recognize that Proxy initiates Secondary Transport, because Core cannot know which transport belongs to which app(s) at transport layer's level. The Start Service frame includes Session ID which has been provided by Start Service ACK frame on Primary Transport. (Please refer to the section "How Core determines that a single app initiates multiple transports".) Core receives Start Service frame on Secondary Transport, remembers which Proxy uses which transports, then sends Start Service ACK frame back.

When starting a service over Secondary Transport, Proxy simply runs the sequence of Start Service and Start Service ACK frames. Again, the Start Service frame includes Session ID which has been provided by Start Service ACK frame on Primary Transport.

### Transport disconnection

When Secondary Transport becomes unavailable, Core and Proxy should abort any services that are running on Secondary Transport. Also, if possible Proxy should retry setting up Secondary Transport on a regular interval.

When Primary Transport becomes unavailable, Core and Proxy should stop Secondary Transport.

### Notification of the information required to set up TCP transport

To set up a TCP transport, Proxy needs to know the IP address and TCP port number on which Core is listening. A new Control Frame is proposed to convey the information. It is called `Transport Config Update` frame and is sent by Core to Proxy on Primary Transport. It should not be sent prior to Version Negotiation.

The reason that we do not include the information in Start Service ACK frame is that Wi-Fi feature may not be available at the time of Version Negotiation. For example, consider a case where a head unit can turn off its Wi-Fi feature through user's operation. The user can turn on Wi-Fi after an SDL app is connected to Core, i.e. after the app exchanges Start Service and Start Service ACK frames.

The reason that we use a Control Frame rather than RPC Notification is simply because we would like to keep transport related information in protocol layer. RPC should concentrate on exchanging application-level information.

### Services that are allowed on each transport

During Version Negotiation, Core sends a matrix through Start Service ACK frame describing which service is allowed to run on which transports (Primary, Secondary or both). Proxy honors this information and starts services only on an allowed transport. The matrix can be configured through smartDeviceLink.ini file. Since RPC and Hybrid services always run on Primary Transport, only Video and Audio services are configurable.

Our primary use-case is to run Video and Audio services on Wi-Fi and USB transports, but not on Bluetooth transport which has low bandwidth. A matrix can be set up to support this scenario:
- When Proxy is connected using Bluetooth as Primary Transport, it initiates Video and Audio services only after TCP connection is added as Secondary Transport. If Secondary Transport is disconnected, Proxy stops these services. It will start Video and Audio services again once Secondary Transport is reconnected.
- When Proxy is connected using USB as Primary Transport, it initiates Video and Audio services on Primary Transport.

The transport types included in the matrix are listed in preferred order, for example, Secondary > Primary. In case the priority of Secondary Transport is higher than that of Primary Transport, Proxy will stop and restart services when Secondary Transport is added or removed. For example, when Video service is running on Bluetooth Primary Transport then Wi-Fi transport is added as Secondary Transport, Proxy stops the service and starts another Video service on Wi-Fi transport. When Wi-Fi transport is then disconnected, Proxy stops the service and starts another Video service on Bluetooth Transport. Please note that since we do not have such use-case right now, implementation of this feature will be in low priority.

### How Core determines that a single app initiates multiple transports

One of the issues arising from multiple-transports feature is that SDL Core needs to distinguish between two cases: "a single SDL app connecting to SDL Core using two different transports" and "two instances of a SDL app on two phones connecting to SDL Core using different transports". For this purpose, this document proposes to update the specification of how Core assigns Session IDs.

Currently Session ID is managed per transport, so it is possible that two apps receive same Session ID if they are connected through different transports. This behavior will be updated so that Core will assign different Session IDs to each app (i.e. Core will make sure to assign different Session IDs in each Version Negotiation procedure).

When Proxy sends a Start Service frame on Secondary Transport, it always includes the Session ID provided by Start Service ACK frame on Primary Transport. This means that Start Service frame will include a non-zero value for Session ID on Secondary Transport. Core uses the Session ID value to recognize which transports are used by a single Proxy. Core's implementation will be updated to accept Start Service frame with a known Session ID even if the frame is received through Secondary Transport.

The downside of this proposal is that maximum number of SDL apps that can connect to Core will be limited to 255.

### Backward compatibility

Since we are adding a new Control Frame, the Protocol Version should be bumped, probably to 5.1.0. Core recognizes that Proxy supports multiple-transports feature by checking the version number.

**New Proxy connecting to old version of Core:** SDL Core that does not support multiple-transports feature does not include additional parameters in Start Service ACK frame. When Proxy detects that the parameters are missing, it should disable multiple-transport feature (i.e. don't start Secondary Transport and run all services on Primary Transport.)

**Old version of Proxy connecting to new Core:** Proxy that does not support multiple-transports feature uses Protocol version 5.0.0 or earlier. When SDL Core detects that the version is not 5.1.0 or higher, it should not include the additional parameters in Start Service ACK frame. It should also suppress sending `Transport Config Update` Control Frame since Proxy doesn't support it.


## Detailed design

### Extension of SDL Protocol

A new Control Frame `Transport Config Update` is added:

Frame Info Value | Name                    | Description
-----------------|-------------------------|------------
0xFD             | Transport Config Update | This frame is sent from Core to Proxy to indicate that configuration(s) of transport(s) is/are updated.<br>This frame should not be sent prior to Version Negotiation.

The new frame includes following parameter:

Tag Name           | Type     | Description
-------------------|----------|------------
tcpTransportConfig | document | (Optional) Specify information necessary to set up TCP transport. The document may include following optional key-value pairs:<br><br>"ipAddress": value is a string representation of IP address that SDL Core is listening on. It can be IPv4 address (example: "192.168.1.1") or IPv6 address (example: "fd12:3456:789a::1").<br>"tcpPort": value is a 32-bit integer representing the TCP port number that SDL Core is listening on. This value should be same as `TCPAdapterPort` in smartDeviceLink.ini file. Example: 12345<br><br>If "ipAddress" is not included, or it is empty, then it indicates that the TCP transport becomes unavailable.

Here is an example of a parameter included in Transport Config Update frame:

```json
{
  "tcpTransportConfig": {
    "ipAddress": "192.168.1.1",
    "tcpPort": 12345
  }
}
```

The definition of Start Service frame is updated to allow including a non-zero value for Session Id field. When Proxy sends a Start Service frame on Secondary Transport, it must include the Session ID provided by Core through Start Service ACK frame on Primary Transport in the Session Id field. (Note that looking at Core's current implementation, Core accepts a Start Service frame with non-zero Session ID to update existing service from unprotected to protected. It may not be documented through.)

Start Service ACK frame of RPC service includes following parameters:

Tag Name           | Type             | Description
-------------------|------------------|------------
secondaryTransport | string           | (Optional) Transport type which Core allows to use for Secondary Transport. Refer to Table 1 for possible values.<br>This parameter is included in the Start Service frame for Version Negotiation. It should not be included in the Start Service frame on Secondary Transport.<br>If Core does not allow setting up the Secondary Transport, it can omit this parameter.
servicesMap        | document         | (Optional) A map indicating which service is allowed on which transport(s).<br>The keys of this map are string representations of service number in hex, i.e. "0x00" through "0xFF". The values are arrays of int32, whose possible values are either 1 (meaning "Primary Transport") or 2 (meaning "Secondary Transport"). The transports are listed in preferred order. Proxy must not start the service on a transport that is not listed in the values.<br>Values for "0x00" (Control Service), "0x07" (Remote Procedure Call Service) and "0x0F" (Hybrid Service) will be ignored by Proxy since they are set up on specific transports.<br>This parameter should not be included in the Start Service frame on Secondary Transport.

**Table 1: list of transport type strings**

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


Here is an example of parameters in Start Service ACK frame:

```json
{
  "secondaryTransport": "TCP_WIFI",
  "servicesMap": {
    "0x0A": [2],
    "0x0B": [2]
  }
}
```
This indicates:
- that Core supports multiple-transports feature and allows Wi-Fi (TCP) transport to be used as a Secondary Transport, and
- that Core allows video and audio services to run on Secondary Transport but does NOT allow to run them on Primary Transport.

Note: Start Service, Start Service ACK, Start Service NAK, End Service, End Service ACK, and End Service NAK are sent on both Primary and Secondary Transports. Other Control Frames are always transferred on Primary Transport. (Currently, only `Transport Config Update` frame is applied.)


### Extension of iOS Proxy

iOS Proxy implementation should include:
- logic to set up and tear down Secondary Transport,
- logic to start and stop services based on the matrix provided by Core,
- support to use two instances of transports, and logic to choose appropriate one when sending frames,
- support new Control Frame `Transport Config Update` to retrieve IP address and TCP port number,
- logic to stop and start services when Secondary Transport with higher priority becomes available or unavailable (in low priority), and
- logic to stop TCP transport when the app goes to background, and restart it when it comes back to foreground.

Public API of `SDLManager` is unchanged. The multiple-transports feature will be automatically enabled unless the app uses `SDLLifecycleConfiguration` created by `[SDLLifecycleConfiguration debugConfigurationWithAppName]`.


### Extension of Android Proxy

Android Proxy implementation should include:
- logic to set up and tear down Secondary Transport,
- logic to start and stop services based on the matrix provided by Core,
- support to use two instances of transports, and logic to choose appropriate one when sending frames,
- support new Control Frame `Transport Config Update` to retrieve IP address and TCP port number, and
- logic to stop and start services when Secondary Transport with higher priority becomes available or unavailable (in low priority)

Public API of `SdlProxyALM` is unchanged. App developers choose one of the constructors in `SdlProxyALM` to start Proxy as they do today. Secondary Transport will be automatically enabled and used inside Proxy.


### Extension of Core

* Detecting connection of Secondary Transport<br>
When Core receives a Start Service frame for RPC service with non-zero Session ID, and the ID is not known on that connection, then Core recognizes that Proxy initiates Secondary Transport. The implementation of `ConnectionHandlerImpl` and `Connection` classes will be updated. `ConnectionHandlerImpl` class will also notify `ApplicationManagerImpl` class of the event through `OnServiceStartedCallback`.<br>
`Application` and `ApplicationImpl` classes are updated to keep `DeviceHandle` for Secondary Transport.
* Handling messages from Secondary Transport as if they were received through Primary Transport<br>
To minimize impacts on existing implementation, Core should treat incoming messages received through Secondary Transport as if they came from Primary Transport.<br>
An idea is to overwrite `connection_key` value of the messages. The value is included in `application_manager::Message` and `protocol_handler::RawMessage` classes, and is used to distinguish between connections. Core remembers the value of `connection_key` of the frames that come from Primary Transport. When Core receives a frame through Secondary Transport, it replaces the value of `connection_key` with that of frames coming through Primary Transport.<br>
Core uses the value of Session ID included in Start Service frame to find out which services are initiated by a single app.
* Updating the logic to assign Session IDs<br>
Implementation is updated so that SDL Core will not manage Session IDs per transport, but it will assign different Session ID to each app.
* Including additional parameters in Start Service ACK frame
Core should include `secondaryTransport` and `servicesMap` parameters in Start Service ACK frame. The value of `secondaryTransport` is acquired from smartDeviceLink.ini file. The value of `servicesMap` is calculated based on input from smartDeviceLink.ini file and transport type of Primary Transport.
* Sending out `Transport Config Update` Control Frame<br>
When the state of a network interface changes, Core should send out `Transport Config Update` frame to Proxy. `TcpClientListener` and related classes are likely to be updated to support this feature.
* Notifying HMI of Secondary Transport being added or removed<br>
Application Manager should be updated to trigger sending `BasicCommunication.UpdateAppList` request when Secondary Transport of an app is added or removed.
* Making the feature configurable through smartDeviceLink.ini file<br>
This document proposes to append following sections in smartDeviceLink.ini file:

```ini
[MultipleTransports]
; Whether multiple-transports feature is enabled
Enabled = true

; Comma-separated list of transports that can be used as Secondary Transport for each Primary Transport.
; Possible values are: WiFi, USB and Bluetooth.
; Core will not suggest Secondary Transport if the value is empty.
SecondaryTransportForBluetooth = WiFi
SecondaryTransportForUSB =
SecondaryTransportForWiFi =

[ServicesMap]
; A matrix to specify which service is allowed on which transports. The transports are listed
; in preferred order. If a transport is not listed, then the service is not allowed
; to run on the transport.
; Only video and audio services are configurable.
; If the entry of a service is completely omitted, the service will be allowed on all transports.
; Possible values are: IAP_BLUETOOTH, IAP_USB, IAP_USB_HOST_MODE, IAP_USB_DEVICE_MODE, IAP_CARPLAY, SPP_BLUETOOTH, AOA_USB and TCP_WIFI.
; Note: this configuration is applied even if multiple-transports feature is not enabled.
; Audio service
0x0A = TCP_WIFI, IAP_CARPLAY, IAP_USB_HOST_MODE, IAP_USB_DEVICE_MODE, IAP_USB, AOA_USB
; Video service
0x0B = TCP_WIFI, IAP_CARPLAY, IAP_USB_HOST_MODE, IAP_USB_DEVICE_MODE, IAP_USB, AOA_USB
```


### Modification of HMI\_API.xml

HMI should be notified that an app is connected over multiple transports. Add an optional param `secondaryDeviceInfo` into `HMIApplication`. The change of `HMIApplication` struct is notified through `BasicCommunication.UpdateAppList` request.

```diff
<struct name="HMIApplication">
     <description>Data type containing information about application needed by HMI.</description>
 
     :
 
    <param name="deviceInfo" type="Common.DeviceInfo" mandatory="true">
        <description>The ID, serial number, transport type the named-app's-device is connected over to HU.</description>
     </param>
+    <param name="secondaryDeviceInfo" type="Common.DeviceInfo" mandatory="false">
+       <description>The ID, serial number, transport type that are acquired through Secondary Transport.</description>
+    </param>
```


## Potential downsides

- This feature introduces additional logic in both Core and Proxy and will increase their complexity.
- When a single device is connected to SDL Core through multiple transports, different values of `DeviceUID` will be assigned per transport. Also, HMI receives multiple `DeviceInfo` information through `BasicCommunication.UpdateDeviceList` request, although there is actually one device. These behaviors may confuse HMI developers.<br>
Note: these behaviors are already seen on current SDL Core when an app on a phone is connected through a transport and another app on the same phone is connected through a different transport.
- Transferring a service between Primary and Secondary Transports may not be smooth as it involves terminating the service on a transport then restarting it on another transport.
- When SDL Core supports multiple-transports feature, Proxy will always open Secondary Transport even if no service will run on it.
- This proposal enables communication over Bluetooth and Wi-Fi transports at the same time. It may introduce wireless interference when Wi-Fi is running in 2.4GHz band. Note that the degree of interference depends on hardware, so we cannot tell if it is a significant issue.
- Because of the updated specification of Session ID, maximum number of SDL apps that can connect to Core will be limited to 255.
- Core may not return a Start Service NAK frame when a malformed Proxy sends a Start Service frame on a transport with Session ID != 0.
- Protocol version is bumped.


## Impact on existing code

* Most of the code changes are limited to protocol layer and below.
* This proposal does not break compatibility, so basic sequence should be kept intact.


## Out of scope of this proposal

- The authors have a use-case to prevent a video-streaming app from automatically launching on HMI if it is not connected with a high-bandwidth transport (i.e. Wi-Fi or USB). To realize this use-case, the resumption logic in SDL Core has to be modified. This feature will be addressed in another proposal [SDL-nnnn: Add capability to disable or reject an app based on app type, transport type and OS type][reg_limitation].
- In some cases, SDL Core should not accept TCP connections on all network interfaces. For example, a head unit is equipped with a Wi-Fi network device and a communication module for cellular network, in which case the system will have two network interfaces. An OEM may want to accept SDL connection only through Wi-Fi's network interface and not through Internet connection. If we need to support such scenario, another proposal should be entered.


## Alternatives considered

* Introduce a mechanism to transfer all services between the transports, including RPC service. This was the approach of the original proposal. After some discussions, it turned out that it will introduce much more impacts on implementations.
* Keep current "single transport" design and introduce transport switching. This approach will not resolve the limitation raised during SDLC workshop to utilize Wi-Fi transport, since iAP transport will be turned off.
* Extend RegisterAppInterface request and response instead of Version Negotiation to convey additional parameters. The merit of this approach is that Core will have a flexibility to return different values based on app's identification. However, this approach has more impacts on implementations since Application Manager layers of SDL Core and Proxies need to be updated.
* Use a service discovery mechanism to convey IP address and TCP port number of SDL Core to Proxy. Right now, this is not needed as Wi-Fi transport is always used as Secondary Transport. It will be required if we want to utilize Wi-Fi transport as Primary Transport in future.
* Instead of using Session ID as app identifier, introduce a new ID such as "App Instance ID" which is generated by Proxy and sent to Core during Version Negotiation. This approach should also work. The only downside is that we need to create a specification for the ID and Proxy may have additional complexity.
* Support Hybrid service running on Secondary Transport. For this use-case, we will need a mechanism to seamlessly transfer the service between Primary and Secondary Transports. (Note that since Hybrid service is an extension of RPC service, it will be always started on Primary Transport.)
* Extend the value of `secondaryTransport` parameter to accept multiple candidates of Secondary Transport. This will end up with Android Proxy running all three kinds of transports (Wi-Fi, Bluetooth and AOA) waiting for connections at the same time, and will introduces much complexity. If we need such advanced feature, perhaps another proposal can be entered in future, with a simplified implementation that Android Proxy will switch to another Secondary Transport only when current Secondary Transport is disconnected.
* Introduce existing protocol like MPTCP (Multi-path TCP) or SCTP (Stream Control Transport Protocol). This will introduce a large amount of code (either implemented by SDLC members or using existing open-source library) and increases complexity.


## References

- [SDL-nnnn: Add capability to disable or reject an app based on app type, transport type and OS type][reg_limitation]


  [reg_limitation]:     https://github.com/XevoInc/sdl_evolution/blob/4242b3ec23c9102cd595e9c7d37f664e785dfdba/proposals/nnnn-mt-registration-limitation.md  "Add capability to disable or reject an app based on app type, transport type and OS type"
