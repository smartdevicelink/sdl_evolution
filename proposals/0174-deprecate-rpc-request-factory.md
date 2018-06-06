# Deprecate RPCRequestFactory

* Proposal: [SDL-0174](0174-deprecate-rpc-request-factory.md)
* Author: [Bilal Alsharifi](https://github.com/bilal-alsharifi)
* Status: **In Review**
* Impacted Platforms: [Android]

## Introduction

This proposal is to deprecate the `RPCRequestFactory` class and start using RPC constructors directly to create new RPC instances.

## Motivation

Currently, the RPC factory methods are hidden inside one big class called `RPCRequestFactory`. A better approach to handle RPC instantiation is to create constructors in each RPC class when necessary. This will make it more natural for the developers to create new RPC instances. Moreover, this will make it easier to maintain the SDL library because everything related to a specific RPC will be within the same class. A [similar solution](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0020-ios-remove-rpcrequestfactory.md) was proposed and applied to the iOS library.


## Proposed solution

The `RPCRequestFactory` will be deprecated and the factory methods will be replaced by constructors in the RPC classes.

## Potential downsides

Because this is a major change, developers who are currently using the public methods in `RPCRequestFactory` class will have to modify their code and use the RPC constructors to create RPC instances.

## Impact on existing code

This will be a major change. The `RPCRequestFactory` will be flagged as deprecated in the next minor release to let developers know that its public methods may not be available in future releases. Developers will then have to use RPC constructors directly after the next major release.

## Alternatives considered

The alternative solution that was considered is to keep the `RPCRequestFactory` class. However, this is not considered a good solution because the factory methods are not very visible to the developers in that way. It will also keep the RPC factory methods in one big class instead of spreading them out to the PRC classes where they should naturally be.



