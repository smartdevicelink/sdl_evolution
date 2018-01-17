# Add Secondary AppHMIType Array iOS

* Proposal: [SDL-NNNN](NNNN-ios-seconary-apptypes.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Awaiting review**
* Impacted Platforms: iOS

## Introduction

This proposal adds a new optional parameter to `SDLLifecycleConfiguration` allowing for more than one AppHMITypes when using `SDLManager`.

## Motivation

Due to an oversight, only one AppHMITypes is currently possible for any app using the `SDLManager` framework. However, in the `RegisterAppInterface`, AppHMITypes is an array, and multiple AppHMITypes are allowed. We should expand the API to support that situation.

## Proposed solution

The proposed solution is very simple, in addition to the current optional `appType` to add the following:

```objc
@property (strong, nonatomic, nullable) NSArray<SDLAppHMIType> *secondaryHMITypes;
```

When not set, only the primary app type will be used. When set, the `secondaryHMITypes` array will be concatenated with the primary app type and all the values sent over in the `RegisterAppInterface`.

## Potential downsides

It might be slightly confusing to developers how to set their `AppHMIType` by having two separate properties.

## Impact on existing code

This would be a minor version change.

## Alternatives considered

1. We could remove the existing `appType` and only use an array, but this would be a major version change.