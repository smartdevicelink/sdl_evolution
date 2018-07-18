# Remove Hello SDL iOS Repository

* Proposal: [SDL-0185](0185-remove-hello-sdl-ios.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Accepted with Revisions**
* Impacted Platforms: [iOS]

## Introduction

With the additions of the Objective-C and Swift example apps within the sdl_ios repository, the hello_sdl_ios example app has become unnecessary.

## Motivation

The hello_sdl_ios app has been unsupported in favor of the example apps within the sdl_ios repository. Having the apps in the sdl_ios repo and deleting the hello_sdl_ios app has several advantages:

* The apps can be run to test changes to the sdl_ios library as those changes are made, with hello_sdl, the library must be imported, and recompiled from scratch to test changes to the library. This simplifies and speeds up development.
* When going to a new branch or an older version of the library, the example app updated for that branch or version of the library is ready to go.
* Developers can use the `pod try` command to quickly try the SDL example apps instead of finding a separate repository, cloning, installing dependencies, and then running the app.
* We have people on the SDL slack pointing developers to the unsupported hello_sdl app, which brings confusion because the app is not fully up to date. There is only one repository to point people towards, and an easy command line command to try an example app.

## Proposed solution

Simply delete the hello_sdl_ios repository and point people to the sdl_ios repository.

## Potential downsides

There are no downsides.

## Impact on existing code

No impact on the libraries. An unsupported example library will be deleted.

## Alternatives considered

No alternatives were identified.
