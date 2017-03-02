# Delegate Support for all onHMIStatus State Changes

* Proposal: [SDL-0032](0032-on-hmi-status-state-changes.md)
* Author: [Alex Muller](https://github.com/asm09fsu)
* Status: **In Review**
* Impacted Platforms: [iOS]

## Introduction
This proposal is to add in support to inform developers of additional state changes with `onHMIStatus`. Currently, [SDLManagerDelegate](https://github.com/smartdevicelink/sdl_ios/blob/master/SmartDeviceLink/SDLManagerDelegate.h) only supports `SDLHMIStatus` changes, and is missing callbacks for `SDLAudioStreamingState` as well as `SDLSystemContext`.


## Motivation

The motivation for this is to allow developers that may require knowing about the audio streaming state and system context to easily detect when this changes. This comes in for music applications especially.

## Proposed solution

The proposed solution is to modify `SDLManagerDelegate` to include two new optional delegate callbacks: `audioStreamingState:didChangeToState:` and `systemContext:didChangeToContext:`. We will also be adding properties to `SDLLifecycleManager.h` and subsequently `SDLManager.h` for current audio streaming state and system context.

## Detailed design

The following design is based off of changes already existing within `develop` (most notably changing from `SDLEnum` to string constants). 

### SDLManagerDelegate.h
```objc

#import "SDLAudioStreamingState.h"
#import "SDLSystemContext.h"

@protocol SDLManagerDelegate <NSObject>

...

@optional
/**
 *  Called when the audio streaming state of this application changes on the remote system. This refers to when streaming audio is audible to the user.
 *
 *  @param oldState The previous state which has now been left.
 *  @param newState The current state.
 */
- (void)audioStreamingState:(nullable SDLAudioStreamingState)oldState didChangeToState:(SDLAudioStreamingState)newState;

/**
 *  Called when the system context of this application changes on the remote system. This refers to whether or not a user-initiated interaction is in progress, and if so, what it is.
 *
 *  @param oldContext The previous context which has now been left.
 *  @param newContext The current context.
 */
- (void)systemContext:(nullable SDLSystemContext)oldContext didChangeToContext:(SDLSystemContext)newContext;

@end
```

### SDLLifecycleManager.h
```objc
#import "SDLAudioStreamingState.h"
#import "SDLSystemContext.h"

@interface SDLLifecycleManager : NSObject

...

@property (copy, nonatomic, nullable) SDLAudioStreamingState audioStreamingState;
@property (copy, nonatomic, nullable) SDLSystemContext systemContext;

...

@end
```

### SDLLifecycleManager.m
```objc
- (void)sdl_stopManager:(BOOL)shouldRestart {

	  ...

    self.registerResponse = nil;
    self.lastCorrelationId = 0;
    self.hmiLevel = nil;
    
    // New Start
    self.audioStreamingState = nil;
    self.systemContext = nil;
    // New End
    
    
    [SDLDebugTool logInfo:@"Stopping Proxy"];
    self.proxy = nil;

    ...
}

- (void)hmiStatusDidChange:(SDLRPCNotificationNotification *)notification {

	  ...
    
	  SDLOnHMIStatus *hmiStatusNotification = notification.notification;
    SDLHMILevel *oldHMILevel = self.hmiLevel;
    self.hmiLevel = hmiStatusNotification.hmiLevel;

// New Start
	  SDLAudioStreamingState oldStreamingState = self.audioStreamingState;
    self.audioStreamingState = hmiStatusNotification.audioStreamingState;
    
    SDLSystemContext oldSystemContext = self.systemContext;
    self.systemContext = hmiStatusNotification.systemContext;
// New End

    ...

    [self.delegate hmiLevel:oldHMILevel didChangeToLevel:self.hmiLevel];

// New Start
	  if (![oldStreamingState isEqualToString:self.audioStreamingState]
        && [self.delegate respondsToSelector:@selector(audioStreamingState:didChangeToState:)]) {
        [self.delegate audioStreamingState:oldStreamingState didChangeToState:self.audioStreamingState];
    }
    
    if (![oldSystemContext isEqualToString:self.systemContext]
        && [self.delegate respondsToSelector:@selector(systemContext:didChangeToContext:)]) {
        [self.delegate systemContext:oldSystemContext didChangeToContext:self.systemContext];
    }
// New End
}
```

### SDLManager.h
```objc

#import "SDLAudioStreamingState.h"
#import "SDLSystemContext.h"

@interface SDLManager : NSObject

...

/**
 *  The current audio streaming state of the running app.
 */
@property (copy, nonatomic, readonly) SDLAudioStreamingState *audioStreamingState;

/**
 *  The current system context of the running app.
 */
@property (copy, nonatomic, readonly) SDLSystemContext *systemContext;

...

@end
```

### SDLLifecycleManagerSpec.m
```objc
describe(@"in the ready state", ^{
   describe(@"receiving an audio state change", ^{
            __block SDLOnHMIStatus *testHMIStatus = nil;
            __block SDLAudioStreamingState testAudioStreamingState = nil;
            __block SDLAudioStreamingState oldAudioStreamingState = nil;
            
            beforeEach(^{
                oldAudioStreamingState = testManager.audioStreamingState;
                testHMIStatus = [[SDLOnHMIStatus alloc] init];
            });
            
            context(@"a not audible audio state", ^{
                beforeEach(^{
                    testAudioStreamingState = SDLAudioStreamingStateNotAudible;
                    testHMIStatus.audioStreamingState = testAudioStreamingState;
                    
                    [testManager.notificationDispatcher postRPCNotificationNotification:SDLDidChangeHMIStatusNotification notification:testHMIStatus];
                });
                
                it(@"should set the audio state", ^{
                    expect(testManager.audioStreamingState).toEventually(equal(testAudioStreamingState));
                });
                
                it(@"should call the delegate", ^{
                    OCMVerify([managerDelegateMock audioStreamingState:oldAudioStreamingState didChangeToState:testAudioStreamingState]);
                });
            });
        });
        
        describe(@"receiving a system context change", ^{
            __block SDLOnHMIStatus *testHMIStatus = nil;
            __block SDLSystemContext testSystemContext = nil;
            __block SDLSystemContext oldSystemContext = nil;
            
            beforeEach(^{
                oldSystemContext = testManager.systemContext;
                testHMIStatus = [[SDLOnHMIStatus alloc] init];
            });
            
            context(@"a alert system context state", ^{
                beforeEach(^{
                    testSystemContext = SDLSystemContextAlert;
                    testHMIStatus.systemContext = testSystemContext;
                    
                    [testManager.notificationDispatcher postRPCNotificationNotification:SDLDidChangeHMIStatusNotification notification:testHMIStatus];
                });
                
                it(@"should set the system context", ^{
                    expect(testManager.systemContext).toEventually(equal(testSystemContext));
                });
                
                it(@"should call the delegate", ^{
                    OCMVerify([managerDelegateMock systemContext:oldSystemContext didChangeToContext:testSystemContext]);
                });
            });
        });
});
```

## Impact on existing code

This will not change any existing code. Currently, if developers wish to know about these states, they have to subscribe to `SDLDidChangeHMIStatusNotification`. Since the delegate callbacks are optional, developers are able to still do this and will not need to conform to these methods.

## Alternatives considered
Alternative is to not support these additional callbacks, although I feel that this makes developer’s lives easier.
