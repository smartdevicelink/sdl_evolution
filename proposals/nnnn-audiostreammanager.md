# SDLAudioStreamManager

* Proposal: [SDL-NNNN](NNNN-sdlaudiostreammanager.md)
* Author: [Joel Fischer](https://github.com/joeljfischer/), [Joey Grover](https://github.com/joeygrover)
* Status: **Awaiting review**
* Impacted Platforms: iOS, Android

## Introduction

This proposal provides an interface for automatically transcoding audio files – such as mp3 – to the SDL compatible PCM format, queueing these files, and playing them using the PCM audio stream available to `NAVIGATION` apps.

## Motivation

Navigation applications have to play their audio via the PCM byte stream channel, which is a very different interface than the standard iOS interface for playing audio. Due to this unfamiliarity, confusion may result. Furthermore, most applications' audio is not already in a compatible PCM audio format, and they are unlikely to alter their current audio sources to use PCM. We should provide an interface that will not only provide a more familiar API for playing through the byte stream audio channel, but should automatically transcode that audio before playback.

## Proposed solution

The proposed solution is to provide a standalone manager with a familiar interface and automatic transcoding.

The `SDLAudioStreamManager` will be a property of the `SDLStreamingMediaManager`. A delegate will be available for the developer if desired. The API of the manager will look like this:

### Public API

#### iOS
```objc
#import <Foundation/Foundation.h>

@class SDLAudioFile;
@class SDLManager;
@protocol SDLAudioStreamManagerDelegate;

NS_ASSUME_NONNULL_BEGIN

extern NSString *const SDLErrorDomainAudioStreamManager;

@interface SDLAudioStreamManager : NSObject

@property (weak, nonatomic) id<SDLAudioStreamManagerDelegate> delegate;

@property (assign, nonatomic, readonly, getter=isPlaying) BOOL playing;
@property (copy, nonatomic, readonly) NSArray<SDLAudioFile *> *queue;

- (instancetype)initWithManager:(SDLStreamingMediaManager *)streamManager;

/**
 Push a new file URL onto the queue after converting it into the correct PCM format for streaming binary data.

 @note This happens on a serial background queue and will provide an error callback to the delegate if the conversion fails.

 @param fileURL File URL to convert
 */
- (void)pushWithFileURL:(NSURL *)fileURL;

/**
 Play the next item in the queue. If an item is currently playing, it will continue playing and this item will begin playing after it is completed. If all items are playing via `playAll`, this will do nothing.

 When complete, this will callback on the delegate.
 */
- (BOOL)playNextWhenReady;

/**
 Stop playing the queue after the current item completes and clear the queue. If nothing is playing, the queue will be cleared.
 */
- (void)stop;

@end

NS_ASSUME_NONNULL_END
```

and the delegate:

```objc
#import <Foundation/Foundation.h>

@class SDLAudioFile;
@class SDLAudioStreamManager;

NS_ASSUME_NONNULL_BEGIN

@protocol SDLAudioStreamManagerDelegate <NSObject>

- (void)audioStreamManager:(SDLAudioStreamManager *)audioManager fileDidFinishPlaying:(SDLAudioFile *)file successfully:(BOOL)successfully;
- (void)audioStreamManager:(SDLAudioStreamManager *)audioManager errorDidOccurForFile:(SDLAudioFile *)file error:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
```

#### Android

**Note:** Android doesn't have an efficient way of transcoding audio files at the moment and encoders will either have to be written or implemented likely through the NDK and a separate project.

```java
public class AudioStreamManager implements ISdlServiceListener {

    ISdl internalInterface;
    boolean didRequestShutdown = false;
    BlockingQueue<SdlAudio> queue;


    public AudioStreamManager(ISdl internalInterface){
        this.internalInterface = internalInterface;
        queue = new BlockingQueue<SdlAudio>(){ ... }
    }

    public void start(boolean encrypted){
        if(internalInterface != null && internalInterface.isConnected()){
            internalInterface.addServiceListener(SessionType.PCM, this);
            internalInterface.startAudioService(encrypted);
        }
    }


    public void stop(){
        if(internalInterface != null && internalInterface.isConnected()){
            didRequestShutdown = true;
            internalInterface.stopAudioService();
        }
    }


    public void play(SdlAudioStream audioClip, boolean playImmediately){ ... }



    @Override
    public void onServiceStarted(SdlSession session, SessionType type, boolean isEncrypted) {}

    @Override
    public void onServiceEnded(SdlSession session, SessionType type) {
        if(didRequestShutdown && internalInterface != null){
            internalInterface.removeServiceListener(SessionType.PCM, this);
        }
    }

    @Override
    public void onServiceError(SdlSession session, SessionType type, String reason) {}

    
}

```

###### SdlAudioStream
This class will be added to handle the actual containing of the audio file to be played and is new to the Android library. It includes a call

```java
    public static class SdlAudioStream{
        URL url;
        File file;
        int resLocation;
        IStreamCallback callback;


        public interface IStreamCallback{
            void onFinished();
            void onError(String error);
        }
    }
```

This is the absolute minimum needed for a first release and could be expanded in the future (see the alternatives below). The above is fairly straightforward, but a few notes.

### The Queue

This manager uses a queue and a "playWhenReady" concept due to the need for transcoding. Whenever a file is pushed onto the queue, it is added to a serial background queue and will be transcoded to a temporary file. While in the queue, that file will be retained, once it has been played, the temporary file will be deleted.

By calling `playNextWhenReady`, the top item of the queue will be played when it has finished transcoding, if it has not already.

## Potential downsides

There are no major potential downsides, however, it does commit us to support. A prototype transcoder has been tested on mp3 files, but not on any other types of files.

## Impact on existing code

This will be a minor version change as it will add additional APIs.

## Alternatives considered

This API is fairly specifically designed. Additional capability could be added, though it is recommended that it not be added until a later time to focus on the initial core API.

### Data
Instead of only taking and transcoding files, it could transcode data as well.

### Additional Queue Capabilities
##### Methods

* `playAll` - Plays the entire queue (including those which are added during playback) until the queue is empty.
* `autoPlay` - Plays the queue as soon as items have finished transcoding until `stop` or `pause` (below) are called.
* `stop` - Stops sending audio files and clears the queue (this can be sent even if not currently playing). The current audio will finish.
* `pause` - Stops sending audio files and leaves the queue as is. The current audio will finish.

##### Properties
* `currentItemDuration` - The length of the top item in the queue or the currently playing item if one is playing.
* `queueDuration` - The length of the entire queue, not including the currently playing item if one is playing.
