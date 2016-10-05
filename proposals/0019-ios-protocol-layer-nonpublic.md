# iOS Library Proxy Layer Should Not Be Public

* Proposal: [SDL-0019](0019-ios-protocol-layer-nonpublic.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **In Review**
* Impacted Platforms: iOS

## Introduction
This proposal is to make major changes by shifting all code on the proxy layer to be non-public. This would leave the new manager-based layer as the developer's primary interaction point.

## Motivation
Since we shifted to the new developer API in SDL iOS 4.3.0, we have provided two primary interaction points, `SDLManager` and `SDLProxy`. `SDLProxy` was deprecated in 4.3.0 as an incentive for developers to shift over to using `SDLManager` and kin. We should use a major update to make breaking changes that remove `SDLProxy.h` from being public and make `SDLManager` the sole interaction point. This change will remove any confusion that may result from having two primary interaction points and allow SDL developers to refactor `SDLProxy` and kin to make sense as the backing marshalling layer for `SDLManager` without worrying about making breaking changes.

## Proposed solution
Currently, the following classes of the protocol layer are public:
* `SDLProxy.h`
* `SDLProxyListener.h`
* `SDLProxyFactory.h`

These classes should be shifted to `project` instead of `public` and all public API references to them should be removed.

## Impact on existing code
This is a major change, but it would not affect anyone if they are using the iOS 4.3.0 APIs. Anyone continuing to use deprecated `SDLProxy` methods will have to switch to using the `SDLManager` based API.

## Alternatives considered
The only alternative is to make API changes to these methods as desired and leave them public. There's no reason to do this, however, and further changes would require further major version changes.
