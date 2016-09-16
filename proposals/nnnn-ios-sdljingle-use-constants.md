# iOS SDLJingle Constants Should Be Constants
* Proposal: [SE-NNNN](NNNN-filename.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Awaiting review**
* Review manager: TBD
* Impacted Platforms: iOS

## Introduction
This proposal is a major change to alter `SDLJingle` string constants to be actual string constants.

## Motivation
The current implementation is to create several class methods which each return a new instance of a string:

```objc
// SDLJingle.m

@implementation SDLJingle

+ (NSString *)NEGATIVE_JINGLE {
    return @"NEGATIVE_JINGLE";
}
+ (NSString *)POSITIVE_JINGLE {
    return @"POSITIVE_JINGLE";
}
+ (NSString *)LISTEN_JINGLE {
    return @"LISTEN_JINGLE";
}
+ (NSString *)INITIAL_JINGLE {
    return @"INITIAL_JINGLE";
}
+ (NSString *)HELP_JINGLE {
    return @"HELP_JINGLE";
}

@end
```

## Proposed solution
The proposed solution is to create actual string constants, so that a new string is not created for each method that's called. These constants would look like (in the .m):

```objc
NSString *const SDLJingleNegative = @"NEGATIVE_JINGLE";
```

## Potential Downsides
None.

## Impact on existing code
This is a major change that would require changes on the developer's part if they are using jingles.
