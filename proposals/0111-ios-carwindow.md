# SDLCarWindow

* Proposal: [SDL-0111](0111-ios-carwindow.md)
* Author: [Joel Fischer](https://github.com/joeljfischer/)
* Status: **In Review**
* Impacted Platforms: iOS

## Introduction

This proposal seeks to provide an interface for video streaming developers by which they may set their phone UI window and have it automatically streamed.

## Motivation

Our current methods of projecting app UI via SDL is video streaming for `NAVIGATION` and `PROJECTION` apps. While this was originally designed with OpenGL-based apps in mind, we ought to help support `UIKit` based applications. To do so, we will provide a set of APIs to take `UIView` based views and send a resulting video stream to the head unit.

## Proposed solution

### Car Window
The proposed solution is called `SDLCarWindow`. This API will take whatever is within a `UIViewController` subclass, transform that into video, and send it on to the `SDLStreamingMediaManager` which will send the video stream data to the head unit.

The approach taken by this proposal is to screenshot the UI, turn that screenshot into a `CVPixelBufferRef` and transform that into a video frame which is then sent to the head unit as a video stream.

`SDLCarWindow` will not subclass `UIWindow`, but will be a custom object subclassing `NSObject`. It will have the ability to set a `rootViewController` which can be the root of the ordinary `UIWindow` but does not have to be.

The final interface is very simple:

```objc
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class SDLManager;

@interface SDLCarWindow : NSObject

/**
 *  View Controller that will be streamed.
 */
@property (strong, nonatomic, nullable) UIViewController *rootViewController;

@end

NS_ASSUME_NONNULL_END
```

There will be a deprecation change to `SDLStreamingMediaConfiguration`, the property `@property (weak, nonatomic, nullable) UIWindow *window;` will change to `@property (strong, nonatomic, nullable) UIViewController *rootViewController`, this will be passed to the `SDLCarWindow` and `SDLFocusableItemLocator`. The old property will be deprecated by automatically passing the `rootViewController` of the window to the `rootViewController` property.

An additional property will be added to the configuration `@property (assign, nonatomic) BOOL disableAutomaticVideoStream`. This will prevent the assigned `UIViewController` from automatically being streamed after setup (for example, if the developer has an all-OpenGL UI and wishes to stream it more effectively than is possible via screenshotting). This will be `YES` if the developer doesn't set the view controller by default, and `NO` if they do. If the developer wants to set the view controller but have car window disabled – in order to enable the focusable item manager – they can manually disable the automatic video stream boolean.

`SDLFocusableItemLocatorType` will also have a deprecation, with `- (instancetype)initWithWindow:(UIWindow *)window connectionManager:(id<SDLConnectionManagerType>)connectionManager;` changing to receive a view controller as well. It will also now expose a writable view controller property so that the developer and CarWindow can update the active view controller if necessary.

### Updates to the SDLLockScreenViewController and SDLLockScreenManager
Due to the way CarWindow is structured and the need to present the lock screen over objects such as alerts, we should change the current lock screen from a view controller presented modally into a `UIWindow` overtop of the existing `UIWindow`. This lock window will take a screenshot of the current UI, place that screenshot into the lock `UIWindow`, place the window over the content `UIWindow`, then present the lock screen.

Most public interfaces will not have to change for this, but `NSNotifications` may be added that will be fired around the presenting and dismissal of the lock screen view controller to give the `SDLStreamingMediaManager` the ability to stop streaming for a short time while that change is occurring.

## Potential downsides

The primary potential downside of this approach is that the screenshotting approach takes quite a bit of CPU. Alternative #1 is significantly more CPU & energy efficient, but has its own downsides.

## Impact on existing code

This will be a minor version change and will not affect any existing applications. Some code will be deprecated and should eventually be removed.

## Alternatives considered

1. Use [RPScreenRecorder](https://developer.apple.com/documentation/replaykit/rpscreenrecorder) API method `startCaptureWithHandler:completionHandler:`, which will give us a `CMSampleBuffer` at a constant framerate. While this is a significant performance and energy win, it has some major downsides:
  * Requires the UI to be displayed on the screen of the app. This means a lock screen is impossible, and the resolution is going to be incorrect.
  * iOS 11 only
  * Requires the user to press "OK" on an alert on the screen before streaming, every time (unless the time between streaming is less than 7 minutes).
