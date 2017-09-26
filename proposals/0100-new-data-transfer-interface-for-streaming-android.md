# New data transfer interface in Android Proxy for streaming

* Proposal: [SDL-0100](0100-new-data-transfer-interface-for-streaming-android.md)
* Author: [Sho Amano](https://github.com/shoamano83/)
* Status: **In Review**
* Impacted Platforms: [Android]

## Introduction

The purpose of this proposal is to add new data transfer interface between Android Proxy and an app for video and audio streaming.


## Motivation

Android Proxy uses `PipedInputStream`/`PipedOuputStream` to receive streaming data from an app. This interface is known to have following issues:

- Poor performance. Prior to API level 24, PipedInputStream/PipedOuputStream copy data one byte at a time. This can be a performance bottleneck.
  * Please refer to proposal [SDL-0069](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0069-enhance-video-streaming-performance-for-android.md) and [its discussion](https://github.com/smartdevicelink/sdl_evolution/issues/200) for details.
- No timestamp information. Some streaming formats, such as RTP, require timestamp information along with video frames. PipedInputStream/PipedOuputStream cannot convey such additional information.


## Proposed solution

This proposal introduces function-call style interfaces for data transferring instead of `PipedInputStream`/`PipedOuputStream`.

A public method `startVideoStream()` is added to `SdlProxyBase` class. It returns `IVideoStreamListener`. Video streaming app calls `IVideoStreamListener.sendFrame()` method to pass video data to Proxy.

A public method `startAudioStream()` is added to `SdlProxyBase` class. It returns `IAudioStreamListener`. Audio streaming app calls `IAudioStreamListener.sendAudio()` method to pass audio data to Proxy.

Existing methods - `startH264(InputStream, boolean)`, `startH264(boolean)`, `startPCM(InputStream, boolean)`, `startPCM(boolean)` are marked as deprecated.

Existing methods - `pauseH264()`, `pausePCM()`, `resumeH264()`, `resumePCM()`, `endH264()` and `endPCM()` will be renamed to `pauseVideoStream()`, `pauseAudioStream()`, `resumeVideoStream()`, `resumeAudioStream()`, `endVideoStream()`, `endAudioStream()`, respectively. i.e. New methods with same implementations are added, and existing methods will be marked as deprecated.


## Detailed design

### Interfaces between app and Proxy

```java
/**
 * A listener that receives video streaming data from app.
 */
public interface IVideoStreamListener {
    /**
     * Sends a chunk of data which represents a frame to SDL Core.
     *
     * The format of the chunk should align with MediaCodec's "Compressed Buffer" format, i.e. it
     * should contain a single video frame, and it should start and end on frame boundaries.
     * Please refer to https://developer.android.com/reference/android/media/MediaCodec.html
     * Also, for H.264 codec case the stream must be in byte-stream format (also known as Annex-B
     * format). This isn't explained in the document above, but MediaCodec does output in this
     * format.
     *
     * In short, you can just provide MediaCodec's data outputs to this method without tweaking
     * any data.
     *
     * Note: this method must not be called after SdlProxyBase.endVideoStream() is called.
     *
     * @param data               Byte array containing a video frame
     * @param offset             Starting offset in 'data'
     * @param length             Length of the data
     * @param presentationTimeUs Presentation timestamp (PTS) of this frame, in microseconds.
     *                           It must be greater than the previous timestamp.
     *                           Specify -1 if unknown.
     *
     * @throws ArrayIndexOutOfBoundsException When offset does not satisfy
     *                                        {@code 0 <= offset && offset <= data.length}
     *                                        or length does not satisfy
     *                                        {@code 0 < length && offset + length <= data.length}
     */
    void sendFrame(byte[] data, int offset, int length, long presentationTimeUs)
        throws ArrayIndexOutOfBoundsException;

    /**
     * Sends chunks of data which represent a frame to SDL Core.
     *
     * The format of the chunk should align with MediaCodec's "Compressed Buffer" format, i.e. it
     * should contain a single video frame, and it should start and end on frame boundaries.
     * Please refer to https://developer.android.com/reference/android/media/MediaCodec.html
     * Also, for H.264 codec case the stream must be in byte-stream format (also known as Annex-B
     * format). This isn't explained in the document above, but MediaCodec does output in this
     * format.
     *
     * In short, you can just provide MediaCodec's data outputs to this method without tweaking
     * any data.
     *
     * Note: this method must not be called after SdlProxyBase.endVideoStream() is called.
     *
     * @param data               Data chunk to send. Its position will be updated upon return.
     * @param presentationTimeUs Presentation timestamp (PTS) of this frame, in microseconds.
     *                           It must be greater than the previous timestamp.
     *                           Specify -1 if unknown.
     */
    void sendFrame(ByteBuffer data, long presentationTimeUs);
}

/**
 * A listener that receives audio streaming data from app.
 */
public interface IAudioStreamListener {
    /**
     * Sends a chunk of audio data to SDL Core.
     *
     * Note: this method must not be called after SdlProxyBase.endAudioStream() is called.
     *
     * @param data               Byte array containing audio data
     * @param offset             Starting offset in 'data'
     * @param length             Length of the data
     * @param presentationTimeUs (Reserved for future use) Presentation timestamp (PTS) of the
     *                           last audio sample data included in this chunk, in microseconds.
     *                           It must be greater than the previous timestamp.
     *                           Specify -1 if unknown.
     *
     * @throws ArrayIndexOutOfBoundsException When offset does not satisfy
     *                                        {@code 0 <= offset && offset <= data.length}
     *                                        or length does not satisfy
     *                                        {@code 0 < length && offset + length <= data.length}
     */
    void sendAudio(byte[] data, int offset, int length, long presentationTimeUs)
        throws ArrayIndexOutOfBoundsException;

    /**
     * Sends a chunk of audio data to SDL Core.
     *
     * Note: this method must not be called after SdlProxyBase.endAudioStream() is called.
     *
     * @param data               Data chunk to send. Its position will be updated upon return.
     * @param presentationTimeUs (Reserved for future use) Presentation timestamp (PTS) of the
     *                           last audio sample data included in this chunk, in microseconds.
     *                           It must be greater than the previous timestamp.
     *                           Specify -1 if unknown.
     */
    void sendAudio(ByteBuffer data, long presentationTimeUs);
}
```

### Addition to public methods

```java
public abstract class SdlProxyBase<proxyListenerType extends IProxyListenerBase> {
    ...

    /**
     * Opens a video service (service type 11) and subsequently provides an IVideoStreamListener
     * to the app to send video data.
     *
     * @param isEncrypted Specify true if packets on this service have to be encrypted
     * @param codec       Video codec which will be used for streaming. Currently, only
     *                    VideoStreamingCodec.H264 is accepted.
     * @param width       Width of the video in pixels
     * @param height      Height of the video in pixels
     *
     * @return IVideoStreamListener interface if service is opened successfully and streaming is
     *         started, null otherwise
     */
    public IVideoStreamListener startVideoStream(boolean isEncrypted, VideoStreamingCodec codec,
                                                 int width, int height) {
        ...
    }

    /**
     * Opens a audio service (service type 10) and subsequently provides an IAudioStreamListener
     * to the app to send audio data.
     *
     * Currently information passed by "params" are ignored, since Audio Streaming feature lacks
     * capability negotiation mechanism. App should configure audio stream data to align with
     * head unit's capability by checking (upcoming) pcmCapabilities. The default format is in
     * 16kHz and 16 bits.
     *
     * @param isEncrypted Specify true if packets on this service have to be encrypted
     * @param codec       Audio codec which will be used for streaming. Currently, only
     *                    AudioStreamingCodec.LPCM is accepted.
     * @param params      (Reserved for future use) Additional configuration information for each
     *                    codec. If "codec" is AudioStreamingCodec.LPCM, "params" must be an
     *                    instance of LPCMParams class.
     *
     * @return IAudioStreamListener interface if service is opened successfully and streaming is
     *         started, null otherwise
     */
    public IAudioStreamListener startAudioStream(boolean isEncrypted, AudioStreamingCodec codec,
                                                 AudioStreamingParams params) {
        ...
    }
}

/**
 * Enum for each type of audio streaming codec.
 */
public enum AudioStreamingCodec {
    /**
     * Linear-PCM without any compression.
     */
    LPCM,
}

/**
 * A struct to hold audio format information that are common to codecs.
 */
public class AudioStreamingParams {
    /**
     * Sampling rate in Hz, e.g. 44100
     *
     * This is reserved for future and not used right now.
     */
    public int samplingRate;

    /**
     * Number of channels in the audio stream
     *
     * This is reserved for future and not used right now.
     */
    public int channels;

    // constructor will be added in actual implementation
}

/**
 * A struct to hold LPCM specific audio format information.
 */
public class LPCMParams extends AudioStreamingParams {
    /**
     * Sample format of linear PCM data.
     */
    public enum SampleFormat {
        /**
         * LPCM data is represented by 8-bit unsigned integers. Centerpoint is 128.
         */
        LPCM_8BIT_UNSIGNED,

        /**
         * LPCM data is represented by 16-bit signed integers, in little endian.
         */
        LPCM_16BIT_SIGNED_LITTLE_ENDIAN,
    }

    /**
     * Sample format in which app will provide LPCM data to
     * IAudioStreamListener.sendAudio()
     *
     * This is reserved for future and not used right now.
     */
    public SampleFormat sampleFormat;

    // constructor will be added in actual implementation
}
```

### Implementations

- Video packetizers (`StreamPacketizer` and `RTPH264Packetizer`) have to be updated to comply `IVideoStreamListener` interface.
- Audio packetizer (`StreamPacketizer`) has to be updated to comply `IAudioStreamListener` interface.
- `SdlProxyBase` returns one of packetizer instance to the app through `startVideoStream()` and `startAudioStream()`.


### Notes

- `IAudioStreamListener.sendAudio()` receives timestamp information. This is added for consistency with `IVideoStreamListener.sendFrame()` but it is not used right now. This might be useful in future if we want to achieve audio-video synchronization.
- `startAudioStream()` receives audio information such as sampling rate, sample format and number of channels. Right now they are useless because we do not have format negotiation mechanism in Audio Streaming feature, with the default format being 16kHz and 16bits per sample. These arguments may be useful if we add such negotiation or introduce audio encoding in future, but they can be removed until then.


## Potential downsides

- App developers need to split video data in frame boundaries. This will not be an issue if an app uses `MediaCodec` encoder, since it outputs coded data of a single frame at a time. Therefore, the app can simply provide received chunk from `MediaCodec` to `IVideoStreamListener.sendFrame()`.
- Adding similar public methods may confuse app developers (though existing methods will be marked as deprecated.)


## Impact on existing code

- This proposal adds and deprecates some public methods in `SdlProxyBase` class.
- This proposal introduces additional implementation in packetizer classes.
- Video and audio streaming apps need to update their code to use the new public methods and interfaces.


## Alternatives considered

- Improve the implementation of PipedInputStream/OutputStream as proposed by [SDL-0069](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0069-enhance-video-streaming-performance-for-android.md). The proposal will resolve performance issue, but we still need timestamp information for RTP format.
