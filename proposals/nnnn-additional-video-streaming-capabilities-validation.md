# Additional Video Streaming Capabilities Validation

* Proposal: [SDL-NNNN](nnnn-additional-video-streaming-capabilities-validation.md)
* Author: [Jack Byrne](https://github.com/JackLivio)
* Status: **Awaiting review**
* Impacted Platforms: [Core / HMI]

## Introduction

This proposal is an extension of an already implemented proposal: SDL 0296 - Possibility to update video streaming capabilities during ignition cycle. This proposal will define some extra validation rules to the capabilities the HMI and SDL Apps send to SDL Core to prevent malformed video streaming capabilities.

## Motivation

The original proposal does not define many rules for the structure of the `additionalVideoStreamingCapabilities` object that can be sent to SDL Core from the HMI. Additionally all of the parameters in the struct `VideoStreamingCapability` are non-mandatory so this can lead to weird interpretations for how resolution switching capabilities should be communicated. 

For example, when a resolution switches and the HMI sends an `OnSystemCapabilityUpdated` notification, it is unclear if the HMI should send all of the video capabilities, or if it should only send the fields that updated.

The app libraries need almost all of the possible fields in the `VideoStreamingCapability` object in order to differentiate between streaming configurations. Just supplying the resolution is not sufficient enough to differentiate between the selected capability and other capabilities that have the same resolution but use different scales, diagonal screen sizes, or pixels per inch.

Additionally SDL Core should do some validation on the capabilities received from an application to ensure no bad capabilities are forwarded to the HMI.

## Proposed solution

### SDL Core

#### Validation of HMI Notification `OnSystemCapabilityUpdated`

To remedy potential issues of resolution switching across different HMI integrations with connected applications, I propose to define a set of validation rules in SDL Core when receiving video streaming capabilities from the HMI via `OnSystemCapabilityUpdated`.

The following set of rules must be followed or else SDL Core should ignore the capabilities from the HMI.

- The root video capability should not be contained within the `additionalVideoStreamingCapabilities` parameter in any message sent to SDL Core. It will be counted as a duplicate in this case.
- No duplicate capabilities should be included in the set of the root capability and the additional capabilities.
- If the root capability includes a video streaming capability parameter, then the additional streaming capabilities should also include the same parameters.
- Additional video streaming capability objects should not contain the parameter `additionalStreamingCapabilities` (prevent unnecessary recursion of capabilities).

The following example capability object is ok. Despite all of the preferred resolutions being the same, the scale parameter is the differentiating factor. Notice that all parameter fields defined in the root capability are also defined in the additional video streaming capabilities.
```
videoStreamingCapability: {
    preferredResolution: {
        resolutionWidth: masterWidth,
        resolutionHeight: templateHeight
    },
    maxBitrate: 400000,
    supportedFormats: [
        { protocol:  "RAW", codec: "H264" },
        { protocol:  "RTP", codec: "H264" },
        { protocol:  "RTSP", codec: "Theora" },
        { protocol:  "RTMP", codec: "VP8" },
        { protocol:  "WEBM", codec: "VP9" }
    ],
    hapticSpatialDataSupported: true,
    diagonalScreenSize: 7,
    pixelPerInch: 96,
    scale: 1,
    preferredFPS: 30,
    additionalVideoStreamingCapabilities: [
        {
            preferredResolution: {
                resolutionWidth: masterWidth,
                resolutionHeight: templateHeight
            },
            maxBitrate: 400000,
            supportedFormats: [
                { protocol:  "RAW", codec: "H264" },
                { protocol:  "RTP", codec: "H264" },
                { protocol:  "RTSP", codec: "Theora" },
                { protocol:  "RTMP", codec: "VP8" },
                { protocol:  "WEBM", codec: "VP9" }
            ],
            hapticSpatialDataSupported: true,
            diagonalScreenSize: 7,
            pixelPerInch: 72,
            scale: 1.5,
            preferredFPS: 30
        },
        {
            preferredResolution: {
                resolutionWidth: masterWidth,
                resolutionHeight: templateHeight
            },
            maxBitrate: 400000,
            supportedFormats: [
                { protocol:  "RAW", codec: "H264" },
                { protocol:  "RTP", codec: "H264" },
                { protocol:  "RTSP", codec: "Theora" },
                { protocol:  "RTMP", codec: "VP8" },
                { protocol:  "WEBM", codec: "VP9" }
            ],
            hapticSpatialDataSupported: true,
            diagonalScreenSize: 7,
            pixelPerInch: 48,
            scale: 2,
            preferredFPS: 30
        }
    ]
}
```

#### Validation of RPC `OnAppCapabilityUpdated`

To prevent the app from sending bad capabilities to SDL Core the following validation rules should be enforced when receiving an `OnAppCapabilityUpdated` notification from an SDL connected App. If any rule is violated by the application, Core will notify the HMI that the current selected resolution is the only resolution supported by the app, thus disabling resolution switching.

- No duplicate capabilities should be included in the `AdditionalStreamingCapability` object.
- No root level capability should be included in the `OnAppCapability` notification. All supported resolutions should be included in the parameter `additionalStreamingCapabilities`.
- All capabilities included in this message should be a subset of the capabilities provided by the HMI.
- Additional streaming capability objects should not contain the parameter `additionalStreamingCapabilities` (prevent unnecessary recursion of capabilities).

### HMI Integration Guidelines

As a guideline for HMI integrations, I would like to note that during a resolution switch, all negotiated capabilities should be included in the notification. If the streaming resolution changes, the HMI should not send a notification that only contains the updated resolution field. I am only noting this as a guideline change and not requiring validation for this in SDL Core. I will mention how validation could work for this scenario in the alternative solutions section.

## Potential downsides

This validation will increase the complexity of the feature and computation required on the head unit. I believe these changes are necessary to prevent future issues of differing App and HMI interpretations of this feature.

## Impact on existing code

SDL Core will need to be updated to handle validation of the mentioned notifications sent during video streaming negotiation and resolution switching.

SDL Core will also need to handle bad capability messages from an application and notify the HMI that the current resolution is the only accepted app resolution.

Since the RPCs mentioned in this proposal do not have responses, when a rule is broken and Core handles/ignores the notification, an ERROR log should be printed by SDL Core.

Changes will be made to SDL Core but these validation rules may impact HMI and App implementations if they are using this feature incorrectly.

## Alternatives considered

Extra validation could be implemented in SDL Core where all `OnSystemCapabilityUpdated` notifications from the HMI that include the `videoStreamingCapability` parameter should contain all capabilities that are included in the `OnAppCapabilityUpdated` notification received by the app.

I am not sure if this change is necessary due to the complexity that would be created in SDL Core due to requiring Core to monitor and save an app's video streaming capability. The author suggests to only implement this rule as a guideline in the documentation.
