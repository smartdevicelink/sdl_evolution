# Align video streaming parameters with VideoStreamingCapability

* Proposal: [SDL-NNNN](NNNN-align-VideoStreamingParameter-with-capability.md)
* Author: [Shinichi Watanabe](https://github.com/shiniwat)
* Status: **Awaiting review**
* Impacted Platforms: [iOS / Java Suite]

## Introduction

When Android SDL application starts video streaming, a developer can specify `VideoStreamingParameters`, but before actually starting the streaming, those parameters need to be aligned with `VideoStreamingCapability` returned by head units.
The same is true for iOS SDL application; i.e. a developer can specify `customVideoEncoderSettings`,  but those settings need to be aligned with `VideoStreamingCapability`.

This proposal addresses possible conflicts between developers' settings and `VideoStreamingCapability` for iOS and Java Suite platforms.

## Motivation

The issue is realized when implementing [SDL-0274](0274-add-preferred-FPS.md) for sdl_java_suite. In [SDL-0274](0274-add-preferred-FPS.md), "iOS mobile proxy changes" section states as follows:

>Later part in the same method (didEnterStateVideoStreamStarting), current videoEncoderSettings are overwritten by customEncoderSettings.
>
>However, for frame rate, we should take lower value approach if frame rate in customEncoderSettings is higher than preferred FPS

We should take the same approach, i.e. taking lower preferred FPS value for Java Suite library too, but during the code review, we found that the same approach should be taken for some other parameters as well.

This proposal addresses how developers' settings should be aligned with `VideoStreamingCapability`.

## Proposed solution

As mentioned in Motivation section, we should take lower value approach for relevant video streaming settings if the value specified by the developer is higher than the capabilities' value.

### Detailed design for iOS library

iOS library takes `customVideoEncoderSettings`, but values relevant to `VideoStreamingCapability` are `AverageBitRate` and `ExpectedFrameRate`.

Those values should be aligned as follows:

SDLVideoStreamingCapability.m:

```objc
- (void)didEnterStateVideoStreamStarting {
		...
        // Apply customEncoderSettings here. Note that value from HMI (such as maxBitrate) will be overwritten by custom settings
        // (Exception: ExpectedFrameRate, AverageBitRate)
        for (id key in self.customEncoderSettings.keyEnumerator) {
            // do NOT override frame rate or average bitrate if custom setting is higher than current setting.
            if ([(NSString *)key isEqualToString:(__bridge NSString *)kVTCompressionPropertyKey_ExpectedFrameRate] ||
                [(NSString *)key isEqualToString:(__bridge NSString *)kVTCompressionPropertyKey_AverageBitRate]) {
                if ([self.customEncoderSettings valueForKey:key] < self.videoEncoderSettings[key]) {
                    self.videoEncoderSettings[key] = [self.customEncoderSettings valueForKey:key];
                }
            } else {
                self.videoEncoderSettings[key] = [self.customEncoderSettings valueForKey:key];
            }
        }
		...
}
```

### Detailed design for Java Suite library

Java Suite library updates custom `VideoStreamingParameters` when `VideoStreamingCapability` is given by head unit. `VideoStreamingParameter#update` method does the job.

For Resolution and Scale, the `update()` method already takes care of capability as well as making some adjustments when `vehicleMake` is specified, like below:

VideoStreamingParameter.java (**no change seems to be needed for Resolution and Scale**)

```java
public void update(VideoStreamingCapability capability, String vehicleMake) {
	...
    // For resolution and scale, the capability values should be taken, rather than taking parameters specified by developers.
    if (capability.getScale() != null) {
        scale = capability.getScale();
    }
    ImageResolution resolution = capability.getPreferredResolution();
    if (resolution != null) {

        if (vehicleMake != null) {
            if ((vehicleMake.contains("Ford") || vehicleMake.contains("Lincoln")) && ((resolution.getResolutionHeight() != null && resolution.getResolutionHeight() > 800) || (resolution.getResolutionWidth() != null && resolution.getResolutionWidth() > 800))) {
                scale = 1.0 / 0.75;
            }
        }

        if (resolution.getResolutionHeight() != null && resolution.getResolutionHeight() > 0) {
            this.resolution.setResolutionHeight((int) (resolution.getResolutionHeight() / scale));
        }
        if (resolution.getResolutionWidth() != null && resolution.getResolutionWidth() > 0) {
            this.resolution.setResolutionWidth((int) (resolution.getResolutionWidth() / scale));
        }
    }
	....
}
```

In the same method, however, bitrate and frame rate should take lower value approach, like below:

VideoStreamingParameter.java (**code snippet that needs to be changed**)

```java
public void update(VideoStreamingCapability capability, String vehicleMake) {
	...
    if (capability.getMaxBitrate() != null) {
        this.bitrate = Math.min(this.bitrate, capability.getMaxBitrate() * 1000);
    } // NOTE: the unit of maxBitrate in getSystemCapability is kbps.
	
	...
	if (capability.getPreferredFPS() != null) {
        this.frameRate = Math.min(this.frameRate, capability.getPreferredFPS());
    }
    ...
}
```

## Potential downsides

It should NOT be a downside by aligning bitrate and frame rate with `VideoStreamingCapability`, but bitrate and frame rate might be changed to lower values depending on the values of  `VideoStreamingCapability`.

## Impact on existing code

As mentioned in the previous section, bitrate and frame rate might be changed to lower values depending on the values of `VideoStreamingCapability`.

## Alternatives considered

The proposed solution takes care of the cases where specified bitrate and/or frame rate exceeds the capability value.
Other parameters (e.g. `VideoStreamingFormat`, `Interval`, `DisplayDensity`, etc.) are considered, but aligning bitrate and frame rate should suffice for now.
