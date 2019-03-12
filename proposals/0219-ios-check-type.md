# Explicit returned type from NSDictionary(Store) category

* Proposal: [SDL-0219](0219-ios-check-type.md)
* Author: [Misha Vyrko](https://github.com/mvyrko)
* Status: **Accepted with Revisions**
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

Mark method as private:
`-(nullable id)sdl_objectForName:(SDLName)name;`. 

Instead of method above use next methods:

For optional values, can be used functions that return object of classType or nil:
`- (nullable id)sdl_objectForName:(SDLName)name ofClass:(Class)classType;`.
`- (nullable NSArray *)sdl_objectsForName:(SDLName)name ofClass:(Class)classType`.

For mandatory values, next functions try to return object of classType overwise error would be filled. 
In case, when error isn't `nil`, returned object can be not type of `classType`:
`- (nullable id)sdl_objectForName:(SDLName)name ofClass:(Class)classType error:(NSError **)error`
`- (nullable NSArray *)sdl_objectsForName:(SDLName)name ofClass:(Class)classType error:(NSError **)error;`.

For suitable working with SDLEnums create the following methods:
`- (nullable SDLEnum)sdl_enumForName:(SDLName)name;`
`- (nullable SDLEnum)sdl_enumForName:(SDLName)name error:(NSError *);`.
`- (nullable NSArray<SDLEnum> *)sdl_enumsForName:(SDLName)name;`
`- (nullable NSArray<SDLEnum> *)sdl_enumsForName:(SDLName)name error:(NSError *);`.


Examples:
~~~~
- (NSNumber<SDLInt> *)menuID {
    NSError *error;
    return [parameters sdl_objectForName:SDLNameMenuId ofClass:NSNumber.class error:&error];
}
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

Store can return wrong type that would be highlighted by error.
For example: 
````
NSNumber *number = @2;
self.store = @{SDLSomeValue : number};

NSError *error;
NSString *string = [self.store sdl_objectForName:SDLSomeValue ofClass:NSString.class error:&error]; 

//string is NSNumber
//string and error aren't nil
````

## Impact on existing code

No impact

## Alternatives considered
