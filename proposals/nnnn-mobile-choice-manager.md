# Mobile Choice Set Manager

* Proposal: [SDL-NNNN](nnnn-mobile-choice-manager.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Awaiting review**
* Impacted Platforms: [iOS / Android]

## Introduction

This proposal is to create a new sub-manager to the Screen Manager that assists developers in creating and performing Choice Sets.

## Motivation

Choice Sets are one of the most complicated and sometimes confusing APIs SDL offers. Properly using Choice Sets can be quite difficult, especially for developers not well versed in the platform.

## Proposed solution

The proposed solution is to build a manager for Choice Sets, making it easier to send them without having to track IDs, keep track of uploaded images, etc.

Below is an example iOS API. The Android API may be somewhat different, as there is currently no manager layer. However, this iOS API may be considered an example of what the Android API will look like, and assuming that the manager layer exists eventually, it should look quite similar.

### Choice Object

```objc
NS_ASSUME_NONNULL_BEGIN

typedef void(^SDLChoiceObjectSelectionHandler)();

@interface SDLChoiceObject

@property (copy, nonatomic, readonly) NSString *title;
@property (copy, nonatomic, readonly, nullable) NSString *text;
@property (copy, nonatomic, readonly, nullable) NSString *subText;
@property (copy, nonatomic, readonly) NSArray<NSString *> *voiceCommands;
@property (strong, nonatomic, readonly, nullable) SDLArtwork *artwork;
@property (strong, nonatomic, readonly, nullable) SDLArtwork *secondaryArtwork;

@end

NS_ASSUME_NONNULL_END
```

This basic building block replicates the `Choice` RPC, except without the ID (since that will be set by the SDLChoiceSetManager), and with `SDLArtwork`s instead of `Image` RPC structs, so that we may upload the image whenever needed.

### Choice Set

```objc
@interface SDLChoiceSetObject
@property (copy, nonatomic, readonly) NSString *title;
@property (copy, nonatomic, readonly) NSArray<SDLTTSChunk *> *voicePrompt;
@property (copy, nonatomic, readonly) SDLInteractionLayout layout;
@property (assign, nonatomic, readonly) TimeInterval timeout;
@property (copy, nonatomic, readonly) NSArray<SDLTTSChunk *> *timeoutVoicePrompt;
@property (copy, nonatomic, readonly) NSArray<SDLTTSChunk *> *helpVoicePrompt;

@property (copy, nonatomic, readonly) NSArray<SDLChoiceObject *> *choices;
@end
```

### Screen Manager Additions

```objc
@interface SDLScreenManager

...

- (void)presentDynamicChoiceSet:(SDLChoiceSetObject *)set mode:(SDLInteractionMode)mode withSelectionHandler:(BOOL (^nullable)(SDLChoiceObject *selectedChoice, NSError *error))handler;
- (NSUInteger)uploadStaticChoiceSet:(SDLChoiceSetObject *)set;
- (void)presentStaticChoiceSetWithId:(NSUInteger)id mode:(SDLInteractionMode)mode withSelectionHandler:(void (^nullable)(SDLChoiceObject *selectedChoice, NSError *error))handler;

...

@end
```

### Caching Dynamic Choice Sets

When dynamic choice sets are uploaded, one choice set will be created per choice. These will be left on the head unit unless the developer return YES in the selection handler. If the developer returns YES, then all of the choices and artworks will be deleted once the selection is made and complete. If the developer sets NO, then the choices and artworks will remain. If the developer attempts another dynamic choice set containing an `SDLChoiceObject` with the same exact parameters, the choice will be reused. If the same artwork is used (but not the same text), the image on the head unit will be reused.

### Automatic IDs

Choice & Choice Set IDs will be intelligently assigned and reused automatically.

## Potential downsides

The main potential downside is that this is not the UI Manager. It isn't entirely intuitive in the sense that it doesn't mimic the `UITableView(Cell)` API. It does not automatically set the correct mode based on whether the user selects via voice or physical press (which the UI manager may be able to do). It should, however, make creating choice sets much easier without needing to track IDs, with `Choice` caching in dynamic sets, and a generally friendlier API.

## Impact on existing code

This should be a minor version change to the mobile libraries only.

## Alternatives considered

No alternatives were considered by the author.