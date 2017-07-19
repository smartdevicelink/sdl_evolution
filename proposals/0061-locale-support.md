# Locale support

* Proposal: [SDL-0061](0061-locale-support.md)
* Author: [Kujtim Shala](https://github.com/kshala-ford)
* Status: **Returned for Revisions**
* Impacted Platforms: [Core / iOS / Android / RPC ]

## Introduction

This proposal is about changing the way how SDL treats languages and localizations. The idea is to replace the `Language` enum and use the Locale structure/class of the native SDKs.

## Motivation

SDL is not flexible in adding new languages or countries. It requires changes to the HMI and mobile API as well as SDL core. Furthermore it would be counterproductive to enumerate all possible variations of language and country SDL should support.

## Proposed solution

The proposed solution is to deprecate the `Language` enum. Instead the locale structure provided by the native phone SDKs should be used that follows locale names defined by the unicode CLDR. Using unicode would allow SDL adopters to be more flexible but still follow a standard to agree to language codes.

### Mobile API

The enum `Language` should be deprecated with no replacement.
The function `OnLanguageChange` should be deprecated and replaced by `OnLocaleChange`.
Every `language` parameter should be deprecated and replaced by a `locale` parameter of type String.
The parameter `languageDesired` should be deprecated and replaced by a `localeDesired` parameter of type String.
Every `hmiDisplayLanguage` and `hmiDisplayLanguageDesired` parameter should be deprecated with no replacement.

```xml
<enum name="FunctionID">
  :
  <element name="OnLocaleChangeID" value="..." hexvalue="..." /> <!-- NEW -->
</enum>
:
<enum name="Language"> <!-- DEPRECATED -->
  :
</enum>

<struct name="KeyboardProperties">
  :
  <param name="language" type="Language" mandatory="false"> <!-- DEPRECATED -->
  <param name="locale" type="String" mandatory="false" /> <!-- NEW -->
  :
</struct>

<function name="RegisterAppInterface" functionID="RegisterAppInterfaceID" messagetype="request">
  :
  <param name="languageDesired" type="Language" mandatory="true"> <!-- DEPRECATED -->
  <param name="localeDesired" type="String" mandatory="true" /> <!-- NEW -->
  :
  <param name="hmiDisplayLanguageDesired" type="Language" mandatory="true"> <!-- DEPRECATED -->
  :
</function>

<function name="RegisterAppInterface" functionID="RegisterAppInterfaceID" messagetype="response">
  :
  <param name="language" type="Language" mandatory="false"> <!-- DEPRECATED -->
  <param name="locale" type="String" mandatory="false" /> <!-- NEW -->
  :
  <param name="hmiDisplayLanguage" type="Language" mandatory="false"> <!-- DEPRECATED -->
  :
</function>

<function name="ChangeRegistration" functionID="ChangeRegistrationID" messagetype="request">
  :
  <param name="language" type="Language" mandatory="true"> <!-- DEPRECATED -->
  <param name="locale" type="String" mandatory="true" /> <!-- NEW -->
  :
  <param name="hmiDisplayLanguage" type="Language" mandatory="true"> <!-- DEPRECATED -->
  :
</function>

<function name="OnLanguageChange" functionID="OnLanguageChangeID" messagetype="notification"> <!-- DEPRECATED -->
  :
<function name="OnLocaleChange" functionID="OnLocaleChangeID" messagetype="notification"> <!-- NEW -->
  <param name="locale" type="String" /> <!-- NEW -->
</function>
```

### HMI API

The enum `Language` should be deprecated with no replacement.
The function `OnLanguageChange` should be deprecated and replaced by `OnLocaleChange`.
The function `GetSupportedLanguages` should be deprecated and replaced by `GetSupportedLocales`.
The function `GetLanguage` should be deprecated and replaced by `GetLocale`.

Every `language` parameter should be deprecated and replaced by a `locale` parameter of type String.
The parameter `hmiDisplayLanguageDesired` should be deprecated and replaced by a `localeDesired` parameter of type String.

#### Interface "Common"

```xml
<enum name="Language"> <!-- DEPRECATED -->
  :
</enum>
:
<struct name="HMIApplication">
  :
  <param name="hmiDisplayLanguageDesired" type="Common.Language" mandatory="false"> <!-- DEPRECATED -->
  <param name="localeDesired" type="String" mandatory="false" /> <!-- NEW -->
  :
</struct>

<struct name="KeyboardProperties">
  :
  <param name="language" type="Common.Language" mandatory="false"> <!-- DEPRECATED -->
  <param name="locale" type="String" mandatory="false" /> <!-- NEW -->
  :
</struct>
```

#### Interface "BasicCommunication"

```xml
<function name="GetSystemInfo" messagetype="response">
  :
  <param name="language" type="Common.Language" mandatory="true"> <!-- DEPRECATED -->
  <param name="locale" type="String" mandatory="true" /> <!-- NEW -->
  :
</function>
:
<function name="OnSystemInfoChanged" messagetype="notification">
  :
  <param name="language" type="Common.Language" mandatory="true"/> <!-- DEPRECATED -->
  <param name="locale" type="String" mandatory="true" /> <!-- NEW -->
  :
</function>
```

#### Interface "VR", "TTS", "UI"

```xml
<function name="ChangeRegistration" messagetype="request">
  :
  <param name="language" type="Common.Language" mandatory="true"> <!-- DEPRECATED -->
  <param name="locale" type="String" mandatory="true" /> <!-- NEW -->
  :
</function>
:
<function name="OnLanguageChange" messagetype="notification"> <!-- DEPRECATED -->
:
<function name="OnLocaleChange" messagetype="notification"> <!-- NEW -->
  <param name="locale" type="String" mandatory="true" />
</function>
:
<function name="GetSupportedLanguages" messagetype="request"> <!-- DEPRECATED -->
:
<function name="GetSupportedLanguages" messagetype="response"> <!-- DEPRECATED -->
:
<function name="GetSupportedLocales" messagetype="request"> <!-- NEW -->
  <description>Request from SDL at system start-up. Response must provide the information about (VR|TTS|UI) supported languages.</description>
</function>
:
<function name="GetSupportedLocales" messagetype="response"> <!-- NEW -->
  :
  <param name="locales" type="String" mandatory="true" array="true" minsize="1" maxsize="100" /> <!-- NEW -->
  :
</function>
:
<function name="GetLanguage" messagetype="request"> <!-- DEPRECATED -->
:
<function name="GetLanguage" messagetype="response"> <!-- DEPRECATED -->
:
<function name="GetLocale" messagetype="request"> <!-- NEW -->
  <description>Request from SDL to HMI to get the currently active (VR|TTS|UI) language.</description>
</function>
<function name="GetLocale" messagetype="response"> <!-- NEW -->
  <param name="locale" type="String" mandatory="true" />
</function>
```

#### Interface "SDL"

```xml
<function name="GetUserFriendlyMessage" messagetype="request" scope="internal">
  :
  <param name="language" type="Common.Language" mandatory="false"> <!-- DEPRECATED -->
  <param name="locale" type="String" mandatory="false /> <!-- NEW -->
  :
</function>
```

### Core & HMI 

Core and HMI should continue to set the deprecated parameters and respond to the deprecated functions. 
If the head unit is configured to a locale which is listed in the `Language` enum the deprecated parameters should be set to that enum value. Otherwise `EN_US` should be used as a fallback.

The `locale` parameters should follow the syntax of locale names. 

> The identifiers can vary in case and in the separator characters. The "-" and "_" separators are treated as equivalent. All identifier field values are case-insensitive. Although case distinctions do not carry any special meaning, an implementation of LDML should use the casing recommendations in [BCP47], especially when a Unicode locale identifier is used for locale data exchange in software protocols. The recommendation is that: the region subtag is in uppercase, the script subtag is in title case, and all other subtags are in lowercase.

See http://www.unicode.org/reports/tr35/tr35-47/tr35.html#Unicode_Language_and_Locale_Identifiers

### SDKs

The SDKs should follow the changes as per mobile API but the `locale` properties should be of type [NSLocale](https://developer.apple.com/reference/foundation/nslocale) for iOS or [java.util.Locale](https://developer.android.com/reference/java/util/Locale.html) for Android instead of String.

The Android SDK should create a locale object by using the static method `Locale.forLanguageTag`. The iOS SDK should create a locale object by using the `NSLocale` initializer `initWithLocaleIdentifier:`. 

Depending on the JSON data the SDK should use the `locale` parameter as the input for the Locale object by default. If the JSON data does not contain a `locale` parameter the SDK should use the `language` parameter instead to keep backward compatibility. If necessary the SDK should modify the `language` String to match the syntax of locale names ("EN_US" > "en-US").

## Potential downsides

The language parameters are mandatory for existing SDL integrations (Ford SYNC1 & SYNC3 with AppLink). Therefore they should be deprecated but still available for a long period of time until a threshold of active head units with locale support is reached. This threshold should be quite high (>90%) and may require years to happen.

## Impact on existing code

The impact on existing code is quite high for mobile apps. Every app uses language parameters at least to register on the head unit. 

## Alternatives considered

As an alternative a new struct called `Locale` could be added to be more independent to the native phone OS SDKs.
