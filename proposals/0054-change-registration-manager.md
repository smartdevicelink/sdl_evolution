# ChangeRegistration-Manager

* Proposal: [SDL-0054](0054-change-registration-manager.md)
* Author: [Kujtim Shala](https://www.github.com/kshala-ford)
* Status: **Returned for Revisions**
* Impacted Platforms: [iOS]

## Introduction

ChangeRegistration RPC allows an app to manipulate parameters that were sent during app registration including app name, TTS name and voice synonyms of the app. This proposal aims to make it more convenient for the app developer to change the apps registration and to provide an API which fits to the design of the application lifecycle manager.

## Motivation

Currently the app provides (or can provide) the list of languages it supports. This is done by using the lifecycle configuration. Any app parameter that has to be localized (TTS name, VR names) is localized to the app's default language. The app still has to check manually if it should change the registration and eventually modify the localizable app parameters using the ready handler.

Automatically sending ChangeRegistration inside the SDK is not sufficient. The SDK doesn't know the names for all the other languages.

## Proposed solution

A convenient way for the developer would be to provide an optional method in SDLManagerDelegate. The app can implement this method and provide an update for the lifecycle configuration. If the app developer returns an instance of `SDLLifecycleConfigurationUpdate` the manager can update the existing lifecycle configuration (including `.language`)  and send a ChangeRegistration request. Otherwise if returning nil the manager does not execute a registration change.

The manager can decide to call the delegate method by checking the language of the newly connected head unit if it matches one of the supported languages.

The following class should be added to the SDK

```objc
@interface SDLLifecycleConfigurationUpdate
@property (copy, nonatomic, nullable) NSString *appName;
@property (copy, nonatomic, nullable) NSString *shortAppName;
@property (copy, nonatomic, nullable) NSArray<SDLTTSChunk *> *ttsName;
@property (copy, nonatomic, nullable) NSArray<NSString *> *voiceRecognitionCommandNames;
@end
``` 

The following method should be added to the `SDLManagerDelegate`.

 ```objc
 @protocol SDLManagerDelegate
 ...
 @optional
 - (nullable SDLLifecycleConfigurationUpdate *)manager:(nonnull SDLManager *)manager willUpdateLifecycleToLanguage:(nonnull SDLLanguage *)language //proposed method
 @end

// example implementation of the protocol's method
- (nullable SDLLifecycleConfigurationUpdate *)manager:(nonnull SDLManager *)manager willUpdateLifecycleToLanguage:(nonnull SDLLanguage *)language {
    SDLLifecycleConfigurationUpdate *update = [[SDLLifecycleconfigurationUpdate alloc] init];
    update.ttsName = SOME_TTS_NAME_SPECIAL_FOR_language;
    return update;
}
```

1. After receiving `RegisterAppInterfaceResponse` and calling the `readyHandler` the lifecycle manager should compare the SDLLanguage of the head unit and the default language of the configuration.
2. If it doesn't match but the SDLLanguage exist in the array `languagesSupported` and the method `manager:willUpdateLifecycleToLanguage:` is implemented the manager should call the method providing the manager instance and the head units language
3. If the app provides an instance of `SDLLifecycleConfigurationUpdate` manager should apply all non-null parameters to the existing lifecycle configuration.
4. The manager should set the lifecycle configuration `language` property to the head unit language and send a ChangeRegistration request using the data of the updated parameters (app name, TTS name, VR names, short name).

## Potential downsides

Compared to manually using the ChangeRegistration  RPC the app developer won't be able to change the registration more than once.

## Impact on existing code

- The `SDLManagerDelegate` will get a new optional method which will not cause impact to existing apps

## Alternatives considered

No alternatives considered.
