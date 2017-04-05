# Add H.264 over RTP format support for video streaming

* Proposal: [SDL-0048](0048-H264-over-RTP-support-for-video-streaming.md)
* Author: Sho Amano
* Status: **In Review**
* Impacted Platforms: [Core / iOS / Android / RPC]

## Introduction

This proposal aims to achieve more robust and smooth video streaming for navigation and projection by adding timestamp information to a video stream.

## Motivation

Currently, only raw H.264 video stream format is allowed for video streaming. Such stream does not have information regarding timing, for example, presentation timestamps (PTS). Because of this nature, current navigation and projection have several issues:

- *Video decoding and rendering on HMI is affected by jitter and may not look smooth.* Jitter is a variation of latency, often caused by network transports and/or inaccurate scheduling of data processing of software. Since the video stream has no timestamps, HMI cannot render video frames in the precise timing that the stream sender (a SDL app) expects, so it may result uneven playback. The issue will become considerable in the future when more apps will run video projection on a wireless transport, such as Wi-Fi or next-gen Bluetooth.

- *HMI may find it difficult to recover from temporal overload.* Consider a case where HMI's media processor gets busy for a short time and H.264 stream data is queued for a few seconds. Due to lack of timestamps, HMI cannot know if the video frame it is processing is "on time" or "too late" for decoding and rendering. In such case it may continue playing the video without catching up to the latest frame. Timestamps in the video stream can let HMI to skip video frames for appropriate time.


## Proposed solution

This proposal includes two changes.

(1) Add H.264 video over RTP format (as defined by RFC 6184) for video streaming

RTP payload format defined by RFC 6184 is a simple packetization of H.264 NAL units, with timestamp included in RTP header. HMI can utilize the timestamp information to achieve smooth video playback and to recover from temporal overload.

RTP packets are framed as defined by RFC 4571. That is, two-byte length field in network byte order is added in front of every RTP packet.

A SDL app should supply proper timing information to SDL proxy along with an image buffer. SDL proxy should use the information to configure timestamp field of RTP header accordingly. If the app does not provide timing information, SDL proxy shall generate such timing information on its own and configure timestamp field of RTP header based on it.

SDL proxy shall correctly set the Marker bit in the RTP header to indicate the very last packet of the access unit indicated by RTP timestamp. Since there is no gateway in SDL core, RTP de-payloader implemented in HMI can rely on this bit to detect the end of an access unit. This can reduce overall latency compared to the case of raw H.264 byte stream.

Payload type (PT) in RTP header shall be chosen from range 96-127 by SDL proxy, and shall be simply ignored by HMI.

For details of RTP packet format, please refer to RFC 6184. (https://www.ietf.org/rfc/rfc6184.txt) For details of the framing method, please refer to RFC 4571. (https://www.ietf.org/rfc/rfc4571.txt)

(2) Add video format negotiation in the protocol

When a video format other than raw H.264 is used, SDL proxy must run *video format negotiation* prior to starting video streaming. Video format negotiation is a pair of `ChangeVideoFormat` request and response, which are sent by SDL proxy and HMI, respectively. SDL proxy specifies the video format it wants to use in `ChangeVideoFormat` request message. The video format is described as a string. Currently, following two strings are defined:
- video/x-h264,stream-format=byte-stream
    * raw H.264 video stream (used by current specification)
- application/x-rtp-stream,media=video,encoding-name=h264
    * H.264 video over RTP format defined by RFC 6184 and framed as defined by RFC 4571, proposed by this document

HMI shall send `ChangeVideoFormat` response with `success` parameter = true if it accepts the specified video format. HMI shall send `ChangeVideoFormat` response with `success` parameter = false if the video format is not currently supported. SDL proxy must not select the video format if it receives such negative response. SDL proxy may initiate another *video format negotiation* prior to starting video streaming to choose another video format.

To keep backward compatibility with current specification, HMI must accept raw H.264 video stream if no video format negotiation took place.


## Detailed design

### Additions to Mobile_API

```xml
  <function name="ChangeVideoFormat" functionID="ChangeVideoFormatID" messagetype="request">
    <description>Request from SDL to HMI to change video format used by video streaming.</description>
    <param name="format" type="String" maxlength="255" minlength="1" mandatory="true">
      <description>
        Specify the video format. Following strings are defined.
        - "video/x-h264,stream-format=byte-stream"
        - "application/x-rtp-stream,media=video,encoding-name=h264"
      </description>
    </param>
  </function>

  <function name="ChangeVideoFormat" functionID="ChangeVideoFormatID" messagetype="response">
    <param name="success" type="Boolean" platform="documentation">
      <description>true if changing video format is successful, otherwise false.</description>
    </param>
  </function>
```

### Additions to HMI_API

Under `BasicCommunication` interface:

```xml
  <function name="ChangeVideoFormat" messagetype="request">
    <description>Request from SDL to HMI to change video format used by video streaming.</description>
    <param name="format" type="String" maxlength="255" minlength="1" mandatory="true">
      <description>
        Specify the video format. Following strings are defined.
        - "video/x-h264,stream-format=byte-stream"
        - "application/x-rtp-stream,media=video,encoding-name=h264"
      </description>
    </param>
    <param name="appID" type="Integer" mandatory="true">
      <description>ID of application related to this RPC.</description>
    </param>
  </function>

  <function name="ChangeVideoFormat" messagetype="response">
  </function>
```

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
- an open standard with many software implementation already available. Hence it should be faily easy to integrate into current implementations.

The video format negotiation can be omitted if current raw H.264 format is completely deprecated by specification. This does not keep backward compatibility with current implementation and thus is not considered to be a good idea.
