# SDL Audio I/O Manager

* Proposal: [SDL-NNNN](nnnn-audio-io-manager.md)
* Author: [Kujtim Shala](https://github.com/kshala-ford)
* Status: **Awaiting review**
* Impacted Platforms: [ iOS ]

## Introduction

This proposal is about integrating a new manager to the sdl_ios library that allows reading audio data from the car microphone and send audio to the car speaker.

## Motivation

For mobile navigation apps supporting voice based location finding is an important feature allowing address search while driving. In the effort to support SDL partners, Ford worked together with nav app partner to develop a feature for audio input and output. The goal was to use "AudioPassThru" RPCs receiving audio from the car microphone and the audio service session from the SDL protocol specification to play audio.

The feature was originally located in the app as it was a joint development specifically for the app. Due to the substantial use of SDL it required quite some experience with SDL to maintain this code. Moving forward the partner requested to maintain it externally. The feature was refactored as an SDL manager and should now be part of the open source sdl_ios repository. 

## Proposed solution

As described in the motivation, the existing audio input and output feature is implemented in an SDL manager called `SDLAudioIOManager`. The goal is to add this manager to the sdl_ios repository and be part of the official library. Sources are attached to this proposal 

- [SDLAudioIOManager.h](../assets/proposals/nnnn-audio-io-manager/SDLAudioIOManager.h)
- [SDLAudioIOManager.m](../assets/proposals/nnnn-audio-io-manager/SDLAudioIOManager.m)
- [SDLAudioIOManagerDelegate.h](../assets/proposals/nnnn-audio-io-manager/SDLAudioIOManagerDelegate.h)

The manager requires to have a delegate that the app needs to implement. Delegate calls are notifications to the app to inform if an input or output stream has started or stopped and also which file was played. Audio data received from the input stream are forwarded to the app through the delegate. More details to each feature is listed below.

### State machine

The manager handles the input and the output stream in different states. Both streams can be `Stopped`, `Starting` and `Started`. In addition the input stream can be `Stopping` (as waiting for RPC responses), `Pausing` and `Paused`. The pause state will be described in detail in the next section.

### Audio Input Stream

The manager provides APIs for an input stream using `PerformAudioPassThru`. The developer can specify two properties for the initial prompt and the text that should be used when presenting the audio pass thru overlay. Other parameters to perform audio pass thru are based on audio capabilities provided in the `RegisterAppInterfaceResponse` or preset (audio is always muted, timeout is 100 seconds according to `maxvalue` in MOBILE_API). 

Audio data is received using the request's `audioDataHandler` callback. The first `OnAudioPassThru` notification will notify the app that the input stream has started. The audio data will be processed before forwarding to the app in order to boost the audio volume. This processing is helpful for certain voice recognition engines but also provides audio recording to other apps for  audio recording with a decent volume. 

The algorithm to boost the audio volume is loops through the audio samples per audio chunk and looks for the maximum possible audio volume multiplier but without causing clipping. This multiplier is stored for subsequent chunks. If any audio chunk returns with high volume samples (user hammers the microphone) the multiplier will be reduced to guarantee no clipping. Over the next silent chunks the multiplier will be slowly increased again to the maximum value. Theoretically this can be 6 seconds in worse case but experience showed that the volume is back to normal within one second. The algorithm is independent for the sampling rate and supports both sampling types 8-Bit (0 to 255 where mute is 128) and 16-Bit (-32,768 to 32,767 where mute is 0). This method is common basic audio recording or telephony. The related methods are in `sdl_calculateAmplifierFactor:size:` and `sdl_applyAmplifierFactor:data:size:`.

While the app receives amplified audio chunks the app can choose to end the input stream at any time. By doing so the manager sends `EndAudioPassThru` and waits for `PerformAudioPassThru` to end with a response. This response will notify the app about the audio input stream to be finished with a result code.

While the input stream is active, the app can also send audio files to be played on the output stream. In order to play the file the current audio pass thru has to end before sending the audio. The manager will try to "pause" the input stream by sending `EndAudioPassThru` and wait for the `PerformAudioPassThru` response. Once received the manager sends the audio data. Once the manager completed all files through the audio output stream the manager will send automatically continue the audio input stream by sending `PerformAudioPassThru` request.

#### Known bugs

There are known bugs related to the audio input stream and Audio pass thru.

Some times the head unit has issues in handling RPCs that can behave very differently:
1. HU stops sending `OnAudioPassThru` notifications
2. HU does not response to `PerformAudioPassThru`
3. HU does not handle `EndAudioPassThru`

Incorrect RPC messaging has severe issues to the operation of the managers. These issues were addressed when found on the head unit. However some vehicles are still equipped with affected software versions. In order to resolve the issues an abort timeout was added that aborts the input stream. This is done by simulating a `PerformAudioPassThru` response with `ABORTED` result code which requires knowledge about the correlation ID upon sending. This is not only necessary to keep the manager running but also remove dead RPC operations from the lifecycle manager's operation queue. The lifecycle manager's operation queue is configured for three concurrent tasks. Without this workaround the lifecycle manager can be stuck as it has to operate with only two concurrent tasks. Previous workarounds were able to recover the state machine but didn't remove the operation from the queue. Overtime this lead to in inoperable app if this error happens three times in one session. 

There is a race condition when the output stream has finished and the input stream should resume. It's not possible to identify the exact moment when the audio output has finished. The HMI priority matrix favors the audio service above audio pass thru. Therefore when sending `PerformAudioPassThru` too early the HMI will reply with `REJECT`. The manager wait's .5 seconds after it predicted audio output stop and retries the request two times also waiting .5 seconds if `REJECT` is received again. After three attempts the manager reverts the state machine to `Stopped` and notifies the app about the error.

### Audio Output Stream

The manager provides APIs to write audio files to the output stream using the audio service session held by the existing streaming audio manager. Before processing the first audio file the manager notifies the app that the output stream starts. The API is simplified as the demand is to play audio files always on demand. Any audio file written to the output stream will be first placed on an operation queue but immediately converted to PCM data and send to the audio service session. 

The only exception to start output stream is to wait for the input stream to finish. As already described in the previous section the input stream must be stopped before starting to send audio during this time the queue remains suspended and will be resumed as soon as the `PerformAudioPassThru` response is received.

Overtime the app can push additional files that will be added to the queue. As long as the manager's output stream is started it'll dequeue the audio files no matter what. For each file the manager reads the estimated playback time and dequeues the next file at the end of the current file. At the end of the last file the manager notifies the app about the output stream being stopped.

Attempts to start the input stream during active output stream will be held back in state `Starting`. The manager will automatically start the input stream then if the output stream stopped.

#### Known bugs

A race condition was identified on the head unit that occurs during an active output stream of multiple audio files. Previously the audio stream manager was used to send the audio files which continues sending audio data at the end of the current audio file. This results in an emptying audio input buffer on the head unit side which is immediately refilled. This short periods of empty audio buffer causes race conditions and blocks the fluent audio output stream.

This manager includes the audio encoding feature and changes the notification behavior. Starting with the first file the manager notifies the app one second in advance about the file being played. This is helpful when apps continue sending new files based on previous files being uploaded. This notification in advance is only performed for one file and doesn't add up with multiple files. This means the head unit's input stream won't empty if not intended and remains with at least 32 kB of data.

This workaround is actually a positive feature of the audio output stream as it provides a more fluent audio playback with no interrupts.

### Replacing `SDLAudioStreamManager`

The current manager `SDLAudioStreamManager` should be deprecated as the new `SDLAudioIOManager` provides the same functionality in addition to synchronizing with Audio pass thru. The only missing feature is to queue audio files before playing (`playNextWhenReady`).

## Potential downsides

A new manager replacing an existing manager instead of extending the existing manager is only possible with deprecations. Due to ht

## Impact on existing code

The current manager `SDLAudioStreamManager` should be deprecated as the new `SDLAudioIOManager` provides the same functionality in addition to synchronizing with Audio pass thru. The only missing feature is to queue audio files before playing (`playNextWhenReady`).

## Alternatives considered

The Java suite was not considered in this proposal because there does not exist an implementation of the Audio IO manager. This does not mean the author doesn't support other libraries. It is necessary to organize resources to work on the manager in advance if the vote is to add the manager also to the Java Suite.

For non-navigation apps this manager could be extended to use `Speak` with audio files to provide an output stream.