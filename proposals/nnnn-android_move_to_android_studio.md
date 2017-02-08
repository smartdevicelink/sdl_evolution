
# Move to Android Studio

* Proposal: [SDL-NNNN](NNNN-android_move_to_android_studio.md)
* Author: [Joey Grover](https://github.com/joeygrover)
* Status: **Awaiting review**
* Impacted Platforms: [Android]

## Introduction

Android Studio is the primary development environment for Android. The IDE has all of the latest features from Google as well as useful third party integrations. Google has stated that this is their course forward. The SDL Android library should be fully compatible with Android Studio.

## Motivation

The SDL Android library currently has a project structure used by Eclipse. Attempts have been made to let the project work in both IDEs, it only fully-functions in Eclipse, and has a basic working level in Android Studio. Because the file structure doesn't match what Android Studio is expecting the project misses out on features that require it or it becomes very difficult to use them.

The biggest motivator is that Google has not only stated Android Studio is their supported IDE, they will no longer support Eclipse at all. Android Police released a story [here](http://www.androidpolice.com/2016/11/02/google-officially-ends-support-for-eclipse-android-developer-tools-in-favor-of-android-studio/)  on November 2, 2016. Android Studio has been released for just over two years at this point, it is time to switch. If the project doesn't switch, there is only so much time left Eclipse will even be useable for development in the slightest.


## Proposed solution

The SDL Android library will be refactored into the standard project structure Android Studio expects. 

Here is an example:

![Android Studio vs Eclipse project structure](http://novasys.in/blogs/wp-content/uploads/2013/11/project-structure.png "Android Studio vs Eclipse project structure")

## Detailed design

There's not much of a design here. It will follow the exact structure Android Studio uses. More information can be found [here on this stackoverflow post](http://stackoverflow.com/questions/17431838/android-studio-project-structure-v-s-eclipse-project-structure) of the comparison of structures.

## Impact on existing code

The code itself won't see any changes. The biggest impact will be the git history will have a rift between Eclipse support and Android Studio support. This will make it a little more difficult to see when changes happened to certain files before and after the switch.

## Alternatives considered

1. Continue to use Eclipse. The Eclipse ADT plugin will become stale and eventually unusable to develop with.
2. The ability to use both AS and Eclipse. This was done previously and somewhat works now. However, with Eclipse no longer being supported by Google, there is no reason to support it either.
