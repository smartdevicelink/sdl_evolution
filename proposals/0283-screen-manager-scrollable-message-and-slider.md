# Add Scrollable Message and Slider to Screen Manager

* Proposal: [SDL-0283](0283-screen-manager-scrollable-message-and-slider.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Accepted with Revisions**
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
@property (copy, nonatomic) NSString *text;

/**
 Maps to ScrollableMessage.timeout. Defaults to `defaultTimeout`. If set to 0, it will use `defaultTimeout`. The minimum is 3 seconds; the maximum is 65 seconds. If this is set below the minimum, it will be capped at 1 second. If this is set above the maximum, it will be capped at 65 seconds. Defaults to 0.
 */
@property (assign, nonatomic) NSTimeInterval timeout;

/**
 Maps to Alert.softButtons. Soft buttons the user may select to perform actions. Only one `SDLSoftButtonState` per object is supported; if any soft button object contains multiple states, an exception will be thrown.
 */
@property (nullable, copy, nonatomic) NSArray<SDLSoftButtonObject *> *buttons;

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
@property (assign, nonatomic) NSTimeInterval timeout;

/**
 Maps to Slider.sliderHeader. The text that is displayed as a title describing the modal.
*/
@property (copy, nonatomic) NSString *title;

/**
 Maps to Slider.position. The initial location of the slider handle. Must be a value between 1 and 26 and cannot exceed `numPositions` or an exception will be thrown.
*/
@property (assign, nonatomic) NSUInteger initialPosition;

/**
 Maps to Slider.numTicks. The number of values that will be available to the user on the slider. If the slider is created as a 'static' slider, then there will be one "footer" value and the 'ticks' on the slider will not have individual values. Must be a number between 2 and 26 or an exception will be thrown.
*/
@property (assign, nonatomic) NSUInteger numPositions;

/**
 Maps to Slider.sliderFooter. The values to be displayed on the slider if the slider is a 'dynamic' slider, or a single 'footer' string if the slider is created a 'static' slider. If it's a dynamic slider, there must be between 2 and 26 values or an exception will be thrown.
*/
@property (copy, nonatomic) NSArray<NSString *> *values;

- (instancetype)initWithStaticSliderTitle:(NSString *)title footerText:(nullable NSString *)footerText timeout:(NSTimeInterval)timeout numPositions:(NSUInteger)positions initialPosition:(NSUInteger)initialPosition;

- (instancetype)initWithDynamicSliderTitle:(NSString *)title values:(NSArray<NSString *> *)values timeout:(NSTimeInterval)timeout initialPosition:(NSUInteger)initialPosition;

/**
 Cancels the slider modal. If the RPC has not yet been sent to Core, it will not be sent. If the slider is already presented on Core, it will be immediately dismissed. Canceling an already presented slider will only work if connected to Core versions 6.0+. On older versions of Core, it will not be dismissed.
*/
- (void)cancel;

@end
```

##### Java Suite
```java
public class ScrollableMessageView {
    private class Integer defaultTimeout = 30;

    private String text;
    private Integer timeout;
    private List<SoftButtonObject> buttons;

    // Add getters / setters for each

    public ScrollableMessageView(@NonNull String text, @Nullable Integer timeout, @Nullable List<SoftButtonObject> buttons)

    public void cancel()
}
```

```java
public class SliderView {
    private class Integer defaultTimeout = 10;

    private String title;
    private Integer timeout;
    private Integer initialPosition;
    private Integer numPositions;
    private List<String> values;

    // Add getters / setters for each
    
    public SliderView(@NonNull String title, @Nullable String footerText, @Nullable Integer timeout, @NonNull Integer initialPosition, @NonNull Integer numPositions)
    public SliderView(@NonNull String title, @Nullable Integer timeout, @NonNull Integer initialPosition, @NonNull List<String> values)

    public void cancel()
}
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

/**
 Present a slider
*/
- (void)presentSlider:(SDLSliderView *)sliderView completionHandler:(SDLScreenManagerSliderCompletionHandler)completionHandler;

@end
```

##### Java Suite
```java
public interface SliderCompletionListener {
    void onComplete(boolean success, Integer selectedPosition);
	void onError(String info);
}
```

```java
public class BaseScreenManager {
    public void presentScrollableMessage(ScrollableMessageView scrollableMessage, CompletionListener listener)
    public void presentSlider(SliderView slider, SliderCompletionListener listener)
}
```

### JavaScript Suite APIs
Due to the similarity between the iOS, Java Suite and eventual JavaScript Suite APIs, this proposal does not present the public APIs of the JavaScript Suite APIs – especially because the JavaScript Suite APIs do not currently have a screen manager layer. The JavaScript Suite APIs should mirror the iOS and Java Suite API appropriately and is up to the maintainers' discretion. However, if any changes needed to be made such that they impacted the iOS / Java Suite API (such as the alteration, addition, or removal of a method or property), then a proposal revision would be needed.

### Additional Implementation Notes
- The internal alert manager will observe the `ScrollableMessageResponse` and `SliderResponse` to know when it has finished presenting, and then call the `completionHandler`.
- The internal alert manager will always send the alert, even if the system context is not MAIN. If the response returns a failure to present, it will call the `completionHandler` with the error.
- The developer will not be notified when the alert appears on the screen, assuming no error occurred – see alternative #1 for possible ways to do that.
- The `SDLAlertManager` sub-manager will use queues to manage alert related requests, similar to how the `SDLChoiceSetManager` does.
- If any images fail to upload, the presentation of the scrollable message should continue without an error.
- The slider and scrollable message views should be copied as soon as they are passed in `presentSlider` and `presentScrollableMessage` to prevent the developer from altering the properties.

## Potential downsides
The creation of the alert sub-manager will be complex because it has to handle the creation of soft buttons and manage their IDs alongside the soft button manager. It will also have to upload the soft button images. However, this is all complexity that every SDL developer must currently consider when developing their app. This is especially difficult for them because they don't usually have to deal with uploading images and waiting until the upload is done.

## Impact on existing code
This is a minor version change for all proxy libraries.

## Alternatives considered
1. Instead of using completion handlers, the iOS library could use a delegate system for the slider and scrollable message. Then the view objects would take a delegate instead of the `SDLScreenManager` methods taking completion handlers.

```objc
@protocol SDLScrollableMessageViewDelegate <NSObject>

- (void)scrollableMessageView:(SDLScrollableMessageView *)scrollableMessageView didFailToAppearWithError:(NSError *)error;
- (void)scrollableMessageViewViewDidAppear:(SDLScrollableMessageView *)scrollableMessageView withWarning:(nullable NSError *)warning; // I don't know for certain if OnHMIStatus.context ALERT works for this.
- (void)scrollableMessageViewDidDismiss:(SDLScrollableMessageView *)scrollableMessageView;

@end
```

```objc
@protocol SDLSliderViewDelegate <NSObject>

- (void)sliderView:(SDLSliderView *)sliderView didFailToAppearWithError:(NSError *)error;
- (void)sliderViewViewDidAppear:(SDLSliderView *)sliderView withWarning:(nullable NSError *)warning; // I don't know for certain if OnHMIStatus.context ALERT works for this.
- (void)sliderViewDidDismiss:(SDLSliderView *)sliderView;

@end
```
