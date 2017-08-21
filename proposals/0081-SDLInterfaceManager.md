# SDLInterfaceManager

* Proposal: [SDL-0081](0081-SDLInterfaceManager.md)
* Author: [Brandon Salahat](https://www.github.com/Toyota-BSalahat)
* Status: **Accepted with Revisions**
* Impacted Platforms: [iOS]

## Introduction

The SendHapticData RPC will allow video projection apps to tell SDLCore where their controls are located. This allows VPM apps to integrate with the OEM haptic engine in a way similar to template SDL apps. This proposal aims to implement the necessary supporting proxy logic so that applications can easily utilize the OEM haptic feedback mechanism.

## Motivation

Currently there is a RPC to support communicating with the OEM haptic engine in progress for SDL Core 4.4, but no associated proxy abstraction. To utilize the interface an app would have to manually call this RPC.

App developers should be decoupled from manually having to manage this behavior.

## Proposed solution

In order to make interfacing with the OEM haptic engine as painless as possible, the iOS proxy could handle the heavy lifting for most use-cases by tapping into the information/interfaces exposed by the iOS Feedback Engine, this is the information that is used to power the focus interface on tvOS.

The proxy (and later SDLCarWindow) could contain an instance of `SDLInterfaceManager` that crawls the view hierarchy and keeps track of what views should be reported to the haptic RPC. The app could choose to refresh this data manually (similar to `reloadData` with a UITableView) or could replace their `UIViewController` inheritance with `SDLViewController` which would automatically update the interface when a new view is presented.

The following is an example of how this could be added to the SDK

```objc
#import <UIKit/UIKit.h>

@protocol SDLHapticInterface <NSObject>

- (instancetype)initWithWindow:(UIWindow *)window;
- (void)updateInterfaceLayout;
// additional method should be added to allow pure openGL apps to specify an array of spatial data directly

@end
```

```objc
#import <UIKit/UIKit.h>
//5
@interface SDLInterfaceManager : NSObject <SDLHapticInterface>
- (instancetype)initWithWindow:(UIWindow *)window;
- (void)updateInterfaceLayout;
@end
``` 

```objc
#import "SDLInterfaceManager.h"
#import "SDLNotificationConstants.h"

@interface SDLInterfaceManager()
@property (nonatomic, strong) UIWindow *projectionWindow;
@property (nonatomic, strong) NSMutableArray<UIView *> *focusableViews;
@end

@implementation SDLInterfaceManager

//1
- (instancetype)initWithWindow:(UIWindow *)window {
    if ((self = [super init])) {
        self.projectionWindow = window;
        self.focusableViews = [NSMutableArray new];
        [self updateInterfaceLayout];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(projectionViewUpdated:) name:SDLProjectionViewUpdate object:nil];
        
    }
    return self;
}

- (void)updateInterfaceLayout {
    self.focusableViews = [NSMutableArray new];
    [self parseViewHierarchy:[[self.projectionWindow subviews] lastObject]]; //2
    
    NSUInteger preferredViewIndex = [self.focusableViews indexOfObject:[[[self.projectionWindow subviews] lastObject] preferredFocusedView]];
    if (preferredViewIndex != NSNotFound && _focusableViews.count > 1) {
        [self.focusableViews exchangeObjectAtIndex:preferredViewIndex withObjectAtIndex:0]; //3
    }
    
    [self highlightAllViews]; //for visual debugging purposes only
    
    //Create and send RPC
}

- (void)parseViewHierarchy:(UIView *)currentView {
    if (currentView == nil) {
        NSLog(@"Error: Cannot parse nil view");
        return;
    }
    //4
    NSArray *focusableSubviews = [currentView.subviews filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(UIView *  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        return evaluatedObject.canBecomeFocused;
    }]];
    
    if (currentView.canBecomeFocused && focusableSubviews.count == 0) {
        [self.focusableViews addObject:currentView];
        return;
    } else if (currentView.subviews.count > 0) {
        NSArray *subviews = currentView.subviews;
        
        for (UIView *childView in subviews) {
            childView.layer.borderWidth = 1.0;
            childView.layer.borderColor = [[UIColor redColor] CGColor];
            [self parseViewHierarchy:childView];
        }
    } else {
        return;
    }
}

#pragma mark notifications
- (void)projectionViewUpdated:(NSNotification *)notification { //5
    [self updateInterfaceLayout];
}

#pragma mark debug functions
- (void)highlightAllViews {
    for (UIView *view in self.focusableViews) {
        view.layer.borderColor = [[UIColor blueColor] CGColor];
        view.layer.borderWidth = 2.0;
    }
}

@end
```

```objc
#import <UIKit/UIKit.h>


@interface SDLProjectionViewController : UIViewController

@end
```

```objc
#import "SDLProjectionViewController.h"
#import "SDLNotificationConstants.h"

@interface SDLProjectionViewController ()

@end

@implementation SDLProjectionViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] postNotificationName:SDLProjectionViewUpdate object:nil];
}

@end
```

```objc
#import <UIKit/UIKit.h>

@interface SDLTableViewController : UITableViewController

@end
```

```objc
#import "SDLTableViewController.h"
#import "SDLNotificationConstants.h"

@implementation SDLTableViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] postNotificationName:SDLProjectionViewUpdate object:nil];
}

@end
```


The following notification would be added to `SDLNotificationConstants`

```objc
extern SDLNotificationName const SDLProjectionViewUpdate;
```

```objc
SDLNotificationName const SDLProjectionViewUpdate = @"com.sdl.notification.projectionViewUpdate";
```


1. The manager is initialized with a UIWindow. This could easily be changed to SDLCarWindow when available, but will work with SDLCarWindow as-is.
2. The currently displayed view on the manager's window is passed to the view parser method (more on that later)
3. If the window's current view is setting a preferred focus view (ie, the view that should be initially focused as per the tvOS spec) it is moved to the front of the parsed focusable views list. This could be used by the OEM haptic engine, if so desired.
4. This method recursively crawls through the entire view hierarchy in a fashion similar to the tvOS focus engine. It will identify every view that should be focusable as per Apple's available focus flags.
5. This is the defined interface protocol. This is the interface that implementations would expect to interact with. In this example the HapticInterfaceManager implements this interface, but any class (currently in SDL, or added later) could take over this responsibility without integrations needing to change or be broken.

## Potential downsides

1. Apps that do not use UIKit will have to either set the focusableViews array manually, call the haptic RPC manually, or the InterfaceManager will need to allow apps to pass in an array of the data needed for the InterfaceManager to build out the spatial structures.
2. Apps will need to request the interface manager to perform an update if they change their UI in a way that effects haptic input without presenting a new view either with the example notification, or by addition of a reload method(s). I believe we could catch some of these cases in SDLViewController, but not all of them.

## Impact on existing code

- The `SDLInterfaceManager` would be new code, it could be more closely coupled with `SDLCarWindow` once that is completed.

## Out of Scope
Changes to the Android proxy are not in the scope of this proposal. While the SDLInterfaceManager should have the same interface as the one being proposed, the under-the-hood implementation details could potentially be different. In order to accommodate the iOS proxy change deadline, those changes are not in scope of this proposal.

## Alternatives considered

1. Apps can manually call the SendHapticData RPC, and manage all of the spatial data manually.
2. Instead of keying off the tvOS focus data, the interface manager could key off of the iOS accessibility focus flags. While the tvOS data is very similar and more robust, the accessibility data must technically be supported by apps to comply with the ADA.
3. Instead of exposing `SDLProjectionViewController` or similar, the interface manager could 'swizzle' the needed update logic into every view/view controller currently within it's window. Since this window belongs to SDL and SDL alone, this could be somewhat justified. However this is not a decision that should be made lightly.
More information about method swizzling:
http://nshipster.com/method-swizzling/
4. Instead of option 3, or using `SDLProjectionViewController` , the interface manager could use Key-Value-Observing (KVO) on the window's `sublayers` property. However `subviews` is not KVO compliant, and there is no promise that `sublayers` will be KVO compliant at any given time. Using KVO in this manner also comes with most of the warnings as swizzling.
5. Refresh logic can be handled completely by the app, and `SDLProjectionViewController` can be dropped from the proposal. It is worth noting that even if `SDLProjectionViewController` is implemented, apps could still choose to do this.

## Apple Documentation
https://developer.apple.com/library/content/documentation/General/Conceptual/AppleTV_PG/WorkingwiththeAppleTVRemote.html

https://developer.apple.com/accessibility/ios/
