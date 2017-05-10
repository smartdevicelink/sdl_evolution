# Add H.264 over RTP format support for video streaming

* Proposal: [SDL-0048](0048-H264-over-RTP-support-for-video-streaming.md)
* Author: [Sho Amano](https://github.com/shoamano83)
* Status: **In Review**
* Impacted Platforms: [Core / iOS / Android / RPC / Protocol]

## Introduction

This proposal aims to achieve more robust and smooth video streaming for navigation and projection by adding timestamp information to a video stream.

## Motivation

Currently, only raw H.264 video stream format is allowed for video streaming. Such stream does not have information regarding timing, for example, presentation timestamps (PTS). Because of this nature, current navigation and projection have several issues:

- *Video decoding and rendering on HMI is affected by jitter and may not look smooth.* Jitter is a variation of latency, often caused by network transports and/or inaccurate scheduling of data processing of software. Since the video stream has no timestamps, HMI cannot render video frames in the precise timing that the stream sender (a SDL app) expects, so it may result uneven playback. The issue will become considerable in the future when more apps will run video projection on a wireless transport, such as Wi-Fi or next-gen Bluetooth.

- *HMI may find it difficult to recover from temporal overload.* Consider a case where HMI's media processor gets busy for a short time and H.264 stream data is queued for a few seconds. Due to lack of timestamps, HMI cannot know if the video frame it is processing is "on time" or "too late" for decoding and rendering. In such case it may continue playing the video without catching up to the latest frame. Timestamps in the video stream can let HMI to skip video frames for appropriate time.


## Proposed solution

This proposal includes three changes.

(1) Add H.264 video over RTP format (as defined by RFC 6184) for video streaming

RTP payload format defined by RFC 6184 is a simple packetization of H.264 NAL units, with timestamp included in RTP header. HMI can utilize the timestamp information to achieve smooth video playback and to recover from temporal overload.

RTP packets are framed as defined by RFC 4571. That is, two-byte length field in network byte order is added in front of every RTP packet.

A SDL app should supply proper timing information to SDL proxy along with an image buffer. SDL proxy should use the information to configure timestamp field of RTP header accordingly. If the app does not provide timing information, SDL proxy shall generate such timing information on its own and configure timestamp field of RTP header based on it.

SDL proxy shall correctly set the Marker bit in the RTP header to indicate the very last packet of the access unit indicated by RTP timestamp. Since there is no gateway in SDL core, RTP de-payloader implemented in HMI can rely on this bit to detect the end of an access unit. This can reduce overall latency compared to the case of raw H.264 byte stream.

Payload type (PT) in RTP header shall be chosen from range 96-127 by SDL proxy, and shall be simply ignored by HMI.

For details of RTP packet format, please refer to RFC 6184. For details of the framing method, please refer to RFC 4571.

(2) Add supported video formats in HMI's System Capabilities

HMI shall notify video formats it supports based on proposal #0055 "System Capabilities Query" scheme. HMI shall include `videoFormats` parameter in `VideoStreamingCapability` struct to show its supported and preferred video formats.

A video format is represented as a string. Currently, following two strings are defined:

- video/x-h264,stream-format=byte-stream
    * raw H.264 video stream (used by current specification)
- application/x-rtp-stream,media=video,encoding-name=h264
    * H.264 video over RTP format defined by RFC 6184 and framed as defined by RFC 4571, proposed by this document

HMI shall list the formats in its preferred order, i.e. the first video format in the list is HMI's most preferred format. SDL proxy may use this preference information to choose a format when starting a video streaming.

Existing HMI implementations that do not support this proposal will not include `videoFormats` parameter in `VideoStreamingCapability` struct. In such case, SDL core and proxy shall assume that HMI still supports raw H.264 video stream.

(3) Add video format negotiation in the protocol

When a video format other than raw H.264 is used, SDL proxy must run *video format negotiation* prior to starting video streaming. This is achieved by specifying a video format when SDL proxy sends a `Start Service` Control Frame. As SDL core receives the Control Frame, it emits a `SetVideoConfig` request to HMI. HMI shall immediately reply whether the format is currently available. Based on the result, SDL core shall send either `Start Service ACK` or `Start Service NACK` to SDL proxy, notifying that it can or cannot start video streaming with the format.

The video format is added to `Start Service` Control Frame based on proposal #0052 "Constructed Payloads". The formats are represented as a string and are same as those listed in previous section.

After SDL proxy receives a `Start Service NACK` Control Frame from SDL core, it may initiate another `Start Service` Control Frame to choose different video format.

`SetVideoConfig` request shall be sent to HMI prior to `StartStream` request. SDL core shall send it every time before each `StartStream` request as long as video format information is included in `Start Service` Control Frame. When HMI receives a `StartStream` request without `SetVideoConfig`, it shall treat the format as raw H.264 video stream. This is to keep backward compatibility with existing SDL proxy implementations.

If HMI does not support this proposal (i.e. `videoFormats` parameter is not included in `VideoStreamingCapability` struct), SDL core should not send `SetVideoConfig` request to HMI. Also, SDL core should immediately reply with `Start Service NACK` if it receives a `Start Service` Control Frame from SDL proxy with a video format other than "video/x-h264,stream-format=byte-stream".

## Detailed design

### Additions to Protocol specification

Append following document in the payload of `Start Service` Control Frame with Service Type = 0x0B (Video Service). Note that the document is expressed using BSON in a Control Frame.

```
{videoFormat:format-string}
```
Where *format-string* is one of below:
- video/x-h264,stream-format=byte-stream
- application/x-rtp-stream,media=video,encoding-name=h264

### Additions to Mobile_API

Include `videoFormats` parameter in `VideoStreamingCapability` struct. (If the struct does not exist then it should be newly added.)


```xml
  <struct name="VideoStreamingCapability">
    <description>Contains information about HMI's video streaming capabilities.</description>

      :
      :

    <param name="videoFormats" type="String" minlength="1" maxlength="255" minsize="1" maxsize="100" array="true" mandatory="false">
      <description>
        List of video formats that HMI supports, in its preferred order. Following strings are defined.
        - "video/x-h264,stream-format=byte-stream"
        - "application/x-rtp-stream,media=video,encoding-name=h264"
      </description>
    </param>
  </struct>
```

### Additions to HMI_API

Include `videoFormats` parameter in `Common.VideoStreamingCapability` struct. (If the struct does not exist then it should be newly added.)

```xml
  <struct name="VideoStreamingCapability">
    <description>Contains information about HMI's video streaming capabilities.</description>

      :
      :

    <param name="videoFormats" type="String" minlength="1" maxlength="255" minsize="1" maxsize="100" array="true" mandatory="false">
      <description>
        List of video formats that HMI supports, in its preferred order. Following strings are defined.
        - "video/x-h264,stream-format=byte-stream"
        - "application/x-rtp-stream,media=video,encoding-name=h264"
      </description>
    </param>
  </struct>
```

Also, add `Common.VideoConfig` struct:

```xml
  <struct name="VideoConfig">
    <description>Configuration of a video stream.</description>
    <param name="format" type="String" minlength="1" maxlength="255" mandatory="false">
      <description>
        The format of a video stream. Following strings are defined.
        - "video/x-h264,stream-format=byte-stream"
        - "application/x-rtp-stream,media=video,encoding-name=h264"
        If this param is omitted, HMI should assume the default value is "video/x-h264,stream-format=byte-stream".
      </description>
    </param>
  </struct>
```

Under `Navigation` interface, add `SetVideoConfig` request/response pair:

```xml
  <function name="SetVideoConfig" messagetype="request">
    <description>Request from SDL to HMI to ask whether HMI accepts a video stream with given configuration.</description>
    <param name="config" type="Common.VideoConfig" mandatory="true">
      <description>Configuration of a video stream.</description>
    </param>
    <param name="appID" type="Integer" mandatory="true">
      <description>ID of application related to this RPC.</description>
    </param>
  </function>

  <function name="SetVideoConfig" messagetype="response">
  </function>
```

### Additional implementations

SDL proxy, core and HMI need to be updated to support additional payload in the Control Frame as well as additional RPC.

SDL proxy and HMI need additional implementations to support new video format as well as video format negotiation sequence.

SDL proxy should also support receiving timestamp information from SDL app. For example, iOS SDL proxy can have additional public method in SDLStreamingMediaManager:
```
- (BOOL)sendVideoData:(CVImageBufferRef)imageBuffer pts:(CMTime)pts;
```

## Potential downsides

The new video format introduces an overhead of RTP header and length field, which is typically 14 bytes in total. It is small enough compare to the size of video payload, so it should not cause performance degradation unless the video projection is running in an extremely low bitrate.

## Impact on existing code

This feature should not have impacts on existing code other than introducing additional implementations to SDL proxy, SDL core and HMI. To get benefits of this feature, SDL apps should consider providing timestamp along with the video image buffers. Also, HMI should consider utilizing timestamp information delivered by RTP header.

## Alternatives considered

Another multimedia container format can be used, or a new SDL-proprietary container format can be invented instead. Nevertheless, RTP is chosen in this proposal because it is:
- much simpler compared to other container formats (such as MPEG transport stream).
- an open standard with many software implementation already available. Hence it should be fairly easy to integrate into current implementations.

The video format negotiation can be omitted if current raw H.264 format is completely deprecated by specification. This does not keep backward compatibility with current implementation and thus is not considered to be a good idea.

Instead of adding a new RPC `SetVideoConfig`, `StartStream` request can be extended to include video format information. The issue with this idea is that `StartStream` response can be delayed when, for example, HMI shows a dialog to ask the user before starting a video stream. (This is the case of sdl_hmi implementation.) Since `Start Service ACK/NACK` has to be sent before `StartStream` response, a new RPC is proposed in this document.

## References

- [RFC 6184: RTP Payload Format for H.264 Video](https://www.ietf.org/rfc/rfc6184.txt)
- [RFC 4571: Framing Real-time Transport Protocol (RTP) and RTP Control Protocol (RTCP) Packets over Connection-Oriented Transport](https://www.ietf.org/rfc/rfc4571.txt)
- [Proposal #0055: System Capabilities Query](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0055-system_capabilities_query.md)
- [Proposal #0052: Constructed Payloads](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0052-constructed-payloads.md)
