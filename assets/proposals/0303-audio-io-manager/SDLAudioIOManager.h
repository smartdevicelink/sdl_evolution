#import <Foundation/Foundation.h>

@class SDLManager;
@class SDLTTSChunk;
@protocol SDLAudioIOManagerDelegate;

NS_ASSUME_NONNULL_BEGIN

extern NSString *const SDLErrorDomainAudioIOManager;

@interface SDLAudioIOManager : NSObject

@property (weak, nonatomic) id<SDLAudioIOManagerDelegate> delegate;

@property (assign, nonatomic, readonly) BOOL isOutputStreamPlaying;
@property (assign, nonatomic, readonly) BOOL isInputStreamPlaying;

@property (strong, nonatomic, readwrite) SDLTTSChunk *inputStreamPrompt;
@property (strong, nonatomic, readwrite) NSString *inputStreamText;

/**
 * Creates an instance of the SDLAudioIOManager.
 */
- (instancetype)initWithManager:(nonnull SDLManager *)sdlManager delegate:(id<SDLAudioIOManagerDelegate>)delegate;

/**
 * Starts writing the audio data of the specified audio file.
 * Audio output as priority to audio input. When writing audio to the output stream while input stream is playing
 * the input stream will be paused during the output stream playback.
 */
- (void)writeOutputStreamWithFileURL:(NSURL *)fileURL;

/**
 * Starts an input stream using the vehicle microphone and sends the audio data to the specified delegate.
 * Audio output as priority to audio input. When starting input stream while output stream is playing
 * the input stream will be paused during the output stream playback.
 */
- (void)startInputStream;

/**
 * Stops the input stream.
 */
- (void)stopInputStream;

@end

NS_ASSUME_NONNULL_END
