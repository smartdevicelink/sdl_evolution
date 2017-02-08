# Minimum iOS Version to 8.0
* Proposal: [SE-0024](0024-os-8-0-minimum.md)
* Author: [Alex Muller](https://github.com/asm09fsu)
* Status: **Accepted**
* Impacted Platforms: iOS

## Introduction
This proposal is to move the minimum iOS version allowed by iOS from 7.0 to 8.0 and to make changes taking advantage of the available iOS 8.0 APIs. Since we don't know of any major partners who currently support iOS 7.0+, we should move up our version accordingly.

## Motivation
The reason to move up to iOS 8.0 is to be able to make sure we are able to leverage newer technologies, such as Swift 3, and Xcode 8, without additional resources to confirm backwards compatibility. This also allows us to remove the checks for SDLStreamingMediaManager being only usable on iOS 8, as the whole library will be iOS 8.0+.

## Proposed solution
In addition to moving to iOS 8.0, we should remove the checks for SDLStreamingMediaManager and iOS 8.0.

## Potential Downsides
Any existing app partners on iOS 7.0 would either have to drop SDL support or move to iOS 8.0+

## Impact on existing code
This would only impact us by making available additional APIs.
