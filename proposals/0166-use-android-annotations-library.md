# Use Android Annotations Library

* Proposal: [SDL-0166](0166-use-android-annotations-library.md)
* Author: [Bilal Alsharifi](https://github.com/bilal-alsharifi)
* Status: **Accepted**
* Impacted Platforms: [Android]

## Introduction

This proposal is to include the annotations dependency and start using it in the SDL Android library. Java annotations allow developers to provide hints to the compiler and code inspection tools. This ensures that code issues do not propagate which enhances the overall quality of the code. 

## Motivation

Android has a support annotation library that can be used by developers to detect code issues in a more subtle way, flag potential problems where code conflicts with annotations, and make the IDE suggest possible resolutions. Android developers are using the annotations library heavily to provide a better code and improve its quality in general.

## Proposed solution

This proposal suggests including the Android Support Annotations library as a dependency and using its annotations to improve the code quality in the SDL Android library.
[Android Developer website](https://developer.android.com/studio/write/annotations.html) lists some of the annotations that can be used in Android. The following annotations, for example, can be very useful to use in the SDL Android library:

* Nullness annotations `@Nullable` and `@Nonnull` are very efficient in preventing null pointer exceptions from happening. When they are used properly, code inspection tools in Android Studio will show a warning when there is a potential null pointer exception. The nullness annotations can be used as shown in this [example](https://developer.android.com/studio/write/annotations.html#adding-nullness).
* Typedef annotations like `@IntDef` can be used to create enumerated annotations of integer sets using static final int values instead of enums. Enums, in fact, are not very recommended to be used in Android because they increase the size of the DEX files as well as the runtime memory allocation size. Google uses this approach in Android SDK instead of enums. An example of using `@IntDef` to create enumerated sets can be found [here](https://developer.android.com/studio/write/annotations.html#enum-annotations).

## Potential downsides

This proposal will add one more dependency to the SDL Android library. However, because the dependency is a library created by Google, it is unlikely to have support removed in the near future, and the author believes the benefit outweighs that risk.

## Impact on existing code
Changes to SDL Android:

* Add `com.android.support:support-annotations` as a dependency in the SDL Android library
* Start using annotations whenever a new feature is implemented or an existing piece of code is modified
* Start using `@IntDef` annotation with static final int values instead of enums when implementing a new enumerated set of values

Those changes should not be breaking as long as the enums that are exposed to developers are not changed.

## Alternatives considered

None.
