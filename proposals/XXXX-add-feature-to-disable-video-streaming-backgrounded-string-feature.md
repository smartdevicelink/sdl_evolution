# Add Feature to Disable "Video Streaming Backgrounded String" Feature

* Proposal: [SDL-NNNN](XXXX-add-feature-to-disable-video-streaming-backgrounded-string-feature.md)
* Author: [t-yoshii](https://github.com/smartdevicelink)
* Status: **Awaiting review**
* Impacted Platforms: iOS

## Introduction
Add an option for app developer to disable the "Video Streaming Backgrounded String (SDL-0118)" feature.

## Motivation
"Video Streaming Backgrounded String" feature is introduced by SDL-0118. Currently, on iOS, (as of sdl_ios v6.2) this string is always shown when video streaming is suspended and cannot be disabled. (On Android, SDL-0118 is not implemented because Android can stream even if app is backgrounded on HS.)

On some HMIs, rendered video picture will disappear after HS stops sending video stream and SDL Core sends OnVideoDataStreaming(false) to HMI. In this case, this string is only shown during video streaming timeout duration (default 3000 msec). This is not user-friendly and is not good from the point of driver distraction because the display contents frequently change in a short period of time (video streaming => message string => another screen).

Also, HMI can notify user that video is not available in another way, eg HU Native's dialog, other template etc, because HMI can detect that video streaming is suspended by OnVideoStreaming notification from SDL Core. So, on such HMI, it would be better to be able to delegate the notification method to HU side.

Therefore, it will be better to offer an option to app developer to disable to show "Video Streaming Backgrounded String".


## Proposed solution
Add parameter `sendVideoBackgroundedString` to `SDLStreamingMediaConfiguration` class to disable the "video streaming backgrounded string (SDL-0118)" feature. The default value of this parameter is `true` and "Video Streaming Backgrounded String" will be sent (Current behavior as of sdl_ios v6.2). If this parameter is set to `false`, `backgroundingPixelBuffer` will not be sent.


## Potential downsides

App developer must be careful which solution to use, default "Video Streaming Backgrounded String" or other by checking HU make/model/trim in RAI response. However, as mentioned above, the default behavior will be *send the backgrounded string*, so, if app developer skips checking, nothing will be changed from sdl_ios v6.2.


## Impact on existing code

Minor API changes are required in `SDLStreamingMediaConfiguration` and `SDLVideoLifecycleManager` in sdl_ios.

## Alternatives considered

1. Add a dedicated field in RAI response which indicates whether the HMI can preserve rendered video on the screen even after OnVideoDataStreaming(false), thus "Video Streaming Backgrounded String" is effective. This solution is better because OEM can control the behavior, however, this requires major API change and cannot cover old version of SDL Core.

2. Enforce HMI not to hide rendered picture while VPM app is in FULL. However, this may limit the design of HMI a lot. For example, some HMIs may not be able to hold a rendered picture for a long time, or, must release a video rendering resource when it is not in use, because of hardware limitation or resource contention by other components.
