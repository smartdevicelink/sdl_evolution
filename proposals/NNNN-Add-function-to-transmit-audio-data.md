# Add function to transmit audio data of AudioStream in time division


* Proposal: [SDL-NNNN](NNNN-Add-function-to-transmit-audio-data.md)
* Author: [Yuki Shoda](https://github.com/Yuki-Shoda)
* Status: **Awaiting review**
* Impacted Platforms: [iOS / Java Suite]

## Introduction
This proposal is to add a function that transmits time-divided audio data via AudioStreaming.

## Motivation
In communication of AudioStreaming, HU expects that it can always get audio data without delay when it wants to play.
Due to the current implementation, it is not possible to cancel the playback of data, which has been sent to the HU, hence audio interruption function cannot be implemented.
Therefore, when the navigation points are continuous, the first audio is played as is, but the second/following audio may be delayed because they are played after the previous one is completed.

Also, if the next navigation guide audio data is sent during a navigation guide audio playback that is longer than a Core timeout, the playback may be interrupted before it is complete due to a Core timeout.

## Proposed solution
Within the proxy (AudioStreamManager), the audio data is split into parts (for example, every second calculated from bitsample/freq) and is sent at intervals so that socket stream data will not have gaps in between.

The process of transmitting audio data to the HU is implemented using a timer thread.

The conceptual diagram is shown below.

![Image](../assets/proposals/NNNN-Add-function-to-transmit-audio-data/Image.gif)

The code samples for iOS and Java Suite are shown below.
* It is necessary to consider pushBuffer and pushWithData of AudioStreamManager.

### iOS
**SDLAudioStreamManager.m file**

1 second voice data byte length:
```objc
	// Byte length of voice data per second
	static const NSInteger PerSecondVoiceData = 32000;
```
Number of seconds to stop processing to send sound on HS:
```objc
	// How many seconds the handset can precede the head unit
	static const NSTimeInterval ThresholdPrecedeSec = 3.0f;
```
Add ForceInterrupt to argument to force data to play:
```objc
	- (void)pushWithFileURL:(NSURL *)fileURL forceInterrupt:(BOOL)forceInterrupt {    dispatch_async(_audioQueue, ^{
	        [self sdl_pushWithContentsOfURL:fileURL forceInterrupt:forceInterrupt];
		});
	}
```
If there is no next sound data, adjust the end time for streaming. If forceInterrupt flag is set, stop audio streaming.

```objc
	- (void)sdl_pushWithContentsOfURL:(NSURL *)fileURL forceInterrupt:(BOOL)forceInterrupt {
		// Convert and store in the queue
		NSError *error = nil;
		SDLPCMAudioConverter *converter = [[SDLPCMAudioConverter alloc] initWithFileURL:fileURL];
		NSURL *_Nullable outputFileURL = [converter convertFileWithError:&error];
		UInt32 estimatedDuration = converter.estimatedDuration;

		if (outputFileURL == nil) {
			SDLLogE(@"Error converting file to CAF / PCM: %@", error);
			if (self.delegate != nil) {
				[self.delegate audioStreamManager:self errorDidOccurForFile:fileURL error:error];
			}
			return;
		}

		if (self.mutableQueue.count == 0) {
			NSTimeInterval precedeTime = self.streamingEndTimeOfHU - [[NSDate date] timeIntervalSince1970];
			if (precedeTime > 0.0f) {
				SDLLogD(@"Time when handset is ahead of head unit: %f", precedeTime);
				[NSThread sleepForTimeInterval:precedeTime];
			}
			self.streamingEndTimeOfHU = [[NSDate date] timeIntervalSince1970];
		}

		if (forceInterrupt) {
			[self sdl_stop];
		}

		SDLAudioFile *audioFile = [[SDLAudioFile alloc] initWithInputFileURL:fileURL outputFileURL:outputFileURL estimatedDuration:estimatedDuration];
		[self.mutableQueue addObject:audioFile];

		if (self.shouldPlayWhenReady) {
			[self sdl_playNextWhenReady];
		}
	}

	- (void)sdl_stop {
		NSError *error = nil;
		for (SDLAudioFile *file in self.mutableQueue) {
			if (file.outputFileURL != nil) {
				[[NSFileManager defaultManager] removeItemAtURL:file.outputFileURL error:&error];
			}
		}
		[self.mutableQueue removeAllObjects];

		if (self.audioStreamTimer != nil) {
			dispatch_stop_timer(self.audioStreamTimer);
			self.audioStreamTimer = nil;
		}
		self.shouldPlayWhenReady = NO;
		self.playing = NO;
	}
```

Send audio data in time division:
```objc
	- (void)sdl_playNextWhenReady {
		if (self.mutableQueue.count == 0) {
			self.shouldPlayWhenReady = YES;
			return;
		}

		if (!self.streamManager.isAudioConnected) {
			if (self.delegate != nil) {
				NSError *error = [NSError errorWithDomain:SDLErrorDomainAudioStreamManager code:SDLAudioStreamManagerErrorNotConnected userInfo:nil];
				[self.delegate audioStreamManager:self errorDidOccurForFile:self.mutableQueue.firstObject.inputFileURL error:error];
			}
			return;
		}

		self.shouldPlayWhenReady = NO;
		if (self.playing == NO) {
			self.playing = YES;
			SDLAudioFile *file = self.mutableQueue.firstObject;

			// Strip the first bunch of bytes (because of how Apple outputs the data) and send to the audio stream, if we don't do this, it will make a weird click sound
			__block NSData *audioData = nil;
			if (file.inputFileURL != nil) {
				audioData = [file.data subdataWithRange:NSMakeRange(5760, (file.data.length - 5760))];
			} else {
				audioData = file.data;
			}

			NSTimeInterval precedeTime = self.streamingEndTimeOfHU - [[NSDate date] timeIntervalSince1970];
			if(precedeTime > ThresholdPrecedeSec){
				SDLLogD(@"The time during which the handset precedes the head unit exceeds the threshold: %f", precedeTime);
				[NSThread sleepForTimeInterval:ThresholdPrecedeSec];
			}

			// Send the audio file, which starts it playing immediately
			SDLLogD(@"Playing audio file: %@", file);
			BOOL success = [self sendAudioData:&audioData of:PerSecondVoiceData * 2];
			if ((success) && (audioData.length > 0)) {
				__weak typeof(self) weakSelf = self;
				self.audioStreamTimer = dispatch_create_timer(1.0f, YES, ^{
					BOOL success = [weakSelf sendAudioData:&audioData of:PerSecondVoiceData];
					if ((success) && (audioData.length > 0)) {
						SDLLogD(@"sendAudioData continue: %lu", (unsigned long)audioData.length);
					} else {
						SDLLogD(@"sendAudioData end");
						dispatch_stop_timer(weakSelf.audioStreamTimer);
						weakSelf.audioStreamTimer = nil;

						[weakSelf sdl_finishAudioStreaming:file success:success];
					}
				});
			} else {
				[self sdl_finishAudioStreaming:file success:success];
			}
		}
	}

	- (void)sdl_finishAudioStreaming:(SDLAudioFile *)file success:(BOOL)success {
		__weak typeof(self) weakself = self;
		dispatch_async(_audioQueue, ^{
			weakself.playing = NO;
			if (weakself.mutableQueue.count > 0) {
				[weakself.mutableQueue removeObjectAtIndex:0];
				[weakself sdl_playNextWhenReady];
			}
		});
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
			NSError *error = nil;
			if (weakself.delegate != nil) {
				if (file.inputFileURL != nil) {
					[weakself.delegate audioStreamManager:weakself fileDidFinishPlaying:file.inputFileURL successfully:success];
				} else if ([weakself.delegate respondsToSelector:@selector(audioStreamManager:dataBufferDidFinishPlayingSuccessfully:)]) {
					[weakself.delegate audioStreamManager:weakself dataBufferDidFinishPlayingSuccessfully:success];
				}
			}

			SDLLogD(@"Ending Audio file: %@", file);
			[[NSFileManager defaultManager] removeItemAtURL:file.outputFileURL error:&error];
			if (strongSelf.delegate != nil && error != nil) {
				if (file.inputFileURL != nil) {
					[strongSelf.delegate audioStreamManager:strongSelf errorDidOccurForFile:file.inputFileURL error:error];
				} else if ([strongSelf.delegate respondsToSelector:@selector(audioStreamManager:errorDidOccurForDataBuffer:)]) {
					[strongSelf.delegate audioStreamManager:strongSelf errorDidOccurForDataBuffer:error];
				}
			}
		});
	}

	- (BOOL)sendAudioData:(NSData **)data of:(NSUInteger)byteLength{
		if (self.streamManager.isAudioConnected == NO) {
			return NO;
		}

		NSUInteger sByte = byteLength;
		if ((*data).length < byteLength) {
			sByte = (*data).length;
		}

		if ([self.streamManager sendAudioData:[*data subdataWithRange:NSMakeRange(0, sByte)]]) {
			// Set remaining voice data
			*data = [(*data) subdataWithRange:NSMakeRange(sByte, (*data).length - sByte)];

			// Calculate the AudioStreaming end time on the HU side.
			self.streamingEndTimeOfHU += (double)sByte / (double)PerSecondVoiceData;
			return YES;
		}
		return NO;
	}
```

### Java Suite
**AudioDecoderListener.java file**

Add a flag called MediaCodec information buffer instead of sample buffer argument that holds decoded audio data:
```java
void onAudioDataAvailable(ArrayList<SampleBuffer> sampleBufferList, int flags);
```
**AudioStreamManager.java file**

Add member variable:
```java
//Decoder queue
private final Queue<Decoder> queue;
//Audio streaming send thread
private SendAudioStreamThread mSendAudioStreamThread;
//Audio buffer list
private ArrayList<SendAudioBuffer> mAudioBufferList = null;
//Data transmission end time
private long mEndTimeOfSendData = 0;
//Lock data transmission thread
private final Object LOCK_SENDTHREAD = new Object();
```
Get audio streaming information:
```java
	private void getAudioStreamingCapabilities(){
		internalInterface.getCapability(SystemCapabilityType.PCM_STREAMING, new OnSystemCapabilityListener() {
			@Override
			public void onCapabilityRetrieved(Object capability) {
				if(capability != null && capability instanceof AudioPassThruCapabilities){
					audioStreamingCapabilities = (AudioPassThruCapabilities) capability;
					checkState();
				}
			}

			@Override
			public void onError(String info) {
				//Added to get default audio passthrough function
				audioStreamingCapabilities = getDefaultAudioPassThruCapabilities();
				checkState();
			}
		});
	}
```
Execute when AudioStreamManager is disposed:
```java
	@Override
	public void dispose() {
		mEndTimeOfSendData = 0;
		cleanAudioStreamThread();
		stopAudioStream(new CompletionListener() {
			@Override
			public void onComplete(boolean success) {
				internalInterface.removeServiceListener(SessionType.PCM, serviceListener);
			}
		});

		super.dispose();
	}
```
Start audio streaming:
```java
	public void startAudioStream(boolean encrypted, final CompletionListener completionListener) {
		// audio stream cannot be started without a connected internal interface
		if (!internalInterface.isConnected()) {
			Log.w(TAG, "startAudioStream called without being connected.");
			finish(completionListener, false);
			return;
		}

	// streaming state must be NONE (starting the service is ready. starting stream is started)
	if (streamingStateMachine.getState() != StreamingStateMachine.NONE) {
		Log.w(TAG, "startAudioStream called but streamingStateMachine is not in state NONE (current: " + streamingStateMachine.getState() + ")");
		finish(completionListener, false);
		return;
	}

	AudioPassThruCapabilities capabilities = (AudioPassThruCapabilities) internalInterface.getCapability(SystemCapabilityType.PCM_STREAMING);

	if(capabilities == null){
		capabilities = getDefaultAudioPassThruCapabilities();
	}
	if (capabilities != null) {
		switch (capabilities.getSamplingRate()) {
			case _8KHZ:
				sdlSampleRate = 8000;
				break;
			case _16KHZ:
				sdlSampleRate = 16000;
				break;
			case _22KHZ:
				// common sample rate is 22050, not 22000
				// see https://en.wikipedia.org/wiki/Sampling_(signal_processing)#Audio_sampling
				sdlSampleRate = 22050;
				break;
			case _44KHZ:
				// 2x 22050 is 44100
				// see https://en.wikipedia.org/wiki/Sampling_(signal_processing)#Audio_sampling
				sdlSampleRate = 44100;
				break;
			default:
				finish(completionListener, false);
				return;
		}

		switch (capabilities.getBitsPerSample()) {
			case _8_BIT:
				sdlSampleType = SampleType.UNSIGNED_8_BIT;
				break;
			case _16_BIT:
				sdlSampleType = SampleType.SIGNED_16_BIT;
				break;
			default:
				finish(completionListener, false);
				return;

		}
	} else {
		finish(completionListener, false);
		return;
	}

	streamingStateMachine.transitionToState(StreamingStateMachine.READY);
	serviceCompletionListener = completionListener;
	serviceCompletionHandler.postDelayed(serviceCompletionTimeoutCallback, COMPLETION_TIMEOUT);
	internalInterface.startAudioService(encrypted);
}

	private void finish(CompletionListener listener, boolean isSuccess) {
		if (listener != null) {
			listener.onComplete(isSuccess);
		}
		synchronized (LOCK_SENDTHREAD) {
			if (mSendAudioStreamThread != null) {
				Log.d(TAG, "finish() Wait for thread termination");
				mSendAudioStreamThread.stopAs();
				try {
					mSendAudioStreamThread.join();
				} catch (InterruptedException e) {
				}
				mSendAudioStreamThread = null;
			}
		}
	}
```
If there is no next sound data, adjust the end time for streaming. If `forceInterrupt` flag is set, stop audio streaming:
```java
	public void pushResource(int resourceId, final CompletionListener completionListener,boolean interrupt) {
		Context c = context.get();
		Resources r = c.getResources();
		Uri uri = new Uri.Builder()
			.scheme(ContentResolver.SCHEME_ANDROID_RESOURCE)
			.authority(r.getResourcePackageName(resourceId))
			.appendPath(r.getResourceTypeName(resourceId))
			.appendPath(r.getResourceEntryName(resourceId))
			.build();
		this.pushAudioSource(uri, completionListener,interrupt);
	}
```
Push audio source:
```java
	public void pushAudioSource(Uri audioSource, final CompletionListener completionListener,boolean interrupt) {
		// streaming state must be STARTED (starting the service is ready. starting stream is started)
		if (streamingStateMachine.getState() != StreamingStateMachine.STARTED) {
			return;
		}

		BaseAudioDecoder decoder;
		AudioDecoderListener decoderListener = new AudioDecoderListener() {
			@Override
			public void onAudioDataAvailable(ArrayList<SampleBuffer> sampleBufferList,int flags) {
				if(mSendAudioStreamThread != null){
					ArrayList<SendAudioBuffer> sendBufferList = new ArrayList<>();
					if(sampleBufferList == null){
						sendBufferList.add(
							new SendAudioBuffer(null, flags == MediaCodec.BUFFER_FLAG_END_OF_STREAM? SendAudioBuffer.DECODER_FINISH_SUCCESS: SendAudioBuffer.DECODER_NOT_FINISH)
                                        );
						} else {
						for(int i = 0 ; i < sampleBufferList.size() ;i++){
							SampleBuffer buffer = sampleBufferList.get(i);
							int iFlag = SendAudioBuffer.DECODER_NOT_FINISH;
							if(flags == MediaCodec.BUFFER_FLAG_END_OF_STREAM &&  sampleBufferList.size() == i+1){
								iFlag = SendAudioBuffer.DECODER_FINISH_SUCCESS;
								}
							sendBufferList.add(
								new SendAudioBuffer(buffer, iFlag)
							);
						}
					}
					mSendAudioStreamThread.addAudioData(sendBufferList);
				}
			}

			@Override
			public void onDecoderFinish(boolean success) {

				// if the queue contains more items then start the first one (without removing it)
				if(mSendAudioStreamThread != null && !success){
					ArrayList<SendAudioBuffer> sendBufferList = new ArrayList<>();
						sendBufferList.add(
							new SendAudioBuffer(null, SendAudioBuffer.DECODER_FINISH_FAILED)
						);
					mSendAudioStreamThread.addAudioData(sendBufferList);
				}
			}

			@Override
			public void onDecoderError(Exception e) {
				Log.e(TAG, "decoder error", e);
			}
		};

		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
			decoder = new AudioDecoder(audioSource, context.get(), sdlSampleRate, sdlSampleType, decoderListener);
		} else {
			// this BaseAudioDecoder subclass uses methods deprecated with api 21
			decoder = new AudioDecoderCompat(audioSource, context.get(), sdlSampleRate, sdlSampleType, decoderListener);
		}
		startAudioStreamThread(new Decoder(decoder,completionListener,interrupt));
	}

		private void startAudioStreamThread(final Decoder _decoder){
			Log.d(TAG, "startAudioStreamThread() queue.size():" + queue.size());
			if (streamingStateMachine.getState() != StreamingStateMachine.STARTED || sdlAudioStream == null) {
				cleanAudioStreamThread();
				return;
			}
			if(_decoder != null){
				if(_decoder.isInterrupt()){
					//Stop AS data
					Log.d(TAG, "Audio playback interrupted");
					finish(null,true);
					synchronized (queue) {
						while (queue.size() > 0){
							queue.element().getAudioDecoder().stop();
							queue.remove();
						}
					}
				}
			}
			synchronized (LOCK_SENDTHREAD) {
				if(mSendAudioStreamThread == null){
					mSendAudioStreamThread = new SendAudioStreamThread(new Runnable() {

						@Override public void run() {
							synchronized (queue) {
								if(queue.size() > 0){
									queue.element().getAudioDecoder().start();
								}
							}
						}
					});
					synchronized (queue) {
						if(_decoder != null){
							queue.add(_decoder);
						}
					}
					mSendAudioStreamThread.start();
				} else {
					synchronized (queue) {
						if(_decoder != null){
							queue.add(_decoder);
						}
					}
				}
			}
	}


	private long getDelayStartAudioTime(){
		long nowTime = System.currentTimeMillis();
		long lDelay = mEndTimeOfSendData - nowTime;
		if(lDelay < 0){
			lDelay = 0;
		} else {
			if(lDelay < 1500){
				lDelay = 0;
			} else {
				lDelay -= 1500;
			}
		}
		return lDelay;
	}


	private void cleanAudioStreamThread(){
		if (mSendAudioStreamThread != null) {
			mSendAudioStreamThread.stopAs();
			try {
				mSendAudioStreamThread.join();
            } catch (InterruptedException e) {
            }
            mSendAudioStreamThread = null;
        }
        synchronized (queue) {
            while (queue.size() > 0){
                queue.element().getAudioDecoder().stop();
                queue.remove();
            }
        }
    }
```
Decoder entity:
```java
    private class Decoder {
        private BaseAudioDecoder mAudioDecoder;
        private CompletionListener mCompletionListener;
        private boolean mInterrupt;
        public Decoder(BaseAudioDecoder decoder,CompletionListener listener,boolean interrupt){
            mAudioDecoder = decoder;
            mCompletionListener = listener;
            mInterrupt = interrupt;
        }
        public BaseAudioDecoder getAudioDecoder(){
            return mAudioDecoder;
        }

        public CompletionListener getCompletionListener(){
            return mCompletionListener;
        }

        public boolean isInterrupt(){
            return mInterrupt;
        }
    }
```
Audio buffer transmission entity:
```java
    private class SendAudioBuffer {
        private final static int DECODER_NOT_FINISH = 0;
        private final static int DECODER_FINISH_SUCCESS = 1;
        private final static int DECODER_FINISH_FAILED = 2;
        private ByteBuffer mByteBuffer;
        private long mPresentationTimeUs;
        private int mFinishFlag;

        public SendAudioBuffer(SampleBuffer _buff,int flag){

            mFinishFlag = flag;
            if(_buff != null){
                mPresentationTimeUs = _buff.getPresentationTimeUs();
                ByteBuffer buff = _buff.getByteBuffer();
                mByteBuffer = ByteBuffer.allocate(buff.remaining());
                mByteBuffer.put(buff);
                mByteBuffer.flip();
            }

        }

        public long getPresentationTimeUs(){
            return mPresentationTimeUs;
        }

        public ByteBuffer getByteBuffer(){
            return mByteBuffer;
        }

        public int getFinishFlag(){
            return mFinishFlag;
        }
    }
```
Audio streaming data transmission thread:
```java
    private final class SendAudioStreamThread extends Thread{
        private static final int MSG_TICK = 1;
        private static final int MSG_ADD = 2;
        private static final int MSG_TERMINATE = -1;
        private boolean isFirst = true;
        private Handler mHandler;
        private Runnable mStartedCallback;
        private boolean mIsStopRequest = false;

        public SendAudioStreamThread(Runnable onStarted) {
            mStartedCallback = onStarted;
        }
        @Override
        public void run() {
            Looper.prepare();
            if(mHandler == null){
                mHandler = new Handler() {
                    long startTime = 0;
                    public void handleMessage(Message msg) {
                        switch (msg.what) {
                            case MSG_TICK: {
                                long delay = 0;
                                if(mAudioBufferList != null && mAudioBufferList.size() > 0){
                                    while (true){
                                        if (streamingStateMachine.getState() != StreamingStateMachine.STARTED || sdlAudioStream == null) {
                                            Log.e(TAG, "Streaming Status error:" + streamingStateMachine.getState() );
                                            Handler handler = new Handler(Looper.getMainLooper());
                                            handler.post(new Runnable() {
                                                @Override
                                                public void run() {
                                                    cleanAudioStreamThread();
                                                }
                                            });
                                            break;
                                        }

                                        if(mAudioBufferList.size() > 0){
                                            SendAudioBuffer sBuffer = mAudioBufferList.get(0);
                                            if(sBuffer.getByteBuffer() != null){
                                                long nowTime = System.currentTimeMillis();
                                                long AllowableTime = (nowTime - startTime + 1000) * 1000;
                                                if( AllowableTime  >  sBuffer.getPresentationTimeUs()){
                                                    long lSendDataTime = (Long.valueOf(sBuffer.getByteBuffer().limit()) * 1000 )/ (sdlSampleRate * 2);
                                                    mEndTimeOfSendData = startTime + ( sBuffer.getPresentationTimeUs()/1000) + lSendDataTime;
                                                    sdlAudioStream.sendAudio(sBuffer.getByteBuffer(), sBuffer.getPresentationTimeUs());
                                                } else {
                                                    //Delay data transmission
                                                    Log.d(TAG, "Delay the call to sendAudio");
                                                    delay = 500;
                                                    break;
                                                }
                                            }
                                            mAudioBufferList.remove(0);

                                            if(sBuffer.getFinishFlag() != SendAudioBuffer.DECODER_NOT_FINISH) {
                                                final boolean isSuccess = sBuffer.getFinishFlag() == SendAudioBuffer.DECODER_FINISH_SUCCESS;

                                                Handler handler = new Handler(Looper.getMainLooper());
                                                long lDelay = getDelayStartAudioTime();
                                                Log.d(TAG, "Playback end notification. lDelay:" + lDelay);
                                                handler.postDelayed(new Runnable() {
                                                    @Override
                                                    public void run() {
                                                        synchronized (queue) {
                                                            if (queue.size() > 0) {
                                                                finish(queue.poll().getCompletionListener(),isSuccess);
                                                            } else {
                                                                Log.e(TAG, "There is no element of the queue");
                                                            }
                                                            if (queue.size() > 0) {
                                                                startAudioStreamThread(null);
                                                            }
                                                        }
                                                    }
                                                    },lDelay);
                                                return;
                                            }
                                        } else {
                                            break;
                                        }
                                    }

                                }
                                sendMessageDelayed(mHandler.obtainMessage(MSG_TICK), delay);
                                break;
                            }
                            case MSG_ADD: {
                                if(mAudioBufferList == null){
                                    mAudioBufferList =  new ArrayList<>();
                                    startTime = System.currentTimeMillis();
                                    if(startTime < mEndTimeOfSendData){
                                        Log.d(TAG, "The playback end time exceeds the current time. EndTime:" + mEndTimeOfSendData);
                                        startTime = mEndTimeOfSendData;
                                    }
                                }
                                ArrayList<SendAudioBuffer> sendBufferList = (ArrayList<SendAudioBuffer>)msg.obj;
                                for(SendAudioBuffer buff: sendBufferList){
                                    mAudioBufferList.add(buff);
                                }
                                break;
                            }
                            case MSG_TERMINATE: {
                                removeCallbacksAndMessages(null);
                                if(mAudioBufferList != null){
                                    mAudioBufferList.clear();
                                    mAudioBufferList = null;
                                }
                                mHandler = null;
                                mIsStopRequest = false;
                                Looper looper = Looper.myLooper();
                                if (looper != null) {
                                    looper.quit();
                                }
                                break;
                            }
                            default:
                                break;
                        }
                    }
                };
            }
            if(mIsStopRequest){
                Log.d(TAG, "StopRequest is valid");
                return;
            }
            if (mStartedCallback != null) {
                mStartedCallback.run();
            }
            Log.d(TAG, "Starting SendAudioStreamThread");
            Looper.loop();
            Log.d(TAG, "Stopping SendAudioStreamThread");
        }

        public void addAudioData(final  ArrayList<SendAudioBuffer> sendBufferList){
            if (mHandler != null && sendBufferList != null && sendBufferList.size() > 0) {
                    Message msg = Message.obtain();
                    msg.what = MSG_ADD;
                    msg.obj = sendBufferList;
                    mHandler.sendMessage(msg);
                    if(isFirst){
                            mHandler.sendMessage(mHandler.obtainMessage(MSG_TICK));
                            isFirst = false;
                        }
                } else {
                    Log.d(TAG, "addAudioData mHandler is null");
                }
        }

    public void stopAs(){
            if (mHandler != null) {
                    mHandler.sendMessage(mHandler.obtainMessage(MSG_TERMINATE));
            } else {
                mIsStopRequest = true;
                Log.d(TAG, "The thread has not started yet");
            }
        }
}
```
Get the default audio passthrough function:
```java
    private AudioPassThruCapabilities getDefaultAudioPassThruCapabilities(){
        AudioPassThruCapabilities aptCapabilities = new AudioPassThruCapabilities();
        aptCapabilities.setAudioType(AudioType.PCM);
        aptCapabilities.setBitsPerSample(BitsPerSample._16_BIT);
        aptCapabilities.setSamplingRate(SamplingRate._16KHZ);
        return aptCapabilities;
    }
```
**AudioDecoder.java file**
Start decoding audio asynchronously:
```java
	public void start() {
		try {
			initMediaComponents();

			decoder.setCallback(new MediaCodec.Callback() {
				@Override
				public void onInputBufferAvailable(@NonNull MediaCodec mediaCodec, int i) {
					try {
						ByteBuffer inputBuffer = mediaCodec.getInputBuffer(i);
						if (inputBuffer == null) return;

						MediaCodec.BufferInfo info = AudioDecoder.super.onInputBufferAvailable(extractor, inputBuffer);
						mediaCodec.queueInputBuffer(i, info.offset, info.size, info.presentationTimeUs, info.flags);
					} catch (Exception e) {
						e.printStackTrace();
						listener.onDecoderError(e);
					}
				}
                @Override
                public void onOutputBufferAvailable(@NonNull MediaCodec mediaCodec, int i, @NonNull MediaCodec.BufferInfo bufferInfo) {
                    try {
                        ByteBuffer outputBuffer = mediaCodec.getOutputBuffer(i);
                        if (outputBuffer == null) return;
                        ArrayList<SampleBuffer> targetSampleBufferList = null;
                        if (outputBuffer.limit() > 0) {
                            targetSampleBufferList = AudioDecoder.super.onOutputBufferAvailable(outputBuffer);
                        } else {
                            Log.w(TAG, "output buffer empty. Chance that silence was detected");
                        }
                        AudioDecoder.this.listener.onAudioDataAvailable(targetSampleBufferList,bufferInfo.flags);
                        mediaCodec.releaseOutputBuffer(i, false);
                        if (bufferInfo.flags == MediaCodec.BUFFER_FLAG_END_OF_STREAM) {
                            listener.onDecoderFinish(true);
                            stop();
                        }
                    } catch (Exception e) {
                        e.printStackTrace();
                        listener.onDecoderError(e);
                    }
                }

                @Override
                public void onOutputFormatChanged(@NonNull MediaCodec mediaCodec, @NonNull MediaFormat mediaFormat) {
                        AudioDecoder.super.onOutputFormatChanged(mediaFormat);
                }

                @Override
                public void onError(@NonNull MediaCodec mediaCodec, @NonNull MediaCodec.CodecException e) {
                    AudioDecoder.super.onMediaCodecError(e);
                }
            });

            decoder.start();
        } catch (Exception e) {
            e.printStackTrace();
            listener.onDecoderError(e);
            listener.onDecoderFinish(false);
            stop();
        }
    }
```
**AudioDecoderCompat.java file**
Stop audio decoding asynchronously:
```java
    @Override
    public void stop() {
        if(mThread != null){
			mThread.interrupt();
			mThread = null;
		}
		super.stop();
	}
```
A thread to start decoding audio asynchronously:
```java
	private static class DecoderRunnable implements Runnable {
		WeakReference<AudioDecoderCompat> weakReference;

		/**
		* Decodes all audio data from source
		* @param audioDecoderCompat instance of this class
		*/
		DecoderRunnable(@NonNull AudioDecoderCompat audioDecoderCompat){
			weakReference = new WeakReference<>(audioDecoderCompat);

		}
		@Override
        public void run() {
            final AudioDecoderCompat reference = weakReference.get();
            try {
                if (reference == null) {
                    Log.w(TAG, "AudioDecoderCompat reference was null");
                    return;
                }
                if(reference.decoder == null){
                    Log.w(TAG, "AudioDecoderCompat decoder was null");
                    return;
                }
                while (reference!= null && !reference.mThread.isInterrupted()) {
                    if( AudioDecoder(reference,reference.decoder.getInputBuffers(),reference.decoder.getOutputBuffers())){
                        break;
                    }
                }
            } catch (Exception e) {
                Log.w(TAG, "DecoderRunnable Exception:" + e);
            } finally {
                if (reference != null && reference.mThread != null) {
                    try {
                        reference.mThread.interrupt();
                    } catch (Exception e) {
                        e.printStackTrace();
                    } finally {
                        reference.mThread = null;
                    }
                }
            }
        }

        boolean AudioDecoder(final AudioDecoderCompat reference,final ByteBuffer[] inputBuffersArray,final ByteBuffer[] outputBuffersArray){
            MediaCodec.BufferInfo outputBufferInfo = new MediaCodec.BufferInfo();
            MediaCodec.BufferInfo inputBufferInfo;
            ByteBuffer inputBuffer, outputBuffer;
            SampleBuffer sampleBuffer;
            int inputBuffersArrayIndex = 0;
            while (inputBuffersArrayIndex != MediaCodec.INFO_TRY_AGAIN_LATER) {
                try {
                    inputBuffersArrayIndex = reference.decoder.dequeueInputBuffer(DEQUEUE_TIMEOUT);
                    if (inputBuffersArrayIndex >= 0) {
                        inputBuffer = inputBuffersArray[inputBuffersArrayIndex];
                        inputBufferInfo = reference.onInputBufferAvailable(reference.extractor, inputBuffer);
                        reference.decoder.queueInputBuffer(inputBuffersArrayIndex, inputBufferInfo.offset, inputBufferInfo.size, inputBufferInfo.presentationTimeUs, inputBufferInfo.flags);
                    }
                } catch (Exception e) {
                    Log.d(TAG, "DecoderRunnable Exception OutputBuffer :" + e);
                    return true;
                }
            }
            int outputBuffersArrayIndex = 0;
            while (outputBuffersArrayIndex != MediaCodec.INFO_TRY_AGAIN_LATER) {
                try {
                    outputBuffersArrayIndex = reference.decoder.dequeueOutputBuffer(outputBufferInfo, DEQUEUE_TIMEOUT);
                    if (outputBuffersArrayIndex >= 0) {
                        outputBuffer = outputBuffersArray[outputBuffersArrayIndex];
                        if ((outputBufferInfo.flags & MediaCodec.BUFFER_FLAG_CODEC_CONFIG) != 0 && outputBufferInfo.size != 0) {
							 reference.decoder.releaseOutputBuffer(outputBuffersArrayIndex, false);
                        } else if (outputBuffer.limit() > 0) {
                            ArrayList<SampleBuffer> sampleBufferList = reference.onOutputBufferAvailable(outputBuffer);
                            if (reference.listener != null) {
                                reference.listener.onAudioDataAvailable(sampleBufferList, outputBufferInfo.flags);
                            }
                            reference.decoder.releaseOutputBuffer(outputBuffersArrayIndex, false);
                        }
                    } else if (outputBuffersArrayIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                        MediaFormat newFormat = reference.decoder.getOutputFormat();
                        reference.onOutputFormatChanged(newFormat);
                    }
                } catch (Exception e) {
                    Log.d(TAG, "DecoderRunnable Exception OutputBuffer :" + e);
                    return true;
                }
            }
            if (outputBufferInfo.flags == MediaCodec.BUFFER_FLAG_END_OF_STREAM) {
                reference.listener.onAudioDataAvailable(null,outputBufferInfo.flags);
                if (reference.listener != null) {
                    reference.listener.onDecoderFinish(true);
                }
                reference.stop();
                return true;
            }
            return false;
        }
    }
```
**BaseAudioDecoder.java file**
Output buffer:
```java
	protected ArrayList<SampleBuffer> onOutputBufferAvailable(@NonNull 			ByteBuffer outputBuffer) {
		double outputPresentationTimeUs = lastOutputPresentationTimeUs;
		double outputDurationPerSampleUs = 1000000.0 / (double)outputSampleRate;

		double targetPresentationTimeUs = lastTargetPresentationTimeUs;
		double targetDurationPerSampleUs = 1000000.0 / (double)targetSampleRate;

		// wrap the output buffer to make it provide audio samples
		SampleBuffer outputSampleBuffer = SampleBuffer.wrap(outputBuffer, outputSampleType, outputChannelCount, (long)outputPresentationTimeUs);
		outputSampleBuffer.position(0);
		SampleBuffer targetSampleBuffer = null;
		Double sample;
		ArrayList<SampleBuffer> targetSampleBufferList = new ArrayList<>();
		do {
			sample = sampleAtTargetTime(lastOutputSample, outputSampleBuffer, outputPresentationTimeUs, outputDurationPerSampleUs, targetPresentationTimeUs);
			if(targetSampleBuffer == null){
				//1 second worth of data
				targetSampleBuffer = SampleBuffer.allocate((targetSampleRate/1000) * 1024, targetSampleType, ByteOrder.LITTLE_ENDIAN, (long)targetPresentationTimeUs);
			}
			if (sample != null) {
				targetSampleBuffer.put(sample);
				targetPresentationTimeUs += targetDurationPerSampleUs;
			}
			if(sample == null || targetSampleBuffer.getByteBuffer().remaining() < 2){
				targetSampleBuffer.limit(targetSampleBuffer.position());
				targetSampleBuffer.position(0);
				targetSampleBufferList.add(targetSampleBuffer);
				targetSampleBuffer = null;
			}
		} while (sample != null);

		lastTargetPresentationTimeUs = targetPresentationTimeUs;
		lastOutputPresentationTimeUs += outputSampleBuffer.limit() * outputDurationPerSampleUs;
		lastOutputSample = outputSampleBuffer.get(outputSampleBuffer.limit() - 1);
		return targetSampleBufferList;
}
```

## Potential downsides
Implementation will take a long time due to the large amount of modification.
It is also necessary to consider `pushBuffer` and `pushWithData` of `AudioStreamManager`.
We have confirmed that the sample code is effective for the base version, but there is room for adjustment due to the differences in the latest version.

## Impact on existing code
This will be a minor version change to the Java Suite and iOS libraries.


## Alternatives considered
None
