# iOS Library Protocol Layer Should Not Be Public

* Proposal: [SDL-0017](0017-ios-protocol-layer-nonpublic.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Accepted**
* Impacted Platforms: iOS

## Introduction
This proposal is to make breaking changes by shifting all code on the protocol layer to be non-public. No class on the protocol layer should have a public API.

## Motivation
The protocol layer is the layer that handles the breaking down of RPCs into bytes to be sent, the building of byte packets into RPCs, and the protocol services. None of these APIs ought to be touched by an app developer, but the APIs are currently public. Because those APIs are public, they are difficult to update because any change to the API of the protocol layer requires minor or major version changes. This change would allow SDL developers to refactor the protocol layer as necessary without needing to make minor or major changes. In addition, it would hide potentially harmful-for-the-developer-to-use APIs from the developer, decreasing cognitive load and increasing safety.

## Proposed solution
Currently, the following classes of the protocol layer are public:
* `SDLProtocolListener.h`
* `SDLProtocolHeader.h`
* `SDLProtocolMessage.h`
* `SDLAbstractProtocol.h`
* `SDLProtocol.h`

These classes should be shifted to `project` instead of `public` and all public API references to them, such as in `SDLProxy`'s `init` method, should be removed.

## Impact on existing code
This is a major change, but would likely not affect many people because they should not be using these methods anyway. The `SDLProxy` method: `- (id)initWithTransport:(SDLAbstractTransport *)transport protocol:(SDLAbstractProtocol *)protocol delegate:(NSObject<SDLProxyListener> *)delegate;` would need to change, but this would be simple. Removing the `protocol` portion of it and simply instantiating an `SDLProtocol` would be all that is required.

## Alternatives considered
The only alternative is to make API changes to these methods as desired and leave them public. There's no reason to do this, however, and further changes would require further major version changes.
