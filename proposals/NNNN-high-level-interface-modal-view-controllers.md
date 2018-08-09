# High level interface: Modal View Controllers

* Proposal: [SDL-NNNN](NNNN-high-level-interface-modal-view-controllers.md)
* Author: [Kujtim Shala](https://github.com/kshala-ford)
* Status: **Awaiting Review**
* Impacted Platforms: [ iOS ]

## Introduction

This proposal is based on [SDL 0156 High level interface: Foundation](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0156-high-level-interface-foundation.md) and [SDL 0176 High level interface: Views and Controllers](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0176-high-level-interface-views-and-controllers.md)) adding modal view controllers to the high level interface. These modal view controllers will make the use of RPcs such as `Alert`, `ScrollableMessage` etc. easier and more intuitive to iOS app developers.

## Motivation

In order to work with SDL, app developers need to learn a new API which mostly doesn't adopt familiar patterns. Including but not limited to 
- read best practices and implement proxy lifecycle (Android above all)
- the use of RPCs and handle notifications, requests and responses
- manually manage concurrent and sequential operations (e.g. image upload)

The time for an app developer to learn SDL (non-productive time) is high and not accepted by some developers. The SDL iOS library already improves the current situation by abstracting painful implementations. However the management layer is still unfamiliar and causes a high learning curve.

## Proposed solution

This proposal is about adding modal view controllers to the SDL library which extends `SDLViewController` (see [SDL 0176](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0176-high-level-interface-views-and-controllers.md)) used by `SDLApplication` (see [SDL 0156](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0156-high-level-interface-foundation.md)). With modal view controllers app developers can use RPCs showing overlays (such as Alert or Slider) and structure the SDL related code.

This proposal does not contain a modal representation of interacting choice sets. This will be proposed separately.

### Modal view controllers

Modal view controllers are responsible for overlay related RPCs such as `Alert`, `ScrollableMessage`, `PerformAudioPassThru`, `Slider` or `PerformInteraction` (proposed separately). Implementing overlays as modal view controllers would follow the modal-mode presentation of view controllers such as [`UIAlertController`](https://developer.apple.com/documentation/uikit/uialertcontroller).

Apps can instanciate modal view controller classes and present them using the view controller manager (VC manager).

#### SDLViewControllerManager (additions)

```objc
@interface SDLViewControllerManager

/**
 * This view controller is currently presenting a modal view on the screen.
 */
@property (nonatomic) SDLViewController *presentingModalViewController;

/**
 * This modal view controller is currently presented on the screen (by the presenting view controller).
 */
@property (nonatomic) SDLModalViewController *presentedModalViewController;

/**
 * Presents a modal view controller on the screen.
 * Calls the completion handler if the modal view controller disappears from the screen or if an error occurred.
 */
- (void)presentModalViewController:(SDLModalViewController *)modalViewController completion:(void (^)(SDLResult result, NSError *error))completion;

@end
```

When a view controller (presenting VC) want's to present a modal view controller (presented VC) it must call the `presentModalViewController:completion:` method of the view controller manager. The presenting VC must be listed in the view controller stack but does not need to be the top view controller. The presenting VC, presented VC and the completion handler are managed in a VC pair.

The VC manager should initiate the presentation (send the RPC request) and store the VC pair in a private list. It should be possible to associate RPC responses to the VC pair in the list. If a response is received and can be associated to a VC pair then the VC pair should be removed from the list and the completion handler should be called.

The oldest VC pair of this list should be the currently presenting and presented VC. The currently presenting VC will be accessible through the `.presentingModalViewController` property and the presented VC through the `.presentedModalViewController`. If the private list is empty the two properties should return nil.

By the nature of the HMI overlays can be aborted by another overlay or get rejected because of a currently presented overlay (or something of a higher priority e.g. VR session). The private list offers flexibility in case the app calls the method multiple times and can deal with rejected overlays that were never visible and aborted overlays if another one is requested.

#### SDLModalViewController

This class should be used as the base class for any kind of overlay. As it inherits `SDLViewController` it is possible to manipulate the head unit during a modal presentation.

```objc
@interface SDLModalViewController : SDLViewController

@property (nonatomic, assign) NSTimeInterval duration; // used throughout all subclasses
@property (nonatomic, copy) NSString *message; // used throughout all subclasses

- (void)present:(SDLApplication *)application; // private method called by the VC manager

@end
```

#### SDLAlertController

The alert controller is used to abstract the RPC `Alert`. The properties match the parameters of the RPC.

```objc
@interface SDLAlertController : SDLModalViewController

@property (nonatomic, copy) NSArray<SDLTTSChunk *> *initialPrompt;
@property (nonatomic, copy) NSArray<SDLSoftButton *> *buttons;

@property (nonatomic) BOOL shouldPlayTone;
@property (nonatomic) BOOL progressIndicator;

@end
``` 

#### SDLAudioInputController

The audio input controller is used to abstract the RPC `PerformAudioPassThru`, `OnAudioPassThru` and `EndAudioPassThru`. The app developer should be able to provide a block which is called for audio data. Furthermore a method called `dismiss` should help to end the audio pass thru.

```objc
@interface SDLAudioInputController : SDLModalViewController

@property (nonatomic, copy) NSArray<SDLTTSChunk *> *initialPrompt;
@property (nonatomic, copy) SDLSamplingRate samplingRate;
@property (nonatomic, copy) SDLBitsPerSample bitsPerSample;
@property (nonatomic, copy) SDLAudioType audioType;
@property (nonatomic) BOOL muteMediaSource;

@property (nonatomic) (^onAudioData)(NSData *audioData);

- (void)finish; // sends an EndAudioPassThru in order to stop audio input

@end
```

#### SDLScrollableMessageController

Similar to `Alert` this view controller takes care of the RPC `ScrollableMessage`.

```objc
@interface SDLScrollableMessageController : SDLModalViewController

@property (nonatomic, copy) NSArray<SDLSoftButton *> *buttons;

@end
```

#### SDLSliderController

This controller matches very closely to the view [`UISlider`](https://developer.apple.com/documentation/uikit/uislider) but for consistency to SDL it makes more sense to treat it as a modal controller. In order to work with the RPC `Slider` it is important to provide the selected value back to the caller. As of UIKit this is not done by using a custom completion handler but simply provide the result in a property of the modal view controller. As per mobile API the property `Slider.sliderFooter` is an array used for two purposes. Either it's a footer (single item) or a list of names representing slider values (number of items must match `.numTicks`). The mobile API allows `.numTicks` to be between 2 and 26. The value range for the parameter `.position` can between 1 and 26 which means the range of values is not more than 26. With the high level abstraction the modal controller can manage the specified range allowing different min and max values. Examples are ranges with negative which are mapped internally to the available range. Future versions of the mobile API could increase the range which would be managed by the slider controller.

```objc
@interface SDLSliderController : SDLModalViewController

@property (nonatomic, copy) NSString *title; // mapped with Slider.sliderHeader
@property (nonatomic, copy) NSArray<NSString *> *valueLables; // overrides control of SDLModalViewController.message 

// minimumValue and maximumValue map to `Slider.numTicks`
@property (nonatomic) NSInteger minimumValue;
@property (nonatomic) NSInteger maximumValue;

// maps to `Slider.position`
@property (nonatomic) NSInteger value;

@end
```

## Potential downsides

The initial workload in order to implement this high level interface is expected to be quite high. Once implemented it is expected that developers will be able to implement SDL into their apps in less time than they would need today. At the end the maintenance of the high level interface may be lower compared to the counterproposal for different reasons.

This proposal mimics the native UI API. Compared to the counterproposal this proposal is not that close to the native UI kit experience. On the other side some SDL specific APIs can be easily abstracted and integrated into the rest of the high level interface.

## Impact on existing code

This proposal will add a total new high level interface layer abstracting many parts of SDL. Existing code should not be affected in a short term but it would make parts of the code obsolete therefore to be deprecated and/or made private.

## Alternatives considered

No other alternative is considered.
