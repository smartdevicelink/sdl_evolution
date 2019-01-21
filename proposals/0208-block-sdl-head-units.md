# Block Old SDL Head Units from Mobile

* Proposal: [SDL-0208](0208-block-old-sdl-protocols.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Accepted with Revisions**
* Impacted Platforms: [iOS / Android / Web]

## Introduction

Add a way for proxy apps to block older head units via protocols or RPC versions.

## Motivation

Old head units sometimes don't support features required by a proxy app (whether iOS, Android, or Cloud). We should support a way to block registration on old head units using both protocol versions (better, but less granular), and RPC versions (worse, but more granular).

## Proposed solution

Blocking protocol versions is more ideal because the app will not appear on the head unit at all; the block will occur pre-registration. RPC blocking will occur post-registration, but there's more granular control over which versions are blocked based on which features are available.

When using protocol version blocking, the library would be capable of checking the protocol version based on the `StartService` / `StartServiceACK`. If the developer wishes to block old head units, if the negotiated protocol version is 2 or less, the library will automatically send an `EndService`.

For RPC version blocking, the negotiated version is sent in the `RegisterAppInterfaceResponse`, if that version is below the specified RPC version, an `UnregisterAppInterface` will be sent.

Additions will be made to the `SDLLifecycleConfiguration`:

```objc
// Defaults to the current protocol version
@property (assign, nonatomic) SDLVersion minimumProtocolVersion;

// Defaults to the current RPC version
@property (assign, nonatomic) SDLVersion minimumRPCVersion;
```

`SDLVersion` will be based on the equivalent [Android object](https://github.com/smartdevicelink/sdl_android/blob/master/sdl_android/src/main/java/com/smartdevicelink/util/Version.java). The Android library version of this code will utilize that object.

Immediately after protocol version negotiation, the `minimumProtocolVersion` will be checked and the app will be disconnected if it fails. Immediately after registration, the `minimumRPCVersion` will be checked and the app unregistered if it fails.

## Potential downsides

1. Most developers will not understand what protocol versions or RPC versions are. They will require direction from OEMs on what to set these values to.
2. The RPC version block using `UnregisterAppInterface` is far from ideal, as the app may appear, then quickly disappear from the user's head unit every time their phone connects.

## Impact on existing code

This would be a minor version change for all proxy libraries.

## Alternatives considered

1. We could build in the ability to use regex to block names of head units based on accessory information gleaned from (iOS) the external accessory protocol. However, Android and web proxies would be more difficult to implement this kind of blocking.
