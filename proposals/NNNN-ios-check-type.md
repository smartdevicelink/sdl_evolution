```
# Feature name

* Proposal: [SDL-NNNN](NNNN-ios-check-type.md)
* Author: [Misha Vyrko](https://github.com/mvyrko)
* Status: **Awaiting review**
* Impacted Platforms: [iOS]

## Introduction

Method (`-(nullable id)sdl_objectForName:(SDLName)name`) in NSDictionary (Store) returns objects as NSObject. 

Clients(`SDLRegisterAppInterface`, `SDLChangeRegistration` and etc) force cast(without checking) the value(NSObject) from the method to type that they want to have NSNumber, NSString, SDLLanguage and etc.
I suggest to require to specify the type explicitly.
Remove method: `- (nullable id)sdl_objectForName:(SDLName)name;`
Use existing method: `- (nullable id)sdl_objectForName:(SDLName)name ofClass:(Class)classType;` 


## Motivation

Returned value type isn't checked at compile time as result we have a lot of crashes in app where one type replaced by another.
`-[NSNull count]: unrecognized selector sent to instance 0x1e99699d0`
`-[__NSDictionaryI firstObject]: unrecognized selector sent to instance 0x282447e80`
`-[__NSCFNumber isEqualToEnum:]: unrecognized selector sent to instance 0xecbbf7f37a5c3eb2`

Checking type at compile time increase stability and resolve problems with unrecognized selector sent to instance.


## Proposed solution

Remove method `-(nullable id)sdl_objectForName:(SDLName)name;`. 
In every classes replace method `-(nullable id)sdl_objectForName:(SDLName)name;`
with `- (nullable id)sdl_objectForName:(SDLName)name ofClass:(Class)classType`.

For suitable working with SDLEnums create methods:
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

Possible solution https://github.com/smartdevicelink/sdl_ios/pull/1158

## Potential downsides

Possible nullability issues when clients expect nonnull value can be returned nil.

## Impact on existing code

Need to specify expected type.

## Alternatives considered

In every method check type like:
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

```
