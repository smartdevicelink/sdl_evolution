# Add preferred FPS to VideoStreamingCapability

* Proposal: [SDL-NNNN](NNNN-add-preferred-FPS.md)
* Author: [Shinichi Watanabe](https://github.com/shiniwat)
* Status: **Awaiting review**
* Impacted Platforms: [Core / iOS / Java Suite / RPC]

## Introduction

This proposal extends SDL video streaming feature by adding preferred FPS to VideoStreamingCapability, so that the quality of video projection can be adjusted per OEM.

## Motivation

Currently, SDL video streaming refers to VideoStreamingCapability, and mobile libraries respect for preferred resolution, maximum bitrate, video format, etc.
However the frame rate of the video streaming totally depends on mobile applications, and some OEM's head unit may not work for high frame rate, such as 60 fps.
This proposal allows head units to specify the preferred FPS, so that mobile library can refer to the specified value. 

## Proposed solution

The proposed solution is to add preferred FPS to VideoStreamingCapability. On a head unit, preferred FPS can be varied on screen resolution; i.e. frame rate can be higher for lower resolution, but the preferred FPS value can be used for the case where screen resolution is the preferred resolution value.
Mobile Proxies should respect for the preferred FPS value, as well as they do for preferred resolution, maximum bitrate, etc.

## Detailed design

### RPC change (Mobile_API and HMI_API)

Add preferredFPS to VideoStreamingCapability struct in both APIs.

```xml
    <struct name="VideoStreamingCapability" since="4.5">
        <description>Contains information about this system's video streaming capabilities.</description>
        ...
        <!-- new param -->
        <param name="preferredFPS" type="Integer" minvalue="0" maxvalue="2147483647" mandatory="false">
            <description>Preferred frame rate of a video stream per second.</description>
        </param>
    </struct>
```

### iOS mobile proxy consideration

A frame rate of iOS SDL application highly depends on how the application capture the video data.
If the application uses AVCaptureDevice, the frame rate must fit into AVFrameRateRange in ACCaptureDevice.format.

When encoding the video frame, the frame rate can be specified to kVTCompressionPropertyKey_ExpectedFrameRate in videoEncoderSettings, but [iOS documentation](https://developer.apple.com/documentation/videotoolbox/kvtcompressionpropertykey_expectedframerate) says, “provided as a hint to the video encoder” and “The actual frame rate depends on frame durations and may vary.”

So developers must make sure taking account of preferredFPS value for capturing the video frame, as well as configuring videoEncoderSettings.

### Android mobile proxy consideration

Android Java Suite library introduces the combination of VirtualDisplay and MediaEncoder to capture a SdlRemoteDisplay class and encode the video stream.
When encoding the video frame, a frame rate can be specified by MediaCodec#configure, but [Android documentation](https://developer.android.com/reference/android/media/MediaFormat.html#KEY_FRAME_RATE) says, "For video encoders this value corresponds to the intended frame rate, although encoders are expected to support variable frame rate based on MediaCodec.BufferInfo#presentationTimeUs",
so situation would be the same as iOS.

The actual frame rate of MediaEncoder depends on the frequency of input surface's update in VirtualDisplay, and varies on the application's (SdlRemoteDisplay's) content.

This issue will be addressed by another proposal later.

## Potential Downsides

Adding an optional parameter to VideoStreamingCapability has no downside. It will be specified by head unit, but how it is used is still up to mobile application.

## Impact on existing code

This proposal has no breaking change, so there should be no impact on existing code. As mentioned, it is still up to mobile application how the additional parameter (preferredFPS) is used.

## Alternatives considered

As well as other video streaming parameters, preferredFPS can be added to other RPC, like StartStream, SetVideoConfig, etc.
But it makes more sense to handle preferred FPS parameter in the same way as bitrate, screen resolution, etc.