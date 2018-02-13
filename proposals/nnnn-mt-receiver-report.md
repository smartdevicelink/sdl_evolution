# Addition of 'Receiver Report' control frame

* Proposal: [SDL-nnnn](nnnn-mt-receiver-report.md)
* Author: [Sho Amano](https://github.com/shoamano83)
* Status: **Awaiting review**
* Impacted Platforms: [Core / iOS / Android / Protocol]

## Introduction

This document proposes to add a Control Frame called Receiver Report. This is a sub-proposal of [SDL-nnnn: Supporting simultaneous multiple transports][multiple_transports].


## Motivation

The key feature of "simultaneous multiple transports" proposal is to switch between transports when one of them gets unavailable. During discussion of the feature, we identified two challenges:
1. Some transports lack a feature of detecting disconnection immediately. For example, TCP transport is considered as "disconnected" only after detecting a timeout error. This will prevent us from switching the transports seamlessly.
2. When a transport becomes unavailable, some data which are being transmitted may not be delivered to peer. For example, data that will be sent through TCP socket are usually kept in the socket buffer for a while. If the connection is lost, the buffered data will be discarded.

The author of this proposal tried to cope with these challenges with existing SDL protocol and did not come up with a solution. This is the background that a new Control Frame is proposed.


## Proposed solution

The Control Frame is named `Receiver Report` (and better naming is welcome.) After RPC service is established, the frame is periodically sent on the transport by both Core and Proxy. The frame includes the Message IDs of the latest frames per service that has been received.

When multiple transports are utilized between Proxy and Core, Receiver Report frames are sent on each transport.

This frame is used for two purposes:
1. When `Receiver Report` frame has not been received for a given period of time, the receiver of the frame considers the transport as unavailable.
2. Both Core and Proxy buffers send frames until they receive a specific `Receiver Report` frame; sent frames whose Message IDs are less than or equal to the Message ID included in `Receiver Report` frame are safely removed from the buffers. This procedure is performed per service, i.e. both Core and Proxy have individual buffers for RPC, Video and Audio services. When switching between transports, Core and Proxy resend all buffered frames on the new transport to avoid data loss.

To avoid exhaustion of RAM, the buffers should have capacity limits. When the buffer gets full, the owner of the buffer should deny queuing new frames. Note that buffers are allocated individually for each service. So if the buffer for Video service gets full for example, queuing RPC messages will not be affected.

Core and Proxy should also check Message IDs of received frames and discard duplicate frames.

It is a good idea to make the interval of `Receiver Report` frames configurable. In this document, it is proposed to add an entry in smartDeviceLink.ini file. The value of interval will be transferred from Core to Proxy during Version Negotiation.

Some transports have a feature to detect disconnection immediately. So it sounds like a good idea to apply the "detection of disconnection using Receiver Report" feature to TCP transport only.


## Detailed design

### Extension of SDL Protocol

Add following Control Frame in "3.1.2 Frame Info Definitions":

Frame Info Value | Name            | Description
-----------------|-----------------|------------
0xFD             | Receiver Report | Notifies up to which frames are successfully received

Payload of Receiver Report frame is as follows:

Tag Name       | Type     | Description
---------------|----------|------------
lastMessageIds | document | MessageIDs of the latest frames per service that has been received by the sender of Receiver Report frame. <br> The document includes pairs of Service Type and Message ID of the latest frame on the service. Service Type is expressed as a string of decimal number. Message ID is in int32. (Note: although the field is int32, it should be interpreted as 4-byte unsigned integer.) <br><br> **Example:** <br> lastMessageIds: { '7': 123, '10': 140, '11': 170}

Description of Receiver Report frame is as follows:

```
"After a successful Version Negotiation, both Core and Proxy start sending Receiver Report frame periodically on the transport. The frame includes `MessageID`s of latest frames on each service that has been received by the receiver. Receiver Report frames are sent using the Control Service Type (0x00).
Sender should buffer frames that have been sent until it receives a Receiver Report frame and confirms that the frames are received successfully.
If Receiver Report frame is not received for a given number of times, receiver may consider the transport as unavailable. In this case the receiver may use another transport to re-send buffered frames. Right now, only TCP transport uses this feature to detect transport's unavailability."
```

Also, add following tag in "3.1.3.2.2 Start Service ACK":

Tag Name               | Type  | Description
-----------------------|-------|------------
receiverReportInterval | int32 | Interval of Receiver Report frames, in msec. This must be a positive number.


### Extension of iOS Proxy

`SDLProtocol` and `SDLProtocolListener` classes are extended to support `Receiver Report` frame handling. When they detect timeout for Receiver Report frame, they notify it to upper layer, which is `SDLProtocolSelector`. (Please refer to proposal [SDL-nnnn][multiple_transports] for this newly added class.)

### Extension of Android Proxy

`WiProProtocol` class and `IProtocolListener` interface are extended to support `Receiver Report` frame handling. When they detect timeout for Receiver Report frame, they notify it to upper layer, which is `SdlConnectionSelector` class. (Please refer to proposal [SDL-nnnn][multiple_transports] for this newly added class.)

### Extension of Core

ProtocolHandler class implements receiving and sending `Receiver Report` frame. It periodically sends `Receiver Report` frames on all connections. When it receives a `Receiver Report` frame, it notifies ConnectionSelector that sent frame(s) is/are successfully received by peer. When it detects a timeout on a particular connection, it notifies ConnectionSelector that the connection becomes unavailable.

Profile and ProtocolHandlerImpl classes include support to read receiver report interval value from smartDeviceLink.ini file and include it in Start Service ACK frame of RPC service. Proposed entry of smartDeviceLink.ini is as follows:

```ini
[MAIN]
  :
  :
; Heart beat timeout used for protocol v3.
; Timeout must be specified in milliseconds. If timeout is 0 heart beat will be disabled.
HeartBeatTimeout = 7000
; Interval of Receiver Report Control Frame in msec.
ReceiverReportInterval = 500
```

Currently Core generates sequence of Message IDs per session (refer to protocol\_handler\_impl.cc). This should be modified so that the sequence is per service of each application.


## Potential downsides

- Core and Proxy buffers send data until Receiver Report frame is received, thereby increasing RAM usage. As described, we should put a limit on the buffer to avoid RAM exhaustion.
Actually, RAM consumption is not a new issue; Core and Proxy already have buffers for sending frames(*1), so when network bandwidth is small, more and more frames may be queued in the buffers and RAM usage may grow.
- If network bandwidth is small and Core/Proxy tries to send a lot of data on it, frames will be delivered with a large delay. In this case, Receiver Report frames may not be delivered on time and Core/Proxy may treat that the transport becomes unavailable.<br>
The fundamental solution is to introduce a mechanism like flow control. However, in this document it is proposed to utilize "detection of disconnection using Receiver Report" feature only for TCP transport, and not to use it on low-bandwidth transports (like Bluetooth) to avoid such regression.
- The Receiver Report frames will increase traffic on the network if the interval is too short. (The author thinks that the frames should be sent only a few times in a second.)
- Protocol version should be bumped up.

(*1) For example, iOS Proxy has prioritizedCollection in SDLProtocol and sendDataQueue in SDLIAPSession. SDL Core has message\_queue\_ in TransportManagerImpl and frames\_to\_send_ in ThreadedSocketConnection class.


## Impact on existing code

Most of the code changes are limited to transport and protocol handler layers, notably:
- Additional implementation in protocol handlers to support Receiver Report frame, and
- Modification to protocol handlers to support new parameters in Version Negotiation.


## Alternatives considered

- Utilize deprecated HeartBeat Control Frame. The author heard that the reason of HeartBeat being deprecated was because iOS apps could not send the frame in regular interval when they are in background. So it may not be a good idea to re-enable it. Also, HeartBeat is in request-response style, which is redundant for the proposed feature.
- Utilize deprecated Service Data ACK frame. Looking at the implementation in Core, the frame is generated every time Core receives a frame. This seems too frequent and may affect performance. Also, we still need heart-beat like frame as well.
- Update SDL Protocol to make it tolerant of data loss.<br>
The author did not come up with a solution. Current SDL Protocol assumes that underlying transport is stream-based, i.e. frame boundary is not preserved. If some data is lost, it is very difficult to find the beginning of next frame without adding some marker or "start code". Adding such marker would break backward compatibility and might require whole rewrite of SDL Protocol.
- Introduce existing protocol like MPTCP (Multi-path TCP) or SCTP (Stream Control Transport Protocol). This will introduce a large amount of code (either implemented by SDLC members or using existing open-source library) and increases complexity. Since we only need retransmission mechanism, this approach seems to be "too much".


## References

- [SDL-nnnn: Supporting simultaneous multiple transports][multiple_transports] (Parent proposal)


  [multiple_transports]: nnnn-multiple-transports.md  "Supporting simultaneous multiple transports"

