# High level interface: Overlay Controllers

* Proposal: [SDL-NNNN](NNNN-high-level-interface-overlay-controllers.md)
* Author: [Kujtim Shala](https://github.com/kshala-ford)
* Status: **Awaiting Review**
* Impacted Platforms: [ iOS ]

## Introduction

This proposal is based on [SDL 0156 High level interface: Foundation](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0156-high-level-interface-foundation.md) and [SDL 0176 High level interface: Views and Controllers](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0176-high-level-interface-views-and-controllers.md)) adding overlay controllers to the high level interface. These overlay controllers will make the use of RPCs such as `Alert`, `ScrollableMessage` etc. easier and more intuitive to iOS app developers.

## Motivation

In order to work with SDL, app developers need to learn a new API which mostly doesn't adopt familiar patterns. Including but not limited to 
- read best practices and implement proxy (manager) lifecycle
- the use of RPCs and handle notifications, requests and responses
- manually manage concurrent and sequential operations (e.g. image upload)

The time for an app developer to learn SDL (non-productive time) is high and not accepted by some developers. The SDL iOS library already improves the current situation by abstracting painful implementations. However the management layer is still unfamiliar and causes a high learning curve.

## Proposed solution

This proposal is about adding overlay controllers to the SDL library which extends `SDLViewController` (see [SDL 0176](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0176-high-level-interface-views-and-controllers.md)) used by `SDLApplication` (see [SDL 0156](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0156-high-level-interface-foundation.md)). With overlay controllers app developers can use RPCs such as Alert, ScrollableMessage or Slider and structure the SDL related code.

This proposal does not contain a overlay controller for choice sets. This will be proposed separately.

### Overlay controllers

Overlay controllers are responsible for overlay related RPCs such as `Alert`, `ScrollableMessage`, `PerformAudioPassThru`, `Slider` or `PerformInteraction` (proposed separately). Apps can instantiate overlay controllers and then present them using the view controller manager (VC manager).

### SDLViewControllerManager (additions)

```objc

@interface SDLViewControllerManager

/**
 * This overlay controller is currently presented on the screen (by the presenting view controller).
 */
@property (nonatomic, readonly) SDLOverlayController *presentedOverlayController;

/**
 * Presents an overlay controller on the screen.
 * Calls the completion handler if the overlay controller disappears from the screen or if an error occurred.
 */
- (void)presentOverlayController:(SDLOverlayController *)overlayController completion:(SDLOverlayControllerCompletionHandler)completion;

// private list to store (pending) overlay controllers and completion handlers;
@property (nonatomic) NSMutableArray<SDLOverlayControllerStoreItem *> *overlayControllerStore;

@end

// private class to store the overlay controller and the completion handler
@interface SDLOverlayControllerStoreItem

@property (nonatomic, strong) SDLOverlayController *overlayController;

@property (nonatomic, copy) SDLOverlayControllerCompletionHandler completionHandler;

@end
```

When a view controller wants to present an overlay controller it must call the `presentOverlayController:completion:` method of the VC manager. 
The presenting VC must be listed in the view controller stack but does not need to be the top view controller. The VC manager should initiate the presentation 
(call `present` of the overlay controller class) and store the overlay controller and completion handler in an internal list. The overlay controller should be able to listen to responses and notification relevant to the presentation. If the overlay controller has detected the end of the presentation it should notify the VC manager.

The internal list of overlay controllers and completion handlers is needed as the app could try to present multiple overlay controllers. In order to control (or recover from) multiple overlay controllers the VC manager needs to store all of them in the internal list and request each overlay controller to get presented. By the nature of the HMI overlays can be aborted by another overlay or get rejected due to currently presented overlay priority. The private list offers flexibility in case the app calls the method multiple times and can deal with rejected overlays that were never visible and aborted overlays if another one is requested. At the end the property `presentedOverlayController` points to the oldes overlay controller of that internal list.

### SDLOverlayController

This class should be used as the base class for any kind of overlay.

```objc

typedef void (^SDLOverlayControllerCompletionHandler)(SDLResult result, NSError *error);

@interface SDLOverlayController : SDLViewController

// The duration the overlay controller should be presented.
@property (nonatomic, assign) NSTimeInterval duration;

// private method called by the VC manager
- (void)present:(SDLApplication *)application completion:(SDLOverlayControllerCompletionHandler)completion;

@end
```

As it inherits `SDLViewController` it is possible to manipulate the head unit during a presentation. To do that the app developer must create a new view and place it in the `view` property of the overlay controller.

#### `duration`

Every overlay comes with a duration that specifies how long the view should be active on the HMI (visible on the screen). This parameter maps to all the different names used for duration such as `duration` (`Alert`), `timeout` (`Slider`, `PerformInteraction` and `ScrollableMesasge`) and `maxDuration` (`PerformAudioPassThru`). 

Depending on the subclass (and the min/max values of the parameter) the duration value will be ignored if it exceeds the value range. 
1. If `duration` value is greater than the max value, the RPC parameter should be set to max value. 
2. If `duration` value is smaller than the min value, the RPC parameter should be set to min value.
3. If `duration` value is set to 0 and the RPC parameter is optional, the parameter should be omitted.
4. If `duration` value is set to 0 and the RPC parameter is required, the parameter should be set to max value (see `PerformAudioPassThru.maxDuration`).

### SDLAlertController

The alert controller is used to abstract the RPC `Alert`. The properties match the parameters of the RPC.

```objc
@interface SDLAlertController : SDLOverlayController

@property (nonatomic, nullable, copy) NSString *message;

@property (nonatomic, nullable, copy) NSArray<SDLTTSChunk *> *prompt;
@property (nonatomic, nullable, copy) NSArray<SDLButtonView *> *buttons;

@property (nonatomic, assign) BOOL shouldPlayTone;
@property (nonatomic, assign) BOOL shouldShowProgressIndicator;

- (instancetype)initWithMessage:(nonnull NSString *)message;

- (instancetype)initWithPrompt:(nonnull NSArray<SDLTTSChunk *> *)prompt;

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

This property is optional and maps to `Alert.ttsChunks`. The name of this property is chosen to be more aligned with other overlays. Convenient initializers should accept a single string to build the chunks array.

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

@property (nonatomic, nullable, copy) NSString *message;

@property (nonatomic, nullable, copy) NSArray<SDLTTSChunk *> *prompt;

@property (nonatomic, assign) BOOL muteMediaSource;

@property (nonatomic, nonnull, copy) SDLAudioPassThruCapabilities *capabilities;

@property (nonatomic, copy) (^onAudioData)(NSData *audioData);

- (void)finish; // sends an EndAudioPassThru in order to stop audio input

- (instancetype)initWithMessage:(nullable NSString *)message
                         prompt:(nullable NSArray<SDLTTSChunk *> *)prompt
                muteMediaSource:(BOOL)muteMediaSource
                   capabilities:(nullable SDLAudioPassThruCapabilities *)capabilities
                       duration:(NSTimeInterval)duration
             onAudioDataHandler:((^)(NSData *audioData))onAudioDataHandler;

- (instancetype)initWithMessage:(nullable NSString *)message
                         speech:(nullable SDLPrerecordedSpeech)speech
                muteMediaSource:(BOOL)muteMediaSource
                   capabilities:(nullable SDLAudioPassThruCapabilities *)capabilities
                       duration:(NSTimeInterval)duration
             onAudioDataHandler:((^)(NSData *audioData))onAudioDataHandler;
             
@end
```

#### `message`

This property is optional and maps to `PerformAudioPassThru.audioPassThruDisplayText[12]` and should be multi-line capable. The app developer should be able to set a single string with newline characters (\n).

#### `prompt`

This property will be handled just like `SDLAlertController` and maps to `PerformAudioPassThru.initialPrompt`. Additional initializers should ask for a simple string or a prerecorded speech (e.g. LISTEN_JINGLE).

#### `capabilities`

`PerformAudioPassThru` requires the parameters `samplingRate`, `bitsPerSample` and `audioType` to be set. This is not necessary as the head unit informs the app about the audio setup it's capable of. Therefore the initializers of this overlay controller provide a parameter to set these three parameters based on a capabilities object. The controller will *not* compare this capabilities object with `RegisterAppInterfaceResponse.audioPassThruCapabilities`. The app developer can also ignore this parameter and let the overlay controller decide. The controller will then use the best option from `RegisterAppInterfaceResponse.audioPassThruCapabilities` (16 bit and 16 khz otherwise first item of `.audioPassThruCapabilities` array).

#### onAudioData (handler)

In order to stream the audio input to the app the developer should provide a code block to receive the audio input coming from the head unit. This code block is called whenever `OnAudioPassThru` notification is received.

### SDLScrollableMessageController

Similar to `Alert` this view controller takes care of the RPC `ScrollableMessage`.

```objc
@interface SDLScrollableMessageController : SDLOverlayController

@property (nonatomic, nonnull, copy) NSString *message;

@property (nonatomic, nullable, copy) NSArray<SDLButtonView *> *buttons;

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

This controller matches very closely to the view [`UISlider`](https://developer.apple.com/documentation/uikit/uislider) but for consistency to SDL it makes more sense to treat it as an overlay controller. In order to work with the RPC `Slider` it is important to provide the selected value back to the caller. As of UIKit this is not done by using a custom completion handler but simply provide the result in a property of the overlay controller. 

As per mobile API the property `Slider.sliderFooter` is an array used for two purposes. Either it's a footer text (single item) or a list of names representing slider values (number of items must match `.numTicks`). This controller is used for the "single item" case. Another controller called `SDLValuePickerController` will be used for picking a named value (see next section). This helps to reduce complexity with properties being ignored (like min/max values).

```objc
@interface SDLSliderController : SDLOverlayController

@property (nonatomic, nonnull, copy) NSString *title;

@property (nonatomic, nullable, copy) NSString *message;

// minimumValue and maximumValue map to "Slider.numTicks"
// the range of the two values must not exceed "maxvalue" of "Slider.numTicks"
@property (nonatomic) NSInteger minimumValue;
@property (nonatomic) NSInteger maximumValue;

// maps to "Slider.position" *and* "SliderResponse.sliderPosition"
@property (nonatomic) NSInteger value;

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

The property `value` maps to `Slider.value` *and*  to `SliderResponse.sliderValue`. This means the result of this overlay (Slider response) is stored in the controller object.

### SDLValuePickerController

This controller is used to allow picking a named value. It also uses the RPC `Slider` but with value labels in an array.

```objc
@interface SDLValuePickerController : SDLOverlayController

@property (nonatomic, nonnull, copy) NSString *title;

@property (nonatomic, nonnull, copy) NSArray<NSString *> *valueLabels;

@property (nonatomic) NSInteger value;

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

This proposal mimics the native UI API. Compared to the counterproposal this proposal is not that close to the native UI kit experience. On the other side some SDL specific APIs can be easily abstracted and integrated into the rest of the high level interface.

## Impact on existing code

This proposal will add a total new high level interface layer abstracting many parts of SDL. Existing code should not be affected in a short term but it would make parts of the code obsolete therefore to be deprecated and/or made private.

## Alternatives considered

As discussed in the steering committee meeting from March 20 (see [here](https://github.com/smartdevicelink/sdl_evolution/issues/379#issuecomment-374736496)) this proposal is a counterproposal to [0133 - Enhanced iOS Proxy Interface](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0133-EnhancediOSProxyInterface.md).
