# Block Old SDL Head Units from Mobile

* Proposal: [SDL-NNNN](NNNN-block-old-sdl-protocols.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Awaiting review**
* Impacted Platforms: [iOS / Android / Web]

## Introduction

Add a way for proxy apps to block older head units from registering and therefore to not appear on those head units.

## Motivation

Old head units sometimes don't support features required by a proxy app (whether iOS, Android, or Cloud). We should support a way to block registration on old head units. We have a limited number of ways to do this pre-registration, unfortunately.

## Proposed solution

Because we don't want the app to appear on the screen at all, we need to block the app before registration. This leaves us with limited options. The proposed solution is to block based on protocol version. The library would be capable of checking the protocol version based on the `StartService` / `StartServiceACK`. If the developer wishes to block old head units, if the negotiated protocol version is 2 or less, the library will automatically send an `EndService`.

An addition will be made to the `SDLLifecycleConfiguration`:

```objc
@property (assign, nonatomic) BOOL shouldBlockOldHeadUnits;
```

This will default to `NO`. If the developer sets to `YES`, then any head unit with protocol version 1 or 2 will receive an `EndService` immediately after protocol version negotiation.

## Potential downsides

1. Not all head units that the developer wants to block may be protocol version 1 or 2. It's a very generic method without any finesse allowed for the developer.

## Impact on existing code

This would be a minor version change for all proxy libraries.

## Alternatives considered

1. We could block via registration version and disconnect just after registration. This was decided not to be used because we don't want to register at all.
2. We could build in the ability to use regex to block names of head units based on accessory information gleaned from (iOS) the external accessory protocol. However, Android and web proxies would be more difficult to implement this kind of blocking.