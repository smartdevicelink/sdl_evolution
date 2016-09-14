# iOS Library RPCs conform to NSCopying
* Proposal: [SDL-NNNN](NNNN-filename.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Awaiting review**
* Impacted Platforms: iOS

## Introduction
This proposal is to make all RPC requests, responses, and structs conform to the `NSCopying` protocol and for all requests containing structs to hold those properties with the `copy` modifier. This is a minor change, as the public interfaces for the RPCs will change to support the `copy` method.

## Motivation
It makes sense for model objects to be copyable. Since we will not be using fully immutable RPCs, we should permit defensive copying instead of only allowing reference passing. For example, if we are passing an RPC between threads, since the properties are mutable, they can be modified while in use on the other thread, or modified on both threads. By copying before passing it to the new thread, we can guarantee that we have two separate objects and modifying one will not modify the other. This could be useful, for example, for copying the RPC after the developer has attempted to send it to the head unit. If it is copied, it can no longer be modified once the developer has passed it to the `send` method.

## Proposed Solution
To implement this proposal, we only need to modify `SDLRPCStruct` and a small number of other types since all other RPC types inherit from it and all other RPC properties (barring a few, discussed below) are stored in the dictionary attached to it. So we need to add `<NSCopying>` as a conformed protocol to `SDLRPCStruct` and implement the following method:

```
- (id)copyWithZone:(NSZone *)zone {
    SDLRPCStruct *newStruct = [[[self class] allocWithZone:zone] init];
    newStruct -> store = [self -> store copy];

    return newStruct;
}
```

The only RPCs that will not work using this method are those in 4.3 that added the 'handler' property. These RPCs will need to add something like:

```
- (id)copyWithZone:(NSZone *)zone {
    SDLAddCommand *newCommand = [super copyWithZone:zone];
    newCommand -> handler = self.handler;

    return newCommand;
}
```

## Potential Downsides
There should be no downsides to this proposal.

## Impact on existing code
This would be a minor change as we are adding protocol conformance to classes, which is a purely additive change.

## Alternatives considered
The only other alternative was to make RPCs fully immutable, a change which died in the concept stage.
