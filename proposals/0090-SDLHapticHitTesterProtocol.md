# SDLHapticHitTester Protocol

* Proposal: [SDL-0090](0090-SDLHapticHitTesterProtocol.md)
* Author: [Brandon Salahat](https://www.github.com/Toyota-BSalahat)
* Status: **Accepted with Revisions**
* Impacted Platforms: [iOS]

## Introduction
SDL-0081 introduced the SDL Haptic Interface Manager. Since this manager stores the location of all haptic UI components, it can be used to ease integration with apps that utilize it when responding to touch events. This proposal aims to introduce a protocol that takes a SDLTouch object, and returns the selected haptic view when applicable.

## Motivation

Currently app integrations are mostly responsible for mapping SDLTouch events to associated actions/views. This can be cumbersome, but is not trivial for the proxy to manage for all integrations. However in the case of integrations that utilize the SDL haptic interface manager, we have enough view data to allow the proxy to determine which view was selected based on the SDLTouch object. This should reduce the amount of work app integrations must do to handle this logic.

## Proposed solution

The proposed solution is to integrate an additional protocol that defines this relationship. Since mapping SDLTouches against stored haptic views is a separate behavior from the main purpose of the haptic interface manager, we believe that putting the behavior in a new protocol is most appropriate. This will allow the two functionalities to remain decoupled should the actual implementation need to be divided among multiple classes in the future.

Below is an example of how this could be integrated into the current proxy:

```objc
#import <UIKit/UIKit.h>

@class SDLTouch;

@protocol SDLHapticHitTester <NSObject>

- (nullable UIView *)viewForSDLTouch:(SDLTouch *_Nonnull)touch;

@end
```

The following additional behavior could then reside in the example interface manager provided for proposal 0081

```objc
 #import <UIKit/UIKit.h>
 #import "SDLHapticInterface.h"
 #import "SDLHapticHitTester.h"
 
 @interface SDLInterfaceManager : NSObject <SDLHapticInterface>
 @interface SDLInterfaceManager : NSObject <SDLHapticInterface, SDLHapticHitTester>
 - (instancetype)initWithWindow:(UIWindow *)window;
 - (void)updateInterfaceLayout;
```	
Additional function added to SDLInterfaceManager
```objc
#pragma mark SDLHapticHitTester functions

- (UIView *)viewForSDLTouch:(SDLTouch *)touch {
    
    UIView *selectedView = nil;
    
    for (UIView *view in self.focusableViews) {
        CGPoint localPoint = [view convertPoint:touch.location fromView:self.projectionWindow];
        if ([view pointInside:localPoint withEvent:nil]) {
            if (selectedView != nil) {
                selectedView = nil;
                break;
                //the point has been identified in two views. We cannot identify which with confidence.
            } else {
                selectedView = view;
            }
        }
    }
    
    NSUInteger selectedViewIndex = [self.focusableViews indexOfObject:selectedView];
    
    if (selectedViewIndex != NSNotFound) {
        return [self.focusableViews objectAtIndex:selectedViewIndex];
    } else {
        return nil;
    }
    
}
```

## Potential downsides

1. Apps that do not utilize the SDL Haptic Interface Manager will see no benefit from this change
2. This example implementation makes the assumption that the location property on SDLTouch is in reference to the UIWindow coordinate space. If this is not the case, additional point transformations may be required.

## Impact on existing code

- Impact to existing code is minimal. This is a new functionality, and in practice would most likely reside in the upcoming SDL Haptic Interface Manager.

## Out of Scope
How apps would receive the selected view data. Most likely the touch manager would query this protocol for a selected view before sending the SDLTouch to the app through current means. 

## Alternatives considered

1. Using the id of the spatial structs to map touch events to the stored focusable views. This would be the best solution, but would require changes to SDL Core. Were these changes to be made in the future, the proposed protocol would still be able to support that mode of mapping.
2. Not utilizing the haptic data to improve touch mapping for projection apps.
