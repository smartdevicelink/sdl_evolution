# ChangeRegistration-Manager

* Proposal: [SDL-0054](0054-change-registration-manager.md)
* Author: [Kujtim Shala](https://www.github.com/kshala-ford)
* Status: **In Review**
* Impacted Platforms: [iOS]

## Introduction

ChangeRegistration RPC allows an app to manipulate parameters that were sent during app registration including app name, TTS name and voice synonyms of the app. This proposal aims to make it more convenient for the app developer to change the apps registration and to provide an API which fits to the design of the application lifecycle manager.

## Motivation

Currently the app provides (or can provide) the list of languages it supports. This is done by using the lifecycle configuration. Any app parameter that has to be localized (TTS name, VR names) is localized to the app's default language. The app still has to check manually if it should change the registration and eventually modify the localizable app parameters using the ready handler.

Automatically sending ChangeRegistration inside the SDK is not sufficient. The SDK doesn't know the names for all the other languages.

## Proposed solution

A convenient way for the developer would be to provide an optional method in SDLManagerDelegate. The app can implement this method and modify the lifecycle configuration. If the app developer returns true the manager can reuse the app parameters from the lifecycle and send a ChangeRegistration request. Otherwise if returning false the manager does not execute a registration change.

The manager can decide to call the delegate method by checking the language of the newly connected head unit if it matches one supported language.

The following method should be added to the `SDLManagerDelegate`.

 ```objc
 @protocol SDLManagerDelegate
 ...
 @optional
 - (BOOL)manager:(SDLManager *)manager willChangeRegistrationToLanguage:(SDLLanguage *)language configuration:(SDLLifecycleConfiguration *)configuration; //proposed method
 @end

// example implementation of the protocol's method
- (BOOL)manager:(SDLManager *)manager willChangeRegistrationToLanguage:(SDLLanguage *)language configuration:(SDLLifecycleConfiguration *)configuration {
    configuration.ttsName = SOME_TTS_NAME_SPECIAL_FOR_language;
    return true;
}
```

The delegate should include a method `manager:didChangeRegistration:` (to follow API design of other protocols in Cocoa Touch).

1. After receiving `RegisterAppInterfaceResponse` and calling the `readyHandler` the lifecycle manager should compare the SDLLanguage of the head unit and the default language of the configuration.
2. If it doesn't match but the SDLLanguage exist in the array `languagesSupported` and the method `manager:willChangeRegistrationToLanguage:configuration` is implemented the manager should call the method
3. If the app decided to get the app registration changed (true returned) the manager can assume the app changed the localized properties in the lifecycle configuration.
4. The manager sets the lifecycle configs `language` property to the head unit language and sends a ChangeRegistration request using the data of the updated parameters (app name, TTS name, VR names, short name).

## Potential downsides

Compared to manually using the ChangeRegistration  RPC the app developer won't be able to change the registration more than once.

## Impact on existing code

- The `SDLManagerDelegate` will get a new optional method which will not cause impact to existing apps
- The parameter `appName` should become writable (remove `readonly` flag) as ChangeRegistration allows changing the app name to another nickname.

## Alternatives considered

No alternatives considered.
