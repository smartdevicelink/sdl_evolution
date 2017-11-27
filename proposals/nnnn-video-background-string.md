# Video Streaming Backgrounded String

* Proposal: [SDL-NNNN](nnnn-video-background-string.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Awaiting review**
* Impacted Platforms: iOS, Android

## Introduction

Display a string of text on the head unit screen when the app leaves the foreground.

## Motivation

When a video streaming `NAVIGATION` or `PROJECTION` app enters the background on the phone, the video stream stops sending data due to background limitations. On current iOS devices as the device is entering the background, it sends a few frames of pure black. Instead we should send a black screen with some white text telling the driver why their stream stopped.

## Proposed solution

The proposed solution is to display a black screen with white text saying:

> "Open \(appname) on the iPhone to continue"
> "Open \(appname) on the Android to continue"

## Potential downsides

Driver distraction is an issue, but a purely black screen is considered to very confusing to the user.

## Impact on existing code

This should be a minor version change, as no API changes are needed.

## Alternatives considered

1. Use IAP messaging to reopen the app when the user interacts with the head unit screen. The app can only go into the backgound because of the user interacting with the phone while they are in the car, and they may not know they need to re-open the navigation / projection app manually to have it work. By bringing it into the foreground automatically, this would be much easier for the driver. Unfortunately, it would require changes to both Core and IAP code.

2. A different string is possible.