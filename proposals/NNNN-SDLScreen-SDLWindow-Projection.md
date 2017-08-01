```
# SDLScreen/SDLWindow Video Projection Developer Interface

* Proposal: [SDL-NNNN](NNNN-SDLScreen-SDLWindow-Projection.md)
* Author: [David Switzer](https://github.com/davidswi)
* Status: **Awaiting review**
* Impacted Platforms: [iOS]

## Introduction

The iOS SDL proxy exposes SDLScreen and SDLWindow subclasses of UIScreen and UIWindow to provide a familiar developer interface to SDL video projection. The SDLScreen attaches to the SDLInterfaceManager described in the [SDLInterfaceManager](https://github.com/Toyota-BSalahat/sdl_evolution/tree/SDLInterfaceManager/proposals) proposal to allow the latter to determine the spatial arrangement of controls. In a later proposal, the SDLInterfaceManager will be extended to include focus and selection control on the handset, following the UIFocusEngine model from tvOS.

## Motivation

Apple provides a well-established programming model for leveraging external displays. This proposal adapts the Apple model for in-car scenarios.

## Proposed solution

In keeping with the Apple programming model and guidelines for [external display usage] (https://developer.apple.com/library/content/documentation/WindowsViews/Conceptual/WindowAndScreenGuide/UsingExternalDisplay/UsingExternalDisplay.html), the iOS proxy defines an SDLScreen subclass of UIScreen and a category on UIScreen that returns a collection of SDLScreens:
 
typedef enum{
    SDLScreenTypeInstrumentCluster,
    SDLScreenTypeCenterConsole,
    SDLScreenTypeRearSeat
} SDLScreenType;
 
@interface SDLScreen : UIScreen
 
- (instancetype)initWithManager:(SDLManager *)manager;
- (CGRect)bounds;
 
@property(nonatomic, readonly) SDLScreenType type;
 
@end
 
 
@interface UIScreen(SDLScreen)
 
+ (NSArray<SDLScreen *> *)inVehicleScreens:(SDLManager *)manager;
 
@end
 
The app developer uses the inVehicleScreens class method to obtain a collection of SDLScreen instances representing the SDL VPM-capable displays in the vehicle. Then to begin capture, encoding and streaming of view hierarchy video frames, processes, the developer instantiates the SDLWindow subclass of UIWindow, attaches it to the SDLScreen and assigns the view controller to be projected to the rootViewController property.
 
@interface SDLWindow : UIWindow
 
- (instancetype)initWithFrame:(CGRect)frame;
 
@property(nonatomic, strong) SDLScreen *inVehicleScreen;
@property(nonatomic, strong) UIViewController *rootViewController;
 
@end
 
The SDLManager attached to the inVehicleScreen instantiates an SDLInterfaceManager instance. If the head unit communicates that it handles focus and selection, the SDLInterfaeManager will operate on the SDLWindow root view controller to populate the focusableViews property. For HUs that allow the app to manage focus and selection, the SDLInterfaceManager provides the local logic to do so and interacts with the views through the [UIFocusEnvironment protocol] (https://developer.apple.com/documentation/uikit/uifocusenvironment).
 
The SDLWindow class will also include the previously app-level common logic that interacts with the existing SDLStreamingMediaManager class to stream pixel buffers and receive audio data. It relies on the helper class SDLStreamingMediaLifecycleManager to ensure streaming is allowed and manage the streaming state.

extern NSString *const SDLVideoStreamDidStartNotification;
extern NSString *const SDLVideoStreamDidStopNotification;

extern NSString *const SDLAudioStreamDidStartNotification;
extern NSString *const SDLAudioStreamDidStopNotification;

@class SDLManager;

@interface SDLStreamingMediaLifecycleManager : NSObject

@property (nonatomic, weak, nullable) SDLManager *sdlManager;

@property (nonatomic, assign, readonly, getter=isVideoConnected) BOOL videoConnected;
@property (nonatomic, assign, readonly, getter=isAudioConnected) BOOL audioConnected;

@property (nonatomic, assign, readonly, getter=isVideoStreamingAllowed) BOOL videoStreamingAllowed;

@end

## Potential downsides

In subclassing UIScreen and UIWindow, there may be undocumented and unforseen interactions between iOS and the subclassed objects. As new iOS versions come out, bugs might emerge due to changes Apple makes behind the scenes of these public interfaces.

## Impact on existing code

This proposal has no impact on existing video/audio streaming applications. It provides a new higher level interface that should improve developer productivity and a foundation for both touch and physical button focus/select interactions.

## Alternatives considered

The SDLScreen and SDLWindow classes could be derived from NSObject instead. This may be preferable.
```
