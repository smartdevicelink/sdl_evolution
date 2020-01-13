# Add Scrollable Message and Slider to Screen Manager

* Proposal: [SDL-NNNN](NNNN-screen-manager-scrollable-message-and-slider.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Awaiting review**
* Impacted Platforms: [iOS / Java Suite / JavaScript Suite]

## Introduction
This proposal adds scrollable message and slider management to the screen manager API.

## Motivation
The screen manager should be capable of handling all screen related RPCs and features. Text, graphics, soft buttons, menus, and choice interactions are currently handled, but scrollable message and slider popups are not.

## Proposed solution
This proposal is to add an API to the `SDLScreenManager` for handling `Slider` and `ScrollableMessage` RPCs.

The proposed solution is to add a new private `SDLAlertManager` sub-manager to the screen manager to handle related capabilities, soft button image uploads, text concatenation, etc. The `SDLScreenManager` itself will then provide a simple public API for presenting these RPCs to the screen.

When `present` is called, if the soft buttons contain images, these will be uploaded before the `Slider` or `ScrollableMessage` is presented.

##### iOS
```objc
typedef void(^SDLScreenManagerSliderCompletionHandler)(NSUInteger selectedPosition, NSError *__nullable error);

- (void)presentScrollableMessageWithText:(NSString *)text timeout:(NSTimeInterval)timeout softButtons:(NSArray<SDLSoftButtonObject *> *)softButtons completionHandler:(SDLScreenManagerUpdateCompletionHandler)handler;

- (void)presentStaticSliderWithTitle:(NSString *)title footerText:(NSString *)footerText timeout:(NSTimeInterval)timeout numPositions:(NSUInteger)positions initialPosition:(NSUInteger)initialPosition completionHandler:(SDLScreenManagerSliderCompletionHandler)completionHandler;
- (void)presentDynamicSliderWithTitle:(NSString *)title values:(NSArray<NSString *> *)values timeout:(NSTimeInterval)timeout initialPosition:(NSUInteger)initialPosition completionHandler:(SDLScreenManagerSliderCompletionHandler)completionHandler;
```

##### Java Suite
```java
// TODO
```

## Potential downsides
This proposal provides a manager-level API for alerts. There is a [higher-level accepted proposal](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0201-high-level-interface-overlay-controllers.md) for dealing with overlays as well. We would be providing two separate APIs for alerts. However, (1) they are on different layers (one manager, one high-level), and we do this already for other APIs (like perform interactions). Furthermore, (2) the high-level API is intended to use the managers, and having this API available would make the high-level API easier to implement. Finally, (3) the high-level API requires a complete rewrite from developers for their SDL integration, while this API is purely additive.

## Impact on existing code
This is a minor version change for all proxy libraries.

## Alternatives considered
No alternatives were considered.