# SDLCarWindow Video Projection Developer Interface

* Proposal: [SDL-0091](0091-SDLScreen-SDLWindow-Projection.md)
* Author: [Michael Pitts](mailto:mpitts@xevo.com)
* Status: **Awaiting review**
* Impacted Platforms: [iOS]

## Introduction

The iOS SDL framework implements an SDLCarWindow class to provide an easy-to-integrate developer interface to SDL video projection the associated task of defining focusable and selectable UI elements and the translation of remote touch events into standard UIKit actions. 

## Motivation

This proposal leverages SDLStreamingMediaManager and SDLTouchManager to provide a convenient and simple programming model for SDL app developers to remotely project and enable interaction with the appropriate subset of their UIKit, OpenGL and hybrid UIKit/OpenGL user interfaces.

## Proposed solution

SDLCarWindow hides the management of video projection and touch event handling from the developer. For apps which use only UIKit derived UI elements, no SDL specific code is necessary. 

**Application Interface**
The video projection interface is exposed to the application as a UIScreen object representing a virtual external display. This external view is separate from the view rendered on the device's LCD.

![Separate Displays](https://imgur.com/a/NAEKL "Separate Displays")

When SDL determines a video stream has been established, it creates a UIScreen object using the attributes of the SDL VPM screen. SDL will then post [UIScreenDidConnectNotification](https://developer.apple.com/documentation/uikit/uiscreendidconnectnotification). This informs the app of the new screen. SDLCarWindow watches for application calls to [-[UIScreen screens]](https://developer.apple.com/documentation/uikit/uiscreen/1617812-screens?language=objc). When called, the SDL managed UIScreen is added to the list of available screens. 

The app enables rendering to the external display using [standard Apple recommended steps](https://developer.apple.com/library/content/documentation/WindowsViews/Conceptual/WindowAndScreenGuide/UsingExternalDisplay/UsingExternalDisplay.html#//apple_ref/doc/uid/TP40012555-CH3-SW3). 
```objc
// When an external screen becomes available, attach SDLWindow storyboard.
// This renders into an offscreen window for SDL Video Projection Mode.
- (void) updateCarWindow:(NSNotification *)notification
{
    if (UIScreen.screens.count <= 1) {
        self.sdlWindow = nil;
        return;
    }

    UIScreen*           sdlScreen   = [UIScreen screens][1];
    UIStoryboard*       storyboard  = [UIStoryboard storyboardWithName:@"SDLWindow" bundle:[NSBundle mainBundle]];
    UIViewController*   vc          = [storyboard instantiateInitialViewController]; 

    vc.view.frame  = sdlScreen.bounds;
    vc.view.bounds = sdlScreen.bounds;

    self.sdlWindow = [[UIWindow alloc] initWithFrame:sdlScreen.bounds];
    self.sdlWindow.screen = sdlScreen;
    self.sdlWindow.rootViewController = vc;
    [self.sdlWindow addSubview:vc.view];
    [self.sdlWindow makeKeyAndVisible];
}
```
SDLCarWindow watches for calls to [-[UIWindow setScreen:]](https://developer.apple.com/documentation/uikit/uiwindow/1621597-screen?language=objc) and [-[UIWindow setRootViewController:]](https://developer.apple.com/documentation/uikit/uiwindow/1621581-rootviewcontroller?language=objc). These are used to create an instance if SDLCarWindow and attach it to the UIWindow. The UIWindow supplied by the application is used as the video projection source and touch event sink (key window).

**Video Projection**
SDLCarWindow uses the SDLStreamingMediaManager created by SDLLifecycleManager to manage video streaming.
SDLStreamingMediaManager is used to project the contents of the virtual external display. 

**Touch Events**
SDLCarWindow adopts the SDLHapticHitTester protocol to enable correlation of SDLTouch events with the corresponding haptic region. In a later proposal, SDL will be extended to include focus and selection control on the handset, following the UIFocusEngine model from tvOS.

Ownership of SDLTouchManager moves from SDLStreamingMediaLifecycleManager to SDLCarWindow. SDLStreamingMediaLifecycleManager links to SDLCarWindow. SDLCarWindow creates an instance of SDLTouchManager and sets itself as the delegate. In this configuration, touch events are delivered from SDLTouchManager to SDLCarWindow. 

SDLCarWindow handles SDL touch events by first giving the app a chance to handle them, then translating them directly into actions if the app doesn't handle them. By translating touch events into view actions within SDLCarWindow, no additional effort is required on the part of the app developer to handle touch events. This is provided for UIKit view types only. 

Currently supported types are: UIButton, UIControl, UINavigationViewController, UITableView, UICollectionViewCell, UIScrollView, UISearchBar, UITextField and UITabBarController. [1]

Touch events for custom views defined by the app must be handled by the app. This is acomplished using SDLTouchManager delegation. An app which adopts the SDLTouchManagerDelegate protocol will have the first chance at handling each touch event. If the app handles the event, it returns YES. A return value of NO instructs SDL to handle the event.

**SDLTouchManagerDelegate support in the application's view controller:**
```objc
- (BOOL)touchManager:(SDLTouchManager *)manager didReceiveSingleTapForView:(UIView*)view atPoint:(CGPoint)point {
    BOOL handled = NO;
    if ([view isEqual:self.customView] == YES) {
        [CustomAlertViewController displayText:@"'CustomView' was tapped" parent:self];
        handled = YES;
    }
    return handled;
}
```
**Maintaining the list of focusable and selectable UI elements**
SDLCarWindow interates the subviews of the VPM view and builds a list of focusable views. This list is sent to the core as SDLHapticData.

```objc
- (void)updateInterfaceLayout
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        // Compile the array of focusable views
        [self buildFocusableView:self.streamingViewController.view];

        // Extract hapticRects to send to SDL core
        NSMutableArray<SDLHapticRect*>* hapticRects = [NSMutableArray new];
        for (SDLFocusableView* fView in self.focusableViews) {
            [hapticRects addObject:fView.hapticRect];
        }

        // Build and send the request
        SDLHapticRectData* request = [[SDLHapticRectData alloc] initWithHapticRectData:hapticRects];

        // Avoid sending duplicate requests
        if ([request isEqual:self.prevHapticRectRequest]) {
            return;
        }
        _prevHapticRectRequest = request;
        
        if (request != nil) {
            [self.sdlManager sendRequest:request withResponseHandler:^( __kindof SDLRPCRequest * _Nullable request,
                                                                       __kindof SDLRPCResponse * _Nullable response,
                                                                       NSError * _Nullable error )
             {
                 if (error != nil) {
                     SDLLogW(@"SDLHapticData: %@", error);
                 } else {
                     SDLLogV(@"Received SDLHapticDataResponse from SDL");
                     SDLLogV(@"%@", response);
                 }
             }];
        }
    });
}

- (instancetype)buildFocusableView:(UIView*)view {
    if (_focusableViews == nil) {
        _focusableViews = [NSMutableArray<SDLFocusableView*> new];
    } else {
        [_focusableViews removeAllObjects];
    }
    NSMutableArray<SDLHapticRect*>* spatialData = [NSMutableArray new];
    [self focusableControlsInView:view result:spatialData];
    return self;
}

- (void)focusableControlsInView:(UIView*)view result:(NSMutableArray<SDLHapticRect*>*)result {
    // UIButtons returns canBecomeFocused==NO, unless idiom is carPlay or tvOS
    BOOL canBecomeFocused = ([view isKindOfClass:[UIButton class]] == YES) || (view.canBecomeFocused == YES);
    if ((canBecomeFocused == YES) &&
        (view.frame.size.width > 0) && (view.frame.size.height > 0) &&
        (view.isHidden == NO) && (view.alpha > 0.0) && (view.userInteractionEnabled == YES))
    {
        CGRect rect = [view convertRect:view.bounds toView:nil];
        SDLHapticRect* hapticRect = [[SDLHapticRect alloc] initWithId:((UInt32)(_focusableViews.count + 1))
                                                                   x:rect.origin.x
                                                                   y:rect.origin.y
                                                               width:rect.size.width
                                                              height:rect.size.height];
        [_focusableViews addObject:[[SDLFocusableView alloc] initWithView:view hapticRect:hapticRect]];
    }
    for (UIView* subview in view.subviews) { // Recursively walk subviews
        [self focusableControlsInView:subview result:result];
    }
}


```

SDLCarWindow automatically handles view layout updates by inserting a listener into -[[CALayer layoutSublayers]](https://developer.apple.com/documentation/quartzcore/calayer/1410935-layoutsublayers?language=objc). 

```objc
//==========================================================================================
// Update focus regions whenever the layout has changed
// https://developer.apple.com/documentation/quartzcore/calayer/1410935-layoutsublayers
//==========================================================================================
static void (*pfnCALayer_layoutSublayers)(CALayer*, SEL) = nil;
static void CALayer_layoutSublayers(CALayer* layer, SEL methodName)
{
    if (pfnCALayer_layoutSublayers) {
        pfnCALayer_layoutSublayers(layer, methodName);
    }
    SDLCarWindow* carWindowForLayer = objc_getAssociatedObject(layer, KEY_CARWINDOW);
    if (([carWindowForLayer isKindOfClass:[SDLCarWindow class]] == YES) &&
        ([carWindowForLayer.sdlLayer isEqual:layer] == YES)) {
        [carWindowForLayer updateInterfaceLayout];
    }
}
```
## Benefits
* The projected video view is separate from the view on the device's LCD.
* Separate views for device and head unit allow for used of device while attached and projecting. (Apps which do not use the lock screen)
* Video projection is achieved using documented Apple procedures for external display support. 
* The app developer doesn't need to write any code to handle touch events. From the app's perpective, view actions are triggered identically as if UIKit had fired them.
* The app developer has the option to handle touch events in the app should they wish to do so. (Custom views)
* Touch event behavior of the iOS proxy remains consistent across all apps using the same version of the SDL framework. 
* Features and fixes propogate to all apps.

## Potential downsides
* SDLCarWindow uses swizzling. However all methods are public and have not changed since iOS 3.2 (most since iOS 2.0).
* Unforeseen challenges may arise when implementing action triggers for other UIKit types. This can be mitigated by building upon existing and tested Xevo implementations [1]. 

## Impact on existing code
* Apps adopting SDLTouchManagerDelegate will need to return a BOOL instead of void for delegate methods.
* SDLTouchManager moves from SDLStreamingMediaLifecycleManager to SDLCarWindow
* SDLCarWindow deprecates SDLHapticManager. Functionality previously found in SDLHapticManager has been moved into SDLCarWindow.  

## Alternatives considered
* Force the each application to handle touch events using a delegate. The developer then has to handle the translation of a view and a point into some sort of desired action. Touch management will be different for each app which will lead to inconsistency amongst SDL apps, which in-turn will lead to user dismay. 

## References
[1] Xevo production code
