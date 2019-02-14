# High level interface: Overlay Controllers

* Proposal: [SDL-0201](0201-high-level-interface-overlay-controllers.md)
* Author: [Kujtim Shala](https://github.com/kshala-ford)
* Status: **In Review**
* Impacted Platforms: [ iOS ]

## Introduction

This proposal is based on [SDL 0156 High level interface: Foundation](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0156-high-level-interface-foundation.md) and [SDL 0176 High level interface: Views and Controllers](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0176-high-level-interface-views-and-controllers.md)) adding overlay controllers to the high level interface. These overlay controllers will make the use of RPCs such as `Alert`, `ScrollableMessage` etc. easier and more intuitive to iOS app developers.

## Motivation

In order to work with SDL, app developers need to learn a new API which mostly doesn't adopt familiar patterns. Including but not limited to:
- read best practices and implement proxy (manager) lifecycle
- the use of RPCs and handle notifications, requests and responses
- manually manage concurrent and sequential operations (e.g. image upload)

The time for an app developer to learn SDL (non-productive time) is high and not accepted by some developers. The SDL iOS library already improves the current situation by abstracting painful implementations. However the management layer is still unfamiliar and causes a high learning curve.

## Proposed solution

This proposal is about adding overlay controllers to the SDL library which extends `SDLViewController` (see [SDL 0176](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0176-high-level-interface-views-and-controllers.md)) used by `SDLApplication` (see [SDL 0156](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0156-high-level-interface-foundation.md)). With overlay controllers app developers can use RPCs such as `Alert`, `ScrollableMessage` or `Slider` and structure SDL related code of the app.

This proposal does not contain an overlay controller for choice sets or constant TBT. This will be proposed separately.

### Overlay controllers

Overlay controllers are responsible for overlay related RPCs such as `Alert`, `ScrollableMessage`, `PerformAudioPassThru`, `Slider` or `PerformInteraction` and `ShowConstantTBT` (proposed separately). Apps can instantiate overlay controllers and present them using the top view controller.

### SDLViewController (additions)

When a view controller wants to present an overlay controller, it must call `presentOverlayController:completion:` of itself.
The presenting VC must be top VC in the view controller stack. Calling the method will forward the presentation request to the VC manager.

```objc
@interface SDLViewController

// Presents the overlay controller on the display and calls the completion handler if the overlay controller disappears from the display or if an error occurred.
- (void)presentOverlayController:(SDLOverlayController *)overlayController completion:(SDLOverlayControllerCompletionHandler)completion;

@end
```

### SDLViewControllerManager (additions)

Independent of the current system context or how many items this list contains, the VC manager should:
1. Initiate the presentation (call `present` of the overlay controller class), then
2. Store the overlay controller and completion handler in an internal list.

The overlay controller should be able to listen to responses and notifications relevant to the presentation. If the overlay controller has detected the end of the presentation (or the app is disconnected) it should call the completion handler provided by the VC manager.

```objc
@interface SDLViewControllerManager

// This overlay controller is currently presented on the display.
@property (nonatomic, readonly) SDLOverlayController *presentedOverlayController;

@end

// Private sdl_ios interface extending VC manager with overlay related methods and properties
@interface SDLViewControllerManager ()

// Private method called by the view controller
- (void)presentOverlayController:(SDLOverlayController *)overlayController completion:(SDLOverlayControllerCompletionHandler)completion;

// Private list to store (pending) overlay controllers and completion handlers;
@property (nonatomic) NSMutableArray<SDLOverlayControllerStoreItem *> *overlayControllerStore;

@end

// private class to store the overlay controller and the completion handler
@interface SDLOverlayControllerStoreItem

@property (nonatomic, strong) SDLOverlayController *overlayController;

@property (nonatomic, copy) SDLOverlayControllerCompletionHandler completionHandler;

@end
```

### Handling multiple concurrent overlays

The internal list of overlay controllers and completion handlers is needed as the app could try to present multiple overlay controllers at the same time without waiting for an overlay to complete or finish. In order to control (or recover from) multiple overlay controllers the VC manager needs to store all of them in the internal list and request each overlay controller to get presented. The nature of the HMI overlays can be aborted by another overlay or get rejected due to the currently presented overlay priority. The private list offers flexibility in case the app calls the method multiple times, it can also deal with rejected overlays that were never visible and aborted overlays if another one is requested. At the end the property `presentedOverlayController` points to the oldest overlay controller of that internal list.

#### Example 1: Second overlay aborts first overlay

1. App presents `Alert` (A1) overlay
2. VC manager starts presenting A1 and stores it in the internal list
   - Internal list count == 1 [(A1)]
   - presented overlay controller is (A1)
3. A1 gets presented on the HMI
4. App presents another `Alert` (A2) overlay
5. VC manager starts presenting A2 and stores it in the internal list
   - Internal list count == 2 [(A1), (A2)]
   - presented overlay controller is (A1)
6. HMI aborts A1 and presents A2. HMI sends response for A1 with `ABORTED` resultCode
7. VC manager is notified with the completion handler of A1 and updates the internal list
   - internal list count == 1 [(A2)]
   - presented overlay controller is (A2)
8. App's completion handler for A1 is called notifying that A1 was aborted

#### Example 1: Second overlay is rejected due to first overlay

1. App presents `Alert` (A1) overlay
2. VC manager starts presenting A1 and stores it in the internal list
   - Internal list count == 1 [(A1)]
   - presented overlay controller is (A1)
3. A1 gets presented on the HMI
4. App presents another `Alert` (A2) overlay
5. VC manager starts presenting A2 and stores it in the internal list
   - Internal list count == 2 [(A1), (A2)]
   - presented overlay controller is (A1)
6. HMI rejects A2 and keeps A1 presented. HMI sends response for A2 with `REJECTED` resultCode
7. VC manager is notified with the completion handler of A2 and updates the internal list
   - internal list count == 1 [(A1)]
   - presented overlay controller is (A1)
8. App's completion handler for A1 is called notifying that A2 was rejected

### SDLOverlayController

This class should be used as the base class for any kind of overlay.

```objc

typedef void (^SDLOverlayControllerCompletionHandler)(SDLResult result, NSError *error);

@interface SDLOverlayController : SDLViewController

// The duration the overlay controller should be presented.
@property (nonatomic, assign, readonly) NSTimeInterval duration;

// internal (non-public) method overriden by subclasses and called by the VC manager
- (void)startPresentationWithApplication:(SDLApplication *)application completion:(SDLOverlayControllerCompletionHandler)completion;

- (instancetype)initWithDuration:(NSTimeInterval)duration;

@end
```

#### `duration`

Every overlay comes with a duration that specifies how long the view should be active on the HMI (visible on the screen). This parameter maps to all the different names used for duration such as `duration` (`Alert`), `timeout` (`Slider`, `PerformInteraction` and `ScrollableMesasge`) and `maxDuration` (`PerformAudioPassThru`).

Depending on the subclass (and the min/max values of the parameter) the duration value will be ignored if it exceeds the value range.
1. If `duration` value is greater than the max value, the RPC parameter should be set to max value.
2. If `duration` value is smaller than the min value, the RPC parameter should be set to min value.
3. If `duration` value is set to 0 and the RPC parameter is optional, the parameter should be omitted.
4. If `duration` value is set to 0 and the RPC parameter is required, the parameter should be set to max value (see `PerformAudioPassThru.maxDuration`).

### Main screen overlay

`SDLOverlayController` inherits `SDLViewController`. With this, it is possible to manipulate the app's main screen during a presentation. This can be very useful to:
- show a text message for "Loading..." or "Please wait" if the overlay takes more time to load
- add buttons to cancel the overlay request if possible.

This feature is planned in the proposal for Overlay controller related to choice sets.

To realize the above behavior, the app developer must create a new view and place it in the `view` property of the overlay controller. When presenting the overlay controller with a view object the view controller manager would override the full screen of the app, but it may be handy to just override a single text field. With that a new property should be added to `SDLView` for an opaque mode.

```objc
@interface SDLView

/**
 * Specifies whether the view is opaque. An opaque view will be presented on the app's screen
 * overriding all content from underlying views. If this property is set to NO the view is
 * transparent and the view controller manager will composite content from underlying views.
 * The default value is YES.
 */
@property (nonatomic, assign) BOOL opaque;

@end
```

If the `opaque` flag is set to NO the view will be called transparent. It should allow views or view parts from the underlying view controller to stay visible while the overlay controller is presenting. The opaque mode is view type related and allows overriding content per view. As an example, a transparent overlay, which contains a graphic will only override the graphic view of the underlying view. With this flag:
- the app developer has full control to decide on what to show and how to show it.
- the complexity is scalable per the app developers choice (no overlay view -> no screen changes)

#### Example: Top view controller's view hierarchy

- view (opaque)
  - textView (opaque) with four lines of text ("title", "artist", "album", "genre")
  - buttonView (opaque) with three buttons ("fav", "remove", "radio")
  - imageView (opaque) for primary graphic

App presents the following overlay controller (present list of albums) with view hierarchy:

- view (transparent)
  - textView (transparent) with one line of text ("loading")
  - buttonView (opaque) with one button ("cancel")

The resulting screen will be:

- four lines of text ("loading", "artist", "album", "genre") because root view and text view are opaque
- one button ("cancel") because button view is non-opaque
- primary graphic because overlay's root view is opaque an no image view is contained.

### SDLAlertController

The alert controller is used to abstract the RPC `Alert`. The properties match the parameters of the RPC.

```objc
@interface SDLAlertController : SDLOverlayController

@property (nonatomic, nullable, copy, readonly) NSString *message;

@property (nonatomic, nullable, copy, readonly) NSArray<SDLTTSChunk *> *prompt;
@property (nonatomic, nullable, copy, readonly) NSArray<SDLButtonView *> *buttons;

@property (nonatomic, assign, readonly) BOOL shouldPlayTone;
@property (nonatomic, assign, readonly) BOOL shouldShowProgressIndicator;

- (instancetype)initWithMessage:(nonnull NSString *)message
                        buttons:(nullable NSArray<SDLButtonView *> *)buttons;

- (instancetype)initWithPrompt:(nonnull NSArray<SDLTTSChunk *> *)prompt
                       buttons:(nullable NSArray<SDLButtonView *> *)buttons;

- (instancetype)initWithMessage:(nullable NSString *)message
                         prompt:(nullable NSArray<SDLTTSChunk *> *)prompt
                        buttons:(nullable NSArray<SDLButtonView *> *)buttons;

- (instancetype)initWithMessage:(nullable NSString *)message
                         prompt:(nullable NSArray<SDLTTSChunk *> *)prompt
                        buttons:(nullable NSArray<SDLButtonView *> *)buttons
                 shouldPlayTone:(BOOL)shouldPlayTone
    shouldShowProgressIndicator:(BOOL)shouldShowProgressIndicator
                       duration:(NSTimeInterval)duration;

@end
```

#### `message`

This string maps to `Alert.alertText[123]` and should be multi-line capable. The app developer should be able to set a single string with newline characters (\n).

#### `prompt`

This property is optional and maps to `Alert.ttsChunks`. The name of this property is chosen to be more aligned with other overlays.

#### `buttons`

This property is optional and maps to `Alert.softButtons` and uses the `SDLButtonView` class. The reason to use `SDLButtonView` is to be more aligned to the concept of using soft buttons on SDL views (see `SDLView` in [SDL 0176](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0176-high-level-interface-views-and-controllers.md)) )

#### `shouldPlayTone`

This property is optional and maps to `Alert.playTone`. By default this boolean is false. If this boolean is false when presenting `playTone` will be omitted.

#### `shouldShowProgressIndicator`

This property is optional and maps to `Alert.progressIndicator`. By default this boolean is false. If this boolean is false when presenting `progressIndicator` will be omitted.

### SDLAudioInputController

The audio input controller is used to abstract the RPC `PerformAudioPassThru`, `OnAudioPassThru` and `EndAudioPassThru`. The app developer should be able to provide a block which is called for audio data. Furthermore a method called `finish` should help to end the audio pass thru.

```objc
@interface SDLAudioInputController : SDLOverlayController

@property (nonatomic, nullable, copy, readonly) NSString *message;

@property (nonatomic, nullable, copy, readonly) NSArray<SDLTTSChunk *> *prompt;

@property (nonatomic, assign, readonly) BOOL muteMediaSource;

@property (nonatomic, nonnull, copy, readonly) SDLAudioPassThruCapabilities *capabilities;

@property (nonatomic, nonnull, copy, readonly) (^audioDataHandler)(NSData *audioData);

- (void)finish; // sends an EndAudioPassThru in order to stop audio input

- (instancetype)initWithMessage:(nullable NSString *)message
                         prompt:(nullable NSArray<SDLTTSChunk *> *)prompt
               audioDataHandler:(nonnull (^)(NSData *audioData))audioDataHandler;

- (instancetype)initWithMessage:(nullable NSString *)message
                         speech:(nullable SDLPrerecordedSpeech)speech
               audioDataHandler:(nonnull (^)(NSData *audioData))audioDataHandler;

- (instancetype)initWithMessage:(nullable NSString *)message
                         prompt:(nullable NSArray<SDLTTSChunk *> *)prompt
                muteMediaSource:(BOOL)muteMediaSource
                   capabilities:(nullable SDLAudioPassThruCapabilities *)capabilities
                       duration:(NSTimeInterval)duration
               audioDataHandler:(nonnull (^)(NSData *audioData))audioDataHandler;

- (instancetype)initWithMessage:(nullable NSString *)message
                         speech:(nullable SDLPrerecordedSpeech)speech
                muteMediaSource:(BOOL)muteMediaSource
                   capabilities:(nullable SDLAudioPassThruCapabilities *)capabilities
                       duration:(NSTimeInterval)duration
               audioDataHandler:(nonnull (^)(NSData *audioData))audioDataHandler;

@end
```

#### `message`

This property is optional and maps to `PerformAudioPassThru.audioPassThruDisplayText[12]` and should be multi-line capable. The app developer should be able to set a single string with newline characters (\n).

#### `prompt`

This property will be handled just like `SDLAlertController` and maps to `PerformAudioPassThru.initialPrompt`. Additional initializers should ask for a simple string or a prerecorded speech (e.g. LISTEN_JINGLE).

#### `capabilities`

`PerformAudioPassThru` requires the parameters `samplingRate`, `bitsPerSample` and `audioType` to be set. This is not necessary as the head unit informs the app about the audio setup it's capable of. Therefore the initializers of this overlay controller provide a parameter to set these three parameters based on a capabilities object. The controller will *not* compare this capabilities object with `RegisterAppInterfaceResponse.audioPassThruCapabilities`. The app developer can also ignore this parameter and let the overlay controller decide. The controller will then use the best option from `RegisterAppInterfaceResponse.audioPassThruCapabilities` (16 bit and 16 khz otherwise first item of `.audioPassThruCapabilities` array).

#### `muteMediaSource`

This property maps to `PerformAudioPassThru.muteAudio`. Some initializers of this overlay controller won't ask for this flag, therefore by default its set to YES. When starting this overlay controller the RPC request will always include the parameter `muteAudio` due to unspecific defvalue in the mobile API.

#### onAudioData (handler)

In order to stream the audio input to the app the developer should provide a code block to receive the audio input coming from the head unit. This code block is called whenever `OnAudioPassThru` notification is received.

### SDLScrollableMessageController

Similar to `Alert` this view controller takes care of the RPC `ScrollableMessage`.

```objc
@interface SDLScrollableMessageController : SDLOverlayController

@property (nonatomic, nonnull, copy, readonly) NSString *message;

@property (nonatomic, nullable, copy, readonly) NSArray<SDLButtonView *> *buttons;

- (instancetype)initWithMessage:(nonnull NSString *)message
                       duration:(NSTimeInterval)duration;

- (instancetype)initWithMessage:(nonnull NSString *)message
                        buttons:(nullable NSArray<SDLButtonView *> *)buttons
                       duration:(NSTimeInterval)duration;

@end
```

#### `message`

This property is optional and maps to `ScrollableMessage.scrollableMessageBody` and should be multi-line capable. The app developer should be able to set a single string with newline characters (\n).

#### `buttons`

This property is optional and maps to `ScrollableMessage.softButtons` and uses the `SDLButtonView` class. The reason to use `SDLButtonView` is to be more aligned to the concept of using soft buttons on SDL views (see `SDLView` in [SDL 0176](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0176-high-level-interface-views-and-controllers.md)) )

### SDLSliderController

This controller matches very closely to the view [`UISlider`](https://developer.apple.com/documentation/uikit/uislider) but for consistency of SDL it makes more sense to treat it as an overlay controller. In order to work with the RPC `Slider`, it is important to provide the selected value back to the caller. As of UIKit this is not done by using a custom completion handler, but simply providing the result in a property of the overlay controller.

As per mobile API the property `Slider.sliderFooter` is an array used for two purposes. Either it's a footer text (single item) or a list of names representing slider values (number of items must match `.numTicks`). This controller is used for the "single item" case. Another controller called `SDLValuePickerController` will be used for picking a named value (see next section). This helps to reduce complexity with properties being ignored (like min/max values).

```objc
@interface SDLSliderController : SDLOverlayController

@property (nonatomic, nonnull, copy, readonly) NSString *title;

@property (nonatomic, nullable, copy, readonly) NSString *message;

// minimumValue and maximumValue map to "Slider.numTicks"
// the range of the two values must not exceed "maxvalue" of "Slider.numTicks"
@property (nonatomic, readonly) NSInteger minimumValue;
@property (nonatomic, readonly) NSInteger maximumValue;

// maps to "Slider.position" *and* "SliderResponse.sliderPosition"
@property (nonatomic, readonly) NSInteger value;

- (instancetype)initWithTitle:(nonnull NSString *)title
                        value:(NSInteger)value
                 minimumValue:(NSInteger)minimumValue
                 maximumValue:(NSInteger)maximumValue;

- (instancetype)initWithTitle:(nonnull NSString *)title
                      message:(nonnull NSString *)message
                        value:(NSInteger)value
                 minimumValue:(NSInteger)minimumValue
                 maximumValue:(NSInteger)maximumValue;

@end
```

#### `title`

The `Slider` request comes with a set of string parameters. `sliderHeader` will be covered by the `title` property of the base class.

#### `message`

The `message` property maps to `Slider.sliderFooter` as a singleton array. As per mobile API this will result in a descriptive message explaining the meaning of the slider value.

#### `minimumValue` and `maximumValue` and `value`

The mobile API allows `.numTicks` value between 2 and 26. The value range for the parameter `.position` can be between 1 and 26 which means the range of values is not more than 26. With the high level abstraction slider controller can manage the specified range allowing different min and max values (though range should not exceed 26). This way apps can easily set a range from -10 to +10. This range is mapped internally to the available range. Future versions of the mobile API could increase the range which would be managed by the slider controller.

If the app does not provide a message the overlay controller creates localized numbers to translate `position` value to the user facing value using `NSNumberFormatter` and `localizedStringFromNumber:numberStyle:`.

The property `value` maps to `Slider.value` *and*  to `SliderResponse.sliderValue`. This means the result of this overlay (Slider response) is stored in the controller object.

### SDLValuePickerController

This controller is used to allow picking a named value. It also uses the RPC `Slider` but with value labels in an array.

```objc
@interface SDLValuePickerController : SDLOverlayController

@property (nonatomic, nonnull, copy, readonly) NSString *title;

@property (nonatomic, nonnull, copy, readonly) NSArray<NSString *> *valueLabels;

@property (nonatomic, readonly) NSInteger value;

- (instancetype)initWithTitle:(nonnull NSString *)title
                  valueLabels:(nonnull NSArray<NSString *> *)valueLabels
                        value:(NSInteger)value;

@end
```

#### `valueLabels`

This property maps to `Slider.SliderFooter`. It must not be a singleton array.

#### `value`

The property `value` behaves as the index for `valueLabel` The RPC parameter `Slider.numTicks` is set to the number of labels.

The property `value` maps to `Slider.value` *and*  to `SliderResponse.sliderValue`. This means the result of this overlay (Slider response) is stored in the controller object.

## Potential downsides

The initial workload in order to implement this high level interface is expected to be quite high. Once implemented it is expected that developers will be able to implement SDL into their apps in less time than they would need today. At the end the maintenance of the high level interface may be lower compared to the counterproposal for different reasons.

The block type `SDLOverlayControllerCompletionHandler` does not return the presented overlay instance. The best practice for overlays follows `UIAlertController` using local variables. See [`UIViewController.presentViewController:animated:completion:`](https://developer.apple.com/documentation/uikit/uiviewcontroller/1621380-presentviewcontroller) and [Objective-C Working with Blocks](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/WorkingwithBlocks/WorkingwithBlocks.html). The reason for not returning the presented overlay in the block is to avoid the pain of dealing with `__kindof` and casting back from the base class to the sub class. With that, a potential downside may happen if an app developer stores the presented view controller in a strong property which may cause a temporary retain cycle to `self` during presentation. This temporary retain cycle is acceptable as it is automatically released, therefore it will not cause any problems within the app. The gain of avoiding casts and `__kindof` for *every* usage is higher than the rare and hypothetical case of a developer storing the overlay instance in a strong property, especially as it is automatically released after the end of the presentation or after a disconnect. Last, the proposed way follows the existing practice.

This proposal mimics the native UI API. Compared to the counterproposal this proposal is not that close to the native UI kit experience. On the other side some SDL specific APIs can be easily abstracted and integrated into the rest of the high level interface.

## Impact on existing code

This proposal will add a total new high level interface layer abstracting many parts of SDL. Existing code should not be affected in a short term but it would make parts of the code obsolete therefore to be deprecated and/or made private.

## Alternatives considered

As discussed in the steering committee meeting from March 20 (see [here](https://github.com/smartdevicelink/sdl_evolution/issues/379#issuecomment-374736496)) this proposal is a counterproposal to [0133 - Enhanced iOS Proxy Interface](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0133-EnhancediOSProxyInterface.md).

Regarding `SDLSliderController` there is a different behavior depending on the existance of a message string. In the main proposal it is proposed to show either value strings *or* the message. The alternative solution would be to always show value strings and concatenate the message into each value string if provided. The concatenation would be `@"%ld\n%@"` where `%ld` is the value and `%@` is the message. The upside is that SDLC can merge translated values including a message. The downside is that the message is repeated for each value. Example:

```objc
[[SDLSliderController alloc] initWithTitle:@"Title" message:@"Negative, Neutral or Positive" value:0 minimumValue:-1 maximumValue:1];
```

presenting the above Slider would create the following `Slider` request:

```json
{
  "numTicks":3,
  "position":2,
  "sliderHeader":"Title",
  "sliderFooter":[
    "-1\nNegative, Neutral or Positive",
    "0\nNegative, Neutral or Positive",
    "1\nNegative, Neutral or Positive",
  ]
}
```


