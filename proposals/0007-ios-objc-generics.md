# iOS Enforce ObjC Generics
* Proposal: [SDL-0007](0007-ios-objc-generics.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **In review**
* Review manager: TBD
* Impacted Platforms: iOS

## Introduction
This feature is a major change affecting primarily RPC requests, responses, and structs, but all classes in the project will be audited and updated. We have many public areas where SDL exposes a collection class; generics would allow us to specify what those collection classes contain.

## Motivation
The SDL iOS library has many public APIs that expose a collection class (array, dictionary, set, etc.), for example, RPCs do this all the time. Before Xcode 7, these collections had to be untyped. However, since Xcode 7, we are able to use "lightweight generics" to expose what, exactly, we expect the collection to contain. These are lightweight because they are not enforced by the compiler except through warnings in Objective-C. However, these generics also translate to Swift apps which integrate the library as compiler-enforced generics. This will not only vastly improve Swift compatibility, but will also improve our indications to Objective-C developers what we intend.

## Proposed solution
This proposed change is to alter all collections in all SDL classes to use generics. This will be most prominently visible in RPCs.

For example, below would be SDLDisplayCapabilities after the change.

```objc
@interface SDLDisplayCapabilities : SDLRPCStruct {
}
- (instancetype)init;
- (instancetype)initWithDictionary:(NSMutableDictionary<NSString *, id> *)dict;
@property (strong) SDLDisplayType *displayType;
@property (strong) NSMutableArray<SDLTextField *> *textFields;
@property (strong) NSMutableArray<SDLImageField *> *imageFields;
@property (strong) NSMutableArray<SDLMediaClockFormat *> *mediaClockFormats;
@property (strong) NSNumber *graphicSupported;
@property (strong) NSMutableArray<NSString *> *templatesAvailable;
@property (strong) SDLScreenParams *screenParams;
@property (strong) NSNumber *numCustomPresetsAvailable;

@end
```

The additions on properties of `textFields`, `imageFields`, `mediaClockFormats`, and `templatesAvailable` can be seen. They now have a generic specifier added to them showing what type of data they contain. This allows developers to write against these APIs with less frustration or tracking down of types. Additionally, generics should be enforced on non-RPC classes as well to allow SDL developers to better reason about our code even in private classes.

## Potential Downsides
There is no downside the author can see.

## Impact on existing code
This would be a breaking change to any Swift developer who integrates our library and does something *very* strange by adding unexpected object types to exposed collections or passes unexpected object types in a collection to SDL. This is a good thing because it will prevent bugs on their end.
