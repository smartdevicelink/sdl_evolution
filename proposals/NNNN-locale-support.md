# Locale support

* Proposal: [SDL-NNNN](NNNN-locale-support.md)
* Author: [Kujtim Shala](https://github.com/kshala-ford)
* Status: **Awaiting review**
* Impacted Platforms: [Core / iOS / Android / Web / RPC ]

## Introduction

This proposal is about changing the way how SDL treats languages and localizations. The idea is to replace the `Language` enum and use the Locale structure/class of the native SDKs.

## Motivation

SDL is not flexible in adding new languages or countries. It requires changes to the HMI and mobile API as well as SDL core. 

## Proposed solution

The proposed solution is to fully remove the `Language` enum. Instead a locale structure should be added that follows locale names defined by the unicode CLDR.

### Mobile and HMI API

The `Language` enum should be completely removed with no replacement.

```xml
- <enum name="Language">
-   <element ....>
-   </element>
- ...
- </enum>
```

Every existing parameter of type `Language` should be changed to the type `String`. Following parameters are affected:

- KeyboardProperties.language
- RegisterAppInterface.languageDesired
- RegisterAppInterface.hmiDisplayLanguageDesired
- RegisterAppInterfaceResponse.language
- RegisterAppInterfaceResponse.hmiDisplayLanguage
- ChangeRegistration.language
- ChangeRegistration.hmiDisplayLanguage
- OnLanguageChange.language
- OnLanguageChange.hmiDisplayLanguage

### SDKs

The 

Describe the design of the solution in detail. Use subsections to describe various details. If it involves new protocol changes or RPC changes, show the full XML of all changes and how they changed. Show documentation comments detailing what it does. Show how it might be implemented on the Mobile Library and Core. The detail in this section should be sufficient for someone who is *not* one of the authors to be able to reasonably implement the feature and future [smartdevicelink.com](https://www.smartdevicelink.com) guides.

## Potential downsides

Describe any potential downsides or known objections to the course of action presented in this proposal, then provide counter-arguments to these objections. You should anticipate possible objections that may come up in review and provide an initial response here. Explain why the positives of the proposal outweigh the downsides, or why the downside under discussion is not a large enough issue to prevent the proposal from being accepted.

## Impact on existing code

Describe the impact that this change will have on existing code. Will some SDL integrations stop compiling due to this change? Will applications still compile but produce different behavior than they used to? Is it possible to migrate existing SDL code to use a new feature or API automatically?

## Alternatives considered

Describe alternative approaches to addressing the same problem, and why you chose this approach instead.
