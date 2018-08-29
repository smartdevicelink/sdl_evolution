# Update SetMediaClockTimer Initializers

* Proposal: [SDL-NNNN](NNNN-setmediaclocktimer-initializers.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Awaiting review**
* Impacted Platforms: [iOS, Android]

## Introduction
This proposal is to update the SDL mobile library `SetMediaClockTimer` class with initializers to assist developers with creating RPCs for each of the use cases of that RPC.

## Motivation
Initializers can be very helpful for developers to create correct code. The `SetMediaClockTimer` RPC has several very specific use cases, however the initializers do not assist developers in creating those use cases correctly.

## Proposed solution
The proposed solution is to add initializers to the RPC classes to assist developers in creating `SetMediaClockTimer` objects conforming to each of the use-cases.

```objc
// Will return nil if startTime is greater than endTime
+ (instancetype)countUpWithStartTime:(NSTimeInterval)startTime endTime:(NSTimeInterval)endTime audioIndicator:(nullable SDLAudioStreamingIndicator)audioIndicator;
+ (instancetype)countUpWithStartTime:(SDLStartTime *)startTime endTime:(SDLStartTime *)endTime audioIndicator:(nullable SDLAudioStreamingIndicator)audioIndicator;

// Will return nil if startTime is lesser than endTime
+ (instancetype)countDownWithStartTime:(SDLStartTime *)startTime endTime:(SDLStartTime *)endTime audioIndicator:(nullable SDLAudioStreamingIndicator)audioIndicator;
+ (instancetype)countDownWithStartTime:(SDLStartTime *)startTime endTime:(SDLStartTime *)endTime audioIndicator:(nullable SDLAudioStreamingIndicator)audioIndicator;

+ (instancetype)pauseWithAudioIndicator:(nullable SDLAudioStreamingIndicator)audioIndicator;
+ (instancetype)resumeWithAudioIndicator:(nullable SDLAudioStreamingIndicator)audioIndicator;
+ (instancetype)clearWithAudioIndicator:(nullable SDLAudioStreamingIndicator)audioIndicator;
```

Changes similar to these should be made on Android. Additionally, old initializers should be deprecated.

## Potential downsides
There are no downsides. This adds additional initializers, but doesn't remove any functionality.

## Impact on existing code
This is a minor version change on the mobile platforms.

## Alternatives considered
No alternatives have been considered.