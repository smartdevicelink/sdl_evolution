# iOS Use Correct Mutability on RPC Storage Properties
* Proposal: [SDL-0005](0005-ios-immutable-rpc-storage-properties.md.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **In Review**
* Review manager: TBD
* Impacted Platforms: iOS

## Introduction
This feature is a major change affecting RPC requests, responses, and structs. Currently, RPCs largely use mutable dictionaries and arrays. This change modifies all RPC public mutable APIs to be immutable instead.

## Motivation
Currently, RPCs largely use mutable dictionaries and arrays. This mutability in public APIs is both senseless and dangerous. There is absolutely no reason for these APIs to be mutable. For example, RPCMessages and RPCStructs are both initialized with a mutable dictionary instead of immutable, and many properties on RPCs are mutable arrays.

For example, this is the class `SDLRPCStruct` which is the base class for all RPC structs:

```objc
@interface SDLRPCStruct : NSObject {
    NSMutableDictionary *store;
}

- (instancetype)initWithDictionary:(NSMutableDictionary *)dict;
- (instancetype)init;

- (NSMutableDictionary *)serializeAsDictionary:(Byte)version;

@end
```

The method `initWithDictionary:` should be taking an immutable dictionary. If it must be modified within the class, the class can turn it into a mutable dictionary. By taking a mutable dictionary as a reference, the dictionary is open to being modified by the developer at runtime after passing it to the class. This could cause any number of oddities.

This is the RPC struct `SDLDisplayCapabilities`:

```objc
//  SDLDisplayCapabilities.h

@interface SDLDisplayCapabilities : SDLRPCStruct {
}

- (instancetype)init;
- (instancetype)initWithDictionary:(NSMutableDictionary *)dict;

@property (strong) SDLDisplayType *displayType;
@property (strong) NSMutableArray *textFields;
@property (strong) NSMutableArray *imageFields;
@property (strong) NSMutableArray *mediaClockFormats;
@property (strong) NSNumber *graphicSupported;
@property (strong) NSMutableArray *templatesAvailable;
@property (strong) SDLScreenParams *screenParams;
@property (strong) NSNumber *numCustomPresetsAvailable;

@end
```

These arrays should be immutable in order to prevent the same types of misuse as described above. It simply doesn't make sense for these arrays to be mutable or for anyone to modify them, therefore we should enforce their immutability.

## Proposed solution
The proposed solution is to change `NSMutableDictionary` symbols to `NSDictionary`, and `NSMutableArray` to `NSArray`. In some cases this may require the local class to alter an immutable array taken in from the API signature into a mutable object for modification. This is a common best practice. In many places throughout the library we are creating immutable objects and must turn them into mutable ones to be passed to the objects, and this would reduce processing times in these cases.

This would be the `SDLDisplayCapabilities` class after the change:

```objc
@interface SDLDisplayCapabilities : SDLRPCStruct {
}

- (instancetype)init;
- (instancetype)initWithDictionary:(NSDictionary *)dict;

@property (strong) SDLDisplayType *displayType;
@property (strong) NSArray *textFields;
@property (strong) NSArray *imageFields;
@property (strong) NSArray *mediaClockFormats;
@property (strong) NSNumber *graphicSupported;
@property (strong) NSArray *templatesAvailable;
@property (strong) SDLScreenParams *screenParams;
@property (strong) NSNumber *numCustomPresetsAvailable;

@end
```

## Potential Downsides
If immutable objects must often be modified into mutable objects, this could add some additional processing time. In the same way, if mutable objects must be modified into immutable types for properties, this could require some additional processing time. However, since this is a very common use case and best practice, these types of operations are heavily optimized, and the impact should be very minimal. The advantage of following programming best practices around immutability in models far outweighs potential minor processing time increases. Furthermore, as mentioned above, we are often doing the opposite to work around these objects' mutability. The cases where we are converting immutable objects to mutable ones in order to pass them through would mitigate processing time increases caused by the reverse.

## Impact on existing code
This would be a breaking change because any developer currently modifying a mutable object when they ought not will no longer be able to do so without converting the immutable object into a mutable version. Furthermore, there would be many minor code changes throughout the code that would need to create objects as properly immutable.

## Alternatives considered
The only alternative would be to leave the code as is, but that is judged to be a poor option.
