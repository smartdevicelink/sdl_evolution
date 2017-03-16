# Audio Data Handler for SDLPerformAudioPassThru

* Proposal: [SDL-0035](0035-filename.md)
* Author: [Alex Muller](https://github.com/asm09fsu)
* Status: **In review**
* Impacted Platforms: [iOS]

## Introduction

Currently, for a developer to implement `SDLPerformAudioPassThru`, the developer must observe the `SDLDidReceiveAudioPassThruNotification` notification. This proposal will allow for developers to add a handler block to the perform audio pass through, so they do not need to monitor this notification.

## Motivation

This proposal is motivated by developers having to do a step that could be easily mitigated by SDL, and allow developers a more familiar way to interact with audio data.

## Proposed solution

This proposed solution would add a handler `audioDataHandler` to the `SDLPerformAudioPassThru` class. This handler would give back the `NSData` that is received from the `bulkData` property of the notification. It will be up to the developer to cache this audio data if necessary.

## Detailed design
### SDLNotificationConstants.h
```objc
/**
 *  A handler used on SDLPerformAudioPassThru.
 *
 *  @param audioData The audio data contained in the notification.
 */
typedef void (^SDLAudioPassThruHandler)(NSData *__nullable audioData);
```


### SDLPerformAudioPassThru.h
```objc
@interface SDLPerformAudioPassThru : SDLRPCRequest

...
- (instancetype)initWithSamplingRate:(SDLSamplingRate)samplingRate bitsPerSample:(SDLBitsPerSample)bitsPerSample audioType:(SDLAudioType)audioType maxDuration:(UInt32)maxDuration audioDataHandler:(nullable SDLAudioPassThruHandler)audioDataHandler;

- (instancetype)initWithInitialPrompt:(nullable NSString *)initialPrompt audioPassThruDisplayText1:(nullable NSString *)audioPassThruDisplayText1 audioPassThruDisplayText2:(nullable NSString *)audioPassThruDisplayText2 samplingRate:(SDLSamplingRate)samplingRate bitsPerSample:(SDLBitsPerSample)bitsPerSample audioType:(SDLAudioType)audioType maxDuration:(UInt32)maxDuration muteAudio:(BOOL)muteAudio audioDataHandler:(nullable SDLAudioPassThruHandler)audioDataHandler;

/**
 *  A handler that will be called whenever an `onAudioPassThru` notification is received.
 */
@property (copy, nonatomic, nullable) SDLAudioPassThruHandler audioDataHandler;
...

@end
```

### SDLPerformAudioPassThru.m
```objc
- (instancetype)initWithInitialPrompt:(nullable NSString *)initialPrompt audioPassThruDisplayText1:(nullable NSString *)audioPassThruDisplayText1 audioPassThruDisplayText2:(nullable NSString *)audioPassThruDisplayText2 samplingRate:(SDLSamplingRate)samplingRate bitsPerSample:(SDLBitsPerSample)bitsPerSample audioType:(SDLAudioType)audioType maxDuration:(UInt32)maxDuration muteAudio:(BOOL)muteAudio {
    return [self initWithInitialPrompt:initialPrompt audioPassThruDisplayText1:audioPassThruDisplayText1 audioPassThruDisplayText2:audioPassThruDisplayText2 samplingRate:samplingRate bitsPerSample:bitsPerSample audioType:audioType maxDuration:maxDuration muteAudio:muteAudio audioDataHandler:nil];
}

- (instancetype)initWithInitialPrompt:(nullable NSString *)initialPrompt audioPassThruDisplayText1:(nullable NSString *)audioPassThruDisplayText1 audioPassThruDisplayText2:(nullable NSString *)audioPassThruDisplayText2 samplingRate:(SDLSamplingRate)samplingRate bitsPerSample:(SDLBitsPerSample)bitsPerSample audioType:(SDLAudioType)audioType maxDuration:(UInt32)maxDuration muteAudio:(BOOL)muteAudio audioDataHandler:(nullable SDLAudioPassThruHandler)audioDataHandler {
    self = [self initWithSamplingRate:samplingRate bitsPerSample:bitsPerSample audioType:audioType maxDuration:maxDuration audioDataHandler:audioDataHandler];
    if (!self) {
        return nil;
    }
    
    self.initialPrompt = [SDLTTSChunk textChunksFromString:initialPrompt];
    self.audioPassThruDisplayText1 = audioPassThruDisplayText1;
    self.audioPassThruDisplayText2 = audioPassThruDisplayText2;
    self.muteAudio = @(muteAudio);
    
    return self;
}

- (instancetype)initWithSamplingRate:(SDLSamplingRate)samplingRate bitsPerSample:(SDLBitsPerSample)bitsPerSample audioType:(SDLAudioType)audioType maxDuration:(UInt32)maxDuration {
    return [self initWithSamplingRate:samplingRate bitsPerSample:bitsPerSample audioType:audioType maxDuration:maxDuration audioDataHandler:nil];
}
    
- (instancetype)initWithSamplingRate:(SDLSamplingRate)samplingRate bitsPerSample:(SDLBitsPerSample)bitsPerSample audioType:(SDLAudioType)audioType maxDuration:(UInt32)maxDuration audioDataHandler:(nullable SDLAudioPassThruHandler)audioDataHandler {
    self = [self init];
    if (!self) {
        return nil;
    }
    
    self.samplingRate = samplingRate;
    self.bitsPerSample = bitsPerSample;
    self.audioType = audioType;
    self.maxDuration = @(maxDuration);
    self.audioDataHandler = [audioDataHandler copy];
    
    return self;
}
```

### SDLResponseDispatcher.h
```objc
@interface SDLResponseDispatcher : NSObject

/**
 *  Holds an audio pass thru block.
 */
@property (copy, nonatomic, readonly, nullable) SDLAudioPassThruHandler audioPassThruHandler;

@end
```
### SDLResponseDispatcher.m
```objc
- (instancetype)initWithNotificationDispatcher:(nullable id)dispatcher {
...
// Audio Pass Thru
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sdl_runHandlerForAudioPassThru:) name:SDLDidReceiveAudioPassThruNotification object:dispatcher];
...
}

- (void)storeRequest:(SDLRPCRequest *)request handler:(nullable SDLResponseHandler)handler {
...
    } else if ([request isKindOfClass:[SDLShow class]]) {
        SDLShow *show = (SDLShow *)request;
        [self sdl_addToCustomButtonHandlerMap:show.softButtons];
    } else if ([request isKindOfClass:[SDLPerformAudioPassThru class]]) {
        SDLPerformAudioPassThru *performAudioPassThru = (SDLPerformAudioPassThru *)request;
        _audioPassThruHandler = [performAudioPassThru.audioDataHandler copy];
    }
...
}

- (void)clear {
	...
    _audioPassThruHandler = nil;
}

- (void)sdl_runHandlersForResponse:(NSNotification *)notification {
...
// If it's a DeleteCommand or UnsubscribeButton, we need to remove handlers for the corresponding commands / buttons
    // If it's a PerformAudioPassThru, we can also remove it.
    if ([response isKindOfClass:[SDLDeleteCommandResponse class]]) {
        SDLDeleteCommand *deleteCommandRequest = (SDLDeleteCommand *)request;
        NSNumber *deleteCommandId = deleteCommandRequest.cmdID;
        [self.commandHandlerMap safeRemoveObjectForKey:deleteCommandId];
    } else if ([response isKindOfClass:[SDLUnsubscribeButtonResponse class]]) {
        SDLUnsubscribeButton *unsubscribeButtonRequest = (SDLUnsubscribeButton *)request;
        SDLButtonName unsubscribeButtonName = unsubscribeButtonRequest.buttonName;
        [self.buttonHandlerMap safeRemoveObjectForKey:unsubscribeButtonName];
    } else if ([response isKindOfClass:[SDLPerformAudioPassThruResponse class]]) {
        _audioPassThruHandler = nil;
    }
}
    
- (void)sdl_runHandlerForAudioPassThru:(NSNotification *)notification {
    SDLOnAudioPassThru *onAudioPassThruNotification = notification.userInfo[SDLNotificationUserInfoObject];
    
    if (self.audioPassThruHandler) {
        self.audioPassThruHandler(onAudioPassThruNotification.bulkData);
    }
}

```
### SDLResponseDispatcherSpec.m
```objc
describe(@"a response dispatcher", ^{
...
context(@"storing an audio pass thru handler", ^{
        __block SDLPerformAudioPassThru* testPerformAudioPassThru = nil;
        __block NSUInteger numTimesHandlerCalled = 0;
        
        context(@"with a handler", ^{
            beforeEach(^{
                testPerformAudioPassThru = [[SDLPerformAudioPassThru alloc] initWithSamplingRate:SDLSamplingRate8KHZ bitsPerSample:SDLBitsPerSample8Bit audioType:SDLAudioTypePCM maxDuration:1000 audioDataHandler:^(NSData * _Nullable audioData) {
                    numTimesHandlerCalled++;
                }];
                
                testPerformAudioPassThru.correlationID = @1;
                [testDispatcher storeRequest:testPerformAudioPassThru handler:nil];
            });
            
            it(@"should store the handler" ,^{
                
                expect(testDispatcher.audioPassThruHandler).toNot(beNil());
                expect(testDispatcher.audioPassThruHandler).to(equal(testPerformAudioPassThru.audioDataHandler));
            });
            
            describe(@"when an on audio data notification arrives", ^{
                beforeEach(^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:SDLDidReceiveAudioPassThruNotification object:nil];
                });
                
                it(@"should run the handler", ^{
                    expect(@(numTimesHandlerCalled)).to(equal(@1));
                });
            });
            
            describe(@"when an on audio data response arrives", ^{
                beforeEach(^{
                    SDLPerformAudioPassThruResponse *performAudioPassThruResponse = [[SDLPerformAudioPassThruResponse alloc] init];
                    performAudioPassThruResponse.success = @YES;
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:SDLDidReceivePerformAudioPassThruResponse object:nil userInfo:@{SDLNotificationUserInfoObject : performAudioPassThruResponse }];
                });
                
                it(@"should clear the handler", ^{
                    expect(testDispatcher.audioPassThruHandler).to(beNil());
                });
            });
        });
        
        context(@"without a handler", ^{
            beforeEach(^{
                numTimesHandlerCalled = 0;
                
                testPerformAudioPassThru = [[SDLPerformAudioPassThru alloc] initWithSamplingRate:SDLSamplingRate8KHZ bitsPerSample:SDLBitsPerSample8Bit audioType:SDLAudioTypePCM maxDuration:1000];
                
                testPerformAudioPassThru.correlationID = @1;
                [testDispatcher storeRequest:testPerformAudioPassThru handler:nil];
            });
            
            describe(@"when an on audio data notification arrives", ^{
               beforeEach(^{
                   [[NSNotificationCenter defaultCenter] postNotificationName:SDLDidReceiveAudioPassThruNotification object:nil];
               });
               
               it(@"should not run a handler", ^{
                   expect(@(numTimesHandlerCalled)).to(equal(@0));
               });
            });
        
            describe(@"when an on audio data response arrives", ^{
                beforeEach(^{
                    SDLPerformAudioPassThruResponse *performAudioPassThruResponse = [[SDLPerformAudioPassThruResponse alloc] init];
                    performAudioPassThruResponse.success = @YES;
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:SDLDidReceivePerformAudioPassThruResponse object:nil userInfo:@{SDLNotificationUserInfoObject : performAudioPassThruResponse }];
                });
                
                it(@"should clear the handler", ^{
                    expect(testDispatcher.audioPassThruHandler).to(beNil());
                });
            });
            
        });
});
```

## Impact on existing code
As this does not remove any functionality, only add to it, the developer would not need to change their code if they do not wish to partake in this new functionality.

## Alternatives considered
Alternative was to not do anything, however with requests for this from multiple developers we feel this is a good improvement to `SDLPerformAudioPassThru`.
