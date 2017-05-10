# Locale support

* Proposal: [SDL-0061](0061-locale-support.md)
* Author: [Kujtim Shala](https://github.com/kshala-ford)
* Status: **In Review**
* Impacted Platforms: [Core / iOS / Android / RPC ]

## Introduction

This proposal is about changing the way how SDL treats languages and localizations. The idea is to replace the `Language` enum and use the Locale structure/class of the native SDKs.

## Motivation

SDL is not flexible in adding new languages or countries. It requires changes to the HMI and mobile API as well as SDL core. Furthermore it would be counterproductive to enumerate all possible variations of language and country SDL should support.

## Proposed solution

The proposed solution is to deprecate the `Language` enum. Instead the locale structure provided by the native phone SDKs should be used that follows locale names defined by the unicode CLDR. Using unicode would allow SDL adopters to be more flexible but still follow a standard to agree to language codes.

### Mobile and HMI API

The `Language` enum should be deprecated with no replacement. Every existing parameter of type `Language` should be deprecated. Furthermore they should be all optional. Making those parameters optional allows the use of unknown languages. Following parameters are affected:

- KeyboardProperties.language
- RegisterAppInterface.languageDesired
- RegisterAppInterface.hmiDisplayLanguageDesired
- RegisterAppInterfaceResponse.language
- RegisterAppInterfaceResponse.hmiDisplayLanguage
- ChangeRegistration.language
- ChangeRegistration.hmiDisplayLanguage
- OnLanguageChange.language
- OnLanguageChange.hmiDisplayLanguage

As a replacement to `language` and `languageDesired` new string parameters called `locale` and `localeDesired` should be added. The legacy parameter `hmiDisplayLanguage` and `hmiDisplayLanguageDesired` should not be replaced. 

### Core & HMI 

Core and HMI should continue to send the language parameters if the head unit is configured to a language which is known within the `Language` enum otherwise they should omit the `language` parameter from the JSON data. They should be always sending the `locale` parameter regardless of if the language is known by the enum.

The `locale` parameters should follow the syntax of locale names. 

> The identifiers can vary in case and in the separator characters. The "-" and "_" separators are treated as equivalent. All identifier field values are case-insensitive. Although case distinctions do not carry any special meaning, an implementation of LDML should use the casing recommendations in [BCP47], especially when a Unicode locale identifier is used for locale data exchange in software protocols. The recommendation is that: the region subtag is in uppercase, the script subtag is in title case, and all other subtags are in lowercase.

See http://www.unicode.org/reports/tr35/tr35-47/tr35.html#Unicode_Language_and_Locale_Identifiers

### SDKs

The SDKs should follow the changes as per mobile API but the `locale` properties should be of type [NSLocale](https://developer.apple.com/reference/foundation/nslocale) for iOS or [java.util.Locale](https://developer.android.com/reference/java/util/Locale.html) for Android instead of String.

The Android SDK should create a locale object by using the static method `Locale.forLanguageTag`. The iOS SDK should create a locale object by using the initializer `initWithLocaleIdentifier:`. 

Depending on the JSON data the SDK should use the `locale` parameter as the input for the Locale object by default. If the JSON data does not contain a `locale` parameter the SDK should use the `language` parameter instead to keep backwards compatibility. If necessary the SDK should modify the `language` String to match the syntax of locale names ("EN_US" > "en-US").

## Potential downsides

The language parameters are mandatory for existing SDL integrations (Ford SYNC1 & SYNC3 with AppLink). Therefore they should be deprecated but still available for a long period of time until a threshold of active head units with locale support is reached. This threshold should be quite high (>90%) and may require years to happen.

## Impact on existing code

The impact on existing code is quite high for mobile apps. Every app uses language parameters at least to register on the head unit. 

## Alternatives considered

The alternative is to keep the enum and add every necessary language/region combination. This could end up with a very huge Language enum.
