# Support for Set Language Separately

* Proposal: [SDL-0289](0289-set-language-separately.md)
* Author: [Zhou Xin](https://github.com/zhouxin627)
* Status: **Accepted with Revisions**
* Impacted Platforms: [iOS / Java Suite / JavaScript Suite]

## Introduction
This proposal provides support for updating to two separate languages.

## Motivation
According to RPC Spec documents, it seems like when the HU's `hmiDisplayLanguage` or `VR/TTS` language is different from the app's desired language, the app will send `ChangeRegistration` to change the registered language which is supported.
But at the SDL Proxy source code's side, only the difference of `VR/TTS` language will trigger `ChangeRegistration`.

The Proxy does not currently support updating to two separate languages.
In other words, the developer can only be told that the language updated, but not which language type.
The `hmiDisplayLanguage` and `VR/TTS` language could be set separately in some use cases for OEM.

## Proposed solution
The proposed solution is to add a new method to pass the HMI display language separately, and the old one should be deprecated.

### iOS Library
A new SDLManagerDelegate method would need to be added, and the old one should be deprecated:

```objc
/**
* Called when the lifecycle manager detected a language mismatch. In case of a language mismatch the manager should change the app's registration by updating the lifecycle configuration to the specified language. If the app can support the specified language it should return an Object of SDLLifecycleConfigurationUpdate, otherwise it should return nil to indicate that the language is not supported.

*
* @param language The language of the connected head unit for which the manager is trying to update the configuration.
* @param hmiLanguage The language of the connected head unit for which the manager is trying to update the configuration.

* @return An object of SDLLifecycleConfigurationUpdate if the head unit language is supported, otherwise nil to indicate that the language is not supported.
*/
- (nullable SDLLifecycleConfigurationUpdate *)manager shouldUpdateLifecycleToLanguage:(SDLLanguage)language hmiLanguage:(SDLLanguage)hmiLanguage;


```

### Java Library
A new SdlManagerListener method would need to be added, and the old one should be deprecated:
```java
/**
* @param language The language of the connected head unit for which the manager is trying to update the configuration.

* @param hmiLanguage The hmiLanguage of the connected head unit for which the manager is trying to update the configuration.

* @return An object of LifecycleConfigurationUpdate if the head unit language is supported,
* otherwise null to indicate that the language is not supported.
*/
LifecycleConfigurationUpdate managerShouldUpdateLifecycle(Language language, Language hmiLanguage);
```

## Potential downsides
Author is not aware of any downsides to proposed solution.

## Impact on existing code
iOS/Java Suite need to be updated to support updating `hmidisplaylanguage` and `VR/TTS` language separately.

## Alternatives considered
None
