# Add video streaming capabilities API

* Proposal: [SDL-nnnn](nnnn-video-streaming-capabilities.md)
* Author: Tomoya Suzuki, Sho Amano
* Status: **Awaiting review**
* Impacted Platforms: [Core / iOS / Android / RPC]

## Introduction

This proposal provides a video streaming capabilites API to SDL apps. This is achieved by HMI notification of video capabilities to SDL core.

## Motivation

HMI's video capabilities vary between head unit devices. Some devices have powerful media processors and are capable of high-resolution, high-bandwidth video playback. Some devices may only support low resolution and/or low framerate video playback.

Currently, neither SDL apps nor the SDL proxy are aware of such capabilities. SDL app developers are forced to include multiple presets of video encoder's configuration in their app, and select a preset according to head unit's model name. This approach will not scale well because the developers eventually have to test against all head units in the market and tune the presets for each model.

The issue is resolved by capturing video related capabilities of the head unit and notifying them to the SDL app prior to video projection. The app will be able to check, for example, the maximum bitrate that the head unit (and HMI) supports, so that the app will configure video encoder to make sure the video stream fit into the limit. The app may also check highest H.264 level that the head unit (and HMI) supports, and may adjust video stream's frame rate accordingly.

## Proposed solution

This document proposes to add a pair of `GetVideoStreamingCapabilities` request/response. SDL proxy issues the request to acquire capabilities of the HMI.

Current SDL spec uses H.264 for video streaming. Therefore SDL proxy creates a request to acquire H.264 related capabilities, and HMI shall return information listed below:
 - preferred resolution of a video stream for decoding and rendering on HMI
   * This is merely a hint for optimization; SDL app may send a video stream whose resolution is higher or lower than this value. Also, this value can be different from the value of `DisplayCapabilities.ScreenParams.resolution` if, for instance, HMI is showing some buttons along with the video so the video area is smaller than the screen resolution.
 - maximum H.264 profile that HMI supports
 - maximum bitrate of H.264 video stream that HMI supports

The request includes a list of strings. Each string indicates a type of capabilities. SDL proxy shall include `H264_CAPABILITIES` string in the list to request H.264 related capabilities. SDL proxy may also include more types to request additional video capabilities, such as information related to another video format.

The response includes a list of `VideoStreamingCapabilities` structs. The field `type` shall match with the string indicated in the request. The field `value` shall include capabilities. In the case of `H264_CAPABILITIES`, `value` field shall include a JSON string with `preferredResolution`, `maxProfile` and `maxBitrateKbps` keys. HMI may include additional or vendor-specific capabilities in the JSON string. SDL proxy may ignore any capabilities that are unknown to it.

When HMI receives a request with a type that is unknown to it, it shall include a `VideoStreamingCapabilities` struct in the response whose `type` matches with the string in the request and whose `value` is an empty string. The empty string implies that the type is not supported by HMI. Note that the number of strings in the list in a request shall be always equal to the number of `VideoStreamingCapabilities` structs in the corresponding response.

## Detailed design

### Additions to Mobile_API

Add `VideoStreamingCapabilities` struct.

```xml
  <struct name="VideoStreamingCapabilities">
    <description>Contains information about HMI's video streaming capabilities.</description>
    <param name="type" type="String" minlength="1" maxlength="100" mandatory="true">
      <description>The type of capabilities. As of now only one type is defined:
                   - "H264_CAPABILITIES"
      </description>
    </param>
    <param name="value" type="String" minlength="0" maxlength="65535" mandatory="true">
      <description>The capability information.
                   In the case of H264_CAPABILITIES type, this parameter shall include a JSON string which includes "preferredResolution", "maxProfile" and "maxBitrateKbps" keys.
                   - "preferredResolution" indicates the preferred resolution of a video stream for decoding and rendering on HMI. The value is a dictionary containing "width" and "height", both in pixels.
                   - "maxProfile" indicates the highest H.264 profile that HMI supports. The value is a string, such as "1b", "3", "4.2".
                   - "maxBitrateKbps" indicates the maximum bitrate of H.264 video stream that HMI supports, in kbps. The value is an integer.
                   Here is an example of H264_CAPABILITIES type:
                   { "preferredResolution": {"width": 640, "height": 480}, "maxProfile": "4.2", "maxBitrateKbps": 10000 }
      </description>
    </param>
  </struct>
```

Add `GetVideoStreamingCapabilities` function. Note that `GetVideoStreamingCapabilitiesID` needs to be defined appropriately in `FunctionID` enum.

```xml
  <function name="GetVideoStreamingCapabilities" functionID="GetVideoStreamingCapabilitiesID" messagetype="request">
    <description>Request from proxy to HMI to query video streaming capabilities of HMI.</description>
    <param name="types" type="String" minsize="1" maxsize="255" minlength="1" maxlength="100" array="true" mandatory="true">
      <description>
        A list of types of capabilities. As of now only one type is defined:
        - "H264_CAPABILITIES"
      </description>
    </param>
  </function>

  <function name="GetVideoStreamingCapabilities" functionID="GetVideoStreamingCapabilitiesID" messagetype="response">
    <param name="success" type="Boolean" platform="documentation">
      <description>true if the request is successful, otherwise false.</description>
    </param>

    <param name="capabilities" type="VideoStreamingCapabilities" minsize="1" maxsize="255" array="true" mandatory="false">
      <description>List of video streaming capabilities returned by HMI.</description>
    </param>
  </function>
```

### Additions to HMI_API

Under `Common` interface, add `VideoStreamingCapabilities` struct.

```xml
  <struct name="VideoStreamingCapabilities">
    <description>Contains information about HMI's video streaming capabilities.</description>
    <param name="type" type="String" minlength="1" maxlength="100" mandatory="true">
      <description>The type of capabilities. As of now only one type is defined:
                   - "H264_CAPABILITIES"
      </description>
    </param>
    <param name="value" type="String" minlength="0" maxlength="65535" mandatory="true">
      <description>The capability information.
                   In the case of H264_CAPABILITIES type, this parameter shall include a JSON string which includes "preferredResolution", "maxProfile" and "maxBitrateKbps" keys.
                   - "preferredResolution" indicates the preferred resolution of a video stream for decoding and rendering on HMI. The value is a dictionary containing "width" and "height", both in pixels.
                   - "maxProfile" indicates the highest H.264 profile that HMI supports. The value is a string, such as "1b", "3", "4.2".
                   - "maxBitrateKbps" indicates the maximum bitrate of H.264 video stream that HMI supports, in kbps. The value is an integer.
                   Here is an example of H264_CAPABILITIES type:
                   { "preferredResolution": {"width": 640, "height": 480}, "maxProfile": "4.2", "maxBitrateKbps": 10000 }
      </description>
    </param>
  </struct>
```

Under `BasicCommunication` interface, add `GetVideoStreamingCapabilities` function:

```xml
  <function name="GetVideoStreamingCapabilities" messagetype="request">
    <description>Request from proxy to HMI to query video streaming capabilities of HMI.</description>
    <param name="types" type="String" minsize="1" maxsize="255" minlength="1" maxlength="100" array="true" mandatory="true">
      <description>
        A list of types of capabilities. As of now only one type is defined:
        - "H264_CAPABILITIES"
      </description>
    </param>
    <param name="appID" type="Integer" mandatory="true">
      <description>ID of application related to this RPC.</description>
    </param>
  </function>

  <function name="GetVideoStreamingCapabilities" messagetype="response">
    <param name="capabilities" type="Common.VideoStreamingCapabilities" minsize="1" maxsize="255" array="true" mandatory="true">
      <description>List of video streaming capabilities returned by HMI.</description>
    </param>
  </function>
```

SDL proxy should consider exposing the capabilities to SDL app. For example, a new property can be added in `SDLStreamingMediaManager` class in iOS SDL proxy. Also, SDL proxy should use the capability information to set up default values of video encoder's configuration. Then a SDL app can overwrite the configuration or can use the default values.

## Impact on existing code

This proposal should not have impacts on existing code since it only adds a new RPC. Of course, HMIs are encouraged to implement capturing video streaming capabilities of the head units and returning appropriate values.

## Alternatives considered

Instead of adding a new request/response pair, a response of `RegisterAppInterface` can be extended to include video streaming capabilities. This approach is simpler, but lacks the opportunity of the proxy to specify capability type. So it is not considered to be flexible. Also, the approach does not support a case where video streaming capabilities change dynamically. For example, the preferred resolution may change according to HMI's state.

A more general API name -- `GetDeviceCapabilities`, `GetDeviceStreamingCapabilities` -- may be a better long term approach.
