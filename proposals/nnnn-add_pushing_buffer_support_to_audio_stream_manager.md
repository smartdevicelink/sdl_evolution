# Add Pushing Buffer Support to AudioStreamManager

* Proposal: [SDL-NNNN](nnnn-add_pushing_buffer_support_to_audio_stream_manager)
* Author: [Bilal Alsharifi](https://github.com/bilal-alsharifi)
* Status: **Awaiting review**
* Impacted Platforms: [Java Suite / iOS]

## Introduction

This proposal is to add the ability to push an audio buffer to the `AudioStreamManager` so it supports playing audio from raw data in addition to supporting playing audio from actual files.

## Motivation

Currently, `AudioStreamManager` in Java Suite supports pushing audio source only from actual files. It doesn't support pushing an audio buffer. iOS, however, has that ability but not through the `AudioManager`. It can do that through the `StreamManager`:

```objc
[self.sdlManager.streamManager sendAudioData:audioData]
```

It will be useful to make `AudioStreamManager` in Java Suite support playing audio from a buffer as some apps may have the audio generated as a buffer rather than stored in an actual file. Also, adding a new API to `AudioStreamManager` in iOS to play audio from a buffer will make playing audio in iOS less confusing to developers. Moreover, that will make iOS and Java Suite APIs more aligned.


## Proposed solution

New API will be added to `AudioStreamManager` to support playing audio from a buffer:

### Java Suite
```java
public class AudioStreamManager extends BaseAudioStreamManager {
    ...
    public void pushBuffer(ByteBuffer data, final CompletionListener completionListener);
}
```

### iOS
```objc
@implementation SDLAudioStreamManager
...
- (void)pushWithData:(NSData *)data;
@end
```

## Potential downsides

The iOS library will end up having two possible APIs for playing audio from a buffer. One being in the `StreamManager` and one in the `AudioStreamManager`.

## Impact on existing code

This would be a minor version update to all libraries implementing `AudioStreamManger`, namely, the iOS, and Java Suite APIs.

## Alternatives considered

The alternative solution that was considered is to keep the current iOS APIs and just add new API to Java Suite but that will make the two libraries less aligned. 

