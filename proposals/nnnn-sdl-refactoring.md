# Feature name

* Proposal: [SDL-NNNN](nnnn-sdl-refactoring.md)
* Author: [Maxim Ghiumiusliu](https://github.com/smartdevicelink/mghiumiusliu)
* Status: **Awaiting review**
* Impacted Platforms: Core

## Introduction

Infrastructure of SDL have to be improved by refactoring of the architecture and some component designs.

## Motivation

After adding lot of functionality including policies alignment and SDL-RC, architecture of SDL requires refactoring.
Components like Application Manager, Policy Manager, Protocol Handler etc. increased internal complexity and have got additional dependencies.
Also infrastructure of SDL have to improved to make parallelization of tasks efficient.

## Proposed solution

One of possible solutions: introduce message driven architecture and usage of stable instruments like SObjectizer for constructed proper communication model.
More detailed description will follow.

## Detailed design

TBD

## Impact on existing code

TBD

## Alternatives considered

TBD
