# iOS Stringly Typed Enums
* Proposal: [SDL-0006](0006-Stringly Typed Enums.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **In review**
* Review manager: TBD
* Impacted Platforms: iOS

## Introduction
This feature is a major change affecting all SDL enums in the iOS library. SDL enums are essentially string enums, but they are not handled as such. We should be handling string enums in the way Apple recommends and in the way that allows for the most Swift compatibility.

## Motivation
The current implementation requires a fair bit of extra code and leaves dozens or hundreds of global objects floating about. For example, the following is the code for a single enum:

```objc
// SDLAmbientLightStatus.h
@interface SDLAmbientLightStatus : SDLEnum {
}

+ (SDLAmbientLightStatus *)valueOf:(NSString *)value;
+ (NSArray *)values;

+ (SDLAmbientLightStatus *)NIGHT;
+ (SDLAmbientLightStatus *)TWILIGHT_1;
+ (SDLAmbientLightStatus *)TWILIGHT_2;
+ (SDLAmbientLightStatus *)TWILIGHT_3;
+ (SDLAmbientLightStatus *)TWILIGHT_4;
+ (SDLAmbientLightStatus *)DAY;
+ (SDLAmbientLightStatus *)UNKNOWN;
+ (SDLAmbientLightStatus *)INVALID;

@end
```

```objc
// SDLAmbientLightStatus.m
SDLAmbientLightStatus *SDLAmbientLightStatus_NIGHT = nil;
SDLAmbientLightStatus *SDLAmbientLightStatus_TWILIGHT_1 = nil;
SDLAmbientLightStatus *SDLAmbientLightStatus_TWILIGHT_2 = nil;
SDLAmbientLightStatus *SDLAmbientLightStatus_TWILIGHT_3 = nil;
SDLAmbientLightStatus *SDLAmbientLightStatus_TWILIGHT_4 = nil;
SDLAmbientLightStatus *SDLAmbientLightStatus_DAY = nil;
SDLAmbientLightStatus *SDLAmbientLightStatus_UNKNOWN = nil;
SDLAmbientLightStatus *SDLAmbientLightStatus_INVALID = nil;

NSArray *SDLAmbientLightStatus_values = nil;

@implementation SDLAmbientLightStatus

+ (SDLAmbientLightStatus *)valueOf:(NSString *)value {
    for (SDLAmbientLightStatus *item in SDLAmbientLightStatus.values) {
        if ([item.value isEqualToString:value]) {
            return item;
        }
    }
    return nil;
}

+ (NSArray *)values {
    if (SDLAmbientLightStatus_values == nil) {
        SDLAmbientLightStatus_values = @[
            SDLAmbientLightStatus.NIGHT,
            SDLAmbientLightStatus.TWILIGHT_1,
            SDLAmbientLightStatus.TWILIGHT_2,
            SDLAmbientLightStatus.TWILIGHT_3,
            SDLAmbientLightStatus.TWILIGHT_4,
            SDLAmbientLightStatus.DAY,
            SDLAmbientLightStatus.UNKNOWN,
            SDLAmbientLightStatus.INVALID,
        ];
    }
    return SDLAmbientLightStatus_values;
}

+ (SDLAmbientLightStatus *)NIGHT {
    if (SDLAmbientLightStatus_NIGHT == nil) {
        SDLAmbientLightStatus_NIGHT = [[SDLAmbientLightStatus alloc] initWithValue:@"NIGHT"];
    }
    return SDLAmbientLightStatus_NIGHT;
}

+ (SDLAmbientLightStatus *)TWILIGHT_1 {
    if (SDLAmbientLightStatus_TWILIGHT_1 == nil) {
        SDLAmbientLightStatus_TWILIGHT_1 = [[SDLAmbientLightStatus alloc] initWithValue:@"TWILIGHT_1"];
    }
    return SDLAmbientLightStatus_TWILIGHT_1;
}

+ (SDLAmbientLightStatus *)TWILIGHT_2 {
    if (SDLAmbientLightStatus_TWILIGHT_2 == nil) {
        SDLAmbientLightStatus_TWILIGHT_2 = [[SDLAmbientLightStatus alloc] initWithValue:@"TWILIGHT_2"];
    }
    return SDLAmbientLightStatus_TWILIGHT_2;
}

+ (SDLAmbientLightStatus *)TWILIGHT_3 {
    if (SDLAmbientLightStatus_TWILIGHT_3 == nil) {
        SDLAmbientLightStatus_TWILIGHT_3 = [[SDLAmbientLightStatus alloc] initWithValue:@"TWILIGHT_3"];
    }
    return SDLAmbientLightStatus_TWILIGHT_3;
}

+ (SDLAmbientLightStatus *)TWILIGHT_4 {
    if (SDLAmbientLightStatus_TWILIGHT_4 == nil) {
        SDLAmbientLightStatus_TWILIGHT_4 = [[SDLAmbientLightStatus alloc] initWithValue:@"TWILIGHT_4"];
    }
    return SDLAmbientLightStatus_TWILIGHT_4;
}

+ (SDLAmbientLightStatus *)DAY {
    if (SDLAmbientLightStatus_DAY == nil) {
        SDLAmbientLightStatus_DAY = [[SDLAmbientLightStatus alloc] initWithValue:@"DAY"];
    }
    return SDLAmbientLightStatus_DAY;
}

+ (SDLAmbientLightStatus *)UNKNOWN {
    if (SDLAmbientLightStatus_UNKNOWN == nil) {
        SDLAmbientLightStatus_UNKNOWN = [[SDLAmbientLightStatus alloc] initWithValue:@"UNKNOWN"];
    }
    return SDLAmbientLightStatus_UNKNOWN;
}

+ (SDLAmbientLightStatus *)INVALID {
    if (SDLAmbientLightStatus_INVALID == nil) {
        SDLAmbientLightStatus_INVALID = [[SDLAmbientLightStatus alloc] initWithValue:@"INVALID"];
    }
    return SDLAmbientLightStatus_INVALID;
}

@end
```

This is not an ideal solution, as it requires a fair bit of code without providing much value. Furthermore, the current solution does not provide good automatic imports into Swift. An ideal solution would translate directly into string backed Swift enums.

## Proposed solution

The new solution is to use simple string constants. For example, the previous example would be written instead as:

```objc
// SDLAmbientLightStatus.h
typedef NSString * SDLEnum;

typedef SDLEnum SDLAmbientLightStatus __attribute__((swift_wrapper(enum)));
extern SDLAmbientLightStatus const SDLAmbientLightStatusNight;
extern SDLAmbientLightStatus const SDLAmbientLightStatusTwilight1;
extern SDLAmbientLightStatus const SDLAmbientLightStatusTwilight2;
extern SDLAmbientLightStatus const SDLAmbientLightStatusTwilight3;
extern SDLAmbientLightStatus const SDLAmbientLightStatusTwilight4;
extern SDLAmbientLightStatus const SDLAmbientLightStatusDay;
extern SDLAmbientLightStatus const SDLAmbientLightStatusUnknown;
extern SDLAmbientLightStatus const SDLAmbientLightStatusInvalid;
```

```objc
// SDLAmbientLightStatus.m

SDLAmbientLightStatus SDLAmbientLightStatusNight = @"NIGHT";
SDLAmbientLightStatus SDLAmbientLightStatusTwilight1 = @"TWILIGHT_1";
SDLAmbientLightStatus SDLAmbientLightStatusTwilight2 = @"TWILIGHT_2";
SDLAmbientLightStatus SDLAmbientLightStatusTwilight3 = @"TWILIGHT_3";
SDLAmbientLightStatus SDLAmbientLightStatusTwilight4 = @"TWILIGHT_4";
SDLAmbientLightStatus SDLAmbientLightStatusDay = @"DAY";
SDLAmbientLightStatus SDLAmbientLightStatusUnknown = @"UNKNOWN";
SDLAmbientLightStatus SDLAmbientLightStatusInvalid = @"INVALID";
```

This would then appear in Swift as:

```swift
// SDLAmbientLightStatus

enum SDLAmbientLightStatus : String {
    case Night
    case Twilight1
    case Twilight2
    case Twilight3
    case Twilight4
    case Day
    case Unknown
    case Invalid
}
```

See this Swift-evolution document for more info on swift importing: https://github.com/apple/swift-evolution/blob/master/proposals/0033-import-objc-constants.md.

Not only will this eliminate the amount of global objects we have floating about, but it will reduce the amount of code and complexity we have in the project, and will greatly improve Swift importing as of Swift 3.

Additionally, if a proposal were accepted which allowed code generation, this would be much easier to implement.

## Potential Downsides
The old SDL enums, when passed around, are passed as strongly typed objects and reflection can be used upon them. The new string enums are not as strongly typed, because they are merely typedef'd. However, the new string enums are considerably more lightweight than the old version and fit much better with how Apple approaches similar problems.

## Impact on existing code
This would be a breaking change and would require some changes to the SDL library as well as changes to developer code that touches enums.

## Alternatives considered
One alternative was to use an objective-c `NS_ENUM` on the developer side and convert to a String when the enum needs to be stored and sent in an RPC, and do the reverse when receiving an RPC. This was decided against as it adds a significant amount of processing time required and does not convert as well with Swift 3.

Additionally we could leave it as is, but I believe the advantages of this proposal outweigh any downsides.
