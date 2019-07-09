# Screen Manager Audio Pass Thru Support

* Proposal: [SDL-NNNN](NNNN-screen-manager-audio-pass-thru.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Awaiting review**
* Impacted Platforms: [iOS / Java Suite]

## Introduction
This proposal adds audio pass thru management and handling to the screen manager API.

## Motivation
The screen manager should be capable of handling all screen related RPCs and features. Text, graphics, soft buttons, menus, and choice interactions are currently handled, but `AudioPassThru` (APT) is not.

## Proposed solution
The proposed solution is to add a new private `SDLAudioPassThruManager` sub-manager to the screen manager. This manager will handle APT-related capabilities, text, callbacks, etc. The `SDLScreenManager` itself will then provide a simple public API for presenting an APT to the screen.

##### Objective-C
```objc
@interface SDLAudioInputView

/**
 * Set this to change the default timeout for all APTs. If a timeout is not set on an individual choice set object (or if it is set to 0.0), then it will use this timeout instead. See `timeout` for more details. If this is not set by you, it will default to 10 seconds. The max is 1000 seconds.
 */
@property (class, assign, nonatomic) NSTimeInterval defaultDuration;

@property (strong, nonatomic, nullable) NSString *title;
@property (strong, nonatomic, nullable) NSString *text;
@property (assign, nonatomic) BOOL *muteAudio; // Defaults to YES
@property (assign, nonatomic) NSTimeInterval defaultDuration;

// If not set, this will default to the primary head unit capability
@property (nonatomic, nonnull, copy, readonly) SDLAudioPassThruCapabilities *capabilities;

- (instancetype)initWithTitle:(nullable NSString *)title text:(nullable NSString *)text muteAudio:(BOOL)muteAudio maxDuration:(NSTimeInterval)maxDuration capabilities:()

@end

@interface SDLScreenManager
// Existing properties and methods

/**
 Called when new audio data arrives. Return YES to continue receiving audio data and NO to cancel the audio input interaction.
 */
typedef BOOL (^SDLAudioDataHandler)(NSData *__nullable audioData);

// APT-specific properties and methods
- (void)presentAudioInputView:(SDLAudioInputInteraction *)interaction withAudioDataHandler:(SDLAudioDataHandler)audioDataHandler completionHandler:(nullable SDLScreenManagerUpdateHandler)completionHandler; // TODO: Determine if this is sent before or after the APT disappears.
@end
```

##### Java
`// TODO`

## Potential downsides

Describe any potential downsides or known objections to the course of action presented in this proposal, then provide counter-arguments to these objections. You should anticipate possible objections that may come up in review and provide an initial response here. Explain why the positives of the proposal outweigh the downsides, or why the downside under discussion is not a large enough issue to prevent the proposal from being accepted.

## Impact on existing code

Describe the impact that this change will have on existing code. Will some SDL integrations stop compiling due to this change? Will applications still compile but produce different behavior than they used to? Is it possible to migrate existing SDL code to use a new feature or API automatically?

## Alternatives considered

Describe alternative approaches to addressing the same problem, and why you chose this approach instead.