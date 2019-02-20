# Explicit returned type from NSDictionary(Store) category

* Proposal: [SDL-NNNN](NNNN-ios-check-type.md)
* Author: [Misha Vyrko](https://github.com/mvyrko)
* Status: **Awaiting review**
* Impacted Platforms: [iOS]

## Introduction

This proposal is to specify returned types from NSDictionary (Store).
This ensures that the return value is assigned to a variable of the correct type. 

## Motivation

Method (`-(nullable id)sdl_objectForName:(SDLName)name`) in NSDictionary (Store) returns `id` in the future it can be casted to any type.
As result wrong casting leads to a crash in runtime.
For example:
````
- (SDLLanguage)languageDesired {
    id object = [parameters sdl_objectForName:SDLNameLanguageDesired];
    return (SDLLanguage)object;
} 

- (void)someFunction:(SDLLanguage)language {
    if ([self.languageDesired isEqualToEnum:language]) { // `-[__NSCFNumber isEqualToEnum:]: unrecognized selector sent to instance`
        
    }
}
````

## Proposed solution

Remove method :
`-(nullable id)sdl_objectForName:(SDLName)name;`. 

Instead of the removed method, use this existing method:
`- (nullable id)sdl_objectForName:(SDLName)name ofClass:(Class)classType;`.

For suitable working with SDLEnums create the following methods:
`- (nullable SDLEnum)sdl_enumForName:(SDLName)name`
`- (nullable NSArray<SDLEnum> *)sdl_enumsForName:(SDLName)name;`

Examples:
~~~~
- (nullable NSString *)fullAppID {
    return [parameters sdl_objectForName:SDLNameFullAppID ofClass:NSString.class];
}
- (nullable NSArray<NSString *> *)vrSynonyms {
    return [parameters sdl_objectsForName:SDLNameVRSynonyms ofClass:NSString.class];
}
- (SDLLanguage)languageDesired {
    return [parameters sdl_enumForName:SDLNameLanguageDesired];
}
- (nullable NSArray<SDLVentilationMode> *)ventilationMode {
    return [store sdl_enumsForName:SDLNameVentilationMode];
}
~~~~

Proposal implemented in https://github.com/smartdevicelink/sdl_ios/pull/1158

## Potential downsides

Store returns `nil` by getting with the wrong key or incorrect type without highlighting the on compile time.
For example: 
````
NSNumber *number = @2;
self.store = @{SDLSomeValue : number};

NSString *string = [self.store sdl_objectForName:SDLSomeValue ofClass:NSString.class]; 
//string is always nil
````

## Impact on existing code

Possible nullability issues when classes expect nonnull value can be returned nil.

For example:
```
// In .h file
NS_ASSUME_NONNULL_BEGIN

@interface SDLSomeClass: NSObject

@property (nonatomic, strong) SDLSomeEnum someProperty;

- (instanceType)init {
    self = [super init];
    if(self) {
        NSNumber *number = @2;
        self.store = @{SDLSomeValue : number};
    }
    return self;
    }

@end

NS_ASSUME_NONNULL_END

// In .m file

- (SDLSomeEnum)someProperty {
    return [self.store sdl_objectForName:SDLSomeValue];
}

- (void)exampleFunction:(SDLSomeClass *)someClass {
    if(someClass.someProperty != nil) {
        // to do something
    }
}
```
Now, someProperty isn't nil, after applying changes someProperty would be nil.

## Alternatives considered

In every method add checking of type like:
~~~~
- (nullable NSArray<NSString *> *)vrSynonyms {
    id vrSynonyms = [parameters sdl_objectsForName:SDLNameVRSynonyms];
    if ([vrSynonyms isKindOfClass:NSArray.class]) {
        id firstSynonym = vrSynonyms.first;
        if ([firstSynonym isKindOfClass:NSString.class]) {
            return vrSynonyms;
        }
    }
    return nil;
}
~~~~

