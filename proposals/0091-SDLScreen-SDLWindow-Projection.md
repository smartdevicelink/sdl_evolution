# SDLCarWindow Video Projection Developer Interface

* Proposal: [SDL-0091](0091-SDLScreen-SDLWindow-Projection.md)
* Author: [Michael Pitts](https://github.com/gnxclone)
* Status: **Awaiting review**
* Impacted Platforms: [iOS]

## Introduction
The iOS SDL framework implements an SDLCarWindow class to provide an easy-to-integrate developer interface to SDL video projection and the associated task of defining focusable and selectable UI elements. 

## Motivation
Provide a convenient and simple programming model for SDL app developers to remotely project and enable interaction with the appropriate subset of their UIKit, OpenGL and hybrid UIKit/OpenGL user interfaces. 

## Proposed solution
SDLCarWindow leverages SDLStreamingMediaManager and SDLTouchManager to hide the management of video projection from the app developer. 

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

SDLCarWindow uses the existing SDLStreamingMediaManager created by SDLLifecycleManager to manage video streaming. SDLStreamingMediaManager is used to project the contents of the virtual external display. 

**Touch Events**

Ownership of SDLTouchManager moves from SDLStreamingMediaLifecycleManager to SDLCarWindow. SDLStreamingMediaLifecycleManager links to SDLCarWindow to retain access to SDLTouchManager. 

At the time of this proposal, the app handles touch events by adopting the SDLTouchManagerDelegate protocol. In a later proposal, SDLTouchManager will be extended to automatically handle touch events for any UIResponder derived class, removing this burden from the app developer and deprecating SDLTouchManagerDelegate.

**Focusable and selectable UI elements**

SDLCarWindow walks the view hierarchy to build a list of focusable views. This list is sent to the head unit as SDLHapticRectData.

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

In a later proposal, SDL will be extended to include focus and selection control on the handset, following the UIFocusEngine model from tvOS. 

## Benefits
* The projected video view is separate from the view on the device's LCD allowing for optional use of device while projecting.
* Video projection is achieved using documented Apple procedures for external display support. 

## Potential downsides
* SDLCarWindow uses swizzling. However, all swizzled methods are public and have not changed since iOS 2.0-3.2.

## Impact on existing code
* SDLTouchManager moves from SDLStreamingMediaLifecycleManager to SDLCarWindow
* SDLCarWindow deprecates SDLHapticManager. Functionality previously found in SDLHapticManager has been moved into SDLCarWindow.  
