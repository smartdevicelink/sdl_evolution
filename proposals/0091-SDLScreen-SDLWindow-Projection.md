# SDLCarWindow Video Projection Developer Interface

* Proposal: [SDL-0091](0091-SDLScreen-SDLWindow-Projection.md)
* Author: [Michael Pitts](mailto:mpitts@xevo.com)
* Status: **Awaiting review**
* Impacted Platforms: [iOS]

## Introduction

The iOS SDL framework implements an SDLCarWindow class to provide an easy-to-integrate developer interface to SDL video projection the associated task of defining focusable and selectable UI elements and the translation of remote touch events into standard UIKit actions. 

## Motivation

Provide a convenient and simple programming model for SDL app developers to remotely project and enable interaction with the appropriate subset of their UIKit, OpenGL and hybrid UIKit/OpenGL user interfaces. [1]

## Proposed solution

SDLCarWindow leverages SDLStreamingMediaManager and SDLTouchManager to hide the management of video projection and touch event handling from the app developer. For apps which use only UIKit derived UI elements, no SDL specific code is necessary. [1]

SDLTouchManager is embellished to invoke view actions based on remote touch events.

If the head unit communicates that it implements a focus/select interaction model rather than direct touch, the focusableItemLocatorEnabled property will be set to YES. 

**Application Interface**

The video projection interface is exposed to the application as a UIScreen object representing a virtual external display. The external view is separate from the view rendered on the device's LCD. This allows the developer to optionally forego the lock screen, instead displaying a different interface on the device than what is projected onto the head unit.

![Separate Displays](https://i.imgur.com/dIBQnyZ.png "Separate Displays")

When SDL determines a video stream has been established, a UIScreen object is created using the attributes of the head unit's display. SDL then posts [UIScreenDidConnectNotification](https://developer.apple.com/documentation/uikit/uiscreendidconnectnotification) to inform the app the display configuration has changed. [-[UIScreen screens]](https://developer.apple.com/documentation/uikit/uiscreen/1617812-screens?language=objc) is overidden to add the SDL managed UIScreen to the list of available screens. 

The app enables rendering to the external display using [standard Apple recommended steps](https://developer.apple.com/library/content/documentation/WindowsViews/Conceptual/WindowAndScreenGuide/UsingExternalDisplay/UsingExternalDisplay.html#//apple_ref/doc/uid/TP40012555-CH3-SW3). 
```objc
// When an external screen becomes available, attach a storyboard  
// designed specifically for the head unit's display.
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
[-[UIWindow setScreen:]](https://developer.apple.com/documentation/uikit/uiwindow/1621597-screen?language=objc) and [-[UIWindow setRootViewController:]](https://developer.apple.com/documentation/uikit/uiwindow/1621581-rootviewcontroller?language=objc) overrides are used to link an SDLCarWindow object to the UIWindow object. The UIWindow supplied by the application is used as the video projection source and touch event sink (key window).

**Video Projection**

SDLCarWindow uses the existing SDLStreamingMediaManager created by SDLLifecycleManager to manage video streaming.
SDLStreamingMediaManager is used to project the contents of the virtual external display. 

**Touch Events**

Ownership of SDLTouchManager moves from SDLStreamingMediaLifecycleManager to SDLCarWindow. SDLStreamingMediaLifecycleManager links to SDLCarWindow to retain access to SDLTouchManager. 

SDLTouchManager handles each touch event by first giving SDLTouchManagerDelegate delegate a chance to handle it. If the event remains unhandled, SDLTouchManager will attempt to translate the event directly into a view action and invoke that action. By translating touch events into view actions within SDLTouchManager, no additional effort is required on the part of the app developer to handle touch events. This is provided for UIKit view types only. 

Currently supported types are: UIButton, UIControl, UINavigationViewController, UITableView, UICollectionViewCell, UIScrollView, UISearchBar, UITextField, UISegmentedControl and UITabBarController. [2]

Touch events for custom views defined by the app must be handled by the app. An app wishing to handle touch events must adopt and implement the SDLTouchManagerDelegate protocol. The app will then have the choice of handling a touch event, or passing the event on to SDL to handle it automatically. When the app handles the event, it returns YES from the delegate method. A return value of NO instructs SDL to handle the event.

In a later proposal, SDL will be extended to include focus and selection control on the handset, following the UIFocusEngine model from tvOS. [3]

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
**Focusable and selectable UI elements**

SDLCarWindow walks the view hierarchy and builds a list of focusable views. This list is sent to the head unit as SDLHapticRectData.

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

SDLCarWindow automatically handles view layout updates by listening for calls to -[[CALayer layoutSublayers]](https://developer.apple.com/documentation/quartzcore/calayer/1410935-layoutsublayers?language=objc).

The app may optionally notify SDL of a layout change by posting SDLDidUpdateProjectionView. This tells SDL to recompile and refresh the head unit's list of focusable and selectable UI elements. 

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
* The projected video view is separate from the view on the device's LCD allowing for optional use of device while projecting.
* Video projection is achieved using documented Apple procedures for external display support. 
* The app developer doesn't need to write any code to handle touch events when using supported UIKit responders. From the app's perpective, actions are triggered identically to UIKit.
* The app developer has the option to handle touch events in the app should they wish to do so. (Custom views, OpenGL)
* Touch event behavior of the iOS proxy remains consistent across all apps using the same version of the SDL framework. 
* VPM features and fixes propogate to all apps.

## Potential downsides
* SDLCarWindow uses swizzling. All swizzled methods are public and have not changed since iOS 2.0-3.2.
* Unforeseen challenges may arise when adding support for new UIKit types. 

## Impact on existing code
* Apps adopting SDLTouchManagerDelegate will need to return BOOL instead of void for delegate methods.
* SDLTouchManager moves from SDLStreamingMediaLifecycleManager to SDLCarWindow
* SDLCarWindow deprecates SDLHapticManager. Functionality previously found in SDLHapticManager has been moved into SDLCarWindow.  

## Alternatives considered
* Force the each application to handle touch events via SDLTouchManagerDelegate. The developer has to handle the translation of a view and location into the desired action. Touch management will be inconsist amongst SDL apps, which could lead to user dismay. 

## Notes
[1] OpenGL based views require SDLTouchManagerDelegate adoption to handle touch events

[2] Xevo production code

[3] Device managed focus navigation is preferred, but has not been PoC'd
