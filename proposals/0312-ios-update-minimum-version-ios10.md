# Update the Minimum Required iOS Version to 10.0
* Proposal: [SDL-0312](0312-ios-update-minimum-version-ios10.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Accepted**
* Impacted Platforms: [iOS]

## Introduction
This proposal is to update the minimum supported iOS deployment version from iOS 8.0 to iOS 10.0.

## Motivation
In September 2020, Xcode 12 will be released. In the current beta release notes, it's noted that Xcode 12 drops support for creating apps below iOS 9.0. We currently support down to iOS 8.0. Therefore, we will need to update our minimum supported version to at least iOS 9.0.

## Proposed solution
The proposal is to move the minimum required deployment version to iOS 10.0. I chose this in order to be able to remove additional version checked code and to give us a larger buffer before another major version change is necessary to do this again.

### Code that can be removed at iOS 9.0
* Workaround for a crash on iOS 8.0 when launching an app when not checking if an app is installed first.
* Failure cases for haptic item locator which only works on iOS 9.0+.

### Code that can be removed at iOS 10.0
* Disabling example app audio transcription code.
* Workarounds for target queues not being available.
* Disabling os_log.

### Additional reasons to move to iOS 10.0
* Gives us a larger buffer before we need to do another major version change.

## Potential downsides
1. I was able to find one iOS partner app that currently supports iOS 9 (Sygic).

## Impact on existing code
This will require a major version change to the iOS library because we are dropping support for some iOS devices.

## Alternatives considered
1. We could update our minimum version to iOS 9.0 instead. We would be unable to remove as much code as if we move to iOS 10.0, and we will be more likely to have to do another major version change to bump the minimum required version again.
