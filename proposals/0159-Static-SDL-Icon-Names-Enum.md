# Static SDL Icon Names Enum

* Proposal: [SDL-0159](0159-Static-SDL-Icon-Names-Enum.mdd)
* Author: [Nicole Yarroch](https://github.com/NicoleYarroch)
* Status: **In Review**
* Impacted Platforms: iOS, Android

## Introduction

This proposal is to create a strongly typed enum for static SDL icon names. This will make it easier for developers to use these icons in their SDL apps.


## Motivation

Developers have access to a set of static on-board icons on SDL Core, however the developer must know the exact name of the icon in order to use it in a RPC. In addition, the static icons are obscurely named with hexadecimal values, which makes it hard to figure out which icon is currently being used. 

## Proposed solution

1. Create a new enum called `SDLStaticIconName`. The hexidecimal name for the static icon will be the string constant. 

    ```objc
    // SDLStaticIconName.h
    typedef SDLEnum SDLStaticIconName SDL_SWIFT_ENUM;
    extern SDLStaticIconName const SDLStaticImageNamePhoneDevice;
    ```
    ```objc
    // SDLStaticIconName.h
    SDLStaticIconName const SDLStaticIconName PhoneDevice = @“0x03”;
    ```

2. Add a convenience initializer to the `SDLImage` class that takes the new enum. 

    ```objc
    [SDLImage initWithStaticIconName:(SDLStaticIconName)]
    ```

## Potential downsides

A manufacturer might choose to support a subset of the 100+ static icons. If a static icon is not supported, an empty icon will be used used in its place. Developers will still need to send a RPC using the static icon and then check the response from SDL Core to see if the static icon is actually available.

## Impact on existing code

This is a minor version change. A new public enum, `SDLStaticIconName`,  will be available, and the `SDLImage` class will get a new convenience initializer. 

## Alternatives considered

None.
