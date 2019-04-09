# Screen Manager Template Management

* Proposal: [SDL-NNNN](NNNN-screenmanager-push-pop.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Awaiting review**
* Impacted Platforms: [iOS / Android / Web]

## Introduction

Adds the ability to separate SDL code according to template, as well as to push and pop templates via the proxy library Screen Manager instead of having to do all template manipulation manually via the `SetDisplayLayout` RPC.

## Motivation

The manager layer should be able to handle most tasks that used to be handled by RPCs, and the Screen Manager in particular should be able to handle manipulating the screen and templates. One big area that it is currently missing is the ability to manage changing templates, currently done with the `SetDisplayLayout` RPC. This proposal seeks to provide an API for manipulating templates in an easy way for app developers, and an optional way for developers to more cleanly separate their SDL code.

## Proposed solution

To make this happen, we will add a new `SDLTemplate` protocol for developers to more cleanly separate their SDL-related code into separate classes and to enable the push / pop feature:

```objc
@protocol SDLTemplate <NSObject>

/**
 * The layout that will be used for the `SetDisplayLayout` call. You will likely want to return an `SDLPredefinedLayout` enum string.
 */
@property (copy, nonatomic, readonly) NSString *layoutName;

/**
 * Called immediately before the Screen Manager calls `SetDisplayLayout` for this template layout. Data can be pulled from the database or the network, but must not be shown on the screen until `templateActivated` is called.
 */
- (void)templateActivating;

/**
 * Called immediately after the head unit has responded with a successful `SetDisplayLayout`. Data can now be shown on the screen. Note that data from the previous template will remain. You can call `ScreenManager.clearScreen` in this method to quickly clear the screen. 
 */
- (void)templateActivated;

/**
 * The template failed to appear on the screen for some reason. The `SetDisplayLayout` likely failed.
 */
- (void)templateFailedToActivateWithError:(NSError *)error;

/**
 * Called immediately before the Screen Manager calls `SetDisplayLayout` to change the template away from this template and to a new template.
 */
- (void)templateDeactivating;

/**
 * Called immediately after the head unit has responded with a successful `SetDisplayLayout` and changed to a different template. This template is no longer displayed on the screen.
 */
- (void)templateDeactivated;

/**
 * Another template failed to appear on the screen for some reason meaning that this template is remaining on screen. The `SetDisplayLayout` likely failed.
 */
- (void)templateFailedToDeactivateWithError:(NSError *)error;

@end
```

Developers may build classes that implement this protocol in order to separate their SDL code so that each "screen" gets its own class instead of all of their SDL code being all in one class. The template lifecycle methods are called by the screen manager as the screen manager internally calls `SetDisplayLayout` to manipulate these templates appearing and disappearing from the screen, using the `layout` property to determine which layout to call. If the next template layout to be shown is equivalent to the current template layout, then the `SetDisplayLayout` call will be skipped, but the lifecycle methods will still be called.

Additions will be made to the screen manager:

```objc
@interface SDLScreenManager : NSObject

// Everything that already exists

/**
 * The current stack of templates.
 */
@property (strong, nonatomic, readonly) NSArray<id<SDLTemplate>> *templateStack;

/**
 * The current template will deactivate, then the new template that is passed will activate and pushed onto the templateStack.
 */
- (void)pushTemplate:(id<SDLTemplate>)template;

/**
 * The current template will deactivate, then the previously displayed template will re-appear while the current template is removed from the templateStack.
 */
- (void)popTemplate;

/**
 * The current template will deactivate. The template stack will be cleared except for the first item, which will either activate, or be replaced if a new template is passed. That new template will then activate.
 */
- (void)popToRootTemplate:(nullable id<SDLTemplate>)newRootTemplate;

/**
 * The current template will deactivate. Then the new template will activate by replacing the current template on the stack instead of pushing it onto the stack.
 */
- (void)replaceCurrentTemplateWithNewTemplate:(id<SDLTemplate>)newTemplate;

/**
 * All text, images, and soft buttons will be cleared from the screen. Preloaded choices and menu items will remain.
 */
- (void)clearScreen;

@end
```

## Potential downsides

This is an alternative (manager-level) API to the ["High-Level" API](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0156-high-level-interface-foundation.md). There could theoretically be confusion between the two, however:

1. This proposed manager-level API is _much_ simpler than the high-level version of it. This API is intended as a simple, lightweight alternative that can be implemented quickly as opposed to the implementation of the very heavy high-level API that is still in the process of being proposed. 
2. The high-level API will use the manager layer, meaning that it can build on top of this fairly simple API.
3. The high-level API is at a totally different layer than this manager-level API, so developers who never move to the high-level API can use this improvement, which is purely additive.

## Impact on existing code

This would be a minor version update to all libraries implementing a screen manager, namely, the iOS, Android, and Java-EE proxy APIs.

## Alternatives considered

1. We could wait for the entire high-level API to be implemented, but that may not happen for quite some time and requires developers to rewrite their SDL integration. This update is an additive update that developers may or may not use.
2. Developers could all roll their own push/pop template API, but we can make this much easier for developers by rolling it all into the manager layer.