# High level interface: Foundation

* Proposal: [SDL-NNNN](NNNN-high-level-interface-foundation.md)
* Author: [Kujtim Shala](https://github.com/kshala-ford)
* Status: **Awaiting review**
* Impacted Platforms: [ iOS / Android ]

## Introduction

This proposal is about setting up a foundation to provide a high level developer interface to the Android and iOS libraries. It proposes a solution to mimic the UI framework of the native OS SDKs. It contains an overview and basic design but won't go much into details of a specific section. Subsequent proposal will be created in the near future in order to provide detailed designs whenever necessary.

As discussed in the steering committee meeting from March 20 (see [here](https://github.com/smartdevicelink/sdl_evolution/issues/379#issuecomment-374736496)) this proposal is a counterproposal to [0133 - Enhanced iOS Proxy Interface](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0133-EnhancediOSProxyInterface.md).

## Motivation

In order to work with SDL app developers need to learn a new API which mostly doesn't adopt familiar patterns. Including but not limited to 
- read best practices and implement proxy lifecycle (Android above all)
- the use of RPCs and handle notifications, requests and responses
- manually manage concurrent and sequential operations (e.g. image upload)

The time for an app developer to learn SDL (non-productive time) is high and not accepted by some developers. The SDL iOS library already improves the current situation by abstracting painful implementations. However the management layer is still unfamiliar and causes a high learning curve.

## Proposed solution

This proposal is about adding a new abstraction layer which utilizes the management layer and provides a high level interface familiar to the UIKit famework in iOS and Activity package in Android.

| High level interface |
|----------------------|
| Management layer     |
| Proxy layer          |
| Protocol layer       |
| Transport layer      |



## Potential downsides

The initial workload in order to implement this high level interface is expected to be quite high. Once implemented it is expected that developers will be able to implement SDL into their apps in less time as they would need today. At the end the maintenance of the high level interface may be lower compared to the counter proposal for different reasons.

This proposal mimics the native UI API. Compared to the counterproposal this proposal is not that close to the native UI kit experience. On the other side some SDL specific APIs can be easily abstracted and integrated into the rest of the high level interface.

Anyway as a result of the workshop 

## Impact on existing code

This proposal will add a total new high level interface layer abstracting many parts of SDL. Existing code should not be affected in a short term but it would make parts of the code obsolete therefore to be deprecated and made private.

## Alternatives considered

There are no other alternatives considered.
