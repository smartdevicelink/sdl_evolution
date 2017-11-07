# ATF Script Runner

* Proposal: [SDL-NNNN](NNNN-atf-script-runner.md)
* Author: [Dmytro Boltovskyi](https://github.com/dboltovskyi)
* Status: **Awaiting review**
* Impacted Platforms: [ATF]

## Introduction

Originally ATF was developed for SDL developers and thats why it lacks a few features of modern Test Frameworks
(Java jUnit, Python Nose, etc.)

The purpose of this proposal is to develop extended script runner as part of ATF functionality.

## Motivation

Currently ATF is unable to:

  - run multiple test scripts
  - run test script in parallel
  - create test reports in standard format

## Proposed solution

Develop script runner with the following features:

  - Ability to run single test script
  - Ability to run batch of test scripts
  - Ability to run test set
  - Possibility to run scripts in parallel
  - Ability to create reports in standard format with logs collected

## Potential downsides

Existing CI jobs needs to be reconfigured in order to use new script runner.

## Impact on existing code

No impact on existing code is observed.

## Alternatives considered

Use one of the existing test runners, e.g. Python Nose, PyTest etc.
