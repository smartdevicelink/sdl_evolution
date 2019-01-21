# Add Support for Static Icons to SDLArtwork

* Proposal: [SDL-0196](0196-sdlartwork-static-icons.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Accepted**
* Impacted Platforms: [iOS / Android]

## Introduction

Make additions to `SDLArtwork` and `SDLScreenManager` to make using static icons as easy as using uploaded artworks.

## Motivation

Currently we have `SDLArtwork`, `SDLScreenManager`, and the [static icon enum](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0159-Static-SDL-Icon-Names-Enum.md), however, these don't currently play well together. You need to use a raw `Image` RPC to use the static icon enum. We should allow the use of static icons in `SDLSoftButtonObject`, `SDLChoiceCell`, etc.

## Proposed solution

The proposed solution is to make API additions to the `SDLArtwork` RPC and internal changes to `SDLScreenManager` subclasses to account for static icons.

### SDLArtwork Changes

```objc
// New Additions
@property (assign, nonatomic, readonly) BOOL isStaticIcon;

- (instancetype)initWithStaticIcon:(SDLStaticIconName)staticIcon;
+ (instancetype)artworkWithStaticIcon:(SDLStaticIconName)staticIcon;
```

The `name` and `data` parameters will both return the hex data to which the static icon name enum corresponds.

### SDLScreenManager Changes
Screen Manager sub-managers, including the Text and Graphic, Soft Button, Menu, and Choice Set managers will need to watch for `isStaticIcon`, skip the upload, and use the static icon in the `SDLImage` RPC that is created.

### SDLFileManager Changes
In order to prevent manual upload by the developer of an `SDLArtwork` with a static icon through the `SDLFileManager`, the `SDLFileManager` will have to return a success automatically if the `SDLArtwork` is a static icon.

### Android
Android will need to make similar changes to their (currently in-progress) managers.

## Potential downsides

`SDLArtwork` and the managers will become somewhat more complex in their handling of artwork as they will have to check for static icon usage.

## Impact on existing code

This will be a minor version change.

## Alternatives considered

1. The `SDLScreenManager` could also add APIs to receive a `SDLStaticIconName` enum in place of an `SDLArtwork`. This would better encapsulate what's going on, as `SDLArtwork` doesn't perfectly make sense to encapsulate a static icon as a subclass of `SDLFile`.

However, this alternative was discarded due to the extensive increase in API surface required to implement this alternative. Every artwork-related API in the `SDLScreenManager`, including `SDLChoice`, `SDLMenuCell`, and `SDLScreenManager` itself, would need to be doubled to account for a static icon. In addition, properties on `SDLScreenManager` like `primaryGraphic` would need to be replicated to account for the static icon. This is simply too complex.
