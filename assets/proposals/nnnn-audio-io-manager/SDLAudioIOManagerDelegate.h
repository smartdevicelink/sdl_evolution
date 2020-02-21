#import <Foundation/Foundation.h>
#import <SmartDeviceLink/SDLResult.h>

@class SDLAudioIOManager;
@class SDLAudioPassThruCapabilities;

NS_ASSUME_NONNULL_BEGIN

@protocol SDLAudioIOManagerDelegate <NSObject>

@optional

#pragma mark - Ouput stream delegate methods

/**
 * Informs the delegate that the manager is starting to play audio files on the output stream.
 */
- (void)audioManagerDidStartOutputStream:(SDLAudioIOManager *)audioManager;

/**
 * Informs the delegate that the manager finished playing all audio files and stopped the output stream. 
 */
- (void)audioManagerDidStopOutputStream:(SDLAudioIOManager *)audioManager;

/**
 * Informs the delegate that the manager finished playing the specified audio file on the output stream.
 */
- (void)audioManager:(SDLAudioIOManager *)audioManager didFinishPlayingURL:(NSURL *)url;

/**
 * Informs the delegate that the manager failed to play the specified audio file on the output stream.
 */
- (void)audioManager:(SDLAudioIOManager *)audioManager errorDidOccurForURL:(NSURL *)url error:(NSError *)error;

#pragma mark - Input stream delegate methods

/**
 * Informs the delegate that the manager did start the input stream with the specified audio options incuding 
 * - audio format (e.g. PCM)
 * - sampling rate (e.g. 22 khz)
 * - bits per sample (e.g. 16 bits)
 */
- (void)audioManager:(SDLAudioIOManager *)audioManager didStartInputStreamWithOptions:(SDLAudioPassThruCapabilities *)options;

/**
 * Informs the delegate that the manager did receive an audio chunk from the input stream.
 */
- (void)audioManager:(SDLAudioIOManager *)audioManager didReceiveAudioData:(NSData *)audioData;

/**
 * Informs the delegate that the manager did finish the input stream with the specified result code.
 * Possible result code are:
 * SUCCESS if the user or the app confirmed to end the audio input stream.
 * DISALLOWED if the application does not have permission to start the audio input stream.
 * REJECTED if the vehicle rejected to start the audio input stream due to other priority.
 * ABORTED if the user has chosen to abort the audio input requesting the app to dicard any audio data recorded in this active session.
 * RETRY if the user requests the app to restart the audio input stream.
 */
- (void)audioManager:(SDLAudioIOManager *)audioManager didFinishInputStreamWithResult:(SDLResult)result;

@end

NS_ASSUME_NONNULL_END
