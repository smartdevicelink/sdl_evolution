# iAP2 transport adapter reference implementation

* Proposal: [SDL-NNNN](NNNN-iap2-transport-adapter.md)
* Author: [Andrey Oleynik](https://github.com/dev-gh)
* Status: **Awaiting review**
* Impacted Platforms: [Core]

## Introduction

Open SDL implementation does not have iAP2 transport adapter implementation due to lack of iAP2 library for open source and Apple licensing policy.


## Motivation

As iAP2 protocol requires hardware support and platform-specific iAP2 library currently it's not possible to create such adapter for open source as reference implementation for other developers. As potential solution its proposed to share time-proved sample implementation for specific platform which can be used as reference for future.

## Proposed solution

There is a Ford-specific iAP2 transport adapter implementation that works currently on SYNC3 hardware which is QNX-based platform. Since SYNC3 is used in production already its iAP2 transport adapter implementation considered as production-ready solution which may be used as a sort of reference during development same adapters for other platforms/libraries.

TDB: add sequence/class diagrams here


## Potential downsides

Solution proposed is valid only for specific QNX-based platform hence it's not possible to use right away. However since it is being used in production currently it is a good reference for other OEM developers and could help to understand quickly how SDL communicates via iAP2 protocol and also may serve a quick start guide for implementing iAP2 adapters for other platforms.

## Impact on existing code

New transport adatpter implementation will be added as a reference but it won't participate in open SDL compilation due to proprietary dependencies.

## Alternatives considered

N/A
