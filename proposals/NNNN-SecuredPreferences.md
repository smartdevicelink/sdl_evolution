# Secured Preferences

* Proposal: [SE-NNNN](NNNN-SecuredPreferences.md)
* Author: [Joey Grover](https://github.com/joeygrover)
* Status: **Awaiting review**
* Review manager: TBD
* Impacted Platforms: [Android]

## Introduction

This proposal will be to introduce a closed-source library that is owned and maintained by the SDL Maintainers and interested parties from the governing body.

## Motivation

Android lacks an ability to store secured preferences. Android does implement [private preferences](https://developer.android.com/reference/android/content/Context.html#MODE_PRIVATE) which help, but we wanted to take a step beyond that. It is important that we are able to provide as much security around certain information that we store to Android's preference system. Android SharedPreferences docs can be found [here.](https://developer.android.com/reference/android/content/SharedPreferences.html)

The actual information we plan on securing is around trusted router services. Each app maintains their own list of router services they trust. If this information can be tampered with outside of the app, it could cause the app to connect to rogue router services or prevent it from connecting to a trusted router service.

In the future we could store other important information using this same mechanism. 

## Proposed solution

The idea is to create a library that is very similar in nature API wise to Android's SharedPreferences and in facts leverages them. However, it also encrypts and decrypts the preferences as they are stored and retrieved respectively. 

The closed source library will also be obfuscated before being added to the library. The library will be licensed as freeware so it can be freely distributed with the SDL Android Library project.

## Detailed design

Due to the necessity of this library being closed source it is not a good idea to disclose how it is securing the information. At a high level, the library will take in a SharedPreferences delegate instance. What is returned can be used as a generic SharedPreferences interface. The library will handle the encrypting and decrypting automatically using the standard SharedPreferences interface.

## Impact on existing code

Essentially only a few lines needed to change after adding the library. Instead of getting the default SharedPreferences object from a supplied context, the new SecuredPreferences' constructor is used. [See example.](https://github.com/smartdevicelink/sdl_android/blob/563826362e73517bab8bf386ebaacfb58f44f0b3/sdl_android_lib/src/com/smartdevicelink/transport/RouterServiceValidator.java#L505)

## Alternatives considered

It was considered to just include the code into the open source library, but adding the extra security measure of obfuscation was a better alternative. 

It was also considered to just rely on the Android SharedPreferences system, but again, extra security measures are better.
