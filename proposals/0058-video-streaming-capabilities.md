# Add video streaming capabilities

* Proposal: [SDL-0058](0058-video-streaming-capabilities.md)
* Author: Tomoya Suzuki, Sho Amano
* Status: **Deferred**
* Impacted Platforms: [Core / iOS / Android / RPC]

## Introduction

This proposal extends SDL video streaming feature by 1) notifying video streaming capabilities of HMI to SDL proxy, and 2) adding "video format negotiation" procedure.

## Motivation

Currently, SDL video streaming always employs H.264 codec and uses byte-streaming format. On the other hand, there is a demand of supporting more formats/protocols such as RTP. Also, there may be a demand to add another video codec like H.265 in future.

To support these cases, two technical issues that need to be resolved:
 - SDL proxy on a phone needs to know which codecs and formats/protocols a head unit supports. Since a video streaming is always initiated by SDL proxy, it needs to know them beforehand.
 - SDL proxy needs to notify the head unit which codec and format/protocol it is going to use before a video streaming session begins. This enables HMI to set up and configure its video player prior to receiving a video stream.

The first issue is resolved by capturing video related capabilities of the head unit and notifying them to the SDL proxy prior to video streaming. The second issue is resolved by adding a "video format negotiation" procedure, in which SDL proxy tells HMI the video configuration when starting a video streaming.

## Proposed solution

### Head unit's video capabilities

Head unit's video capabilities are transferred to SDL proxy based on "System Capabilities Query" RPC proposed by [SDL-0055 (https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0055-system_capabilities_query.md)](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0055-system_capabilities_query.md). The capabilities include:
 - preferred resolution of a video stream for decoding and rendering on HMI
   * This is merely a hint for optimization; SDL app may send a video stream whose resolution is higher or lower than this value. Also, this value can be different from the value of `DisplayCapabilities.ScreenParams.resolution` if, for instance, HMI is showing some buttons along with the video so the video area is smaller than the screen resolution.
 - maximum bitrate of a video stream that HMI supports
 - list of video formats that the head unit supports. Here, a video format is a combination of "protocol" and "codec".

### Video format negotiation

When starting a video streaming, SDL proxy sends a `StartService` Control Frame with the desired video configurations. They should include:
- desired height in pixels
- desired width in pixels
- video protocol
- video codec

As SDL core receives the Control Frame, it emits a `SetVideoConfig` request to HMI. HMI shall immediately reply whether these parameters are acceptable or not. Based on the result, SDL core shall send either `Start Service ACK` or `Start Service NACK` to SDL proxy, notifying that it may or may not start video streaming with the configurations.

`Start Service NACK` includes a list of parameters which have not been accepted by HMI.

After SDL proxy receives a `Start Service NACK` Control Frame from SDL core, it may initiate another `Start Service` Control Frame with updated parameters.

`SetVideoConfig` request shall be sent to HMI prior to `StartStream` request. SDL core shall send it every time before each `StartStream` request as long as video configurations are included in `Start Service` Control Frame. If HMI receives a `StartStream` request without `SetVideoConfig`, it shall treat the protocol is "RAW" and the codec is "H264". This is to keep backward compatibility with existing SDL proxy implementations.

If either Core or HMI does not support this proposal (i.e. `videoStreaming` param in `HMICapabilities` struct is false or does not exist), SDL proxy should not include video configuration parameters in `Start Service` Control Frame. This is to keep backward compatibility with existing Core and HMI implementations.

### Overall sequence

Here is what happens when a SDL video streaming app is launched and tries to start video streaming. Please also refer to "System Capabilities Query" proposal.

When an app is launched,

1. Proxy -> Core [RegisterAppInterface Request]
2. Core -> Proxy [RegisterAppInterface Response with HMICapabilities including "videoStreaming" = true]
3. Proxy -> Core [GetSystemCapability Request with "systemCapabilityType" = "VIDEO_STREAMING"]
4. Core -> Proxy [GetSystemCapability Response including "videoStreamingCapability" struct]

When the app tries to start video streaming,

5. Proxy -> Core [Start Service Control Frame with video configurations (in BSON format), based on "videoStreamingCapability" information]
6. Core -> HMI [SetVideoConfig Request including the configurations]
7. HMI -> Core [SetVideoConfig Response (accepted, or rejected with a list of params)]
8. Core -> HMI [StartStream Request (Note: this is sent only when SetVideoConfig response is positive)]
9. Core -> Proxy [Start Service ACK or NACK Control Frame. NACK frame includes a list of rejected params in BSON format.]

## Detailed design

### Additions to Protocol specification

Append following BSON document in the payload of `Start Service` Control Frame with Service Type = 0x0B (Video Service).

```
{
    "desiredHeight": height,
    "desiredWidth": width,
    "videoProtocol": protocol,
    "videoCodec": codec
}
```
Where,
 - `height` and `width` are `int32` values
 - `protocol` is a `string` value which is one of `VideoStreamingProtocol` element name (e.g. "RAW")
 - `codec` is a `string` value which is one of `VideoStreamingCodec` element name (e.g. "H264")

Also, append a BSON document in the payload of `Start Service NACK` Control Frame with Service Type = 0x0B (Video service). The document includes an array of rejected parameters with "rejectedParams" key. For example if "videoProtocol" and "videoCodec" are rejected, the `Start Service NACK` Control Frame includes following document:

```
{"rejectedParams": ["videoProtocol", "videoCodec"]}
```

### Modification to existing RPCs (Mobile_API and HMI_API)

```xml
<struct name="HMICapabilities">
    <param name="navigation" type="Boolean" mandatory="false">
        <description>Availability of build in Nav. True: Available, False: Not Available</description>
    </param>
    <param name="phoneCall" type="Boolean" mandatory="false">
        <description>Availability of build in phone. True: Available, False: Not Available</description>
    </param>
    <param name="videoStreaming" type="Boolean" mandatory="false">
        <description>Availability of video streaming. </description>
    </param>
</struct>

<struct name="SystemCapability">
    <description>The systemCapabilityType indicates which type of data should be changed and identifies which data object exists in this struct. For example, if the SystemCapability Type is NAVIGATION then a "navigationCapability" should exist.</description>
    <param name="systemCapabilityType" type="SystemCapabilityType" mandatory="true">
    </param>
    <param name="videoStreamingCapability" type="VideoStreamingCapability" mandatory="false">
    </param>
</struct>

<enum name="SystemCapabilityType">
    <element name="VIDEO_STREAMING"/>
</enum>
```

### New additions to RPCs (Mobile_API)

Add `VideoStreamingCapability`, `VideoStreamingFormat`, `VideoStreamingProtocol` and `VideoStreamingCodec` structs.

```xml
<struct name="VideoStreamingCapability">
    <description>Contains information about this system's video streaming capabilities.</description>
    <param name="preferredResolution" type="ImageResolution" mandatory="false">
        <description>The preferred resolution of a video stream for decoding and rendering on HMI.</description>
    </param>
    <param name="maxBitrate" type="Integer" minvalue="0" maxvalue="2147483647" mandatory="false">
        <description>The maximum bitrate of video stream that is supported, in kbps.</description>
    </param>
    <param name="supportedFormats" type="VideoStreamingFormat" array="true" mandatory="false">
        <description>Detailed information on each format supported by this system. Each object will contain a VideoStreamingFormat that describes what can be expected.</description>
    </param>
</struct>

<struct name="VideoStreamingFormat">
    <description>Video streaming formats and their specifications.</description>
    <param name="protocol" type="VideoStreamingProtocol" mandatory="true">
        <description>Protocol type, see VideoStreamingProtocol</description>
    </param>
    <param name="codec" type="VideoStreamingCodec" mandatory="true">
        <description>Codec type, see VideoStreamingCodec</description>
    </param>
</struct>

<enum name="VideoStreamingProtocol">
    <description>Enum for each type of video streaming protocol type.</description>
    <element name="RAW">
        <description>Raw stream bytes that contains no timestamp data and is the lowest supported video streaming</description>
    </element>
    <element name="RTP">
        <description>RTP facilitates the transfer of real-time data. Information provided by this protocol include timestamps (for synchronization), sequence numbers (for packet loss and reordering detection) and the payload format which indicates the encoded format of the data.</description>
    </element>
    <element name="RTSP">
        <description>The transmission of streaming data itself is not a task of RTSP. Most RTSP servers use the Real-time Transport Protocol (RTP) in conjunction with Real-time Control Protocol (RTCP) for media stream delivery. However, some vendors implement proprietary transport protocols. </description>
    </element>
    <element name="RTMP">
        <description> Real-Time Messaging Protocol (RTMP) was initially a proprietary protocol developed by Macromedia for streaming audio, video and data over the Internet, between a Flash player and a server. Macromedia is now owned by Adobe, which has released an incomplete version of the specification of the protocol for public use.</description>
    </element>
    <element name="WEBM">
        <description>The WebM container is based on a profile of Matroska. WebM initially supported VP8 video and Vorbis audio streams. In 2013 it was updated to accommodate VP9 video and Opus audio.</description>
    </element>
</enum>

<enum name="VideoStreamingCodec">
    <description>Enum for each type of video streaming codec.</description>
    <element name="H264">
        <description>A block-oriented motion-compensation-based video compression standard. As of 2014 it is one of the most commonly used formats for the recording, compression, and distribution of video content.</description>
    </element>
    <element name="H265">
        <description>High Efficiency Video Coding (HEVC), also known as H.265 and MPEG-H Part 2, is a video compression standard, one of several potential successors to the widely used AVC (H.264 or MPEG-4 Part 10). In comparison to AVC, HEVC offers about double the data compression ratio at the same level of video quality, or substantially improved video quality at the same bit rate. It supports resolutions up to 8192x4320, including 8K UHD.</description>
    </element>
    <element name="Theora">
        <description>Theora is derived from the formerly proprietary VP3 codec, released into the public domain by On2 Technologies. It is broadly comparable in design and bitrate efficiency to MPEG-4 Part 2, early versions of Windows Media Video, and RealVideo while lacking some of the features present in some of these other codecs. It is comparable in open standards philosophy to the BBC's Dirac codec.</description>
    </element>
    <element name="VP8">
        <description>VP8 can be multiplexed into the Matroska-based container format WebM along with Vorbis and Opus audio. The image format WebP is based on VP8's intra-frame coding. VP8's direct successor, VP9, and the emerging royalty-free internet video format AV1 from the Alliance for Open Media (AOMedia) are based on VP8.</description>
    </element>
    <element name="VP9">
        <description>Similar to VP8, but VP9 is customized for video resolutions beyond high-definition video (UHD) and also enables lossless compression.</description>
    </element>
</enum>
```

SDL proxy should consider exposing the capabilities to SDL app. For example, a new property can be added in `SDLStreamingMediaManager` class in iOS SDL proxy.

### New additions to RPCs (HMI_API)

Add `VideoStreamingCapability`, `VideoStreamingFormat`, `VideoStreamingProtocol` and `VideoStreamingCodec` structs (see previous section). Note that these structs should be added under `Common` interface.

Also, add `Common.VideoConfig` struct:

```xml
  <struct name="VideoConfig">
    <description>Configuration of a video stream.</description>
    <param name="protocol" type="Common.VideoStreamingProtocol" mandatory="false">
      <description>The video protocol configuration</description>
    </param>
    <param name="codec" type="Common.VideoStreamingCodec" mandatory="false">
      <description>The video codec configuration</description>
    </param>
    <param name="width" type="Integer" mandatory="false">
      <description>Width of the video stream, in pixels.</description>
    </param>
    <param name="height" type="Integer" mandatory="false">
      <description>Height of the video stream, in pixels.</description>
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
    <description>Response from HMI to SDL whether the configuration is accepted. In a negative response, a list of rejected parameters are supplied.</description>
    <param name="rejectedParams" type="String" array="true" minsize="1" maxsize="1000" mandatory="false">
      <description>List of params of VideoConfig struct which are not accepted by HMI, e.g. "protocol" and "codec". This param exists only when the response is negative.</description>
    </param>
  </function>
```

## Potential Downsides

This proposal introduces new parameters in `VideoStreamingCapability` struct and a new document in `Start Service` Control Frame, thereby slightly increases their sizes. The data size is small enough and will not impact performance. Moreover, the changes affect video streaming apps only; non video-streaming apps will not issue `GetSystemCapability` request with `SystemCapabilityType = VIDEO_STREAMING` hence `VideoStreamingCapability` struct will not be used.

## Impact on existing code

This proposal should have little impacts on existing code since it mainly adds new RPCs and updates SDL protocol, with backward compatibility kept. Of course, it will introduce additional implementations to SDL proxies, core and HMI.

## Alternatives considered

Parameters of `VideoStreamingCapability` struct could be added to `RegisterAppInterface` response instead. This is not considered as a good approach since the response now includes large capability information and it does not seem to scale well.

Instead of adding a new RPC `SetVideoConfig`, `StartStream` request can be extended to include video configurations. The issue with this idea is that `StartStream` response can be delayed when, for example, HMI shows a dialog to ask the user before starting a video stream. (This is the case of sdl_hmi implementation.) Since `Start Service ACK/NACK` has to be sent before `StartStream` response, a new RPC is proposed in this document.
