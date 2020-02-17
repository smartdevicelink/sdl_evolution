# Screen Manager Audio Pass Thru Support

* Proposal: [SDL-NNNN](NNNN-screen-manager-audio-pass-thru.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Awaiting review**
* Impacted Platforms: [iOS / Java Suite / JavaScript Suite]

## Introduction
This proposal adds audio pass thru management and handling to the screen manager API.

## Motivation
The screen manager should be capable of handling all screen related RPCs and features. Text, graphics, soft buttons, menus, and choice interactions are currently handled, but `AudioPassThru` (APT) is not.

## Proposed solution
The proposed solution is to add a new private `SDLAudioPassThruManager` sub-manager to the screen manager. This manager will handle APT-related capabilities, text, callbacks, etc. The `SDLScreenManager` itself will then provide a simple public API for presenting an APT to the screen.

##### iOS
```objc
@interface SDLMicrophoneInputView

/// Set this to change the default timeout for all microphone input. If a timeout is not set on an individual object (or if it is set to 0.0), then it will use this timeout instead. See `timeout` for more details. If this is not set by you, it will default to 10 seconds. The max is 1000 seconds.
@property (class, assign, nonatomic) NSTimeInterval defaultTimeout;

/// Maps to `PerformAudioPassThru.audioPassThruDisplayText1`. The primary text of the view.
@property (strong, nonatomic, nullable) NSString *text;

/// Maps to `PerformAudioPassThru.audioPassThruDisplayText2`. The secondary text of the view.
@property (strong, nonatomic, nullable) NSString *secondaryText;

/// Maps to `PerformAudioPassThru.muteAudio`. If true, the head unit will mute any other audio output while the microphone input is in progress. This defaults to YES if not set.
@property (assign, nonatomic) BOOL *muteAudio;

/// Maps to `PerformAudioPassThru.maxDuration`. Defaults to `defaultTimeout`. If set to 0, it will use `defaultTimeout`. If this is set below the minimum, it will be capped at 1 second. Minimum 1 seconds, maximum 1000 seconds. If this is set above the maximum, it will be capped at 1000 seconds. Defaults to 0.
@property (assign, nonatomic) NSTimeInterval timeout;

// Maps to `PerformAudioPassThru.samplingRate`, `PerformAudioPassThru.bitsPerSample`, and `PerformAudioPassThru.audioType`. If not set, this will default to the primary head unit capability.
@property (nonatomic, nonnull, copy) SDLAudioPassThruCapabilities *capabilities;

- (instancetype)initWithPrimaryText:(nullable NSString *)primaryText secondaryText:(nullable NSString *)secondaryText muteAudio:(BOOL)muteAudio maxDuration:(NSTimeInterval)maxDuration capabilities:(nullable SDLAudioPassThruCapabilities *)capabilities;

@end

@interface SDLScreenManager
// Existing properties and methods

/**
 Called when new audio data arrives. Return YES to continue receiving audio data and NO to cancel the audio input interaction.
 */
typedef BOOL (^SDLMicrophoneDataHandler)(NSData *__nullable audioData);

// APT-specific properties and methods
- (void)presentMicrophoneInputView:(SDLMicrophoneInputView *)microphoneInputView withAudioDataHandler:(SDLMicrophoneDataHandler)microphoneDataHandler completionHandler:(nullable SDLScreenManagerUpdateHandler)completionHandler; // TODO: Determine if this is sent before or after the APT disappears.
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