# Mobile Choice Set Manager

* Proposal: [SDL-NNNN](nnnn-mobile-choice-manager.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Awaiting review**
* Impacted Platforms: [iOS / Android]

## Introduction

This proposal is to create a new sub-manager to the Screen Manager that assists developers in creating and performing Choice Sets.

## Motivation

Choice Sets are one of the most complicated and sometimes confusing APIs SDL offers. Properly using Choice Sets can be quite difficult, especially for developers not well versed in the platform. Currently the developer must create `Choice` RPC structs, assign IDs, assign those to `CreateChoiceInteractionSet` RPCs, assign an ID to that, and upload it, send a `PerformInteractionChoiceSet` RPC, and watch for the response choice ID and do something based on that choice.

## Proposed solution

The proposed solution is to build a manager for Choice Sets, making it easier to send them without having to track IDs, keep track of uploaded images, etc.

Below is an example iOS API. The Android API may be somewhat different, as there is currently no manager layer. However, this iOS API may be considered an example of what the Android API will look like, and assuming that the manager layer exists eventually, it should look quite similar.

### SDLChoiceCell

This basic building block replicates the `Choice` RPC, except without the ID (since that will be set by the SDLChoiceSetManager), and with `SDLArtwork`s instead of `Image` RPC structs, so that we may upload the image whenever needed.

```objc
NS_ASSUME_NONNULL_BEGIN

@interface SDLChoiceCell

@property (copy, nonatomic, readonly) NSString *title;
@property (copy, nonatomic, readonly, nullable) NSString *text;
@property (copy, nonatomic, readonly, nullable) NSString *subText;
@property (copy, nonatomic, readonly) NSArray<NSString *> *voiceCommands;
@property (strong, nonatomic, readonly, nullable) SDLArtwork *artwork;
@property (strong, nonatomic, readonly, nullable) SDLArtwork *secondaryArtwork;

@end

NS_ASSUME_NONNULL_END
```

### Choice Set

A `SDLChoiceSetObject` is a blending of the `CreateInteractionChoiceSet` and `PerformInteractionChoiceSet` RPCs. The developer only has to create this single layout for each choice interaction set, and the manager will handle uploading the artworks, choices, etc. properly.

```objc
NS_ASSUME_NONNULL_BEGIN

@interface SDLChoiceSetObject
@property (copy, nonatomic, readonly) NSString *title;
@property (copy, nonatomic, readonly, nullable) NSArray<SDLTTSChunk *> *voicePrompt;
@property (copy, nonatomic, readonly) SDLInteractionLayout layout;
@property (assign, nonatomic, readonly) TimeInterval timeout;
@property (copy, nonatomic, readonly, nullable) NSArray<SDLTTSChunk *> *timeoutVoicePrompt;
@property (copy, nonatomic, readonly, nullable) NSArray<SDLTTSChunk *> *helpVoicePrompt;

@property (weak, nonatomic, readonly) id<SDLChoiceSetDelegate> delegate;
@property (copy, nonatomic, readonly) NSArray<SDLChoiceObject *> *choices;
@end

NS_ASSUME_NONNULL_BEGIN
```

### SDLChoiceSetDelegate

The choice set delegate will be implemented by the developer to receive callbacks regarding the choice sets they've uploaded.

```objc
NS_ASSUME_NONNULL_BEGIN

@protocol SDLChoiceSetDelegate<NSObject>

- (void)choiceSet:(SDLChoiceSet *)choiceSet didSelectChoice:(SDLChoice *)choice withSource:(SDLTriggerSource)source;
- (void)choiceSet:(SDLChoiceSet *)choiceSet didReceiveError:(NSError *)error;

// This is a less common use case, but if the app is using a choice set with search, this is where the text from the search can be retrieved
- (void)choiceSet:(SDLChoiceSet *)choiceSet didReceiveText:(NSString *)text fromSource:(SDLTriggerSource)source;

@optional
// If not implemented, defaults to NO
- (BOOL)shouldDeleteChoiceSet;

@end

NS_ASSUME_NONNULL_END
```

### Screen Manager Additions

The screen manager additions allow the developer to present a "dynamic" choice set, that is, one that is created just for this particular instance and may not be invoked again with the same items. Alternatively, a "static" choice set may be uploaded (and should be very early on, it can be done even before the app is connected and the manager will intelligently upload when it can) which is expected to be presented with the same items every time it is invoked.

```objc
@interface SDLScreenManager

...

- (void)presentDynamicChoiceSet:(SDLChoiceSetObject *)set mode:(SDLInteractionMode)mode;
- (NSUInteger)uploadStaticChoiceSet:(SDLChoiceSetObject *)set;
- (void)presentStaticChoiceSetWithId:(NSUInteger)id mode:(SDLInteractionMode)mode;

...

@end
```

### Caching Dynamic Choice Sets

When dynamic choice sets are uploaded, one choice set will be created per choice. These will be left on the head unit unless the developer returns YES in the `shouldDeleteChoiceSet:` method. If the developer returns YES, then all of the choices and artworks (unless persistant) will be deleted once the selection is made and complete. If the developer returns NO (or doesn't implement the delegate method), then the choices and artworks will remain. If the developer attempts another dynamic choice set containing an `SDLChoiceObject` with the same exact parameters, the choice will be reused. If the same artwork is used (but not the same text), the image on the head unit will be reused.

### Automatic IDs

Choice & Choice Set IDs will be intelligently assigned and reused automatically.

## Potential downsides

The main potential downside is that this is not the UI Manager. It does not automatically set the correct mode based on whether the user selects via voice or physical press (which the UI manager may be able to do). It should, however, make creating choice sets much easier without needing to track IDs, with `Choice` caching in dynamic sets, and a generally friendlier API. It is also not entirely dissimilar from the `UITableView(Cell)` API.

This API also does not consider the Keyboard use-case. Creating and using a keyboard seems shoehorned into the ChoiceSet API by the author. Therefore, a separate manager / high-level API should be created specifically for the keyboard use-case. Additionally, the keyboard cannot be used by non-`NAVIGATION` developers and therefore has a much smaller audience.

## Impact on existing code

This should be a minor version change to the mobile libraries only.

## Alternatives considered

No alternatives were considered by the author.
