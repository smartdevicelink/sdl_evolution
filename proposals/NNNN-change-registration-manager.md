# change-registration-manager

* Proposal: [SDL-0052](NNNN-change-registration-manager.md)
* Author: [Kujtim Shala](https://www.github.com/kshala)
* Status: **Awaiting review**
* Impacted Platforms: [iOS]

## Introduction

ChangeRegistration RPC allows an app to manipulate parameters that were send. Including the app name, TTS name and voice synonyms of the app. This proposal aims to make it more convenient for the app developer and to provide an API of a similar style unlike the RPC request.

This proposal comes together with the proposal of localization. It's not required to have both but they would work well together.

## Motivation

Currently the app provides (or can provide) the list of languages it supports. This is done by using the lifecycle configuration. Any app parameter that has to be localized (TTS name, VR names) is localized to the apps default language. The app still has to check manually if it should change the registration and eventually modify the localizable app parameters using the ready handler.

Automatically sending ChangeRegistration inside the SDK is not sufficient. The SDK doesn't know the names for all the other languages.

## Proposed solution

A convenient way for the developer would be to provide an optional method in SDLManagerDelegate. The app can implement this method and modify the lifecycle configuration. If the app developer returns true the manager can reuse the app parameters from the lifecycle and send a ChangeRegistration request. Otherwise if returning false the manager does not execute a registration change.

The manager can decide to call the delegate method by checking the language of the newly connected head unit if it matches one supported language.

The folloing method should be added to the `SDLManagerDelegate`.

 ```objc
 @protocol SDLManagerDelegate
 ...
 @optional
 - (BOOL)manager:(SDLManager *)manager willChangeRegistrationToLanguage:(SDLLanguage *)language configuration:(SDLLifecycleConfiguration *)configuration; //proposed method
 @end
 ```

Optionally the delegate could include a method `manager:didChangeRegistration:` (to follow API design of other protocols in Cocoa Touch).

The method signature is extended to the maximum. Providing the manager or configuration instance are not mandatory but can shorten the access to the app data.

Example:
```objc
- (BOOL)manager:(SDLManager *)manager willChangeRegistrationToLanguage:(SDLLanguage *)language configuration:(SDLLifecycleConfiguration *)configuration {
    configuration.ttsName = SOME_TTS_NAME_SPECIAL_FOR_language;
    return true;
}
```

1. After receiving `RegisterAppInterfaceResponse` and calling the `readyHandler` the lifecycle manager should compare the SDLLanguage of the head unit and the default language of the configuration.
2. If it doesn't match but the SDLLanguage exist in the array `languagesSupported` and the method `manager:willChangeRegistrationToLanguage:configuration` is implemented the manager should call the method
3. If the app decided to get the app registration changed (true returned) the manager can assume the app changed the localized properties in the lifecycle configuration.
4. The manager sets the lifecycle configs `language` property to the he head unit language and sends a ChangeRegistration using the data of the updated parameters (app name, TTS name, VR names, short name).
## Potential downsides

Describe any potential downsides or known objections to the course of action presented in this proposal, then provide counter-arguments to these objections. You should anticipate possible objections that may come up in review and provide an initial response here. Explain why the positives of the proposal outweigh the downsides, or why the downside under discussion is not a large enough issue to prevent the proposal from being accepted.

## Impact on existing code

- The `SDLManagerDelegate` will get a new optional method which will not cause impact to existing apps
- The parameter `appName` should become writable (remove `readonly` flag) as ChangeRegistration allows changing the app name to another nickname.

## Alternatives considered

No.
