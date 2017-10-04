# SDLCarWindow Video Projection Developer Interface

* Proposal: [SDL-0091](0091-SDLScreen-SDLWindow-Projection.md)
* Author: [Michael Pitts](https://github.com/GNXClone)
* Status: **Returned for Revisions**
* Impacted Platforms: [iOS]

## Introduction

The iOS SDL proxy exposes the SDLCarWindow class to provide an easy-to-integrate developer interface to SDL video projection. The SDLCarWindow attaches to the SDLStreamingMediaManager. 

## Motivation

This proposal builds on the SDLStreamingMediaManager to provide a convenient and simple programming model for SDL app developers to project their user interface.

## Proposed solution

The SDLStreamingMediaManager class is extended to include a car window property:

```objc  
@interface SDLStreamingMediaManager : NSObject <SDLProtocolListener>
:
:
/**
 *  Touch Manager responsible for providing touch event notifications.
 */
@property (nonatomic, strong, readonly) SDLTouchManager *touchManager;

/**
* Car Window instance responsible for providing video projection.
* /
@property (nonatomic, strong, readonly) SDLCarWindow *carWindow;
:
:
```
The SDLCarWindow interface is defined as follows:

```objc
@interface SDLCarWindow : NSObject

/**
 *  View Controller that will be streamed.
 */
@property (strong, nonatomic, nullable) UIViewController *streamingViewController;

-(id)initWithStreamingMediaManager:(SDLStreamingMediaManager*)streamingMediaManager;

@end
```
 
The app developer uses SDLLifecycleConfiguration to set the app type to SDLAppHMITypeNavigation and to set the root view to project. 

```objc
    // Enable VPM
    [lifecycleConfig setAppType:SDLAppHMITypeNavigation];
    // Attach the view controller we want streamed over VPM
    [lifecycleConfig setStreamingViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
```

The reason the root view is set here instead of assigning it directly to streamingViewController property is because SDLHapticManager looks for the window early on in the SDL setup process. The window must be available to SDL by the time the app calls SDLManager's initWithConfiguration:delegate: method.

The SDLCarWindow class will also include the previously app-level common logic that interacts with the existing SDLStreamingMediaManager class to stream pixel buffers and receive audio data. It relies on the helper class SDLStreamingMediaLifecycleManager to ensure streaming is allowed and manage the streaming state.

## Potential downsides

In choosing a projection API that differs from the standard UIScreen/UIWindow model for displaying content on an external screen, we are asking developers to adopt a model that is somewhat unfamiliar. 

## Impact on existing code

This proposal has no impact on existing video/audio streaming applications. It provides a new higher level interface that should improve developer productivity and a foundation for video projection.

## Alternatives considered

This proposal provides no support for SDLCarWindow encoding of pure OpenGL interfaces. Since all OpenGL content must be displayed within a UIView on iOS, it might be possible to intelligently encode video for the OpenGL layer(s) in SDLCarWindow. \

