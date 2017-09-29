# Add H.264 over RTP format support for video streaming

* Proposal: [SDL-0048](0048-H264-over-RTP-support-for-video-streaming.md)
* Author: [Sho Amano](https://github.com/shoamano83)
* Status: **Accepted with Revisions**
* Impacted Platforms: [iOS / Android]

## Introduction

This proposal aims to achieve more robust and smooth video streaming for navigation and projection by adding timestamp information to a video stream.

## Motivation

Currently, only raw H.264 video stream format is allowed for video streaming. Such stream does not have information regarding timing, for example, presentation timestamps (PTS). Because of this nature, current navigation and projection have several issues:

- *Video decoding and rendering on HMI is affected by jitter and may not look smooth.* Jitter is a variation of latency, often caused by network transports and/or inaccurate scheduling of data processing of software. Since the video stream has no timestamps, HMI cannot render video frames in the precise timing that the stream sender (a SDL app) expects, so it may result uneven playback. The issue will become considerable in the future when more apps will run video projection on a wireless transport, such as Wi-Fi or next-gen Bluetooth.

- *HMI may find it difficult to recover from temporal overload.* Consider a case where HMI's media processor gets busy for a short time and H.264 stream data is queued for a few seconds. Due to lack of timestamps, HMI cannot know if the video frame it is processing is "on time" or "too late" for decoding and rendering. In such case it may continue playing the video without catching up to the latest frame. Timestamps in the video stream can let HMI to skip video frames for appropriate time.


## Proposed solution

### Add H.264 video over RTP format (as defined by RFC 6184) for video streaming

RTP payload format defined by RFC 6184 is a simple packetization of H.264 NAL units, with timestamp included in RTP header. HMI can utilize the timestamp information to achieve smooth video playback and to recover from temporal overload.

RTP packets are framed as defined by RFC 4571. That is, two-byte length field in network byte order is added in front of every RTP packet.

A SDL app should supply proper timing information to SDL proxy along with an image buffer. SDL proxy should use the information to configure timestamp field of RTP header accordingly. If the app does not provide timing information, SDL proxy shall generate such timing information on its own and configure timestamp field of RTP header based on it.

SDL proxy shall correctly set the Marker bit in the RTP header to indicate the very last packet of the access unit indicated by RTP timestamp. Since there is no gateway in SDL core, RTP de-payloader implemented in HMI can rely on this bit to detect the end of an access unit. This can reduce overall latency compared to the case of raw H.264 byte stream.

Payload type (PT) in RTP header shall be chosen from range 96-127 by SDL proxy, and shall be simply ignored by HMI.

For details of RTP packet format, please refer to RFC 6184. For details of the framing method, please refer to RFC 4571.

### Video streaming capabilities and video format negotiation

To enable RTP format, HMI needs to advertise that it supports the format. Also, SDL proxy needs to notify HMI which video format it is going use.

These are achieved by extending System Capabilities and adding "video format negotiation" procedure. They are covered by another proposal [SDL-0058](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0058-video-streaming-capabilities.md). Here is the brief summary:

- HMI shall include its supported video formats in `VideoStreamingCapability` struct. SDL proxy acquires this struct after `RegisterAppInterface` response.
- SDL proxy shall include the video format it is going to use in `Start Service` Control Frame, along with other video configuration parameters. Once it receives `Start Service ACK` Control Frame, it starts video streaming with the format.

Please refer to proposal SDL-0058 for details.

## Detailed design

### Additional implementations

SDL proxy and HMI need additional implementations to support new video format.

SDL proxy should also support receiving timestamp information from SDL app. For example, iOS SDL proxy can have additional public method in SDLStreamingMediaManager:
```
- (BOOL)sendVideoData:(CVImageBufferRef)imageBuffer pts:(CMTime)pts;
```

### Additions to Protocol specification, Mobile\_API and HMI\_API

These are covered by proposal SDL-0058, thus are not included here.

## Potential downsides

The new video format introduces an overhead of RTP header and length field, which is typically 14 bytes in total. It is small enough compare to the size of video payload, so it should not cause performance degradation unless the video projection is running in an extremely low bitrate.

## Impact on existing code

This feature should not have impacts on existing code other than introducing additional implementations to SDL proxy and HMI. To get benefits of this feature, SDL apps should consider providing timestamp along with the video image buffers. Also, HMI should consider utilizing timestamp information delivered by RTP header.

## Alternatives considered

Another multimedia container format can be used, or a new SDL-proprietary container format can be invented instead. Nevertheless, RTP is chosen in this proposal because it is:
- much simpler compared to other container formats (such as MPEG transport stream).
- an open standard with many software implementation already available. Hence it should be fairly easy to integrate into current implementations.

The video format negotiation can be omitted if current raw H.264 format is completely deprecated by specification. This does not keep backward compatibility with current implementation and thus is not considered to be a good idea.

## References

- [RFC 6184: RTP Payload Format for H.264 Video](https://www.ietf.org/rfc/rfc6184.txt)
- [RFC 4571: Framing Real-time Transport Protocol (RTP) and RTP Control Protocol (RTCP) Packets over Connection-Oriented Transport](https://www.ietf.org/rfc/rfc4571.txt)
- [Proposal #0058: Add video streaming capabilities](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0058-video-streaming-capabilities.md)
