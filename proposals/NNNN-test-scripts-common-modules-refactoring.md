# Test Scripts - Refactoring of common mudules

* Proposal: [SDL-NNNN](NNNN-testing-refactoring-common-modules.md)
* Author: [Dmytro Boltovskyi](https://github.com/dboltovskyi)
* Status: **Awaiting review**
* Impacted Platforms: [ATF]

## Introduction

The main aim of this proposal is to update common modules of test scripts.

## Motivation

User modules consist of commonly used functions.

Current downsides are:
 - No single standard
 - Duplicates
 - Lack of description
 - A lot of outdated or unused code

## Proposed solution

To Do:
 - Design a standard template for common functions
 - Split all functions into two groups: Utils and Common sequences
 - Split these two huge groups between a few modules (based on functionality)
 - Update all existing test scripts

## Potential downsides

Existing test scripts may need to be updated if some funtion from new common modules is required

## Impact on existing code

Since new common modules is going to be implemented in a new separate folder there will be no impact on existing code.

## Alternatives considered

No alternatives considered

