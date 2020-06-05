# Add a Reason Parameter to All Protocol NAKs

* Proposal: [SDL-0308](0308-protocol-nak-reason.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **In Review**
* Impacted Platforms: [Core / iOS / Java Suite / JavaScript Suite / Protocol]

## Introduction
This proposal seeks to add a "reason" string parameter to all NAKs in the protocol spec.

## Motivation
As a maintainer of an app library, it is often difficult to understand why Core has NAKed a protocol message. Most NAKs currently have a `rejectedParams` parameter, but in practice, this has not been enough information to determine why a NAK has occurred and properly alert the developer. In place of the `rejectedParams` parameter, the `RegisterSecondaryTransportNAK` has a `reason` parameter to describe the failure reason. This is a better approach and we should expand it to all NAK parameters.

## Proposed solution
The proposed solution is to introduce a `reason` parameter into all protocol_spec NAK packets, and to update Core to provide strings for all known cases of NAKing a protocol spec request.

The following would be the new parameter

| Tag Name | Type | Introduced | Description |
|----------|------|------------|-------------|
| reason | string | x.x.x | Specify a string describing the reason of failure |

The following messages would be affected:

### Control Service
* Start Service NAK
* End Service NAK

### Audio Service
* Start Service NAK
* End Service NAK

### Video Service
* Start Service NAK
* End Service NAK

## Potential downsides
1. This proposal adds a small amount of redundancy between the existing `rejectedParams` field and the new `reason` field. However, there isn't always a 1-1 tie between a send parameter and the rejection reason. Therefore I believe that the `reason` parameter will be a good addition.
2. This does bump the protocol version spec, which should be avoided as often as possible. However, this is only a minor version update and I believe that this proposal's utility is worth the update.

## Impact on existing code
This would be a minor version change to the protocol spec, and therefore would affect Core and all mobile libraries with corresponding minor version changes. Core would also need to update in order to provide reason strings whenever a failure is occurring.

## Alternatives considered
The author did not consider any alternatives.
