# Add Example Apps Github Organization

* Proposal: [SDL-0287](0287-example-apps-organization.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Accepted**
* Impacted Platforms: [none]

## Introduction
This proposal adds a new Github organization `SmartDeviceLink-Examples` that is dedicated to example apps for various platforms.

## Motivation
Currently, SDL has example apps in the main `SmartDeviceLink` organization. These are harder to find, and the fact that they are in the main organization implies that they are updated frequently, but they are not.

## Proposed solution
In order to enforce a separation between libraries and utilities on one hand, and example applications on the other, we will add a `SmartDeviceLink-Examples` organization. We will then move example apps to that organization.

### General Principles
1. Apps in this organization should state in the README which version of the respective library they were last updated for. For example, an example weather app for iOS should state in the README, "Uses sdl_ios v6.5.0."
2. There are no requirements about timelines for updating the example apps. They do not need to be updated with every release. They are presented as-is and no guarantees are made about their upkeep.
   * These apps may nevertheless be referenced in the documentation as examples.
3. Improvements and bug-fixes to example apps submitted by partners or the open-source community will be reviewed by the SDLC Project Maintainer (PM) at their discretion and as time allows.
4. The naming scheme will be changed for app library examples to `example_{app category/type}_app_{platform}` and the app itself should be named `SDL Example {app category/type} {platform}`. Example apps for non-app-library utilities and platforms will have looser rules.
    * Examples of this might be `example-security-app-ios`, `example-carthage-distribution-app-ios`, `example-weather-app-android`, or `example-navigation-app-javascript`.
5. Partners are welcome to contribute additional example apps, keeping in mind the same general principles above. The PM will not be responsible for their quality or upkeep but may choose to improve the app at their discretion. In other words, contributed apps are under the PM's purview to improve if they wish, but does not obligate the PM to maintain or improve them.

### Apps That Will Be Moved
The following apps will be moved to this new organization:

* `sdl_mobileweather_tutorial_android` also renamed to `sdl-example-weather-app-android`
* `sdl_example_weather_app_ios`

### Apps That Will Remain
* The `sdl_ios` example obj-c and swift apps. These will remain in the library repository in order to speed up development.
* `hello_sdl_android`, `hello_sdl_java`, `hello_sdl_java_ee` will remain in the library repository in order to speed up development.

## Potential downsides
This will introduce additional workload upon the PM, but because the apps have no obligation for upkeep, the additional workload should not strain the PM, whose primary focus will still be upon library and utility quality.

## Impact on existing code
This impacts no code.

## Alternatives considered
1. We add example apps to the main `SmartDeviceLink` organization. This could clutter the main organization.
2. We change the requirements for the PM to update the example apps. We could require the PM to ensure all example apps to be updated with the latest library at every release or to keep up with issues and PRs on these example apps. However, that would place a burden upon the PM that may require them to slow down development on the libraries and utilities, which should be their main focus.
