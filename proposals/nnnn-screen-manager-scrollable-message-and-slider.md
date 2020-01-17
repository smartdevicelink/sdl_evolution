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
This proposal is to add an API to the `SDLScreenManager` for handling the `Slider` and `ScrollableMessage` RPCs.

The proposed solution is to add a new private `SDLAlertManager` sub-manager to the screen manager to handle related capabilities, soft button image uploads, text concatenation, etc. The `SDLScreenManager` itself will then provide a simple public API for presenting these RPCs to the screen.

When `present` is called, if the soft buttons contain images, these will be uploaded before the `Slider` or `ScrollableMessage` is presented.

### ScrollableMessage and Slider Views
##### iOS
```objc
@interface SDLScrollableMessageView
/**
 Set this to change the default timeout for all scrollable messages. If a timeout is not set on an individual view (or if it is set to 0.0), then it will use this timeout instead. See `timeout` for more details. If this is not set by you, it will default to 30 seconds. The minimum is 1 second, the maximum is 65 seconds. If this is set below the minimum, it will be capped at 1 second. If this is set above the maximum, it will be capped at 65 seconds.
 */
@property (class, assign, nonatomic) NSTimeInterval defaultTimeout;

/**
 Maps to ScrollableMessage.scrollableMessageBody. Text to be displayed in the scrollable message. This text string can contain newline and tab characters.
 */
@property (copy, nonatomic, readonly) NSString *text;

/**
 Maps to ScrollableMessage.timeout. Defaults to `defaultTimeout`. If set to 0, it will use `defaultTimeout`. The minimum is 3 seconds; the maximum is 65 seconds. If this is set below the minimum, it will be capped at 1 second. If this is set above the maximum, it will be capped at 65 seconds. Defaults to 0.
 */
@property (assign, nonatomic, readonly) NSTimeInterval timeout;

/**
 Maps to Alert.softButtons. Soft buttons the user may select to perform actions. Only one `SDLSoftButtonState` per object is supported; if any soft button object contains multiple states, an exception will be thrown.
 */
@property (nullable, copy, nonatomic, readonly) NSArray<SDLSoftButtonObject *> *buttons;

- (instancetype)initWithText:(NSString *)text timeout:(NSTimeInterval)timeout buttons:(NSArray<SDLSoftButtonObject *>)buttons;

/**
 Cancels the scrollable message. If the RPC has not yet been sent to Core, it will not be sent. If the message is already presented on Core, it will be immediately dismissed. Canceling an already presented message will only work if connected to Core versions 6.0+. On older versions of Core, it will not be dismissed.
*/
- (void)cancel;

@end
```

```objc
@interface SDLSliderView
/**
 Set this to change the default timeout for all sliders. If a timeout is not set on an individual view (or if it is set to 0.0), then it will use this timeout instead. See `timeout` for more details. If this is not set by you, it will default to 10 seconds. The minimum is 1 second, the maximum is 65 seconds. If this is set below the minimum, it will be capped at 1 second. If this is set above the maximum, it will be capped at 65 seconds.
 */
@property (class, assign, nonatomic) NSTimeInterval defaultTimeout;

/**
 Maps to Slider.timeout. Defaults to `defaultTimeout`. If set to 0, it will use `defaultTimeout`. The minimum is 3 seconds; the maximum is 65 seconds. If this is set below the minimum, it will be capped at 1 second. If this is set above the maximum, it will be capped at 65 seconds. Defaults to 0.
 */
@property (assign, nonatomic, readonly) NSTimeInterval timeout;

/**
 Maps to Slider.sliderHeader. The text that is displayed as a title describing the modal.
*/
@property (copy, nonatomic, readonly) NSString *title;

/**
 The number of values that will be available to the user on the slider. If the slider is created as a 'static' slider, then there will be one "footer" value and the 'ticks' on the slider will not have individual values. Must be a number between 1 and 26 or an exception will be thrown.
*/
@property (assign, nonatomic, readonly) NSUInteger numValues;

/**
 Maps to Slider.sliderFooter. The values to be displayed on the slider if the slider is a 'dynamic' slider, or a single 'footer' string if the slider is created a 'static' slider.
*/
@property (copy, nonatomic, readonly) NSArray<NSString *> *values;

/**
 Cancels the slider modal. If the RPC has not yet been sent to Core, it will not be sent. If the slider is already presented on Core, it will be immediately dismissed. Canceling an already presented slider will only work if connected to Core versions 6.0+. On older versions of Core, it will not be dismissed.
*/
- (void)cancel;
@end
```

##### Java
```java
public class ScrollableMessageView {
    private Integer defaultTimeout = 30;

    private String text;
    private Integer timeout;
    private List<SoftButtonObject> buttons;

    // Also add getters for each 

    public ScrollableMessageView(String text, Integer timeout, List<SoftButtonObject> buttons)

    public void cancel()
}
```

```java
public class 
```

### ScreenManager Additions
##### iOS
```objc
@interface SDLScreenManager: NSObject

extern NSTimeInterval SDLScreenManagerDefaultTimeout; // Is 0 in the implementation, used for `View` class `timeout`s to activate the `defaultTimeout`.

/**
 This completion handler is used to return the user's selected position or an error if the slider fails. 
*/
typedef void(^SDLScreenManagerSliderCompletionHandler)(NSUInteger selectedPosition, NSError *__nullable error);

/**
 Present a scrollable message
*/
- (void)presentScrollableMessage:(SDLScrollableMessageView *)scrollableMessage completionHandler:(SDLScreenManagerUpdateCompletionHandler)handler;

- (void)presentStaticSliderWithTitle:(NSString *)title footerText:(NSString *)footerText timeout:(NSTimeInterval)timeout numPositions:(NSUInteger)positions initialPosition:(NSUInteger)initialPosition completionHandler:(SDLScreenManagerSliderCompletionHandler)completionHandler;
- (void)presentDynamicSliderWithTitle:(NSString *)title values:(NSArray<NSString *> *)values timeout:(NSTimeInterval)timeout initialPosition:(NSUInteger)initialPosition completionHandler:(SDLScreenManagerSliderCompletionHandler)completionHandler;

@end
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
1. Instead of 