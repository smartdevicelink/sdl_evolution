# Update SDL-Android minimum SDK

* Proposal: [SDL-NNNN](XXXX-update-android-min-sdk.md)
* Author: [Brett M.](https://github.com/brettywhite)
* Status: **Awaiting Review**
* Impacted Platforms: Android

## Introduction

With the progression of SDL Android as a library, it has become necessary to update the minimum supported SDK from 8. The proposed minimum SDK will be API 16, Jelly Bean. 

## Motivation

Maintaining backwards compatibility is often a double edged sword. While it is important for SDL libraries to be able to be used on the widest array of phones possible, maintaining old APIs and not being able to use newer ones comes at a cost of additional time and a reduction in forward movement. This allows the use of newer libraries, such as `ConstraintLayout` that are not usable in the current SDL Android library because its' minimum SDK is higher than our own.

## Proposed solution

The proposed solution is to raise the minimum SDK from 8 to 16. According to [Android's Dashboard](https://developer.android.com/about/dashboards/), 99.5% of all Android devices run SDK 16 or newer. 

Because this is a major change, it would need to be implemented in SDL Android's 5.0 release.

The current minimum SDK 8 was released in 2010. SDK 16 was released in 2012. In comparison, the current SDL iOS's minimum deployment target is 8, which was released in 2014. Both SDK 16 and iOS deployment target 8 have similar numbers in terms of devices not supported (<= 0.5%).

Having our minimum at 16 will help with managers as well. It will allow a more streamlined audio streaming manager, for example, by not having to create any *coding tricks* (read: messy code) to make it work with lower unsupported APIs.

A much larger reason, however, is for testing. The library should, as it is being updated, test against all supported SDKs. It is difficult to find phones that go back to SDK 8, adding to testing cost, time and complexity - for very little in return in terms of additional devices being supported.

## Potential downsides

We potentially leave out 0.5% of Android devices. However, many developers now only write apps with higher minimum SDKs meaning that this is a non-issue.


## Impact on existing code

Change the min SDK in the `build.gradle` file. As stated earlier, it is a major version change and should target SDL Android v5.0.

## Alternatives considered

Raising the min SDK to a number higher than 8 but less than 16 was considered. However, distribution on those versions are on average less than 0.5% of the entire Android ecosystem.