# Screen Manager Template Management

* Proposal: [SDL-NNNN](NNNN-screenmanager-push-pop.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Awaiting review**
* Impacted Platforms: [iOS / Java Suite / JavaScript Suite]

## Introduction

Adds the ability to separate SDL code according to template, as well as to push and pop templates via the proxy library Screen Manager instead of having to do all template manipulation manually via the `SetDisplayLayout` / `Show` RPC.

## Motivation

The manager layer should be able to handle most tasks that used to be handled by RPCs, and the Screen Manager in particular should be able to handle manipulating the screen and templates without requiring the developer to fall back to RPCs in any cases.

One big area that it is currently missing is the ability to manage changing templates, currently done with the `SetDisplayLayout` RPC (on RPC spec <6.0) and `Show` RPC (on RPC spec >6.0). This proposal seeks to provide an API for manipulating templates in an easy but optional way for app developers to more cleanly separate their SDL code into classes.

## Proposed solution

To make this happen, we will add a new `SDLTemplate` protocol for developers to more cleanly separate their SDL-related code into separate classes and to enable the push / pop feature:

### SDLTemplate Interface

```objc
@protocol SDLTemplate <NSObject>

/**
 The layout that will be used for the RPC call. You will likely want to return an `SDLPredefinedLayout` enum string.
 */
@property (copy, nonatomic, readonly) NSString *layoutName;

/**
 Called immediately before the Screen Manager sends an RPC to change to this template layout. Data can be pulled from the database or the network, but must not be shown on the screen until `templateActivated` is called.
 */
- (void)templateActivating;

/**
 Called immediately after the head unit has responded successfully to an RPC that changes to this template layout. Data for this template can now be shown on the screen. Note that data from the previous template will remain until modified. You can call `ScreenManager.clearScreen` in this method to quickly clear the screen. 
 */
- (void)templateActivated;

/**
 The template failed to appear on the screen for some reason. The RPC to change templates likely failed.
 */
- (void)templateFailedToActivateWithError:(NSError *)error;

/**
 Called immediately before the Screen Manager calls an RPC to change from this template to a new template.
 */
- (void)templateDeactivating;

/**
 Called immediately after the head unit has responded with a successful RPC and changed to a different template. This template is no longer displayed on the screen.
 */
- (void)templateDeactivated;

/**
 Another template failed to appear on the screen, meaning that this template will remain on screen. The RPC call to change the template likely failed.
 */
- (void)templateFailedToDeactivateWithError:(NSError *)error;

@end
```

Developers may build classes that implement this protocol in order to separate their SDL code so that each "screen" gets its own class instead of all of their SDL code being all in one class. The template lifecycle methods are called by the screen manager as it sends RPCs to present and dismiss the templates displaying on the screen. It will use the `layout` property to determine which layout to present. If the next template layout to be shown is equivalent to the current template layout, then the RPC call will be skipped, but the lifecycle methods will still be called.

### Screen Manager Additions

Additions will be made to the screen manager:

```objc
@interface SDLScreenManager : NSObject

// Everything that already exists

/**
 The current stack of templates.
 */
@property (strong, nonatomic, readonly) NSArray<id<SDLTemplate>> *templateStack;

/**
 The current template will deactivate and the new template that is passed will activate and be pushed onto the templateStack.
 */
- (void)pushTemplate:(id<SDLTemplate>)template;

/**
 The current template will deactivate and the previously displayed template (lastObject - 1 in the templateStack) will re-appear while the current template is removed from the templateStack. If there is only one object in the templateStack, nothing will happen.
 */
- (void)popTemplate;

/**
 The current template will deactivate and the template stack will be cleared except for the first item, which will either activate or be replaced if a new template is passed. That new template will then activate. If there is only one object in the templateStack and no newRootTemplate is passed, nothing will happen.
 */
- (void)popToRootTemplate:(nullable id<SDLTemplate>)newRootTemplate;

/**
 The current template will deactivate. Then the new template will activate by replacing the current template on the stack instead of pushing it onto the stack.
 */
- (void)replaceCurrentTemplateWithNewTemplate:(id<SDLTemplate>)newTemplate;

/**
 All text, images, and soft buttons will be cleared from the screen. Preloaded choices and main menu items will remain.
 */
- (void)clearScreen;

@end
```

### Additional Implementation Notes
1. When connected to systems running RPC <6.0, the screen manager should send `SetDisplayLayout` to change the template, and on systems running RPC >6.0, the screen manager should send `Show` to change the template.

### Java APIs
This will be set up in a similar way to the Obj-C APIs above. The `SDLTemplate` protocol and screen manager additions above would be translated into appropriate Java APIs. Any necessary changes are at the discretion of the Project Maintainer. However larger changes that would impact the Objective-C code above (such as adding or removing a method) will require proposal revisions.

### JavaScript APIs
The JavaScript APIs will be set up in a similar way to the Obj-C APIs above. The `SDLTemplate` protocol and screen manager additions above would be translated into appropriate JavaScript APIs. All changes will be at the discretion of the Project Maintainer. However larger changes that would impact the Objective-C code above (such as adding or removing a method) will require proposal revisions.

## Potential downsides

This proposal adds additional complexity to the manager layer to handle changing templates. This is a moderate source of complexity, however, this complexity burden is currently placed on each developer. Furthermore, this should enable developers to build more maintainable apps by separating out their code related to their individual template screens.

## Impact on existing code

This would be a minor version update to all libraries implementing a screen manager, namely, the iOS, Java, and JavaScript app libraries.

## Alternatives considered

1. We could only have an API to change the template and remove the push/pop APIs and separation of template screens, but the author determined that the change to allow developers to separate their code was a big improvement for developers who can now easily separate their unrelated SDL code into contained classes.
2. We could add an API that changes templates without using the `SDLTemplate` protocol (e.g. by simply passing a string), but the author determined that this would create confusion for developers and implementation difficulties to have two different ways to change templates.
