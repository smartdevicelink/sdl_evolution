# Update SDL-Android minimum SDK

* Proposal: [SDL-XXX](XXXX-update-android-min-sdk.md)
* Author: [Bretty White](https://github.com/brettywhite)
* Status: **Awaiting Acceptance**
* Impacted Platforms: Android

## Introduction

With the progression of SDL Android as a library, it has become necessary to update the minimum supported SDK from 8. The proposed minimum SDK will be API 16, Jelly Bean. 

## Motivation

Maintaining backwards compatibility is often a double edged sword. While it is important for SDL libraries to be able to be used on the widest array of phones possible, maintaining old APIs and not being able to use newer ones comes at a cost of additional time and a reduction in forward movement. This allows the use of newer libraries, such as `ConstraintLayout` that are not usable in the current SDL Android library because its' minimum SDK is higher than our own.

## Proposed solution

The proposed solution is to raise the minimum SDK from 8 to 16. According to [Android's Dashboard](https://developer.android.com/about/dashboards/), 99.5% of all Android devices run SDK 16 or newer. 

Because this is a major change, it would need to be implemented in SDL Android's 5.0 release.

Why 16 and not something lower? Because this covers almost every Android phone in use today. Minimum version changes are major version changes in semantic versioning, and this will also future-proof our library into SDL Android Version 6, sometime in the distant future.


## Potential downsides

We potentially leave out 0.5% of Android devices. However, many developers now only write apps with higher minimum SDKs meaning that this is a non-issue.


## Impact on existing code

Change the min SDK in the `build.gradle` file.

## Alternatives considered

Raising the min SDK to a number higher than 8 but less than 16 was considered. However, distribution on those versions are on average less than 0.5% of the entire Android ecosystem.