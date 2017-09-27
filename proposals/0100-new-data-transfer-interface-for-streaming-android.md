# New data transfer interface in Android Proxy for streaming

* Proposal: [SDL-0100](0100-new-data-transfer-interface-for-streaming-android.md)
* Author: [Sho Amano](https://github.com/shoamano83/)
* Status: **Accepted with Revisions**
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

For video streaming, `IVideoStreamListener` is returned by `SdlProxyBase.startH264()`. The app calls `IVideoStreamListener.sendFrame()` method to pass video data to Proxy.

For audio streaming, `IAudioStreamListener` is returned by `SdlProxyBase.startPCM()`. The app calls `IAudioStreamListener.sendAudio()` method to pass audio data to Proxy.


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
     * Note: this method must not be called after SdlProxyBase.endH264() is called.
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
     * In some formats, a video frame consists of multiple chunks of data (e.g. multiple NAL
     * units). This method is intended to send a list of such chunks as a single frame.
     * Note: this method must not be called after SdlProxyBase.endH264() is called.
     *
     * @param chunkList          A list of data chunks to send. Positions inside each
     *                           ByteBuffer will be updated upon return.
     * @param presentationTimeUs Presentation timestamp (PTS) of this frame, in microseconds.
     *                           It must be greater than the previous timestamp.
     *                           Specify -1 if unknown.
     */
    void sendFrame(ByteBuffer[] chunkList, long presentationTimeUs);
}

/**
 * A listener that receives audio streaming data from app.
 */
public interface IAudioStreamListener {
    /**
     * Sends a chunk of audio data to SDL Core.
     *
     * Note: this method must not be called after SdlProxyBase.endPCM() is called.
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
}
```

### Addition to public methods

```java
public abstract class SdlProxyBase<proxyListenerType extends IProxyListenerBase> {
    :

    /**
     * Opens a video service (service type 11) and subsequently provides an IVideoStreamListener
     * to the app to send H264 video data.
     *
     * @param isEncrypted Specify true if packets on this service have to be encrypted
     * @param format      Stream format in which app will provide H.264 data to
     *                    IVideoStreamListener.sendFrame()
     * @param width       Width of the video in pixels
     * @param height      Height of the video in pixels
     *
     * @return IVideoStreamListener interface if service is opened successfully and streaming is
     *         started, null otherwise
     */
    public IVideoStreamListener startH264(boolean isEncrypted, H264StreamFormat format,
                                          int width, int height) {
        :
    }

    /**
     * Opens a audio service (service type 10) and subsequently provides an IAudioStreamListener
     * to the app to send PCM audio data.
     *
     * @param isEncrypted  Specify true if packets on this service have to be encrypted
     * @param samplingRate (Reserved for future use) Sampling rate in Hz, e.g. 44100
     * @param format       (Reserved for future use) Sample format in which app will provide
     *                     LPCM data to IAudioStreamListener.sendAudio()
     * @param channels     (Reserved for future use) Number of channels in the audio stream
     *
     * @return IAudioStreamListener interface if service is opened successfully and streaming is
     *         started, null otherwise
     */
    public IAudioStreamListener startPCM(boolean isEncrypted, int samplingRate,
                                         LPCMSampleFormat format, int channels) {
        :
    }
}

/**
 * Stream format of H.264 video data.
 */
public enum H264StreamFormat {
    /**
     * List of NAL units without start code or length field.
     *
     * Use IVideoStreamListener#sendFrame(ByteBuffer[], long) to send in this format.
     */
    NAL_UNIT_LIST,

    /**
     * One or more H.264 NAL units are concatenated, each NAL units having start codes at the
     * beginning. Also known as Annex-B format.
     */
    BYTE_STREAM,

    /**
     * One or more H.264 NAL units are concatenated in AVCC format (also known as NAL File format).
     * Each NAL unit has length field of 1 byte at the beginning.
     */
    AVCC_WITH_1_BYTE_LENGTH,

    /**
     * One or more H.264 NAL units are concatenated in AVCC format (also known as NAL File format).
     * Each NAL unit has length field of 2 bytes in big endian at the beginning.
     */
    AVCC_WITH_2_BYTE_LENGTH,

    /**
     * One or more H.264 NAL units are concatenated in AVCC format (also known as NAL File format).
     * Each NAL unit has length field of 4 bytes in big endian at the beginning.
     */
    AVCC_WITH_4_BYTE_LENGTH,
}

/**
 * Sample format of linear PCM data.
 */
public enum LPCMSampleFormat {
    /**
     * LPCM data is represented by 8-bit unsigned integers. Centerpoint is 128.
     */
    LPCM_8BIT_UNSIGNED,

    /**
     * LPCM data is represented by 16-bit signed integers, in little endian.
     */
    LPCM_16BIT_SIGNED_LITTLE_ENDIAN,
}
```

### Implementations

- Video packetizers (`StreamPacketizer` and `RTPH264Packetizer`) have to be updated to comply `IVideoStreamListener` interface.
- Audio packetizer (`StreamPacketizer`) has to be updated to comply `IAudioStreamListener` interface.
- `SdlProxyBase` returns one of packetizer instance to the app through `startH264()` and `startPCM()`.


### Discussions

- Since Android's `MediaCodec` outputs encoded H.264 data in byte-stream format, there might be little benefit to support other stream formats like AVCC. I am fine to remove `H264StreamFormat` enum so that `sendFrame()` will support H.264 byte-stream format only, if everyone agrees.
  * Just FYI, iOS' VideoToolbox encoder outputs H.264 data in AVCC format, usually with 4-byte length field.
- `startH264()` may be renamed to `startVideoStreaming()` and receive additional argument to specify video codec. This may be useful in future when we want to support more codecs. However, we need detailed study of stream format (like `H264StreamFormat`) of each codec, so this sounds overkill.
- `IAudioStreamListener.sendAudio()` receives timestamp information. This is added for consistency with `IVideoStreamListener.sendFrame()` but it is not used right now. This might be useful in future if we want to:
  * encode audio data, for example using AAC, to save network bandwidth, or
  * to achieve Audio-Video synchronization.
- `startPCM()` receives audio information such as sampling rate, sample format and number of channels. Right now they are useless because we do not have format negotiation mechanism in Audio Streaming feature, with the default format being 16kHz and 16bits per sample. These arguments may be useful if we add such negotiation or introduce audio encoding in future, but they can be removed until then.


## Potential downsides

- App developers need to split video data in frame boundaries. This will not be an issue if an app uses `MediaCodec` encoder, since it outputs coded data of a single frame at a time. Therefore, the app can simply provide received chunk from `MediaCodec` to `IVideoStreamListener.sendFrame()`.
- Adding similar public methods may confuse app developers.


## Impact on existing code

- This proposal adds public methods in `SdlProxyBase`.
- This proposal introduces additional implementation in packetizer classes.
- Video and audio streaming apps need to update their code to use the new public methods and interfaces.


## Alternatives considered

- Improve the implementation of PipedInputStream/OutputStream as proposed by [SDL-0069](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0069-enhance-video-streaming-performance-for-android.md). The proposal will resolve performance issue, but we still need timestamp information for RTP format.
