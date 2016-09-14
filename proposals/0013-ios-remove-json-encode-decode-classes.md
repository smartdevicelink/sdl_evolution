# iOS Remove SDLJsonEncoder & Decoder
* Proposal: [SDL-0013](0013-ios-remove-json-encode-decode-classes.md)
* Author: [Alex Muller](https://github.com/asm09fsu)
* Status: **In Review**
* Review manager: TBD
* Impacted Platforms: iOS

## Introduction

Currently in the iOS implementation of SDL, we have two classes `SDLJsonEncoder` and `SDLJsonDecoder` which are wrappers around Apple's `NSJSONSerialization` class. These two classes simply do a size check on the data incoming from the module and then do the appropriate `NSJSONSerialization` calls. There isn't anything special about these classes, or the functionality they do. My proposal is to remove these classes and replace their usage with just `NSJSONSerialization`.


## Motivation

The problem with `SDLJsonEncoder` and `SDLJsonDecoder` is that they are unnecessary, and increase bloat of the project for no technical gain. They also adhere to `SDLEncoder` and `SDLDecoder`, which gives us 4 unnecessary files. 

## Proposed solution

Since `SDLJsonEncoder` and `SDLJsonDecoder` are only slightly used in the project, the implementation would be straightforward. We would remove all instances of `SDLJsonEncoder`, `SDLJsonDecoder`, `SDLEncoder` and `SDLDecoder` and replace the usages of the two former classes using Apple's `NSJSONSerialization` (as we already do), and just include the error checking where it is used.

## Detailed design

Removing `SDLJsonEncoder` and `SDLJsonDecoder` would look like the following:

#### For `SDLJsonDecoder`

In [SDLV1ProtocolMessage.m](https://github.com/smartdevicelink/sdl_ios/blob/master/SmartDeviceLink/SDLV1ProtocolMessage.m) 
```objc
- (NSDictionary *)rpcDictionary {
    NSDictionary *rpcMessageAsDictionary = [[SDLJsonDecoder instance] decode:self.payload];
    return rpcMessageAsDictionary;
}
```
would be
```objc
- (NSDictionary *)rpcDictionary {
	if (self.payload.length == 0) {
		return 0;
	}

    NSError *error = nil;
    NSDictionary * rpcMessageAsDictionary = [NSJSONSerialization JSONObjectWithData:self.payload options:kNilOptions error:&error];
    if (error != nil) {
        [SDLDebugTool logInfo:[NSString stringWithFormat:@"Error decoding JSON data: %@", error] withType:SDLDebugType_Protocol];
        return nil;
    }

    return rpcMessageAsDictionary;
}
```

In [SDLV2ProtocolMessage.m](https://github.com/smartdevicelink/sdl_ios/blob/master/SmartDeviceLink/SDLV2ProtocolMessage.m) 
```objc
- (NSDictionary *)rpcDictionary {
    ...

    // Get the son data from the struct
    if (rpcPayload.jsonData) {
        NSDictionary *jsonDictionary = [[SDLJsonDecoder instance] decode:rpcPayload.jsonData];
        if (jsonDictionary) {
            [innerDictionary setObject:jsonDictionary forKey:NAMES_parameters];
        }
    }

	  ...
}
```
would be 
```objc
- (NSDictionary *)rpcDictionary {
    ...

    // Get the son data from the struct
    if (rpcPayload.jsonData) {
        NSDictionary *jsonDictionary = [[SDLJsonDecoder instance] decode:rpcPayload.jsonData];
		  NSError *error = nil;
        NSDictionary * jsonDictionary = [NSJSONSerialization JSONObjectWithData:rpcPayload.jsonData options:kNilOptions error:&error];
    	  if (error != nil) {
       	  [SDLDebugTool logInfo:[NSString stringWithFormat:@"Error decoding JSON data: %@", error] withType:SDLDebugType_Protocol];
    	  } else if (jsonDictionary) {
            [innerDictionary setObject:jsonDictionary forKey:NAMES_parameters];
        }
    }

	  ...
}
```

#### For `SDLJsonEncoder`
In [SDLProtocol.m](https://github.com/smartdevicelink/sdl_ios/blob/master/SmartDeviceLink/SDLProtocol.m) 
```objc
- (BOOL)sendRPC:(SDLRPCMessage *)message encrypted:(BOOL)encryption error:(NSError *__autoreleasing *)error {
	...
    NSData *jsonData = [[SDLJsonEncoder instance] encodeDictionary:[message serializeAsDictionary:[SDLGlobals globals].protocolVersion]];

	...
}
```
would be
```objc
- (BOOL)sendRPC:(SDLRPCMessage *)message encrypted:(BOOL)encryption error:(NSError *__autoreleasing *)error {
	...

    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[message serializeAsDictionary:[SDLGlobals globals].protocolVersion] options:kNilOptions error:&error];

    if (error != nil) {
        [SDLDebugTool logInfo:[NSString stringWithFormat:@"Error encoding JSON data: %@", error] withType:SDLDebugType_Protocol];
    }

	...
}
```


## Impact on existing code

This will have an impact on `SDLV1ProtocolMessage`, `SDLV2ProtocolMessage`, and `SDLProtocol`, however none of these will have an impact on a developer. Since we are using the same functions as before, we should experience zero issues related to this change.

## Alternatives considered

The only alternative would be to leave it as it is, but there is no benefit to this.
