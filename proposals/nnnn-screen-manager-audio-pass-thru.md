# Screen Manager Microphone Input Manager

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

### Microphone Input View
##### iOS
```objc
@interface SDLMicrophoneInputView

/// Set this to change the default timeout for all microphone input. If a timeout is not set on an individual object (or if it is set to 0.0), then it will use this timeout instead. See `timeout` for more details. If this is not set by you, it will default to 10 seconds. The max is 1000 seconds.
@property (class, assign, nonatomic) NSTimeInterval defaultTimeout;

/// Maps to `PerformAudioPassThru.audioPassThruDisplayText1`. The primary text of the view.
@property (strong, nonatomic, nullable) NSString *text;

/// Maps to `PerformAudioPassThru.audioPassThruDisplayText2`. The secondary text of the view.
@property (strong, nonatomic, nullable) NSString *secondaryText;

/// Maps to `PerformAudioPassThru.initialPrompt`. Will play a prompt to the user before microphone input is begun.
@property (assign, nonatomic) SDLPlayAudioData *audioPrompt;

/// Maps to `PerformAudioPassThru.muteAudio`. If true, the head unit will mute any other audio output while the microphone input is in progress. This defaults to YES if not set.
@property (assign, nonatomic) BOOL *muteAudio;

/// Maps to `PerformAudioPassThru.maxDuration`. Defaults to `defaultTimeout`. If set to 0, it will use `defaultTimeout`. If this is set below the minimum, it will be capped at 1 second. Minimum 1 seconds, maximum 1000 seconds. If this is set above the maximum, it will be capped at 1000 seconds. Defaults to 0.
@property (assign, nonatomic) NSTimeInterval timeout;

// Maps to `PerformAudioPassThru.samplingRate`, `PerformAudioPassThru.bitsPerSample`, and `PerformAudioPassThru.audioType`. If not set, this will default to the primary head unit capability.
@property (nonatomic, nonnull, copy) SDLAudioPassThruCapabilities *capabilities;

- (instancetype)initWithPrimaryText:(nullable NSString *)primaryText secondaryText:(nullable NSString *)secondaryText muteAudio:(BOOL)muteAudio maxDuration:(NSTimeInterval)maxDuration capabilities:(nullable SDLAudioPassThruCapabilities *)capabilities;

@end
```

##### Java
```java
public class MicrophoneInputView {
    private Integer defaultTimeout = 10;

    private String text, secondaryText;
    private PlayAudioData audioPrompt;
    private boolean muteAudio;
    private Integer timeout;
    private SDLAudioPassThruCapabilities capabilities;
    
    // All vars have getters / setters

    public MicrophoneInputView(@Nullable String text, @Nullable String secondaryText, @Nullable PlayAudioData audioPrompt, @Nullable boolean muteAudio, @Nullable Integer timeout, @Nullable capabilities)
}
```

Note that the `PlayAudioData` class comes from another proposal that has not been accepted as of the writing of this proposal, and is [found here](https://github.com/smartdevicelink/sdl_evolution/pull/928/files#diff-05979b405babd4a720b6d0f3ecb98e9dR22).

### Screen Manager Updates
##### iOS
```objc
@interface SDLScreenManager
// Existing properties and methods


/// Called when new audio data arrives. Return YES to continue receiving audio data and NO to cancel the audio input interaction.
typedef BOOL (^SDLMicrophoneDataHandler)(NSData *__nullable audioData);

/// Create a view to receive raw microphone input information from the head unit. This maps to the SDLAudioPassThru RPC.
/// @param microphoneInputView The view that will be presented to the screen and various capabilities related to the microphone information that will be retrieved.
/// @param microphoneDataHandler A handler that will be called with raw audio data
/// @completionHandler A handler sent when the head unit sends a response and a possible error if one occurs.
- (void)presentMicrophoneInputView:(SDLMicrophoneInputView *)microphoneInputView withAudioDataHandler:(SDLMicrophoneDataHandler)microphoneDataHandler completionHandler:(nullable SDLScreenManagerUpdateHandler)completionHandler;

/// Dismisses the current microphone input view if there is one.
/// @param completionHandler A possible error if one occurs
- (void)dismissMicrophoneInputViewWithCompletionHandler:(nullable SDLScreenManagerUpdateHandler)completionHandler;

@end
```

##### Java
```java
public interface AudioDataListener {
    void onAudioData(byte[] audioData)
}

public class BaseScreenManager {
    public void presentMicrophoneInputView(@NonNull MicrophoneInputView view, @NonNull AudioDataListener audioDataListener, @Nullable CompletionListener completionListener)
    public void dismissMicrophoneInputView(@Nullable CompletionListener completionListener)
}
```

## Potential downsides
The author can not think of any downsides to this proposal.

## Impact on existing code
This would be a minor version change for each of the app libraries.

## Alternatives considered
1. For iOS, we could add another `presentMicrophoneInputView:` that uses a selector as well.