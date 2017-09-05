# SDLCarWindow Video Projection Developer Interface* Proposal: [SDL-NNNN](NNNN-SDLScreen-SDLWindow-Projection.md)* Author: [David Switzer](https://github.com/davidswi)* Status: **Awaiting review*** Impacted Platforms: [iOS]## IntroductionThe iOS SDL proxy exposes the SDLCarWindow class to provide an easy-to-integrate developer interface to SDL video projection and the associated task of defining focusable and selectable UI elements. The SDLCarWindow attaches to the SDLStreamingMediaManager and exposes the SDLInterfaceManager described in the [SDLInterfaceManager](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0081-SDLInterfaceManager.md) proposal to allow the latter to determine the spatial arrangement of controls. The SDLInterfaceManager adopts the [SDLHapticHitTester](https://github.com/smartdevicelink/sdl_evolution/issues/270) protocol to enable correlation of SDLTouch events with the corresponding haptic region. In a later proposal, the SDLInterfaceManager will be extended to include focus and selection control on the handset, following the UIFocusEngine model from tvOS.## MotivationThis proposal builds on the SDLStreamingMediaManager to provide a convenient and simple programming model for SDL app developers to project and enable interaction with the appropriate subset of their UIKit, OpenGL and hybrid UIKit/OpenGL user interfaces.## Proposed solutionThe SDLStreamingMediaManager class is extended to include a car window property:```objc  @interface SDLStreamingMediaManager : NSObject <SDLProtocolListener>
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
```The SDLCarWindow interface is defined as follows:

```objc
@interface SDLCarWindow : NSObject

/**
 *  View Controller that will be streamed.
 */
@property (strong, nonatomic, nullable) UIViewController *streamingViewController;

/**
 * Dimensions of the target in-car screen
 */
@property (assign, nonatomic, readonly) CGSize screenDimensions;

/**
 * SDLInterfaceManager instance for head-unit focusing and selection
 */
@property (strong, nonatomic) SDLInterfaceManager *interfaceManager;

@end
``` The app developer uses the carWindow property on the streaming media manager to obtain the SDLCarWindow instance. Then to begin capture, encoding and streaming of view hierarchy video frames, the developer assigns the root view controller to be projected to the streamingViewController property on the car window instance.If the head unit communicates that it handles focus and selection, the SDLInterfaceManager will use the BOOL appHandlesTouches property on the SDLStreamingMediaConfiguration class to determine whether to iterate over the views contained in the SDLCarWindow streamingViewController property to determine and send the haptic spatial configuration to the head unit. It will also return nil from the viewForTouch SDLHapticHitTester method. Otherwise, it will attempt to find the view that matches the passed-in SDLTouch object.

### Handling focusable UIButtons
The UIButton class returns NO for the UIFocusItem canBecomeFocused method unless it is being displayed on a CarPlay window. However, the SDLInterfaceManager relies on the canBecomeFocused property to determine which buttons should have spatial data sent to the head unit. To overcome this issue, the SDL proxy will implement the following category on UIButton that will return YES for canBecomeFocused.

```objc
@interface UIButton (SDLFocusable)

@property(nonatomic, readonly) BOOL canBecomeFocused;

@end
```

For head units that allow the app to manage focus and selection, the SDLInterfaceManager provides the local logic to do so and interacts with the views through the [UIFocusEnvironment protocol](https://developer.apple.com/documentation/uikit/uifocusenvironment). The SDLCarWindow class will also include the previously app-level common logic that interacts with the existing SDLStreamingMediaManager class to stream pixel buffers and receive audio data. It relies on the helper class SDLStreamingMediaLifecycleManager to ensure streaming is allowed and manage the streaming state.```objcextern NSString *const SDLVideoStreamDidStartNotification;extern NSString *const SDLVideoStreamDidStopNotification;extern NSString *const SDLAudioStreamDidStartNotification;extern NSString *const SDLAudioStreamDidStopNotification;@class SDLManager;@interface SDLStreamingMediaLifecycleManager : NSObject@property (nonatomic, weak, nullable) SDLManager *sdlManager;@property (nonatomic, assign, readonly, getter=isVideoConnected) BOOL videoConnected;@property (nonatomic, assign, readonly, getter=isAudioConnected) BOOL audioConnected;@property (nonatomic, assign, readonly, getter=isVideoStreamingAllowed) BOOL videoStreamingAllowed;@end```## Potential downsidesIn choosing a projection API that differs from the standard UIScreen/UIWindow model for displaying content on an external screen, we are asking developers to adopt a model that is somewhat unfamiliar. However, it is also similar enough that the learning curve should be short and it avoids the possibility of strange side-effects due to subclassing UIKit controls.## Impact on existing codeThis proposal has no impact on existing video/audio streaming applications. It provides a new higher level interface that should improve developer productivity and a foundation for both touch and physical button focus/select interactions.## Alternatives consideredThis proposal provides no support for SDLCarWindow and SDLInterfaceManager encoding of pure OpenGL interfaces. Since all OpenGL content must be displayed within a UIView on iOS, it might be possible to intelligently encode video for the OpenGL layer(s) in SDLCarWindow. The SDLInterfaceManager could expose a CGRect collection property for defining the haptic spatial regions of an OpenGL UI.