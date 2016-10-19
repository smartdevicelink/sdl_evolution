# Remove SDLTTSChunkFactory
* Proposal: [SDL-0021](0021-remove-sdlttschunkfactory.md)
* Author: [Alex Muller](https://github.com/asm09fsu)
* Status: **In Review**
* Impacted Platforms: iOS

## Introduction

This proposal is to remove the `SDLTTSChunkFactory` class and move all functions to create TTS Chunks into `SDLTTSChunk`

## Motivation

First and foremost, factories are a java construct, not used in Objective-C/Swift. With having these useful functions extracted out to a separate class, this results in them being hidden from the developer more difficult to use. Moving these functions out of `SDLTTSChunkFactory` and place them in `SDLTTSChunk` will help developers understand how to easily create chunks used in other RPCs.

## Proposed solution

The proposed solution is to remove `SDLTTSChunkFactory` and place them within `SDLTTSChunk`


## Detailed design

```objc
//  SDLTTSChunk.h
//

#import "SDLRPCMessage.h"

@class SDLSpeechCapabilities;

@interface SDLTTSChunk : SDLRPCStruct

- (instancetype)init;

- (instancetype)initWithDictionary:(NSMutableDictionary *)dict;

+ (instancetype)ttsChunkForString:(NSString *)text type:(SDLSpeechCapabilities *)type;

+ (NSMutableArray *)ttsChunksForString:(NSString *)simple;

@property (strong) NSString *text;

@property (strong) SDLSpeechCapabilities *type;

@end
```

## Impact on existing code

The impact on existing code is that `SDLTTSChunkFactory` will cease to exist. We could also deprecate the class, and direct developers to use `SDLTTSChunk` and remove it in a future release.

## Alternatives considered

An alternative considered would be to leave `SDLTTSChunkFactory`, although it is felt that this adds confusion to the end developer.
