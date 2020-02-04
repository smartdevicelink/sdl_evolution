# Add preferred FPS to VideoStreamingCapability

* Proposal: [SDL-0274](0274-add-preferred-FPS.md)
* Author: [Shinichi Watanabe](https://github.com/shiniwat)
* Status: **Accepted with Revisions**
* Impacted Platforms: [Core / iOS / Java Suite / JavaScript Suite / RPC]

## Introduction

This proposal extends SDL video streaming feature by adding preferred FPS to `VideoStreamingCapability`, so that frame rate of video streaming can be adjusted per OEM.

## Motivation

Currently, SDL video streaming refers to `VideoStreamingCapability` and mobile libraries respect for preferred resolution, maximum bitrate, video format, etc.
However frame rate of video streaming totally depends on mobile applications, and some OEM's head unit may not work well for high frame rate, such as 60 fps.
This proposal allows head units to specify the preferred FPS, so that mobile library can refer to the specified value. 

## Proposed solution

The proposed solution is to add preferred FPS to `VideoStreamingCapability`. On a head unit, preferred FPS can vary by screen resolution; i.e. frame rate can be higher for lower resolution, but the preferred FPS value can be used for the case where screen resolution is the preferred resolution value.
Mobile proxies should respect the preferred FPS value, just as they do for preferred resolution, maximum bitrate, etc.

## Detailed design

### RPC change (Mobile_API and HMI_API)

Add `preferredFPS` to `VideoStreamingCapability` struct in both APIs.

```xml
    <struct name="VideoStreamingCapability" since="4.5">
        <description>Contains information about this system's video streaming capabilities.</description>
        ...
        <!-- new param -->
        <param name="preferredFPS" type="Integer" minvalue="0" maxvalue="2147483647" mandatory="false">
            <description>Preferred frame rate per second. Mobile application should take this value into account for capturing and encoding video frame, but mobile application should also take care of the case where mobile device's hardware performance is constrained. It is up to mobile application to determine the actual frame rate.</description>
        </param>
    </struct>
```

Like other parameters in `VideoStreamingCapability`, `preferredFPS` should be returned in `GetSystemCapability` RPC response.

### iOS mobile proxy changes

Extend `SDLVideoStreamingCapability` class to have `preferredFPS` property:

SDLVideoStreamingCapability.h:

```objc
/**
 *  Preferred frame rate (assuming the case where resolution is the same as preferredResolution)
 *  Optional
 */
@property (nullable, strong, nonatomic) NSNumber<SDLInt> *preferredFPS;

```

SDLVideoStreamingCapability.m:
```objc
- (void)setPreferredFPS:(nullable NSNumber<SDLInt> *)preferredFPS {
    [store sdl_setObject:preferredFPS forName:SDLRPCParameterNamePreferredFPS];
}

- (nullable NSNumber<SDLInt> *)preferredFPS {
    return [store sdl_objectForName:SDLRPCParameterNamePreferredFPS ofClass:NSNumber.class error:nil];
}
```

And then, modify `SDLStreamingVideoLifecycleManager#didEnterStateVideoStreamStarting`, so that `preferredFPS` value would be taken into account:
```objc
static NSUInteger const defaultFrameRate = 15;

- (void)didEnterStateVideoStreamStarting {
    ...
    if (capability != nil) {
        NSUInteger  preferredFPS = (capability.preferredFPS.integerValue == 0) ? defaultFrameRate : capability.preferredFPS.integerValue;
        weakSelf.videoEncoderSettings[(__bridge NSString *)kVTCompressionPropertyKey_ExpectedFrameRate] = @(preferredFPS);
        ...
    } else {
        ...
        weakSelf.videoEncoderSettings[(__bridge NSString *)kVTCompressionPropertyKey_ExpectedFrameRate] = @(defaultFrameRate);
    }

}
```

Later part in the same method (`didEnterStateVideoStreamStarting`), current `videoEncoderSettings` are overwritten by `customEncoderSettings`.

However, for frame rate, we should take lower value approach if frame rate in customEncoderSettings is higher than preferred FPS, like below:
```objc
        // Apply customEncoderSettings here. Note that value from HMI (such as maxBitrate) will be overwritten by custom settings.
        for (id key in self.customEncoderSettings.keyEnumerator) {
            if ([(NSString *)key isEqualToString:(__bridge NSString *)kVTCompressionPropertyKey_ExpectedFrameRate] == YES) {
                // do NOT override frame rate if custom setting's frame rate is higher than current setting's one, which now refers to preferredFPS if specified in capability.
                if ([self.customEncoderSettings valueForKey:key] < self.videoEncoderSettings[key]) {
                    self.videoEncoderSettings[key] = [self.customEncoderSettings valueForKey:key];
                }
            } else {
                self.videoEncoderSettings[key] = [self.customEncoderSettings valueForKey:key];
            }
        }
```

### iOS mobile proxy consideration

A frame rate of iOS SDL application highly depends on how the application captures the video data.

If an application uses combination of `SDLCarWindow` and `SDLStreamingVideoLifecycleManager`, above change should take account of
1) `videoEncoderSettings` used in `SDLStreamingVideoLifecycleManager`,
2) capture rate of `CADisplayLink#preferredFramePerSecond` (available in iOS10 or higher)

So that should suffice the needs.

If an application uses `AVCaptureDevice` directly, and does not rely on `SDLStreamingVideoLifecycleManager` at all, the frame rate must fit into `AVFrameRateRange` in `AVCaptureDevice.format`.

Regarding `kVTCompressionPropertyKey_ExpectedFrameRate` in `videoEncoderSettings`, however, [iOS documentation](https://developer.apple.com/documentation/videotoolbox/kvtcompressionpropertykey_expectedframerate) says, “provided as a hint to the video encoder” and “The actual frame rate depends on frame durations and may vary.”
Therefore, developers must make sure taking account of `preferredFPS` value for capturing video frames (especially if the app does not use `SDLCarWindow`), as well as configuring `videoEncoderSettings`.

### Android mobile proxy consideration

Android Java Suite library introduces the combination of `VirtualDisplay` and `MediaEncoder` to capture a `SdlRemoteDisplay` class and encode the video stream.
When encoding the video frame, a frame rate can be specified by `MediaCodec#configure`, but [Android documentation](https://developer.android.com/reference/android/media/MediaFormat.html#KEY_FRAME_RATE) says,

"For video encoders this value corresponds to the intended frame rate, although encoders are expected to support variable frame rate based on MediaCodec.BufferInfo#presentationTimeUs".

Therefore situation would be the same as iOS; i.e. mobile developer must take care of actual frame rate.

The actual frame rate of `MediaEncoder` depends on the frequency of input surface's update in `VirtualDisplay`, and varies on the application's (`SdlRemoteDisplay`'s) content.

For instance, if the `VirtualDisplay` gets updated aggressively, the frame rate would be larger than 60 fps, while in idle time, the frame rate will be something like 20 fps.

This issue will be addressed by another proposal later.

## Potential Downsides

Adding an optional parameter to `VideoStreamingCapability` has no downside. It will be specified by head unit, but how it is used is still up to the mobile application.

## Impact on existing code

This proposal has no breaking change, so there should be no impact on existing code. As mentioned, it is still up to the mobile application to determine how the additional parameter (`preferredFPS`) is used.

## Alternatives considered

As well as other video streaming parameters, `preferredFPS` can be added to other RPCs, like `StartStream`, `SetVideoConfig`, etc.
But it makes more sense to handle `preferredFPS` parameter in the same way as bitrate, screen resolution, etc.
