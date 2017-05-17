# Support Indian English and Thai

* Proposal: [SDL-0060](0060-support-indian-english-thai.md)
* Author: [Kujtim Shala](https://github.com/kshala-ford)
* Status: **Accepted**
* Impacted Platforms: [Core / iOS / Android / RPC]

## Introduction

This proposal is about adding support for Indian English (EN_IN) and Thai (TH_TH).

## Motivation

Ford's infotainment system is going to support those languages in a future version. Those languages don't exist in the current list of supported languages.

## Proposed solution

The solution is to add and implement both languages to the HMI and mobile API (the change is equal to both APIs):

```xml
<element name="EN-IN" internal_name="EN_IN">
  <description>English - India</description>
</element>
    
<element name="TH-TH" internal_name="TH_TH">
  <description>Thai - Thailand</description>
</element>
```
    
## Potential downsides

The effort of adding new languages is quite high. However, given our need to add these Langauges, adding new items to the `Language` enum is simpler than changing the language support to be more flexible.

## Impact on existing code

The proposal requires changes on SDL_core, both SDKs (Android, iOS) and APIs (mobile, HMI).

## Alternatives considered

SDL should not control localization through an enumeration which will be proposed in a separate proposal as a long-term solution.
