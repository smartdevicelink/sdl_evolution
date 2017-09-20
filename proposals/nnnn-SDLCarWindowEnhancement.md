# SDLCarWindow Enhancement

* Proposal: [SDL-nnnn](nnnn-SDLCarWindow-Projection.md)
* Author: [Michael Pitts](mailto:mpitts@xevo.com)
* Status: **PoC**
* Impacted Platforms: [iOS]

## Introduction

This proposal builds on [SDLCarWindow Video Projection Developer Interface](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0091-SDLScreen-SDLWindow-Projection.md#sdlcarwindow-video-projection-developer-interface) by introducing a simplified method of SDL touch event handling. Interaction with VPM and focusable view regions is also discussed in this proposal.

## Motivation

Current proposals for handling remote touch events place the burden of handling these events on the SDL application developer. This will certainly lead to code duplication, more code to maintain, as well as inconsistencies amongst various applications. 

## Proposed solution

SDLCarWindow will handle SDL touch events, translating those events directly into view actions. By translating touch events into view actions within SDLCarWindow, no additional effort is required on the part of the application developer to handle touch events.

SDLCarWindow will also handle VPM focusable view selection. The focusable view region list is sent to the HU to allow remote focus navigation and selection of views on VPM view. SDLCarWindow has all of the information required to build the region list and update the list when the view layout changes. 

### Building the focusable view region list

SDLCarWindow holds the view associated with its StreamingViewController. SDLCarWindow is therefore able to interate the subviews of the VPM view and build a list of focusable view regions to be sent to the HU for remote focus navigation and selection.

```objc
@interface SDLSendHapticData ()
@property (strong, nonatomic, nullable) NSArray<SDLSpatialStruct *> *hapticSpatialData;
@end

- (instancetype)initWithView:(UIView*)view {
    if (self = [super initWithName:SDLNameSendHapticData]) {
        if (focusableControl == nil) {
            focusableControl = [NSMutableArray<UIView*> new];
        } else {
            [focusableControl removeAllObjects];
        }
        NSMutableArray<SDLSpatialStruct*>* spatialData = [NSMutableArray new];
        [SDLSendHapticData focusableControlsInView:view result:spatialData];
        [self setHapticSpatialData:[NSArray arrayWithArray:[[spatialData reverseObjectEnumerator] allObjects]]];
    }
    return self;
}

+ (void)focusableControlsInView:(UIView*)view result:(NSMutableArray<SDLSpatialStruct*>*)result {
    BOOL canBecomeFocused = ([view isKindOfClass:[UIButton class]] == YES) || (view.canBecomeFocused == YES);
    if ((canBecomeFocused == YES) &&
        (view.frame.size.width > 0) && (view.frame.size.height > 0) &&
        (view.isHidden == NO) && (view.alpha > 0.0) && (view.userInteractionEnabled == YES))
    {
        [focusableControl addObject:view];
        CGRect rect = [view convertRect:view.bounds toView:nil];
        SDLSpatialStruct* sss = [[SDLSpatialStruct alloc] initWithId:((UInt32)[focusableControl indexOfObject:view] + 1)
                                                                   x:@(rect.origin.x)
                                                                   y:@(rect.origin.y)
                                                               width:@(rect.size.width)
                                                              height:@(rect.size.height)];
        [result addObject:sss]; 
    }
    for (UIView* subview in view.subviews) { 
        [SDLSendHapticData focusableControlsInView:subview result:result];
    }
}
```

SDLCarWindow automatically handles view layout updates by inserting a listener into [CALayer layoutSublayers]. 

```objc
//==========================================================================================
// Update focus regions whenever the layout has changed
// https://developer.apple.com/documentation/quartzcore/calayer/1410935-layoutsublayers
//==========================================================================================
static void (*pfnCALayer_layoutSublayers)(CALayer*, SEL) = nil;
static void CALayer_layoutSublayers(CALayer* layer, SEL methodName)
{
    if (pfnCALayer_layoutSublayers)
        pfnCALayer_layoutSublayers(layer, methodName);
    if ([layer isEqual:[SDLCarWindow sharedWindow].layer]) {
        [[SDLCarWindow sharedWindow] updateHapticData];
    }
}

// SDLCarWindow
- (void)setStreamingViewController:(nullable UIViewController *)streamingViewController {
    Class cls = objc_getClass("CALayer");
    pfnCALayer_layoutSublayers =
    (void *)method_setImplementation(class_getInstanceMethod(cls, sel_getUid("layoutSublayers")),
                                     (IMP)CALayer_layoutSublayers);
    _streamingViewController = streamingViewController;
    _layer = _streamingViewController.childViewControllers[0].view.layer;
    if ([[_streamingViewController.childViewControllers[0] class] conformsToProtocol:@protocol(SDLTouchManagerDelegate)]) {
        self.sdlManager.streamManager.touchManager.touchEventDelegate = (id<SDLTouchManagerDelegate>)_streamingViewController.childViewControllers[0];
    }
}
```

### Translating SDL touch event into a view action

If the developer wishes to handle touch events in their app, they can adopt a protocol provided by SDL, such as   [SDLTouchManagerDelegate](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0090-SDLHapticHitTesterProtocol.md). SDLCarWindow gives the application the choice of handling the raw event, or allowing the iOS proxy to trigger the action for the target view.

```objc
// SDLProxy
NSString *const SDLTouchEventNotification = @"com.sdl.onTouchEvent";

- (void)handleTouchEvent:(SDLRPCMessage *)message {
    NSString*   type   = (id)[message getParameters:SDLNameType];
    NSArray*    events = (id)[message getParameters:SDLNameEvent];
    if (([type isKindOfClass:[NSString class]] == NO) ||
        ([events isKindOfClass:[NSArray class]] == NO)) {
        return;
    }
    NSDictionary* firstEvent = events[0];
    if ([firstEvent isKindOfClass:[NSDictionary class]] == NO) {
        return;
    }
    NSArray* coords = (id)firstEvent[@"c"];
    if ([coords isKindOfClass:[NSArray class]] == NO) {
        return;
    }
    NSDictionary* coord = coords[0];
    if ([firstEvent isKindOfClass:[NSDictionary class]] == NO) {
        return;
    }
    NSNumber* x = coord[@"x"];
    NSNumber* y = coord[@"y"];
    NSNumber* touchPhase;
    if ([type isEqualToString:@"BEGIN"]) {
        touchPhase = [NSNumber numberWithInteger:UITouchPhaseBegan];
    } else if ([type isEqualToString:@"END"]) {
        touchPhase = [NSNumber numberWithInteger:UITouchPhaseEnded];
    } else if ([type isEqualToString:@"MOVE"]) {
        touchPhase = [NSNumber numberWithInteger:UITouchPhaseMoved];
    } else {
        return;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:SDLTouchEventNotification
                                                        object:nil
                                                      userInfo:@{ @"x": x,
                                                                  @"y": y,
                                                                  @"touchPhase": touchPhase }];
}

// SDLCarWindow
- (instancetype)init {
    ...
    [self sdl_addSelfObserverForName:SDLTouchEventNotification selector:@selector(sdl_didReceiveTouchEvent:)];
    ...
}

- (void)sdl_didReceiveTouchEvent:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSNumber* x = notification.userInfo[@"x"];
        NSNumber* y = notification.userInfo[@"y"];
        NSNumber* touchPhase = notification.userInfo[@"touchPhase"];
        if (!x && !y) {
            return;
        }
        UITouchPhase phase = touchPhase.integerValue;
        CGPoint locationInWindow;
        locationInWindow.x = x.doubleValue;
        locationInWindow.y = y.doubleValue;
        UIView* targetView = [self.streamingViewController.view.window hitTest:locationInWindow withEvent:nil];
        // Give the application a chance to handle the event
        id<SDLTouchManagerDelegate> delegate = self.sdlManager.streamManager.touchManager.touchEventDelegate;
        if ([delegate respondsToSelector:@selector(view:didReceiveSingleTapAtPoint:)] == YES) {
            if ([delegate view:targetView didReceiveSingleTapAtPoint:locationInView] == YES) {
                return; // Application's touch manager delegate handled the event
            }
        }
        if ([targetView isKindOfClass:[UIControl class]]) {
            [self handleTouchOnUIButton:phase]; 
        } else if (<Other actionable view types>) {
            ...
        }
    });
}

-(void)handleTouchOnUIButton:(UITouchPhase)phase
{
    UIControlEvents evt = 0;
    switch (phase) {
        case UITouchPhaseBegan:
            evt = UIControlEventTouchDown;
            break;
        case UITouchPhaseEnded:
            evt = UIControlEventTouchUpInside;
            break;
        case UITouchPhaseMoved:
            break;
        default:
    }
    if (evt != 0) {
        UIControl* ctrl = (UIControl*)targetView;
        [ctrl sendActionsForControlEvents:evt];
    }
}
```

Addition of new optional SDLTouchManagerDelegate method. Called by SDLCarWindow.

```objc
@protocol SDLTouchManagerDelegate <NSObject>
@optional
/**
 *  @abstract
 *      Single tap was received. This is called from SDLCarWindow for artificial
 *      touch events generated by touch-less display head units
 *  @param view
 *      The view which received the tap.
 *  @param point
 *      Location of the single tap in the head unit's coordinate system.
 *
 *  @return value
 *      YES if the app handled the event
 *      NO if the app did not handle the event
 */
- (BOOL)view:(UIView *)view didReceiveSingleTapAtPoint:(CGPoint)point;
```

## Benefits
* The app developer doesn't need to write any code to handle touch events. From the app's perpective, view actions are triggered identically as if UIKit had fired them.
* The app developer has the option to handle touch events in the app should they wish to do so.
* Touch event behavior of the iOS proxy remains consistent across all apps using the same version of the SDL framework. 
* Features and fixes propogate to all apps.

## Potential downsides
* SDLCarWindow swizzles one method. However, the method is public and will therefore likely remain in future versions of iOS. If it does change, it will follow Apple's standard deprecation cycle.
* Difficulties may arise when implementing action triggers for other UIKit types. This can be mitigated by building upon existing Xevo implementations of the same.

## Impact on existing code
* No impact to applications using the iOS proxy.
* These changes will be brought in with the integration of SDLCarWindow.

## Alternatives considered
* Force the application developer to handle touch events using a delegate. The developer then has to handle the translation of a view and a point into the desired action. 


