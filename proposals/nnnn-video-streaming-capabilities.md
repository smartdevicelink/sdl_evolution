# Add video streaming capabilities

* Proposal: [SDL-nnnn](nnnn-video-streaming-capabilities.md)
* Author: Tomoya Suzuki, Sho Amano
* Status: **Awaiting review**
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
 - maximum H.264 profile that HMI supports
 - maximum bitrate of H.264 video stream that HMI supports

The capabilities are transferred to SDL core and proxy using "System Capabilities Query" RPC proposed by [SDL-0055 (https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0055-system_capabilities_query.md)](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0055-system_capabilities_query.md).

Currently, the capabilities focus on H.264 related properties since video projection always employs the codec. If another codec is added in the future, this capabilities can be extended at the same time.

## Detailed design

### Additions to Mobile_API

Include `preferredResolution`, `maxH264Profile`, `maxH264Bitrate` parameters in `VideoStreamingCapability` struct. (If the struct does not exist then it should be newly added.)

```xml
  <struct name="VideoStreamingCapability">
    <description>Contains information about HMI's video streaming capabilities.</description>

      :
      :

    <param name="preferredResolution" type="ImageResolution" mandatory="false">
      <description>The preferred resolution of a video stream for decoding and rendering on HMI.</description>
    </param>
    <param name="maxH264Profile" type="String" minlength="1" maxlength="7" mandatory="false">
      <description>The highest H.264 profile that HMI supports. Examples: "1b", "3", "4.2".</description>
    </param>
    <param name="maxH264Bitrate" type="Integer" minvalue="0" maxvalue="2147483647" mandatory="false">
      <description>The maximum bitrate of H.264 video stream that HMI supports, in kbps.</description>
    </param>
  </struct>
```

### Additions to HMI_API

Include `preferredResolution`, `maxH264Profile`, `maxH264Bitrate` parameters in `Common.VideoStreamingCapability` struct. (If the struct does not exist then it should be newly added.)

```xml
  <struct name="VideoStreamingCapability">
    <description>Contains information about HMI's video streaming capabilities.</description>

      :
      :

    <param name="preferredResolution" type="Common.ImageResolution" mandatory="false">
      <description>The preferred resolution of a video stream for decoding and rendering on HMI.</description>
    </param>
    <param name="maxH264Profile" type="String" minlength="1" maxlength="7" mandatory="false">
      <description>The highest H.264 profile that HMI supports. Examples: "1b", "3", "4.2".</description>
    </param>
    <param name="maxH264Bitrate" type="Integer" minvalue="0" maxvalue="2147483647" mandatory="false">
      <description>The maximum bitrate of H.264 video stream that HMI supports, in kbps.</description>
    </param>
  </struct>
```

SDL proxy should consider exposing the capabilities to SDL app. For example, a new property can be added in `SDLStreamingMediaManager` class in iOS SDL proxy. Also, SDL proxy should use the capability information to set up default values of video encoder's configuration. A SDL app can overwrite the configuration or can use the default values.

## Impact on existing code

This proposal should not have impacts on existing code since it only adds some capability parameters in the structures. Of course, HMIs are encouraged to implement capturing these capabilities of the head units and filling in the structures with appropriate values.

## Alternatives considered

The struct could be added to `RegisterAppInterface` response instead. This is not considered as a good approach since the response now includes large capability information and it does not seem to scale well.

## Notes

While this proposal includes an idea of `preferredResolution`, it does not provide a mean to determine the actual resolution of the video stream. In other word, a HMI cannot know whether a SDL app uses a resolution of `preferredResolution` or not without inspecting the H.264 video stream (such as SPS NAL unit). The HMI needs video stream's resolution information in order to send out touch events with correct coordinate on the video image. This issue is outside the scope of this proposal, and may be addressed by another one.
