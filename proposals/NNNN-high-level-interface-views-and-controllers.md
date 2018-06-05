# High level interface: Views and Controllers

* Proposal: [SDL-NNNN](NNNN-high-level-interface-views-and-controllers.md)
* Author: [Kujtim Shala](https://github.com/kshala-ford)
* Status: **Awaiting Review**
* Impacted Platforms: [ iOS ]

## Introduction

This proposal is based on #448 adding views and view controllers to the high level interface. It proposes a solution to mimic the UI framework of the native OS SDKs.

## Motivation

In order to work with SDL, app developers need to learn a new API which mostly doesn't adopt familiar patterns. Including but not limited to 
- read best practices and implement proxy lifecycle (Android above all)
- the use of RPCs and handle notifications, requests and responses
- manually manage concurrent and sequential operations (e.g. image upload)

The time for an app developer to learn SDL (non-productive time) is high and not accepted by some developers. The SDL iOS library already improves the current situation by abstracting painful implementations. However the management layer is still unfamiliar and causes a high learning curve.

## Proposed solution

This proposal is about adding views and view controllers to the SDL library which should be used by the `SDLApplication` (see #448). With view controllers app developers can separate and structure the SDL related code.

### View Controller lifecycle

Based on the MVC pattern used by UIKit the high level interface should introduce the SDL view controller in order to manage and control views. App developers need to subclass the base view controller class and implement the use cases.

A view controller can exist in a set of states. Below flow shows the possible transitions between loading view, view to appear or to disappear.

![view-controller-lifecycle](../assets/proposals/NNNN-high-level-interface-views-and-controllers/view-controller-lifecycle.png)

#### `Init`

View controllers are instantiated when they are pushed to the view controller manager (see subsection *ViewControllerManager* below). For the root view controller it would be instantiated once a connection is established to the head unit (app is registered). In this state there is no view loaded. The app developer should not load data or perform other memory/time intense code at this time.

#### `loadView`

In case the view controller appears on the screen but does not have a loaded view the method `loadView` is called. By default `SDLViewController` implements the method placing a plain view to the view controller's view property. The app developer can override the method in order to do custom actions right before the view is created. The default implementation should be fine for most partners.

This method is following [`UIViewController.loadView`](https://developer.apple.com/documentation/uikit/uiviewcontroller/1621454-loadview?language=objc)

#### `viewDidLoad`

The view controller is notified that the view did load through this method. The app developer can override this method in order to create the view hierarchy, load data sources and apply assets to the views.

#### `viewWillAppear`

Whenever a view controller's view should become visible on the head unit the view controller will be notified that the view will appear. Reasons to appear on the head unit are:
1. The app is launched by the user (entered HMI_LIMITED or HMI_FULL). The root view controller will appear.
2. The app has pushed a second view controller to the stack. The second view controller's view will appear after the first view controller's view will disappear.
3. The top view controller was removed from the stack. The underlying view controller's view will appear after the top view controller's view will disappear.

The app developer can override this method in order to manipulate view elements before they are presented on the head unit.

#### `viewDidAppear`

This method is called after `viewWillAppear`.

#### `viewWillDisappear`

Whenever a view is/will not be visible on the head unit anymore the view controller will be notified by `viewWillDisappear`. Reasons for that are:
1. The app entered HMI_NONE or HMI_BACKGROUND. In this case the view already disappeared. Still in order to follow the flow this method should be called.
2. The app has pushed a second view controller to the stack. The first view controller's view will disappear before the second view controller's view will appear.
3. The top view controller was removed from the stack. The top view controller's view will disappear before the underlying view controller's view will appear.

#### `viewDidDisappear`

This method is called after `viewWillDisappear`. 

### SDLViewController

The view controller class is called `SDLViewController`. It implements the view controller and provides the necessary classes for the lifecycle. It's expected that the app developers creates subclasses of this base class.

```objc
@interface SDLViewController

@property (nonatomic, readonly) BOOL isViewLoaded;

@property (nonatomic) SDLView *view;

@property (nonatomic, copy) SDLPredefinedLayout layout;

@property (nonatomic, copy) NSString *customLayout;

- (void)loadView;
- (void)viewDidLoad;

- (void)viewWillAppear;
- (void)viewDidAppear;

- (void)viewWillDisappear;
- (void)viewDidDisappear;

- (void)showViewController:(SDLViewController *)viewController;

@end
```

#### `isViewLoaded`

This property will simply return `YES` if the view controller's view is loaded.

#### `view`

The view controller's view. Can be set by the app developer. By default it is set to a plain view by the default implementation of `loadView`.

#### `layout`

The display layout that should be used while the view controller is presented. It can be set to one of the predefined layouts.

#### `customLayout`

In order to support non-predefined layouts (OEM or custom layouts) the app developer can set the name of the custom template.

#### `showViewController`

Similar to [`UIViewController.showViewController:sender:`](`https://developer.apple.com/documentation/uikit/uiviewcontroller/1621377-showviewcontroller?changes=_2&language=objc`) This method should allow app developer to present another view controller in the primary context. The method is a shortcut to the shared application and the view controller manager. Depending on the manager's mode the method either replaces the current presented view controller or pushes it to the view controller stack (see `SDLModalViewController`).

### SDLViewControllerManager

A manager for view controllers should be added and used by the `SDLApplication`. The manager should be able to support two different modes: `basic` and `stack`.

```objc
typedef NS_ENUM(NSInteger, SDLViewControllerManagerMode) {
	SDLViewControllerManagerModeBasic,
	SDLViewControllerManagerModeStack,
};

@interface SDLViewControllerManager

@property (nonatomic, assign) SDLViewControllerManagerMode mode;

@property (nonatomic, copy) NSArray<SDLViewController *> *viewControllers;

@property (nonatomic) SDLViewController *rootViewController;
@property (nonatomic) SDLViewController *topViewController;

- (void)pushViewController:(SDLViewController *)viewController;
- (void)popViewController;

@end
```

The basic mode should maintain a single view controller instance. If the app developer requests to show a new view controller the manager should drop the old view controller and keep the new one. Technically the `viewControllers` array will always contain a single instance. If this mode is set the shortcut method `SDLViewController.showViewController` will replace the array of the property with the new view controller.

The stack mode should behave similar to [`UINavigationController`](https://developer.apple.com/documentation/uikit/uinavigationcontroller) providing code to push and pop view controllers within a stack whereby the top view controller is visible on the screen.

The `viewControllers` array should keep all view controller instances pushed to the stack. `rootViewController` points to the first item of this array. `topViewController` to the last item. The method `pushViewController:` can be used by the app developer to push and present a new view controller. As an alternative the method `SDLViewController.showViewController` will use `pushViewController` if the mode `stack` is set.

### Views

The high level interface introduces three different kind of views: text view, image view and button view. The views of the currently presented view controller will be responsible to manage the screen. Future proposals will add more views to abstract more RPCs.

#### SDLView

```objc
@interface SDLView

@property (nonatomic) NSArray<SDLView *> *subviews;

@end
```

#### SDLTextView

The text view is a view which takes care of any kind of text field modifyable by the `Show` RPC. Main fields are dynamically added (first item used for `mainField1`, second for `mainField2`).

```objc
@interface SDLTextView : SDLView

@property (nonatomic, nullable, copy) SDLTextAlignment textAlignment;

@property (nonatomic, nullable, copy) NSArray<SDLTextField *> *mainFields;

@property (nonatomic, nullable, copy) NSString *statusBar;

@property (nonatomic, nullable, copy) NSString *mediaTrack;

@property 

@end

@interface SDLTextField

@property (nonatomic, nonnull, copy) NSString *text;
@property (nonatomic, nullable, copy) NSArray<SDLMetadataType> *metadataTypes;

@end
```

#### SDLImageView

The image view will be used for the primary and secondary graphic in the order added to the view controller's view. The image provided will be automatically scaled depending on the current display layout.

```objc
@interface SDLImageView : SDLView

@properties (nonatomic) SDLArtwork *image;

@end
```

#### SDLButtonView

Every button view added to the view controller's view will be used for the button managers `softButtons` array. If desired the app developer can manage the soft button views in a dedicated subview of type `SDLView`.

```objc
@interface SDLButtonView : SDLView

@property (nonatomic, nullable, strong) SDLSoftButtonWrapper *button;

@end
```

## Potential downsides

The initial workload in order to implement this high level interface is expected to be quite high. Once implemented it is expected that developers will be able to implement SDL into their apps in less time than they would need today. At the end the maintenance of the high level interface may be lower compared to the counterproposal for different reasons.

This proposal mimics the native UI API. Compared to the counterproposal this proposal is not that close to the native UI kit experience. On the other side some SDL specific APIs can be easily abstracted and integrated into the rest of the high level interface.

## Impact on existing code

This proposal will add a total new high level interface layer abstracting many parts of SDL. Existing code should not be affected in a short term but it would make parts of the code obsolete therefore to be deprecated and made private.

## Alternatives considered

As discussed in the steering committee meeting from March 20 (see [here](https://github.com/smartdevicelink/sdl_evolution/issues/379#issuecomment-374736496)) this proposal is a counterproposal to [0133 - Enhanced iOS Proxy Interface](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0133-EnhancediOSProxyInterface.md).

