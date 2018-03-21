# ImageFieldName for SecondaryImage

* Proposal: [SDL-NNNN](NNNN-imagefieldname-for-secondary-image.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Awaiting review**
* Impacted Platforms: [Core / iOS / Android / RPC]

## Introduction

Adds a `secondaryGraphic` enum value to the `ImageFieldName` enum to enable app developers to know if a secondary graphic is on screen.

## Motivation

Currently, there is no way for an app developer to know if there is a secondary graphic on the current template. This requires developers to always set the `secondaryGraphic` in Show if they have one, or to check and guess based on the template. This may result in the app developer always uploading the secondary image and attempting to set it.

## Proposed solution

The proposed solution is to add the enum value `secondaryGraphic` to the `ImageFieldName` enum, and to send it within `ImageField` / `DisplayCapabilities` whenever a display capabilities is sent for a layout that contains a secondary graphic.

## Potential downsides

The author could not identify any downsides.

## Impact on existing code

This would be a minor version change. Additions may have to be made to HMI to support this. This will help the iOS Show Manager better support automatically doing the right thing based on the current display layout.

## Alternatives considered

No alternatives were identified.