# Add video streaming capabilities

* Proposal: [SDL-0058](0058-video-streaming-capabilities.md)
* Author: Tomoya Suzuki, Sho Amano
* Status: **In Review**
* Impacted Platforms: [Core / iOS / Android / RPC]

## Introduction

This proposal provides a video streaming capability information to SDL apps. This is achieved by HMI notification of video capabilities to SDL core and proxy.

## Motivation

HMI's video capabilities vary between head unit devices. Some devices have powerful media processors and are capable of high-resolution, high-bandwidth video playback. Some devices may only support low resolution and/or low framerate video playback.

Currently, neither SDL apps nor the SDL proxy are aware of such capabilities. SDL app developers are forced to include multiple presets of video encoder's configuration in their app, and select a preset according to head unit's model name. This approach will not scale well because the developers eventually have to test against all head units in the market and tune the presets for each model.

The issue is resolved by capturing video related capabilities of the head unit and notifying them to the SDL app prior to video projection. The app will be able to check, for example, the maximum bitrate that the head unit (and HMI) supports, so that the app will configure video encoder to make sure the video stream fit into the limit. The app may also check highest H.264 level that the head unit (and HMI) supports, and may adjust video stream's frame rate accordingly.

## Proposed solution

This document proposes to add video streaming related capabilities. They include:
 - preferred resolution of a video stream for decoding and rendering on HMI
   * This is merely a hint for optimization; SDL app may send a video stream whose resolution is higher or lower than this value. Also, this value can be different from the value of `DisplayCapabilities.ScreenParams.resolution` if, for instance, HMI is showing some buttons along with the video so the video area is smaller than the screen resolution.
 - video format(s) that the system supports. This is to sync with proposal [SDL-0048](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0048-H264-over-RTP-support-for-video-streaming.md).
 - maximum H.264 level that HMI supports
 - maximum bitrate of H.264 video stream that HMI supports

The capabilities are transferred to SDL core and proxy using "System Capabilities Query" RPC proposed by [SDL-0055 (https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0055-system_capabilities_query.md)](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0055-system_capabilities_query.md).

Currently, the capabilities focus on H.264 related properties since video projection always employs the codec. If another codec is added in the future, this capabilities can be extended at the same time.

## Detailed design

### Modification to existing RPCs (Mobile_API and HMI_API)

Please also refer to "System Capabilities Query" proposal.

```xml
<struct name="HMICapabilities">
    <param name="navigation" type="Boolean" mandatory="false">
        <description>Availability of build in Nav. True: Available, False: Not Available</description>
    </param>
    <param name="phoneCall" type="Boolean" mandatory="false">
        <description>Availability of build in phone. True: Available, False: Not Available </description>
    </param>
    <param name="videoStreaming" type="Boolean" mandatory="false">
        <description>Availability of video streaming. </description>
    </param>
</struct>

<struct name="SystemCapability">
    <description>The systemCapabilityType indicates which type of data should be changed and identifies which data object exists in this struct. For example, if the SystemCapability Type is NAVIGATION then a "navigationCapability" should exist</description>
    <param name="systemCapabilityType" type="SystemCapabilityType" mandatory="true">
    </param>
    <param name="videoStreamingCapability" type="VideoStreamingCapability" mandatory="false">
    </param>
</struct>

<enum name="SystemCapabilityType">
    <element name="VIDEO_STREAMING"/>
</enum>
```

### Additions to Mobile_API

Add `VideoStreamingCapability` struct which includes `preferredResolution`, `supportedFormats`, `maxH264Level` and `maxH264Bitrate` parameters.

```xml
  <struct name="VideoStreamingCapability">
    <description>Contains information about this system's video streaming capabilities.</description>
    <param name="preferredResolution" type="ImageResolution" mandatory="false">
      <description>The preferred resolution of a video stream for decoding and rendering on HMI.</description>
    </param>
    <param name="supportedFormats" type="String" minlength="1" maxlength="255" minsize="1" maxsize="100" array="true" mandatory="false">
      <description>
        List of video formats that HMI supports, in its preferred order. Following strings are defined.
        - "video/x-h264,stream-format=byte-stream" (Raw H.264 stream that contains no timestamp data and is the lowest supported video streaming.)
        - "application/x-rtp-stream,media=video,encoding-name=h264" (H.264 video over RTP format defined by RFC 6184 and framed as defined by RFC 4571. This format includes timestamps and sequence numbers.)
      </description>
    </param>
    <param name="maxH264Level" type="String" minlength="1" maxlength="7" mandatory="false">
      <description>The highest H.264 level that HMI supports. Examples: "1b", "3", "4.2".</description>
    </param>
    <param name="maxH264Bitrate" type="Integer" minvalue="0" maxvalue="2147483647" mandatory="false">
      <description>The maximum bitrate of H.264 video stream that HMI supports, in kbps.</description>
    </param>
  </struct>
```

### Additions to HMI_API

Add `Common.VideoStreamingCapability` struct which includes `preferredResolution`,`supportedFormats`, `maxH264Level` and `maxH264Bitrate` parameters.

```xml
  <struct name="VideoStreamingCapability">
    <description>Contains information about this system's video streaming capabilities.</description>
    <param name="preferredResolution" type="Common.ImageResolution" mandatory="false">
      <description>The preferred resolution of a video stream for decoding and rendering on HMI.</description>
    </param>
    <param name="supportedFormats" type="String" minlength="1" maxlength="255" minsize="1" maxsize="100" array="true" mandatory="false">
      <description>
        List of video formats that HMI supports, in its preferred order. Following strings are defined.
        - "video/x-h264,stream-format=byte-stream" (Raw H.264 stream that contains no timestamp data and is the lowest supported video streaming.)
        - "application/x-rtp-stream,media=video,encoding-name=h264" (H.264 video over RTP format defined by RFC 6184 and framed as defined by RFC 4571. This format includes timestamps and sequence numbers.)
      </description>
    </param>
    <param name="maxH264Level" type="String" minlength="1" maxlength="7" mandatory="false">
      <description>The highest H.264 level that HMI supports. Examples: "1b", "3", "4.2".</description>
    </param>
    <param name="maxH264Bitrate" type="Integer" minvalue="0" maxvalue="2147483647" mandatory="false">
      <description>The maximum bitrate of H.264 video stream that HMI supports, in kbps.</description>
    </param>
  </struct>
```

SDL proxy should consider exposing the capabilities to SDL app. For example, a new property can be added in `SDLStreamingMediaManager` class in iOS SDL proxy. Also, SDL proxy should use the capability information to set up default values of video encoder's configuration. A SDL app can overwrite the configuration or can use the default values.

## Potential Downsides

This proposal introduces new parameters in `VideoStreamingCapability` struct and slightly increases its size. The data size is small enough and will not impact performance. Moreover, due to the nature of "System Capabilities Query" scheme, the change has impacts only on video streaming apps; non video-streaming apps will not issue `GetSystemCapability` request with `SystemCapabilityType = VIDEO_STREAMING` hence `VideoStreamingCapability` struct will not be used.

## Impact on existing code

This proposal should not have impacts on existing code since it only adds some capability parameters in the structures. Of course, HMIs are encouraged to implement capturing these capabilities of the head units and filling in the structures with appropriate values.

## Alternatives considered

The struct could be added to `RegisterAppInterface` response instead. This is not considered as a good approach since the response now includes large capability information and it does not seem to scale well.

## Notes

While this proposal includes an idea of `preferredResolution`, it does not provide a means to determine the actual resolution of the video stream. In other words, a HMI cannot know whether a SDL app uses a resolution of `preferredResolution` or not without inspecting the H.264 video stream (such as SPS NAL unit). The HMI needs video stream's resolution information in order to send out touch events with correct coordinate on the video image. This issue is outside the scope of this proposal, and may be addressed by another one.
