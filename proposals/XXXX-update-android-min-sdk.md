# Update SDL-Android minimum SDK

* Proposal: [SDL-XXX](XXXX-update-android-min-sdk.md)
* Author: [Bretty White](https://github.com/brettywhite)
* Status: **Awaiting Acceptance**
* Impacted Platforms: Android

## Introduction

With the progression of SDL Android as a library, it has become necessary to update the minimum supported SDK from 8. The proposed minimum SDK will be API 19, KitKat. 

## Motivation

Maintaining backwards compatibility is often a double edged sword. While it is important for SDL libraries to be able to be used on the widest array of phones possible, maintaining old APIs and not being able to use newer ones comes at a cost of additional time and a reduction in forward movement.

## Proposed solution

The proposed solution is to raise the minimum SDK from 8 to 19. According to [Android's Dashboard](https://developer.android.com/about/dashboards/), 95.9% of all Android devices run SDK 19 or newer. 

Because this is a major change, it would need to be implemented in SDL Android's 5.0 release.


## Potential downsides

We potentially leave out 4.1% of Android devices. However, many developers now only write apps with higher minimum SDKs meaning that this is a non-issue.


## Impact on existing code

Change the min SDK in the `build.gradle` file.

## Alternatives considered

Raising the min SDK to a number higher than 8 but less than 19 was considered. However, distribution on those versions are on average less than 1% of the entire Android ecosystem. SDK 19 is generally regarded as a comfortable minimum SDK.