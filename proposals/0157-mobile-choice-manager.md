# Mobile Choice Set Manager

* Proposal: [SDL-0157](0157-mobile-choice-manager.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Accepted with Revisions**
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

@property (copy, nonatomic, readonly) NSString *text;
@property (copy, nonatomic, readonly, nullable) NSString *secondaryText;
@property (copy, nonatomic, readonly, nullable) NSString *tertiaryText;
@property (copy, nonatomic, readonly, nullable) NSArray<NSString *> *voiceCommands;
@property (strong, nonatomic, readonly, nullable) SDLArtwork *artwork;
@property (strong, nonatomic, readonly, nullable) SDLArtwork *secondaryArtwork;

- (instancetype)initWithText:(NSString *)text;
- (instancetype)initWithText:(NSString *)text artwork:(nullable SDLArtwork *)artwork voiceCommands:(nullable NSArray<NSString *> *)voiceCommands;
- (instancetype)initWithText:(NSString *)text secondaryText:(nullable NSString *)secondaryText tertiaryText:(nullable NSString *)tertiaryText voiceCommands:(nullable NSArray<NSString *> *)voiceCommands artwork:(nullable SDLArtwork *)artwork secondaryArtwork:(nullable SDLArtwork *)secondaryArtwork;

@end

NS_ASSUME_NONNULL_END
```

### Choice Set

A choice set is "presented" using the ScreenManager.

```objc
typedef NS_ENUM(NSUInteger, SDLChoiceSetLayout) {
    SDLChoiceSetLayoutList,
    SDLChoiceSetLayoutTiles,
};
```

```objc
NS_ASSUME_NONNULL_BEGIN

@interface SDLChoiceSet

@property (copy, nonatomic, readonly) NSString *title;
@property (copy, nonatomic, readonly, nullable) NSArray<SDLTTSChunk *> *initialPrompt;
@property (copy, nonatomic, readonly) SDLChoiceSetLayout layout;
@property (assign, nonatomic, readonly) NSTimeInterval timeout;
@property (copy, nonatomic, readonly, nullable) NSArray<SDLTTSChunk *> *timeoutPrompt;
@property (copy, nonatomic, readonly, nullable) NSArray<SDLTTSChunk *> *helpPrompt;

@property (weak, nonatomic, readonly) id<SDLChoiceSetDelegate> delegate;
@property (copy, nonatomic, readonly) NSArray<SDLChoiceCell *> *choices;

- (instancetype)initWithTitle:(NSString *)title delegate:(id<SDLChoiceSetDelegate>)delegate layout:(SDLChoiceSetLayout)layout initialPrompt:(nullable NSArray<SDLTTSChunk *> *)initialPrompt choices:(NSArray<SDLChoiceCell *> *)choices;
- (instancetype)initWithTitle:(NSString *)title delegate:(id<SDLChoiceSetDelegate>)delegate layout:(SDLChoiceSetLayout)layout initialPrompt:(nullable NSArray<SDLTTSChunk *> *)initialPrompt timeout:(NSTimeInterval)timeout choices:(NSArray<SDLChoiceCell *> *)choices;

- (instancetype)initWithTitle:(NSString *)title delegate:(id<SDLChoiceSetDelegate>)delegate initialPrompt:(nullable NSArray<SDLTTSChunk *> *)initialPrompt timeoutPrompt:(nullable NSArray<SDLTTSChunk *> *)timeoutPrompt helpPrompt:(nullable NSArray<SDLTTSChunk *> *)helpPrompt choices:(NSArray<SDLChoiceCell *> *)choices;
- (instancetype)initWithTitle:(NSString *)title delegate:(id<SDLChoiceSetDelegate>)delegate layout:(SDLChoiceSetLayout)layout initialPrompt:(nullable NSArray<SDLTTSChunk *> *)initialPrompt timeoutPrompt:(nullable NSArray<SDLTTSChunk *> *)timeoutPrompt helpPrompt:(nullable NSArray<SDLTTSChunk *> *)helpPrompt choices:(NSArray<SDLChoiceCell *> *)choices;

@end

NS_ASSUME_NONNULL_BEGIN
```

### SDLChoiceSetDelegate

The choice set delegate will be implemented by the developer to receive callbacks regarding the choice sets they've uploaded.

```objc
NS_ASSUME_NONNULL_BEGIN

@protocol SDLChoiceSetDelegate<NSObject>

- (void)choiceSet:(SDLChoiceSet *)choiceSet didSelectChoice:(SDLChoiceCell *)choice withSource:(SDLTriggerSource)source;
- (void)choiceSet:(SDLChoiceSet *)choiceSet didReceiveError:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
```

```objc
NS_ASSUME_NONNULL_BEGIN

@protocol SDLKeyboardDelegate<NSObject>

// This will be sent upon ENTRY_SUBMITTED or ENTRY_VOICE
- (void)userDidSubmitInput:(NSString *)inputText withEvent:(SDLKeyboardEvent *)source;

// This will be sent if the keyboard event ENTRY_CANCELLED or ENTRY_ABORTED is sent
- (void)userDidCancelInputWithReason:(SDLKeyboardEvent)event;

@optional
// If keyboard properties different than ScreenManager.keyboardConfiguration are desired, this can be implemented and customized. A SetGlobalProperties will be sent just before the PresentInteraction and the other properties restored after it completes.
- (SDLKeyboardProperties *)customKeyboardConfiguration;

// This will be sent upon KEYPRESS to update KeyboardProperties.autoCompleteText
- (void)updateAutocompleteWithInput:(NSString *)currentInputText completionHandler:(void (^nonnull)(NSString *updatedAutocompleteText))completionHandler;

// This will be sent upon KEYPRESS to update KeyboardProperties.limitedCharacterSet
-(void)updateCharacterSetWithInput:(NSString *)currentInputText completionHandler:(void (^nonnull)(NSArray<NSString *> *updatedCharacterSet))completionHandler;

// This will be sent for any event that occurs with the event and the current input text
- (void)keyboardDidSendEvent:(nonnull SDLKeyboardEvent)event text:(nullable NSString *)currentInputText;

@end

NS_ASSUME_NONNULL_END
```

### Screen Manager Additions

The screen manager additions allow the developer to present a "dynamic" choice set, that is, one that is created just for this particular instance and may not be invoked again with the same items. Alternatively, a "static" choice set may be uploaded (and should be very early on, it can be done even before the app is connected and the manager will intelligently upload when it can) which is expected to be presented with the same items every time it is invoked.

```objc
@interface SDLScreenManager

...

// Return an error with userinfo [key: SDLChoiceCell, value: NSError] if choices failed to upload
typedef void(^SDLPreloadChoiceCompletionHandler)(NSError *error);

// The default keyboard configuration, this can be additionally customized per 
@property (strong, nonatomic) SDLKeyboardProperties *keyboardConfiguration;

// Cells will be hashed by their text, image names, and VR command text
@property (copy, nonatomic, readonly) NSSet<SDLChoiceCell *> *preloadedChoices;

// This can only take up to 100 items, if more are passed the completion handler will be called with an error
- (void)preloadChoices:(NSArray<SDLChoiceCell *> *)choices withCompletionHandler:(nullable SDLPreloadChoiceCompletionHandler)handler;
- (void)deleteChoices:(NSArray<SDLChoiceCell *> *)preloadedChoiceKeys;

- (void)presentSearchableChoiceSet:(SDLChoiceSet *)choiceSet mode:(SDLInteractionMode)mode withKeyboardDelegate:(id<SDLKeyboardDelegate>)delegate;
- (void)presentChoiceSet:(SDLChoiceSet *)set mode:(SDLInteractionMode)mode;

- (void)presentKeyboardWithInitialText:(NSString *)initialText delegate:(id<SDLKeyboardDelegate>)delegate;

...

@end
```

### Caching Dynamic Choice Sets

When dynamic choice sets are uploaded, one choice set will be created per choice. These will be left on the head unit until the developer calls `deleteChoices:`. If the developer calls that method, all of the choices and artworks (unless persistant) will be deleted. If the developer attempts another dynamic choice set containing an `SDLChoiceSet` with the same hashed information, the choice will be reused. If the same artwork is used (but not the same text), the image on the head unit will be reused.

### Automatic IDs

Choice & Choice Set IDs will be intelligently assigned and reused automatically.

### Optional Choice VRs

Some head units break from the RPC spec and allow Choice voice recognition phrases to be optional, and in the future they should be optional for everyone. To assist with this, the choice set manager, upon first HMI FULL, will send a placeholder `ChoiceCell` without any VR attached. If the head unit accepts this cell, future choices without VR will be allowed to pass without VR. This cell will then be used for keyboard presentations, which require a choice. If the head unit rejects this cell, a new cell with a VR attached will be sent to be used for keyboard presentations, and future choices without VR will be given a placeholder VR matching their place in the presented list.

## Potential downsides

This use-case has been streamlined and simplified significantly, but the interface is still relatively complex, and the implementation will necessarily be so as well. There will be fewer options available to developers with the removal of the ability to have "static" choice sets, and there will be additional data sent over the wire to have dynamic choice sets.

## Impact on existing code

This should be a minor version change to the mobile libraries only.

## Alternatives considered

1. Instead of hashing the Cell and storing it in an `NSSet`, we could require the developer to place a unique "name" string on the Cell. This would allow storing it in an `NSDictionary` and easier lookup / deletion for the developer. However, this is deemed to be an unnecessary step and hashing to be adequate. It also has some advantages, such as automatically preventing the developer from creating and uploading multiple of the same Cell.
