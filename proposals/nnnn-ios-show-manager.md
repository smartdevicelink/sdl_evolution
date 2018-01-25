# Show Manager - iOS

* Proposal: [SDL-NNNN](nnnn-ios-show-manager.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Awaiting review**
* Impacted Platforms: iOS

## Introduction

This proposal is to create a manager (akin to the file manager) that will give developers a high-level API to handle text (including metadata from [SDL-0073](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0073-Adding-Metadata-Types.md)), graphics, and soft buttons.

## Motivation

The current `Show` request is rather complex and hard to work with. It has several different components, all related to the home screen, some for media only (such as the media clock), and some more general. Because of the complexity of dealing with `Show` and it's components, we should provide a high level API to encapsulate it.

## Proposed solution

The solution to this problem is to provide a set of related managers centered around Show usage.


### SDLTextAndGraphicManager
First, the `SDLTextAndGraphicManager` would be designed to handle the `SDLShow` `mainField` properties and the `graphic` and `secondaryGraphic` properties.

#### Interfaces

##### SDLTextAndGraphicConfiguration
The class used to configure the `SDLTextAndConfigurationManager`.

```objc
@interface SDLTextAndGraphicConfiguration : NSObject

@property (copy, nonatomic) SDLTextAlignment alignment;
@property (copy, nonatomic) SDLMetadataType textField1Type;
@property (copy, nonatomic) SDLMetadataType textField2Type;
@property (copy, nonatomic) SDLMetadataType textField3Type;
@property (copy, nonatomic) SDLMetadataType textField4Type;

/**
 Create a default configuration. The alignment defaults to SDLTextAlignmentCenter. The Metadata types default to SDLMetadataTypeNone.

 @return A new configuration
 */
- (instancetype)init;

/**
 Create metadata tags describing the four text fields sent via `updateTextField1:textField2:textField3:textField4:`. These tags may be used by the system to present data elsewhere, for example, presenting the artist and song, or weather data, in another context than strictly your apps's.

 If the system does not support a full 4 fields, this will automatically be concatenated and properly describe the fields sent.

 If some fields describe your context and not others, pass an empty array for any you do not wish to describe. If no fields describe your context, do not call this method, as `SDLMetadataTypeNone` is the default. If you feel your context should be described, but none of the current metadata tags apply, contact us at http://slack.smartdevicelink.com/

 @param field1Type The metadata description of field 1
 @param field2Type The metadata description of field 2
 @param field3Type The metadata description of field 3
 @param field4Type The metadata description of field 4
 @param alignment The alignment of the text fields, if supported
 @return The configuration to feed to the SDLTextAndImageManager
 */
- (instancetype)initWithTextField1:(nullable SDLMetadataType)field1Type textField2:(nullable SDLMetadataType)field2Type textField3:(nullable SDLMetadataType)field3Type textField4:(nullable SDLMetadataType)field4Type alignment:(nullable SDLTextAlignment)alignment;

+ (instancetype)defaultConfiguration NS_SWIFT_UNAVAILABLE("Use the ordinary initializer");

@end
```

##### SDLTextAndGraphicManager
The new high-level manager developers use to update the `SDLShow` `mainField`s and graphics.

```objc
NS_ASSUME_NONNULL_BEGIN

/**
 The handler run when the update has completed

 @param error An error if the update failed and an error occurred
 */
typedef void(^SDLTextAndGraphicUpdateCompletionHandler)(NSError *__nullable error);

@interface SDLTextAndGraphicManager : NSObject

/**
 The current configuration of text metadata and alignment. If this is set, it will not change the current data on the screen but will take effect on the next update.
 */
@property (copy, nonatomic) SDLTextAndImageConfiguration *configuration;

@property (copy, nonatomic, readonly, nullable) NSString *textField1;
@property (copy, nonatomic, readonly, nullable) NSString *textField2;
@property (copy, nonatomic, readonly, nullable) NSString *textField3;
@property (copy, nonatomic, readonly, nullable) NSString *textField4;
@property (strong, nonatomic, readonly, nullable) SDLArtwork *primaryGraphic;
@property (strong, nonatomic, readonly, nullable) SDLArtwork *secondaryGraphic;

/**
 Create a Text and Image Manager with the default SDLTextAndImageConfiguration.

 @return A new SDLTextAndImageManager
 */
- (instancetype)init;

/**
 Create a Text and Image Manager with a custom SDLTextAndImageConfiguration.

 @param configuration The configuration to use
 @return A new SDLTextAndImageManager
 */
- (instancetype)initWithConnectionManager:(id<SDLConnectionManagerType>)connectionManager configuration:(SDLTextAndImageConfiguration *)configuration;

/**
 Update text fields with new text set into the text field properties. Pass an empty string `\@""` to clear the text field.
 
 If the system does not support a full 4 fields, this will automatically be concatenated and properly send the field available.
 
 If 3 lines are available: [field1, field2, field3 - field 4]

 If 2 lines are available: [field1 - field2, field3 - field4]
 
 If 1 line is available: [field1 - field2 - field3 - field4]
 
 Also updates the primary and secondary images with new image(s) if new one(s) been set. This method will take care of naming the files (based on a hash). This is assumed to be a non-persistant image.
 
 If it needs to be uploaded, it will be. Once the upload is complete, the on-screen graphic will be updated.

 @param handler A handler run when the fields have finished updating, with an error if the update failed
 */
- (void)updateWithCompletionHandler:(SDLTextAndGraphicUpdateCompletionHandler)handler;

@end

NS_ASSUME_NONNULL_END
```

Similar to other managers, the `SDLTextAndGraphicManager` is initialized with a configuration to setup its metadata and alignment. Because the metadata and alignment may need to change over the course of the app's lifetime, the configuration may be updated with a new metadata and alignment. Future text updates will then use that new configuration.

#### Internals
The internals of this are generally up in the air. The main question comes when the user sends a second update within a short span of time, or even before the previous one completes. Or, when the user sends an update with text and an image that is not currently uploaded. This will be implemented as a very simple two update queue for both text and graphics.

* If there is no current update, the requested update will be performed immediately.
* If there is an in-progress update, the current update will be queued and performed immediately after the current one returns.
* If there is an in-progress update and a queued update, the queued update will be replaced by the new update and sent when the current update completes.
* If there is text and a non-uploaded image, the text will be immediately sent and the image will be queued to be set when it finishes uploading.

#### Auto-pull manual `Show` requests
Any `SDLShow` message sent through `SDLTextAndImageManager` will be cached in the `currentField1` etc. If the developer needs to manually send an `SDLShow`, the `SDLManager` will watch for it and forward that message to the `SDLTextAndImageManager` which will update its properties.

### SDLSoftButtonManager

#### Interfaces

##### SDLSoftButtonState
```objc
NS_ASSUME_NONNULL_BEGIN

@interface SDLSoftButtonState : NSObject

/**
 The name of this soft button state
 */
@property (copy, nonatomic, readonly) NSString *name;

/**
 The artwork to be used with this button or nil if it is text-only
 */
@property (strong, nonatomic, readonly, nullable) SDLArtwork *artwork;

/**
 The text to be used with this button or nil if it is image-only
 */
@property (copy, nonatomic, readonly, nullable) NSString *text;

/**
 Whether or not the button should be highlighted on the UI
 */
@property (assign, nonatomic, getter=isHighlighted) BOOL highlighted;

/**
 Create the soft button state. Either the text or artwork or both may be set.

 @param stateName The name of this state for the button
 @param text The text to be displayed on the button
 @param artwork The artwork to be displayed on the button
 @return A new soft button state
 */
- (instancetype)initWithStateName:(NSString *)stateName text:(nullable NSString *)text artwork:(nullable SDLArtwork *)artwork;

@end

NS_ASSUME_NONNULL_END
```

A specific state for a soft button. Many soft buttons may have a single state; examples of soft buttons with multiple states would be a "repeat" button that has a "repeat off" state, "repeat one" state, and "repeat all" state, each with different text and/or image.

##### SDLSoftButtonWrapper
```objc
NS_ASSUME_NONNULL_BEGIN

@interface SDLSoftButtonWrapper : NSObject

/**
 The name of this button
 */
@property (copy, nonatomic, readonly) NSString *name;

/**
 All states available to this button
 */
@property (copy, nonatomic, readonly) NSArray<SDLSoftButtonState *> *states;

/**
 The name of the current state of this soft button
 */
@property (copy, nonatomic, readonly) NSString *currentStateName;

/**
 The handler to be called when the button is in the current state and is pressed
 */
@property (strong, nonatomic, readonly) SDLRPCButtonNotificationHandler eventHandler;

/**
 Create a multi-state (or single-state, but you should use initWithName:state: instead for that case) soft button. For example, a button that changes it's image or text, such as a repeat or shuffle button.

 @param name The name of the button
 @param states The states available to the button
 @param eventHandler The handler to be called when the button is in the current state and is pressed
 @param initialStateName The first state to use
 */
- (void)initWithName:(NSString *)name states:(NSArray<SDLSoftButtonState *> *)states initialStateName:(NSString *)initialStateName handler:(SDLRPCButtonNotificationHandler)eventHandler;

/**
 Create a single-state soft button. For example, a button that brings up a Perform Interaction menu.

 @param name The name of the button
 @param eventHandler The handler to be called when the button is in the current state and is pressed
 @param state The single state of the button
 */
- (void)initWithName:(NSString *)name state:(SDLSoftButtonState *)state handler:(SDLRPCButtonNotificationHandler)eventHandler;

/**
 Transition the soft button to another state in the `states` property. The wrapper considers all transitions valid (assuming a state with that name exists).
 
 @warning This method will throw an exception and crash your app (on purpose) if you attempt an invalid transition. So...don't do that.

 @param stateName The next state.
 */
- (void)transitionToState:(NSString *)stateName;

@end

NS_ASSUME_NONNULL_END
```

A wrapper of one or multiple states for a soft button

##### SDLSoftButtonManager
```objc
NS_ASSUME_NONNULL_BEGIN

@interface SDLSoftButtonManager : NSObject

/**
 An array of soft button wrappers containing soft button states. This is the current set of soft buttons in the process of being displayed or that are currently displayed. To display a new set of soft buttons, set this property.
 */
@property (copy, nonatomic) NSArray<SDLSoftButtonWrapper *> *softButtons;

/**
 Create a soft button manager with a connection manager

 @param connectionManager The manager that forwards RPCs
 @return A new instance of a soft button manager
 */
- (instancetype)initWithConnectionManager:(id<SDLConnectionManagerType>)connectionManager;
- 
/**
 Update a particular button's current state into a new state and update the screen.

 @param connectionManager The manager that forwards RPCs
 @return A new instance of a soft button manager
 */
- (void)updateButtonNamed:(NSString *)buttonName replacingCurrentStateWithState:(SDLButtonState *)state;

@end

NS_ASSUME_NONNULL_END
```

The actual manager that handles translating the soft button wrappers and states into RPCs.

#### Internals
The soft button manager attempts to make it clearer and easier to set soft buttons, especially those that change themselves with different states when pressed, such as repeat or shuffle buttons. Developers create states for a specific button (though some buttons may need only one state), which is then composed into a button wrapper (because our naming sucks here), which is then set into the manager.

The wrapper carries the event handler so that developers can transition states within the handler.

To update the buttons, either developers can update an individual button to a new state through the `SDLSoftButtonWrapper`. If the buttons themselves are changing, the developer can set the `softButtons` array of the `SDLSoftButtonManager`.

## Potential downsides
* The proposed `SDLSoftButtonManager` does not work particularly well for dynamic soft buttons. The best support is to use the `updateButtonNamed:replacingCurrentStateWithState:`.

* `Show` contains quite a number of sub-APIs within it and turns out to be fairly complex, with corner cases abounding. Dealing with those corner cases for developers is the goal of this API, but also presents its biggest risk. As developers rely more on this API, it must provide a consistent and reasonable interface to developers while providing them with clear guidelines on what may be going wrong when something does go wrong. Error handling and recovery is easier (in some senses) when you're manually sending RPCs, but as complexity gets layered on top of the manual RPCs, consistency and clarity are needed.

With that said, this is still a vital improvement and these issues have been addressed before (for example with the File Manager). We just have to be good about continuous bug fixes and enhancements as needs arise.

## Impact on existing code

The changes should be purely additive (a minor version change) with new classes coming into existence where there were none. This would be hooked up to the Lifecycle Manager and started then. The developer would be able to interact with it at that point.

## Alternatives considered

1. (Technically an addition) We are commonly asked how to clear the primary / secondary graphic. There is no good way to currently do this I am aware of outside of sending a transparent PNG. We could bundle such a transparent PNG and add methods to the `SDLTextAndGraphicManager`: `clearPrimaryGraphic` and `clearSecondaryGraphic`. These methods would send that transparent PNG to "clear" the graphic from the screen. The only downside is if the remote head unit doesn't support such a transparent PNG, then the proxy is doing something "wrong" for that head unit.
2. Theoretically we could have the developer set the text and image properties on `SDLTextAndGraphicManager` and send show updates. The downside to this is the possiblity of sending multiple Shows in a very short time. It could be mitigated by setting a timer and the Show request is only sent, say 100 ms after the first property was set.
