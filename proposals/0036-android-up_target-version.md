
# Up Android Target/Compile Version

* Proposal: [SDL-0036](0036-android-up_target-version.md)
* Author: [Joey Grover](https://github.com/joeygrover)
* Status: **Accepted**
* Impacted Platforms: Android

## Introduction

The Android SDL Library is currently targeting and compiling with Android 4.3 which uses Java 1.6. This proposal will be to increase this target version to Android 4.4. 

[Great article](https://medium.com/google-developers/picking-your-compilesdkversion-minsdkversion-targetsdkversion-a098a0341ebd#.bv5lr5889) explaining the different version types in Android. 

## Motivation

The SDL Android library currently targets and compiles against the Android API level 18 (Android 4.3). We are be unable to use new Android APIs introduced in Android 4.4. Android 4.4 was released October 31, 2013. Android KitKat (4.4) was a huge advancement forward in terms of efficiency in code compiling and we should be taking advantage of that. 

- One of the features that could be used is the notification listener to be able to listen for when the SDL Router Service propagates its notification so all apps would know that router service is connected. 
- It can possibly help with video streaming through the hardware composer support for virtual displays.
- Bluetooth APIs are increased and include BLE

All features for Android 4.4 can be found [here](https://developer.android.com/about/versions/kitkat.html). 

This also limits the project to use Java 1.6. We are unable to use newer features introduced into Java 1.7. Some of those features help make code cleaner (eg multiple exceptions in a single catch). Java 7 was released July 28, 2011 and the project is behind in terms of compliance. All updates can be found [here](http://www.oracle.com/technetwork/java/javase/jdk7-relnotes-418459.html). 


## Proposed solution

The SDL Android library will be moved up to version 4.4 (API level 19). This is only a target and compile version, not the min version required to run. **The min version will remain Android 2.2** which covers the vast majority of users. 

![Android Version Market Share](http://i.imgur.com/XtUdUCW.png)
*\*Android Version Market Share as of 3/11/2017*

## Detailed design

The target and compile version will be changed from 18 to 19 This will only affect configuration files.

## Impact on existing code

The code itself won't see immediate impacts. Future pull requests can be made to take advantage of Android 4.4 APIs and Java 7.

## Possible Disadvantages
App developers will be forced to also up their target and compile versions to Android 4.4 (19). The vast majority of developers have already done this. Android recommends compiling against the latest version of Android.

## Alternatives considered

1. Moving up to Java 8. Currently Android doesn't support all features for Java 8. When Android does fully support 8 a new proposal will be introduced as it introduces lambda functionality which could greatly reduce code. Also the Jack compiler doesn't support Java 8 yet. 
