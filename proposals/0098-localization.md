# SDL Localization

* Proposal: [SDL-0098](0098-localization.md)
* Author: [Kujtim Shala](https://github.com/kshala-ford)
* Status: **In Review**
* Impacted Platforms: [ iOS / Android ]

## Introduction

This proposal is about providing a localization API to developers and make it easy to localize the app based on the language settings of the head unit.

## Motivation

Android and iOS provide smart APIs to localize the app based on specifications of the [Unicode CLDR project](http://cldr.unicode.org/index). These APIs load localization files bundled in the app based on a combination of

- languages/locale supported by the app
- Preferred languages set by the user on the phone

In multilingual regions (e.g. Europe) it may happen that the language set on the users phone is different to the language set in the vehicle. The attempt of app developers to solve this issue and use the vehicle language is challenging.

## Proposed solution

This proposal is about adding a localization class to the SDL library. This class can load the localization files bundled in the app based on a specified locale (language, region, script). The SDL manager can create localization objects based on the head unit language and provide those to the app developer.

### Example for iOS:

Today an app developer ready localized strings by using

```objc
NSLocalizedString(@"some-key"); // loading string of phone language
```

For SDL it would be

```objc
[self.manager.localization stringForKey:@"some-key"]; // loading string from SDL language
```

As of today the iOS library can automatically provide a localization instance using the SDL manager.

### Example for Android:

```java
this.getResources().getText(R.string.some_key); // loading string from phone language
```

would be

```java
getLocalization().getText(R.string.some_key); // loading string from SDL language
```

The Android library doesn't contain SDL managers yet. The app developer can use the class manually if needed. Once Android includes a lifecycle manager it can automatically provide a localization object.

### Detailed design

First of all the localization code already exists:

for Android see 
[Localization.java](https://github.com/kshala-ford/sdl_android/blob/feature/localization/sdl_android_lib/src/com/smartdevicelink/util/Localization.java)

and for iOS see 
[SDLLocalization.h](https://github.com/kshala-ford/sdl_ios/blob/feature/localization/SmartDeviceLink-iOS/SmartDeviceLink/SDLLocalization.h) and [SDLLocalization.m](https://github.com/kshala-ford/sdl_ios/blob/feature/localization/SmartDeviceLink-iOS/SmartDeviceLink/SDLLocalization.m)

#### Android

For Android the Localization class is basically creating a new context with a custom locale and then provide the resource instance of the newly created context.

```java
Resources resources = context.getResources();
Configuration config = new Configuration(resources.getConfiguration());
config.setLocale(locale);
ContextWrapper wrapper = new ContextWrapper(context);
this.context = wrapper.createConfigurationContext(config);
```

This proposal is using an API called [createConfigurationContext()](https://developer.android.com/reference/android/content/ContextWrapper.html#createConfigurationContext(android.content.res.Configuration)) which was added at API level 17 (Android 4.2 Jelly Beans MR1). This method creates a new context separated from the apps configuration which allows the app to access resources of another language.

The downside is the API level (see [Android dashboards](https://developer.android.com/about/dashboards/index.html)). As it is expected that this number will become lower over time, and as it has already reached a low number, it is proposed to just use the phone language instead.

```java
this.context = context.getApplicationContext(); // just use the original context
```

This class should be added to the Android SDL library and be used when Android gets a lifecycle manager like structure. This can make the class available to app developers in an early phase before having a lifecycle manager ready.

#### iOS

For iOS the localization class loads language bundles based on a specified locale (language, script, region). iOS prioritizes script rather than the region (see [Hant](http://www.unicode.org/cldr/charts/latest/summary/root.html#71) and [Hans](http://www.unicode.org/cldr/charts/latest/summary/root.html#70)). That said: the localization class supports scripts.

At the end the localization class loads a list of bundles including localizable files. The localization class provide access to those files with `-stringForKey: ...` which include support of format and plural rules.

This localization class should be used by the SDLLifecycleManager. An instance should be created right after the app got connected. This instance should be made accessible to the developer by a property e.g. `@property ... SDLLocalization *localization;`

## Potential downside

No downside identified for iOS. Downside of Android mentioned above.

## Impact on existing code

This change whould not affect any existing code as it's adding classes and a single property to the lifecycle manager.

## Alternatives considered

**Change language configuration of the entire app** would be an easy approach (very few lines of code) but causes the UI of the app on the phone to change to the SDL language. This was dropped as it is too agressive.

**Create custom localization files** separate from the existing and known ones. This would make localization independent of the Android and iOS API but it's much more effort to follow CLDR specifications especially when it comes to plural rules (which are very helpful for natural voice output). Furthermore the app developer has to do translations outside of the known environment which may not be accepted.
