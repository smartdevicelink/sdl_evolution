#import "SDLAudioIOManager.h"
#import "SDLAudioIOManagerDelegate.h"

#import "SDLAsynchronousRPCRequestOperation.h"
#import "SDLAudioFile.h"
#import "SDLAudioPassThruCapabilities.h"
#import "SDLEndAudioPassThru.h"
#import "SDLLogMacros.h"
#import "SDLManager.h"
#import "SDLPerformAudioPassThru.h"
#import "SDLPerformAudioPassThruResponse.h"
#import "SDLPCMAudioConverter.h"
#import "SDLRegisterAppInterfaceResponse.h"
#import "SDLRPCNotification.h"
#import "SDLRPCResponseNotification.h"
#import "SDLStreamingMediaManager.h"

/** Amplifier const settings */
#define INPUT_STREAM_AMPLIFIER_FACTOR_MAX (50.0)
#define INPUT_STREAM_AMPLIFIER_INCREASE_STEP (2.5)
#define INPUT_STREAM_ABORT_TIMEOUT (4)

NS_ASSUME_NONNULL_BEGIN

NSString *const SDLErrorDomainAudioIOManager = @"com.sdl.extension.AudioIOManager";

typedef NS_ENUM(NSInteger, SDLAudioIOManagerError) {
    SDLAudioIOManagerErrorNotConnected = -1
};

typedef NS_ENUM(NSInteger, SDLAudioIOManagerState) {
    SDLAudioIOManagerStateStopped = 0,
    SDLAudioIOManagerStateStarting = 1,
    SDLAudioIOManagerStateStarted = 2,
    SDLAudioIOManagerStateStopping = 3, // only for input stream. When waiting for the APT response.
    SDLAudioIOManagerStatePausing = 4, // only for input stream. It'll be paused when active and output stream starts
    SDLAudioIOManagerStatePaused = 5, // only for input stream while output stream is playing
};

@interface SDLAudioIOManager ()

@property (weak, nonatomic) SDLManager *sdlManager;

@property (assign, nonatomic) SDLAudioIOManagerState outputStreamState;
@property (strong, nonatomic, nonnull) NSDate *outputStreamPlaybackEnd;

@property (assign, nonatomic) SDLAudioIOManagerState inputStreamState;
@property (strong, nonatomic, nullable) SDLAudioPassThruCapabilities *inputStreamOptions;
@property (strong, nonatomic, nullable) SDLAsynchronousRPCRequestOperation *inputStreamOperation;
@property (assign, nonatomic) double inputStreamAmplifierFactor;
@property (assign, nonatomic) NSUInteger inputStreamRetryCounter;

@property (strong, nonatomic) dispatch_queue_t dispatchQueue;
@property (strong, nonatomic) NSOperationQueue *operationQueue;

@end

@implementation SDLAudioIOManager

- (instancetype)initWithManager:(SDLManager *)sdlManager delegate:(id<SDLAudioIOManagerDelegate>)delegate {
    self = [super init];
    if (!self) { return nil; }

    SDLLogV(@"Init Audio IO Manager");
    
    self.delegate = delegate;
    self.sdlManager = sdlManager;

    self.outputStreamState = SDLAudioIOManagerStateStopped;
    self.outputStreamPlaybackEnd = [NSDate dateWithTimeIntervalSince1970:0];
    
    self.inputStreamState = SDLAudioIOManagerStateStopped;
    self.inputStreamOptions = nil;
    self.inputStreamAmplifierFactor = 0;
    self.inputStreamRetryCounter = 0;
    
    self.dispatchQueue = dispatch_queue_create("com.sdl.manager.ioaudio.queue", nil);
    self.operationQueue = [[NSOperationQueue alloc] init];
    self.operationQueue.maxConcurrentOperationCount = 1;
    self.operationQueue.suspended = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onTransportDisconnect) name:SDLTransportDidDisconnect object:nil];
    
    return self;
}

- (BOOL)isOutputStreamPlaying {
    SDLLogV(@"Output Stream State %@", [self nameForStreamState:self.outputStreamState]);
    return self.outputStreamState != SDLAudioIOManagerStateStopped;
}

- (BOOL)isInputStreamPlaying {
    SDLLogV(@"Input Stream State %@", [self nameForStreamState:self.inputStreamState]);
    return self.inputStreamState != SDLAudioIOManagerStateStopped;
}

- (void)setInputStreamState:(SDLAudioIOManagerState)inputStreamState {
    SDLLogV(@"Change Input Stream state from %@ to %@", [self nameForStreamState:self->_inputStreamState], [self nameForStreamState:inputStreamState]);
    self->_inputStreamState = inputStreamState;
}

- (void)setOutputStreamState:(SDLAudioIOManagerState)outputStreamState {
    SDLLogV(@"Change Output Stream state from %@ to %@", [self nameForStreamState:self->_outputStreamState], [self nameForStreamState:outputStreamState]);
    self->_outputStreamState = outputStreamState;
}

- (NSString *)nameForStreamState:(SDLAudioIOManagerState)state {
    switch (state) {
        case SDLAudioIOManagerStateStopped:
            return @"Stopped";
        case SDLAudioIOManagerStateStarting:
            return @"Starting";
        case SDLAudioIOManagerStatePaused:
            return @"Paused";
        case SDLAudioIOManagerStatePausing:
            return @"Pausing";
        case SDLAudioIOManagerStateStarted:
            return @"Started";
        case SDLAudioIOManagerStateStopping:
            return @"Stopping";
        default:
            return @"Unknown";
    }
}

- (void)onTransportDisconnect {
    SDLLogV(@"Cancelling operations due to transport disconnect");
    [self.operationQueue cancelAllOperations];
    
    self.inputStreamOptions = nil;
    self.inputStreamRetryCounter = 0;
    self.inputStreamState = SDLAudioIOManagerStateStopped;
    self.outputStreamState = SDLAudioIOManagerStateStopped;
}

#pragma mark- Output stream area

- (void)writeOutputStreamWithFileURL:(NSURL *)fileURL {
    dispatch_async(self.dispatchQueue, ^{
        [self sdl_writeOutputStreamWithFileURL:fileURL];
    });
}

- (void)sdl_writeOutputStreamWithFileURL:(NSURL *)fileURL {
    SDLLogV(@"Writing file to output stream. URL: %@", fileURL);
    
    // push the audio file to the underlying manager
    NSBlockOperation *operation = [[NSBlockOperation alloc] init];
    __weak NSBlockOperation *weakOperation = operation;
    [operation addExecutionBlock:^{
        if (!weakOperation || weakOperation.isCancelled) return;
        
        [self sdl_pushWithFileURL:fileURL];
    }];

    [self.operationQueue addOperation:operation];
        
    // if the output stream is stopped, the input stream could be started (or starting)
    if (self.outputStreamState == SDLAudioIOManagerStateStopped) {
        SDLLogV(@"Output stream is stopped. Starting output stream.");
        self.outputStreamState = SDLAudioIOManagerStateStarting;

        // in case the input stream is active we have to get it to pause
        if (self.inputStreamState == SDLAudioIOManagerStateStarting) {
            SDLLogV(@"Input stream is starting. Pause starting input stream");
            [self sdl_pauseInputStream];
            return;
        } else if (self.inputStreamState == SDLAudioIOManagerStateStarted) {
            // we should pause the playback and wait for being called again.
            SDLLogV(@"Input stream is started. Pause input stream");
            [self sdl_pauseInputStream];
            return;
        }
    }
    
    // in case the input stream is stopping or pausing we will return here and wait until it's fully paused or stopped (there we will start the stream)
    if (self.inputStreamState == SDLAudioIOManagerStateStopping || self.inputStreamState == SDLAudioIOManagerStatePausing) {
        SDLLogV(@"Input stream state is %@. Waiting for input stream transition to be completed.", [self nameForStreamState:self.inputStreamState]);
        return;
    }
    
    SDLLogV(@"Starting output stream");
    [self sdl_startOutputStream];
}

- (void)sdl_startOutputStream {
    SDLLogV(@"Attempt to start output stream");
    if (self.outputStreamState == SDLAudioIOManagerStateStarting) {
        self.outputStreamState = SDLAudioIOManagerStateStarted;
        
        if ([self.delegate respondsToSelector:@selector(audioManagerDidStartOutputStream:)]) {
            [self.delegate audioManagerDidStartOutputStream:self];
        }
        
        SDLLogV(@"Output stream did start. Resume operation queue");
        // the input stream is not in our way we can start the output stream
        self.operationQueue.suspended = NO;
    } else {
        SDLLogE(@"Error. Output stream state should be Starting. Output stream state is %@", [self nameForStreamState:self.outputStreamState]);
    }
}

- (void)sdl_stopOutputStream {
    SDLLogV(@"Attempt to stop output stream");
    // queue is now empty. stop the output stream
    self.outputStreamState = SDLAudioIOManagerStateStopped;
    
    // suspend the output manager (so that new output can be added but is not immediately played)
    self.operationQueue.suspended = YES;
    
    if ([self.delegate respondsToSelector:@selector(audioManagerDidStopOutputStream:)]) {
        [self.delegate audioManagerDidStopOutputStream:self];
    }
    
    SDLLogV(@"Checking input stream state (%@)", [self nameForStreamState:self.inputStreamState]);
    // possible that the input stream is paused. resume it
    if (self.inputStreamState == SDLAudioIOManagerStatePaused) {
        SDLLogV(@"Input stream is paused. Start the input stream again (in 0.5 sec)");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), self.dispatchQueue, ^{
            [self sdl_startInputStream];
        });
    }
}

- (void)sdl_continueOutputStream {
    SDLLogV(@"Attempt to continue input stream");
    dispatch_async(self.dispatchQueue, ^{
    BOOL operationCountZero = self.operationQueue.operationCount == 0;
    BOOL playbackEndInPast = [self.outputStreamPlaybackEnd compare:[NSDate date]] == NSOrderedAscending;
    
    SDLLogV(@"Checking OperationCountZero (%@) && playbackEndInPast (%@)", operationCountZero ? @"YES" : @"NO", playbackEndInPast ? @"YES" : @"NO");
    if (operationCountZero && playbackEndInPast) {
        SDLLogV(@"No operations queued anymore and playback ended already. Stopping output stream (in 1 sec)");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), self.dispatchQueue, ^{
            [self sdl_stopOutputStream];
        });
    }
    });
}

#pragma mark- SDL write data area

- (void)sdl_pushWithFileURL:(NSURL *)fileURL {
    SDLLogV(@"Attempt to push data with file url %@", fileURL);
    if (!self.sdlManager.streamManager.isAudioConnected) {
        SDLLogE(@"The audio stream of the SDL stream manager (%@) is not connected",  self.sdlManager.streamManager);
        NSError *error = [NSError errorWithDomain:SDLErrorDomainAudioIOManager code:SDLAudioIOManagerErrorNotConnected userInfo:nil];
        [self sdl_raiseErrorDidOccurForFile:fileURL error:error];
        return;
    }
    
    // Convert and store in the queue
    NSError *error = nil;
    SDLPCMAudioConverter *converter = [[SDLPCMAudioConverter alloc] initWithFileURL:fileURL];
    NSURL *_Nullable outputFileURL = [converter convertFileWithError:&error];
    UInt32 estimatedDuration = converter.estimatedDuration;

    if (error) {
        SDLLogE(@"Error converting file to CAF / PCM: %@", error);
        [self sdl_raiseErrorDidOccurForFile:fileURL error:error];
        return;
    }
    
    SDLLogV(@"Convert audio to PCM finished. Estimated duration: %u. Output file url %@", (unsigned int)estimatedDuration, outputFileURL);
    SDLAudioFile *audioFile = [[SDLAudioFile alloc] initWithInputFileURL:fileURL outputFileURL:outputFileURL estimatedDuration:estimatedDuration];
    [self sdl_playAudioFile:audioFile];
}

- (void)sdl_playAudioFile:(SDLAudioFile *)audioFile {
    SDLLogV(@"Attempt to play audio file %@", audioFile);
    // Strip the first bunch of bytes (because of how Apple outputs the data) and send to the audio stream, if we don't do this, it will make a weird click sound
    NSData *data = audioFile.data;
    NSData *audioData = [data subdataWithRange:NSMakeRange(5760, (data.length - 5760))];

    BOOL success = [self.sdlManager.streamManager sendAudioData:audioData];
    SDLLogV(@"Send audio data %@", success ? @"success" : @"failed");
    
    NSTimeInterval audioLengthSecs = (double)audioData.length / 32000.0;
    
    // delete the output data. not needed anymore
    [[NSFileManager defaultManager] removeItemAtURL:audioFile.outputFileURL error:nil];
    
    // date1 is now + playback time (only correct if no playback is active)
    NSDate *date1 = [NSDate dateWithTimeIntervalSinceNow:audioLengthSecs];
    // date2 is last known playback endtime + playback time (only true if playback is currently active)
    NSDate *date2 = [self.outputStreamPlaybackEnd dateByAddingTimeInterval:audioLengthSecs];
    
    SDLLogV(@"Checking playback end dates (date1 %@) (date2 %@)", date1, date2);
    // date1 > date2 if playback is not active
    if ([date1 compare:date2] == NSOrderedDescending) {
        // WORKARONUD: the first playback file finish notification should be a second ahead so the audio buffer doesn't run empty
        SDLLogV(@"Adding first audio file to audio buffer");
        self.outputStreamPlaybackEnd = [date1 dateByAddingTimeInterval:-1.0];
    } else {
        SDLLogV(@"Adding subsequent audio file to audio buffer");
        self.outputStreamPlaybackEnd = date2;
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.outputStreamPlaybackEnd.timeIntervalSinceNow * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        SDLLogV(@"Ending Audio file: %@", audioFile);
        [self sdl_raiseFileDidFinishPlaying:audioFile.inputFileURL successfully:success];
    });
}

- (void)sdl_raiseFileDidFinishPlaying:(NSURL *)fileURL successfully:(BOOL)successfully {
    dispatch_async(self.dispatchQueue, ^{
    if ([self.delegate respondsToSelector:@selector(audioManager:didFinishPlayingURL:)]) {
        [self.delegate audioManager:self didFinishPlayingURL:fileURL];
    }
    
    [self sdl_continueOutputStream];
    });
}

- (void)sdl_raiseErrorDidOccurForFile:(NSURL *)fileURL error:(NSError *)error {
    SDLLogV(@"Attempt to raise error. File %@. Error %@", fileURL, error);
    
    dispatch_async(self.dispatchQueue, ^{
    if ([self.delegate respondsToSelector:@selector(audioManager:errorDidOccurForURL:error:)]) {
        [self.delegate audioManager:self errorDidOccurForURL:fileURL error:error];
    }
    
    if ([error.domain isEqualToString:SDLErrorDomainAudioIOManager] && error.code == SDLAudioIOManagerErrorNotConnected) {
        SDLLogV(@"Error is NotConnected. Cancel all operations and stop the output stream");
        [self.operationQueue cancelAllOperations];
        [self sdl_stopOutputStream];
    } else {
        SDLLogV(@"Error code is not known. Continue output stream");
        [self sdl_continueOutputStream];
    }
    });
}

#pragma mark- Input stream area

- (void)startInputStream {
    SDLLogV(@"Attempt to start input stream");
    dispatch_async(self.dispatchQueue, ^{
        
    SDLLogV(@"Checking input stream state %@", [self nameForStreamState:self.inputStreamState]);
    if (self.inputStreamState == SDLAudioIOManagerStateStarting) {
        SDLLogV(@"Input stream state is already starting. Ignore attempt to start.");
        return;
    }
        
    if (self.inputStreamState != SDLAudioIOManagerStateStopped && self.inputStreamState != SDLAudioIOManagerStatePaused) {
        SDLLogE(@"Error: Start input stream not valid. Current input stream state is %@", [self nameForStreamState:self.inputStreamState]);
        return;
    }
    
    SDLLogV(@"Checking output stream state %@", [self nameForStreamState:self.outputStreamState]);
    if (self.outputStreamState != SDLAudioIOManagerStateStopped) {
        SDLLogV(@"Ouput stream is not stopped. Pause the input stream and wait.");
        self.inputStreamState = SDLAudioIOManagerStatePaused;
    } else {
        SDLLogV(@"Output stream is stopped. Start the input stream finally");
        [self sdl_startInputStream];
    }
    });
}

- (void)stopInputStream {
    SDLLogV(@"Attempt to stop input stream");
    dispatch_async(self.dispatchQueue, ^{
        SDLLogV(@"Checking input stream state %@", [self nameForStreamState:self.inputStreamState]);
        switch (self.inputStreamState) {
            case SDLAudioIOManagerStatePaused: {
                // stream is paused so immediately set it to stopped.
                SDLLogV(@"Input stream is paused. Just set it to stopped");
                self.inputStreamState = SDLAudioIOManagerStateStopped;
                break;
            }
            case SDLAudioIOManagerStatePausing: {
                // stream is pausing we already sent a end request so update the status to stopping
                SDLLogV(@"Input stream is pausing. Set it to stopping and wait");
                self.inputStreamState = SDLAudioIOManagerStateStopping;
                break;
            }
            case SDLAudioIOManagerStateStarted: {
                // if input stream is starting or already started we have to send a request to stop it
                SDLLogV(@"Input stream is started. Call stop input stream");
                [self sdl_stopInputStream];
                break;
            }
            case SDLAudioIOManagerStateStarting: {
                SDLLogV(@"Input stream is starting. Call stop input stream");
                [self sdl_stopInputStream];
                break;
            }
            default: {
                // other states are irrelevant
                SDLLogW(@"Input stream state unknown. Ignore!");
                break;
            }
        }
    });
}

- (void)sdl_startInputStream {
    SDLLogV(@"Checking input stream state %@", [self nameForStreamState:self.inputStreamState]);
    if (self.inputStreamState != SDLAudioIOManagerStateStopped && self.inputStreamState != SDLAudioIOManagerStatePaused) {
        SDLLogE(@"Error: Start input stream (internal) not valid. State should be starting.");
        return;
    }
    
    // prepare the input stream state
    self.inputStreamState = SDLAudioIOManagerStateStarting;
    
    // find a proper apt setting. best would be 16bit,16khz but at least one capable option is selected
    SDLAudioPassThruCapabilities *audioOptions = self.sdlManager.registerResponse.audioPassThruCapabilities.lastObject;
    
    // fallback options are set. PCM with 16bit and 16khz still preferred (sufficient for voice recognition)
    for (SDLAudioPassThruCapabilities *item in self.sdlManager.registerResponse.audioPassThruCapabilities) {
        if (![item.audioType isEqualToEnum:SDLAudioTypePCM]) continue;
        if (![item.bitsPerSample isEqualToEnum:SDLBitsPerSample16Bit]) continue;
        if (![item.samplingRate isEqualToEnum:SDLSamplingRate16KHZ]) continue;
        
        audioOptions = item;
        break;
    }
    
    // split the text into multiple lines.
    NSArray<NSString *> *lines = [self.inputStreamText componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    self.inputStreamOptions = audioOptions;
    self.inputStreamAmplifierFactor = 0;
    
    // create a request we will be sending
    SDLPerformAudioPassThru *performAudioInput = [[SDLPerformAudioPassThru alloc] init];
    performAudioInput.audioType = audioOptions.audioType;
    performAudioInput.bitsPerSample = audioOptions.bitsPerSample;
    performAudioInput.samplingRate = audioOptions.samplingRate;
    performAudioInput.initialPrompt = [NSArray arrayWithObject:self.inputStreamPrompt];
    performAudioInput.maxDuration = @1000000;
    performAudioInput.audioPassThruDisplayText1 = lines.count > 0 ? lines[0] : nil;
    performAudioInput.audioPassThruDisplayText2 = lines.count > 1 ? lines[1] : nil;
    performAudioInput.muteAudio = @YES;
    
    __weak SDLAudioIOManager * weakSelf = self;
    
    // this is the important area... handle the microphone audio data
    performAudioInput.audioDataHandler = ^(NSData * _Nullable audioData) {
        __strong SDLAudioIOManager * strongSelf = weakSelf;
        if (strongSelf == nil || audioData == nil) {
            return;
        }
        
        [strongSelf sdl_initiateAbortInputStreamTimer];
        
        SDLLogV(@"Receiving audio data (length %lu)", (unsigned long)audioData.length);
        
        dispatch_async(strongSelf.dispatchQueue, ^{
        [strongSelf sdl_handleInputStreamData:audioData];
        });
    };
    
    [self sdl_initiateAbortInputStreamTimer];
    
    // send the request out to the head unit
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    SDLLogV(@"Sending request %@", [performAudioInput serializeAsDictionary:0]);
    [self.sdlManager sendRequest:performAudioInput withResponseHandler:^(__kindof SDLRPCRequest * _Nullable request, __kindof SDLRPCResponse * _Nullable response, NSError * _Nullable error) {
        SDLLogV(@"Response received %@", [response serializeAsDictionary:0]);
#pragma clang diagnostic pop
        
        if (error) {
            SDLLogW(@"Audio IO manager: Error in response %@", error);
        }
        
        __strong SDLAudioIOManager * strongSelf = weakSelf;
        if (strongSelf == nil) {
            return;
        }
        
        SDLLogV(@"Cancel Delayed Abort call");
        [NSObject cancelPreviousPerformRequestsWithTarget:strongSelf selector:@selector(sdl_abortInputStream) object:nil];
        
        self.inputStreamOperation = nil;
        SDLResult result = response ? response.resultCode : SDLResultTimedOut;
        
        dispatch_async(strongSelf.dispatchQueue, ^{
            [strongSelf sdl_handleInputStreamResponse:result];
        });
    }];
    
    // WORKARUND. In some cases Core does not respond to PerformAudioPassThru. Need to store the operation in this case.
    NSArray<__kindof NSOperation *> *operations = self.sdlManager.pendingRPCTransactions;
    
    for (NSOperation *operation in [operations reverseObjectEnumerator]) {
        if ([operation isKindOfClass:[SDLAsynchronousRPCRequestOperation class]]) {
            SDLAsynchronousRPCRequestOperation *rpcOperation = (SDLAsynchronousRPCRequestOperation *)operation;
            if (rpcOperation.requests.count == 1 && [rpcOperation.requests[0] isEqual:performAudioInput]) {
                self.inputStreamOperation = rpcOperation;
                break;
            }
        }
    }
    
    if (self.inputStreamOperation) {
        SDLLogV(@"Audio IO Manager: Found the operation of Input Stream");
    } else {
        SDLLogW(@"Audio IO Manager: Warning: No operation found for Input Stream");
    }
}

- (void)sdl_handleInputStreamData:(nonnull NSData *)audioData {
    SDLLogV(@"Attempt to handle input stream data");
    __strong id<SDLAudioIOManagerDelegate> d = self.delegate;
    
    if (self.inputStreamState == SDLAudioIOManagerStateStarting) {
        SDLLogV(@"Received first chunk of audio. Set input stream state to started");
        self.inputStreamState = SDLAudioIOManagerStateStarted;
        
        if (d && [d respondsToSelector:@selector(audioManager:didStartInputStreamWithOptions:)]) {
            [d audioManager:self didStartInputStreamWithOptions:self.inputStreamOptions];
        }
    }
    
    if (self.inputStreamState == SDLAudioIOManagerStateStarted) {
        SDLLogV(@"Received subsequent audio chunk. Forward to delegate");
        if (d && [d respondsToSelector:@selector(audioManager:didReceiveAudioData:)]) {
            NSMutableData *mutableAudioData = [audioData mutableCopy];
            double factor = [self sdl_calculateAmplifierFactor:[mutableAudioData bytes] size:mutableAudioData.length];
            
            if (factor > self.inputStreamAmplifierFactor) {
                self.inputStreamAmplifierFactor = MIN(MIN(factor, self.inputStreamAmplifierFactor + INPUT_STREAM_AMPLIFIER_INCREASE_STEP), INPUT_STREAM_AMPLIFIER_FACTOR_MAX);
            } else {
                self.inputStreamAmplifierFactor = factor;
            }
            
            [self sdl_applyAmplifierFactor:self.inputStreamAmplifierFactor data:[mutableAudioData mutableBytes] size:mutableAudioData.length];
            
            [d audioManager:self didReceiveAudioData:mutableAudioData];
        }
    }
}

- (void)sdl_handleInputStreamResponse:(nonnull SDLResult)resultCode {
    SDLLogV(@"Attempt to handle input stream response with result %@. Checking input stream state (%@), Retry counter (%lu)", resultCode, [self nameForStreamState:self.inputStreamState], (unsigned long)self.inputStreamRetryCounter);
    
    if (self.inputStreamState == SDLAudioIOManagerStateStarting && [resultCode isEqualToEnum:SDLResultRejected] && self.inputStreamRetryCounter < 3) {
        // this state can be true if the request is rejected so we set the state back to paused and retry in a bit
        SDLLogV(@"Detected a unsuccessful input stream starting request. Pause the input stream state, increase the retry counter and try to start again in 0.5 seconds");
        self.inputStreamRetryCounter++;
        self.inputStreamState = SDLAudioIOManagerStatePaused;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), self.dispatchQueue, ^{
            [self sdl_startInputStream];
        });
        // do not notify that it didn't work
        return;
    } else if (self.inputStreamState == SDLAudioIOManagerStatePausing) {
        // the response is received because we wanted to pause the input stream
        SDLLogV(@"Input stream state is pausing, set status to paused");
        self.inputStreamState = SDLAudioIOManagerStatePaused;
    } else {
        // the input stream was started (or even stopping) and now we want to finally stop it
        SDLLogV(@"Set input stream state to stopped");
        self.inputStreamState = SDLAudioIOManagerStateStopped;
    }
    
    // reset the retry counter in case previous tries were rejected
    self.inputStreamRetryCounter = 0;
    
    // notify about the result (unless it was rejected and we want to retry)
    SDLLogV(@"Notify delegate that input stream is finished");
    __strong id<SDLAudioIOManagerDelegate> d = self.delegate;
    if (d && [d respondsToSelector:@selector(audioManager:didFinishInputStreamWithResult:)]) {
        [d audioManager:self didFinishInputStreamWithResult:resultCode];
    }
    
    // if output stream is starting. now it's time to do so.
    SDLLogV(@"Checking output stream state %@", [self nameForStreamState:self.outputStreamState]);
    if (self.outputStreamState == SDLAudioIOManagerStateStarting) {
        SDLLogV(@"Output sream state is starting, call start ouput stream");
        [self sdl_startOutputStream];
    }
}

- (void)sdl_pauseInputStream {
    SDLLogV(@"Attempt to pause input stream with input state %@", [self nameForStreamState:self.inputStreamState]);
    
    switch (self.inputStreamState) {
        case SDLAudioIOManagerStateStarting:
        case SDLAudioIOManagerStateStarted: {
            // if input stream is started or starting we have to send a request to stop it but the status will be pausing (or paused later on)
            SDLLogV(@"Input stream state is started. Change state to pausing and send request to end audio input");
            self.inputStreamState = SDLAudioIOManagerStatePausing;
            [self.sdlManager sendRequest:[[SDLEndAudioPassThru alloc] init]];
            [self sdl_initiateAbortInputStreamTimer];
            break;
        }
        default: {
            // other states are irrelevant
            SDLLogV(@"Ignoring state");
            break;
        }
    }
}

- (void)sdl_stopInputStream {
    SDLLogV(@"Attempt to stop input stream with input state %@",  [self nameForStreamState:self.inputStreamState]);
    
    switch (self.inputStreamState) {
        case SDLAudioIOManagerStateStarting:
        case SDLAudioIOManagerStateStarted: {
            SDLLogV(@"Stopping input stream. Sending request to end audio input");
            self.inputStreamState = SDLAudioIOManagerStateStopping;
            [self.sdlManager sendRequest:[[SDLEndAudioPassThru alloc] init]];
            [self sdl_initiateAbortInputStreamTimer];
            break;
        }
        default: {
            // other states are irrelevant
            SDLLogV(@"Ignoring state");
            break;
        }
    }
}

- (void)sdl_initiateAbortInputStreamTimer {
    dispatch_async(dispatch_get_main_queue(), ^{
        SDLLogV(@"(re)initiate abort timer");
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(sdl_abortInputStream) object:nil];
        [self performSelector:@selector(sdl_abortInputStream) withObject:nil afterDelay:INPUT_STREAM_ABORT_TIMEOUT];
    });
}

- (BOOL)sdl_abortInputStream {
    SDLLogV(@"Attempt to abort input stream from %@", [self nameForStreamState:self.inputStreamState]);
    
    switch (self.inputStreamState) {
        case SDLAudioIOManagerStateStarted:
        case SDLAudioIOManagerStateStopped:
            SDLLogW(@"Input stream abort not possible when Started or Stopped. Current state %@", [self nameForStreamState:self.inputStreamState]);
            return NO;
    }
    
    if (self.inputStreamOperation == nil) {
        SDLLogW(@"Cannot abort pending input stream without correlation ID");
        return NO;
    }

    // Aborting from Pausing to Paused or Stopping to Stopped is already regular workflow. We need to enforce stopping when we tried to start.
    if (self.inputStreamState == SDLAudioIOManagerStateStarting) {
        self.inputStreamState = SDLAudioIOManagerStateStopping;
    }
    
    SDLPerformAudioPassThruResponse *response = [[SDLPerformAudioPassThruResponse alloc] init];
    response.correlationID = self.inputStreamOperation.requests[0].correlationID;
    response.resultCode = SDLResultAborted;
    response.success = @NO;
    
    // WORKAROUND this will notify the RPC dispatcher
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
    SDLLogV(@"Simulate a audio input response with aborted code: %@", [response serializeAsDictionary:0]);
    #pragma clang diagnostic pop
    SDLRPCResponseNotification *notification = [[SDLRPCResponseNotification alloc] initWithName:SDLDidReceivePerformAudioPassThruResponse object:self.sdlManager.notificationDispatcher rpcResponse:response];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
    
    return YES;
}

- (double)sdl_calculateAmplifierFactor:(const void *)bytedata size:(NSUInteger)size {
    double factor = INPUT_STREAM_AMPLIFIER_FACTOR_MAX;
    
    if ([self.inputStreamOptions.bitsPerSample isEqualToEnum:SDLBitsPerSample16Bit]) {
        // divide count to short elements
        size = size >> 1;
        
        // create pointer with short type (2 byte int)
        int16_t *shortbuffer = (int16_t *)bytedata;
        
        for (int i = 0; i < size; i++) {
            int16_t a = shortbuffer[i];
            double f;
            if (a >= 0) {
                f = ((double)INT16_MAX) / ((double)a);
            } else {
                f = ((double)INT16_MIN) / ((double)a);
            }
            
            factor = MIN(factor, f);
        }
    } else {
        // create pointer with byte type (signed byte int)
        uint8_t *bytebuffer = (uint8_t *)bytedata;
        
        for (int i = 0; i < size; i++) {
            int8_t a = (int8_t)((int16_t)bytebuffer[i] - (int16_t)127);
            double f;
            if (a >= 0) {
                f = ((double)INT8_MAX) / ((double)a);
            } else {
                f = ((double)INT8_MIN) / ((double)a);
            }
            
            factor = MIN(factor, f);
        }
    }
    
    return factor;
}

- (void)sdl_applyAmplifierFactor:(double)factor data:(void *)bytedata size:(NSUInteger)size {
    if (factor == 1.0) {
        return;
    }
    
    if ([self.inputStreamOptions.bitsPerSample isEqualToEnum:SDLBitsPerSample16Bit]) {
        // divide count to short elements
        size = size >> 1;
        
        // create pointer with short type (2 byte int)
        int16_t *shortbuffer = (int16_t *)bytedata;
        
        // loop through all samples
        for (int i = 0; i < size; i++) {
            int16_t a = shortbuffer[i];
            // apply the amplifier factor with the best precision and round it
            a = (int16_t)(round(((double)a) * factor));
            // write the amplified sample value back to the buffer
            shortbuffer[i] = a;
        }
    } else {
        // create pointer with byte type (unsigned signed byte int)
        uint8_t *bytebuffer = (uint8_t *)bytedata;
        
        // loop through all samples
        for (int i = 0; i < size; i++) {
            // get the sample value
            int8_t a = (int8_t)((int16_t)bytebuffer[i] - (int16_t)127);
            // apply the amplifier factor with the best precision and round it
            a = (int8_t)(round(((double)a) * factor));
            // write the amplified sample value back to the buffer
            bytebuffer[i] = (uint8_t)((int16_t)a + (int16_t)127);
        }
    }
}


@end

NS_ASSUME_NONNULL_END
