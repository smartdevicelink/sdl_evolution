# iOS ReplayKit Streaming

* Proposal: [SDL-0215](0215-ios-replaykit-streaming.md)
* Author: [Satbir Tanda](https://github.com/satbirtanda)
* Status: **Awaiting review**
* Impacted Platforms: [iOS]

## Introduction

This proposal aims to optimize how the car window API captures the screen in the iOS Framework using ReplayKit.

## Motivation

This comes in wake of the fact that there is 30-70% CPU usage on navigation apps which causes the phone to heat up excessively and deplete battery quickly. Also, Apple has recently announced the deprecating of OpenGL in favor of its GPU optimized graphics library - Metal. Metal objects aren't being captured with the current method of the screen capturing.

## Proposed solution

SDLCarWindow.m relies heavily on ```[self.rootViewController.view drawViewHierarchyInRect:bounds afterScreenUpdates:YES];``` (30-70% CPU usage).  However, ReplayKit has a screen recording object that implements an efficient capture (1%-30% CPU Usage).  Normally this framework is used to stream iOS games to services like Twitch or Youtube.


```objc
#import <ReplayKit/ReplayKit.h>

- (void)syncFrame {
    if (!self.streamManager.isVideoConnected || self.streamManager.isVideoStreamingPaused) {
        return;
    }
    
    if (self.isLockScreenPresenting || self.isLockScreenDismissing) {
        SDLLogD(@"Paused CarWindow, lock screen moving");
        return;
    }
    
    CGRect bounds = self.rootViewController.view.bounds;
    
    if (@available(iOS 11.0, *) && self.allowReplayKit) {
        if (![[RPScreenRecorder sharedRecorder] isRecording]) {
            [[RPScreenRecorder sharedRecorder] startCaptureWithHandler:^(CMSampleBufferRef  _Nonnull sampleBuffer, RPSampleBufferType bufferType, NSError * _Nullable error) {
                if (error) {
                    SDLLogD(@"Video stream error %@", error.debugDescription);
                } else {
                    [self.streamManager sendVideoData:CMSampleBufferGetImageBuffer(sampleBuffer)];
                }
            } completionHandler:^(NSError * _Nullable error) {
                if (error) {
                    SDLLogD(@"Video stream error %@", error.debugDescription);
                }
            }];
        }
    } else {
        // Fallback on earlier versions
        UIGraphicsBeginImageContextWithOptions(bounds.size, YES, 1.0f);
        switch (self.renderingType) {
            case SDLCarWindowRenderingTypeLayer: {
                [self.rootViewController.view.layer renderInContext:UIGraphicsGetCurrentContext()];
            } break;
            case SDLCarWindowRenderingTypeViewAfterScreenUpdates: {
                [self.rootViewController.view drawViewHierarchyInRect:bounds afterScreenUpdates:YES];
            } break;
            case SDLCarWindowRenderingTypeViewBeforeScreenUpdates: {
                [self.rootViewController.view drawViewHierarchyInRect:bounds afterScreenUpdates:NO];
            } break;
        }
        
        UIImage *screenshot = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        CGImageRef imageRef = screenshot.CGImage;
        CVPixelBufferRef pixelBuffer = [self.class sdl_pixelBufferForImageRef:imageRef usingPool:self.streamManager.pixelBufferPool];
        if (pixelBuffer != nil) {
            [self.streamManager sendVideoData:pixelBuffer];
            CVPixelBufferRelease(pixelBuffer);
        }
    };
    
}
```

## Potential downsides

* ReplayKit displays an alert asking the user to allow the app to record the screen.  However, after the user taps this once, it will only ask again on a new app launch after a certain time window
* The app would need to support horizontal orientation otherwise the screen would be captured in portrait
* Must be on iOS 11 or greater

## Impact on existing code

* No changes to the Android library
* The iOS library would need to alter it's code to add a flag to pick between ReplayKit streaming or the current method of streaming (possibly via the ```SDLStreamingMediaConfiguration``` ).  Additionally, it would need to alter SDLCarWindow.m's ```syncFrame``` method that causes the jump in CPU usage (which can be seen via the CPU profiling instrument while running an SDL enabled navigation app by filtering out system methods).  The app would need to be forced in a horizontal orientation.

## Alternatives considered

* There are private methods that can capture the screen very efficiently, however, implementing these can get your app removed from the app store or rejected from submission by Apple.

* Nothing beyond keeping the original design.

## Update

* After testing the SDL Lock Screen appearance, ReplayKit does not take in a root view controller to display; it seems to record the current window that is displayed.  Because the SDL Lockscreen shows up on another window, it does not seem to impede the recording of the original window.
* Attached in the proposal issue is an app that can run as an example - there still needs to be code that resizes the pixel buffer (it needs to be determined if it is possible at all, the snippet provided did not alter the stream).
* The app does not need to be landscaped if the pixel sizing issue is solved, however, then it would also need to make sure the root-view controller does not resize on video streaming.
* It has been determined the replay kit stream also contains audio data that can be used to stream audio to the Head Unit exactly like a media app. This would mean the developer would no longer need to send PCM audio files to SDL (they can play audio as they would in their app and it should carry over).
* Tests would need to be done with iPhone XS, X, XS Max, XR - when testing these phones, there has been notable crashes.
