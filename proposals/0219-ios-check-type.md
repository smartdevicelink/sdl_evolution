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

For mandatory values, the following functions try to return object of classType overwise error will be filed. 
When the object is not of type `classType`, the error will not be `nil`
`- (nullable id)sdl_objectForName:(SDLName)name ofClass:(Class)classType error:(NSError **)error`
`- (nullable NSArray *)sdl_objectsForName:(SDLName)name ofClass:(Class)classType error:(NSError **)error;`.

For optional values, can use functions that return object of classType or nil. These functions are syntactic sugar on functions with error where put nil to error parameter.
`- (nullable id)sdl_objectForName:(SDLName)name ofClass:(Class)classType;`.
`- (nullable NSArray *)sdl_objectsForName:(SDLName)name ofClass:(Class)classType`.

For suitable working with SDLEnums create the following methods:
`- (nullable SDLEnum)sdl_enumForName:(SDLName)name;`
`- (nullable SDLEnum)sdl_enumForName:(SDLName)name error:(NSError **)error;
`- (nullable NSArray<SDLEnum> *)sdl_enumsForName:(SDLName)name;`
`- (nullable NSArray<SDLEnum> *)sdl_enumsForName:(SDLName)name error:(NSError **)error;

These new methods will assert (which only affects apps in DEBUG mode), log the error using the SDL logging framework, and return `nil` with an error object containing the faulty data sent by the head unit and an error message.

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

Store can return wrong type, which would be highlighted by an error.
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
