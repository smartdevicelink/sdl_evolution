# Locale support

* Proposal: [SDL-0061](0061-locale-support.md)
* Author: [Kujtim Shala](https://github.com/kshala-ford)
* Status: **Returned for Revisions**
* Impacted Platforms: [Core / iOS / Android / RPC ]

## Introduction

This proposal is about changing the way how SDL treats languages and localizations. The idea is to replace the `Language` enum and use the Locale structure/class of the native SDKs.

## Motivation

SDL is not flexible in adding new languages or countries. It requires changes to the HMI and mobile API as well as SDL core. Furthermore it would be counterproductive to enumerate all possible variations of language and country SDL should support. One critical issue that was seen is that apps fail to register if it desires a language which is not known to the head unit.

1. App registers with indian english as desired language
2. Existing head units which don't know indian english in the Language enum will reply with INVALID_DATA

## Proposed solution

The proposed solution is to deprecate the `Language` enum. Instead the locale structure provided by the native phone SDKs should be used that follows locale names defined by the unicode CLDR. Using unicode allows SDL adopters to be more flexible but still follow a standard to agree to language codes.

1. App registers with indian english as desired locale
2. Proxy internally sets the deprecated langauge parameter to something known (en_US)
3. Any head unit (old and new) would successfuly register the app. The head units reply with the language (and locale for new head units) the head unit is configured to.

### Mobile API

- The enum `Language` should be deprecated with no replacement.
- The function `OnLanguageChange` should be deprecated and replaced by `OnLocaleChange`.
- Every `language` parameter should be deprecated and replaced by a `locale` parameter of type String.
- The parameter `languageDesired` should be deprecated and replaced by a `localeDesired` parameter of type String.
- Every `hmiDisplayLanguage` and `hmiDisplayLanguageDesired` parameter should be deprecated with no replacement.

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

- The enum `Language` should be removed with no replacement.
- The function `OnLanguageChange` should be removed and replaced by `OnLocaleChange`.
- The function `GetSupportedLanguages` should be removed and replaced by `GetSupportedLocales`.
- The function `GetLanguage` should be removed and replaced by `GetLocale`.
- Every `language` parameter should be removed and replaced by a `locale` parameter of type String.
- The parameter `hmiDisplayLanguageDesired` should be removed and replaced by a `localeDesired` parameter of type String.

#### Interface "Common"

```xml
<enum name="Language"> <!-- REMOVE -->
  :
</enum>
:
<struct name="HMIApplication">
  :
  <param name="hmiDisplayLanguageDesired" type="Common.Language" mandatory="false"> <!-- REMOVE -->
  <param name="localeDesired" type="String" mandatory="false" /> <!-- NEW -->
  :
</struct>

<struct name="KeyboardProperties">
  :
  <param name="language" type="Common.Language" mandatory="false"> <!-- REMOVE -->
  <param name="locale" type="String" mandatory="false" /> <!-- NEW -->
  :
</struct>
```

#### Interface "BasicCommunication"

```xml
<function name="GetSystemInfo" messagetype="response">
  :
  <param name="language" type="Common.Language" mandatory="true"> <!-- REMOVE -->
  <param name="locale" type="String" mandatory="true" /> <!-- NEW -->
  :
</function>
:
<function name="OnSystemInfoChanged" messagetype="notification">
  :
  <param name="language" type="Common.Language" mandatory="true"/> <!-- REMOVE -->
  <param name="locale" type="String" mandatory="true" /> <!-- NEW -->
  :
</function>
```

#### Interface "VR", "TTS", "UI"

```xml
<function name="ChangeRegistration" messagetype="request">
  :
  <param name="language" type="Common.Language" mandatory="true"> <!-- REMOVE -->
  <param name="locale" type="String" mandatory="true" /> <!-- NEW -->
  :
</function>
:
<function name="OnLanguageChange" messagetype="notification"> <!-- REMOVE -->
:
<function name="OnLocaleChange" messagetype="notification"> <!-- NEW -->
  <param name="locale" type="String" mandatory="true" />
</function>
:
<function name="GetSupportedLanguages" messagetype="request"> <!-- REMOVE -->
:
<function name="GetSupportedLanguages" messagetype="response"> <!-- REMOVE -->
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
<function name="GetLanguage" messagetype="request"> <!-- REMOVE -->
:
<function name="GetLanguage" messagetype="response"> <!-- REMOVE -->
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
  <param name="language" type="Common.Language" mandatory="false"> <!-- REMOVE -->
  <param name="locale" type="String" mandatory="false /> <!-- NEW -->
  :
</function>
```

### Locale format

The `.locale` parameters should follow the syntax of locale names. 

> The identifiers can vary in case and in the separator characters. The "-" and "_" separators are treated as equivalent. All identifier field values are case-insensitive. Although case distinctions do not carry any special meaning, an implementation of LDML should use the casing recommendations in [BCP47], especially when a Unicode locale identifier is used for locale data exchange in software protocols. The recommendation is that: the region subtag is in uppercase, the script subtag is in title case, and all other subtags are in lowercase.

- See http://www.unicode.org/reports/tr35/tr35-47/tr35.html#Unicode_Language_and_Locale_Identifiers
- See http://www.rfc-editor.org/rfc/bcp/bcp47.txt

Examples:

- `"en"` for english language or `"en-US"`, `"en-GB"`, `"en-AU"`, `"en-IN"` etc.
- `"zh-Hans"` or `"zh-Hant"` for Chinese in the simplified or traditional script.

### Core

Core should continue to use `.language` parameters in addition to `.locale` parameters when sending RPCs to an app. If `.locale` is set to an identifier which matches an enum value of `Language` this enum value should be used for `.language`. Otherwise `.EN_US` should be used as a fallback to keep mandatory rules valid.

Whenever Core receives an RPC from an app and `.locale` parameter is set Core should ignore `.language` parameter. This way Core should be made ready when deprecations are removed.

Core should continue to send `OnLanguageChange` notification followed by `OnLocaleChanged` notification to an app whenever the head unit language changes.

### Proxies

The proxies should follow the changes as per mobile API but the `locale` properties should not be of type String. Instead it should be: 
- [NSLocale](https://developer.apple.com/reference/foundation/nslocale) for iOS. The iOS proxy should create a locale object by using the `NSLocale` initializer `initWithLocaleIdentifier:`.
- [java.util.Locale](https://developer.android.com/reference/java/util/Locale.html) for Android. The Android proxy should create a locale object by using the static method `Locale.forLanguageTag`.

Although `RegisterAppInterface.localeDesired` and `ChangeRegistration.locale` are marked as mandatory in the mobile API they must not be marked as nonnull in the library. Otherwise nullability would be violated when using apps on existing head units.

## Potential downsides

Apps would need to manually check `.locale` and `.language` parameters. On existing head units apps would not receive a `.locale`.

## Impact on existing code

Whenever an app wants to register or change an existing registration it has to set both `.language` and `.locale` as both are mandatory. Otherwise apps won't register. An app would receive two notifications when Core notifies about a language change. Both downsides should not cause any issue to existing apps or head units. Existing head units and apps would just ignore the locale parameters in the JSON data.

The proposal should not cause a breaking change and can be integrated in a minor version increase.

## Alternatives considered

Deprecating `OnLanguageChange` on the mobile API is not key to this proposal. This proposal marks the RPC as deprecated only for naming reasons. 
