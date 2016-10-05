# iOS Library Make Transport Classes Private and Cleaner
* Proposal: [SDL-0016](0016-ios-library-transport-private-cleanup.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Accepted**
* Impacted Platforms: iOS

## Introduction
This proposal is to make a major change by altering transport classes to be private instead of public.

## Motivation
Privacy should be preferred in order to allow developers to make API changes to the classes without requiring minor or major version changes. The transport classes have no need for a developer to interact with them, and doing so would be harmful. Therefore, these classes should be private. The second change should be made for safety reasons and to simply be cleaner.

## Proposed Solution
The specific classes to be changed from public to private are:
* `SDLTransportDelegate`
* `SDLAbstractTransport`
* `SDLIAPSessionDelegate`
* `SDLIAPTransport`
* `SDLTCPTransport`

Changing this would additionally require changes in `SDLProxy`'s initializer: `- (id)initWithTransport:(SDLAbstractTransport *)transport protocol:(SDLAbstractProtocol *)protocol delegate:(NSObject<SDLProxyListener> *)delegate;` because we would no longer be having the developer create the transports.

## Potential Downsides
There are no potential downsides. We do not want the developer to interface with these classes, so we should disable that ability.

## Impact on existing code
This would be a breaking change. We would need to change these classes' scope in Xcode, Cocoapods, and alter the `SDLProxy` initializer.
