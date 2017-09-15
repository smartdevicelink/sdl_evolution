# SDLCarWindow Video Projection Developer Interface* Proposal: [SDL-NNNN](NNNN-SDLScreen-SDLWindow-Projection.md)* Author: [David Switzer](https://github.com/davidswi)* Status: **Awaiting review*** Impacted Platforms: [iOS]## IntroductionThe iOS SDL proxy exposes the SDLCarWindow class to provide an easy-to-integrate developer interface to SDL video projection and the associated task of defining focusable and selectable UI elements. The SDLCarWindow attaches to the SDLStreamingMediaManager and exposes the SDLFocusableItemLocator, previously called the SDLInterfaceManager, described in the [SDLInterfaceManager](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0081-SDLInterfaceManager.md) proposal to allow the latter to determine the spatial arrangement of controls. The SDLFocusableItemLocator adopts the [SDLHapticHitTester](https://github.com/smartdevicelink/sdl_evolution/issues/270) protocol to enable correlation of SDLTouch events with the corresponding haptic region. In a later proposal, the SDLFocusableItemLocator will be extended to include focus and selection control on the handset, following the UIFocusEngine model from tvOS.## MotivationThis proposal builds on the SDLStreamingMediaManager to provide a convenient and simple programming model for SDL app developers to project and enable interaction with the appropriate subset of their UIKit, OpenGL and hybrid UIKit/OpenGL user interfaces.## Proposed solutionThe SDLLifecycleConfiguration class is extended to include a new nil-able property called carWindowConfiguration of type SDLCarWindowConfiguration. The SDLCarWindowConfiguration class is defined as follows:

```objc
@interface SDLCarWindowConfiguration : NSObject

@property (nonatomic, weak) id<SDLCarWindowDelegate> delegate;
@property (nonatomic, strong) UIViewController *rootViewController; 

@end
```When the property is non-nil, the SDLManager will manage the creation of SDLCarWindow interface instances based on the SDLLifecycleManager state. As it creates SDLCarWindow instances, it will call the app provided delegate, which is defined as follows:

```objc
@class SDLCarWindow;

typedef enum{
    SDLCarWindowStateDisconnected,
    SDLCarWindowStateReadyForStreaming,
    SDLCarWindowStateStreaming,
    SDLCarWindowStateStoppingStreaming
}SDLCarWindowState;

@protocol SDLCarWindowDelegate <NSObject>

- (void)carWindow:(SDLCarWindow *)window didChangeState:(SDLCarWindowState)state;
- (void)carWindow:(SDLCarWindow *)window didEncounterError:(NSError *)error;

@end
```The SDLCarWindow interface is defined as follows:

```objc
@interface SDLCarWindow : NSObject

-(instancetype)init;
-(instancetype)initWithStreamingMediaManager:(SDLStreamingMediaManager *)smm;


-(void)startVideoSessionWithRootViewController:(UIViewController *)vc startBlock:(SDLStreamingStartBlock)sb;

-(void)startTLSVideoSessionWithRootViewController:(UIViewController *)vc (SDLEncryptionFlag)encryptionFlag startBlock:(SDLStreamingEncryptionStartBlock)startBlock;

-(void)stopVideoSession;

@property(nonatomic, assign, readonly) SDLCarWindowState state;
@property(nonatomic, strong, readonly) SDLCarWindowCapabilities *capabilities;
@property(nonatomic, strong) SDLFocusableItemLocator *focusableItemLocator;

@end
```To determine the resolution and aspect ratio of the physical device represented by the SDLCarWindow instance, the app developer will examine the capabilities property of type SDLCarWindowCapabilities, defined as follows:

```objc
typedef enum{
    SDLCarWindowTypeCenterConsole,
    SDLCarWindowTypeInstrumentCluster,
    SDLCarWindowTypeRearSet
}SDLCarWindowType;

@interface SDLCarWindowCapabilities : NSObject

@property(nonatomic, readonly, assign) SDLCarWindowType type;
@property(nonatomic, readonly, assign) CGSize size;
@property(nonatomic, readonly, assign) CGFloat pixelAspectRatio;
@property(nonatomic, readyonly, assign) BOOL focusableItemLocatorEnabled;

@end
```For the near term, SDL will support only a single car window corresponding to the head unit display. In the future, there may be multiple screens available for video streaming and this design allows for such configurations by virtue of the delegate pattern and SDLCarWindowType property.If the head unit communicates that it implements a focus/select interaction model rather than direct touch, the focusableItemLocatorEnabled property will be set to YES. As part of setting up streaming of the rootViewController views, SDLCarWindow will pass the view hierarchy to the focusable item locator so it can determine and send the haptic spatial configuration to the head unit. 

The focusable item selector will be available to the app developer from the SDLCarWindow focusableItemSelector property. This allows the app developer to determine which view has been focused or selected using the viewForTouch SDLHapticHitTester method. 

For head units that allow the app to manage focus and selection, the SDLFocusableItemLocator provides the local logic to do so and interacts with the views through the [UIFocusEnvironment protocol](https://developer.apple.com/documentation/uikit/uifocusenvironment).

### Handling focusable UIButtons
The UIButton class returns NO for the UIFocusItem canBecomeFocused method unless it is being displayed on a CarPlay window. However, the SDLInterfaceManager relies on the canBecomeFocused property to determine which buttons should have spatial data sent to the head unit. To overcome this issue, the SDL proxy will implement the following category on UIButton that will return YES for canBecomeFocused.

```objc
@interface UIButton (SDLFocusable)

@property(nonatomic, readonly) BOOL canBecomeFocused;

@end
```## Potential downsidesIn choosing a projection API that differs from the standard UIScreen/UIWindow model for displaying content on an external screen, we are asking developers to adopt a model that is somewhat unfamiliar. However, it is also similar enough that the learning curve should be short and it avoids the possibility of strange side-effects due to subclassing UIKit controls.## Impact on existing codeThis proposal has no impact on existing video/audio streaming applications. It provides a new higher level interface that should improve developer productivity and a foundation for both touch and physical button focus/select interactions.## Alternatives consideredThis proposal provides no support for SDLCarWindow and SDLInterfaceManager encoding of pure OpenGL interfaces. Since all OpenGL content must be displayed within a UIView on iOS, it might be possible to intelligently encode video for the OpenGL layer(s) in SDLCarWindow. The SDLFocusableItemLocator could expose a CGRect collection property for defining the haptic spatial regions of an OpenGL UI.