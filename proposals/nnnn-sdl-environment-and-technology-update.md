# Feature name

* Proposal: [SDL-NNNN](nnnn-environment-and-technology-update.md)
* Author: [Maxim Ghiumiusliu](https://github.com/smartdevicelink/mghiumiusliu)
* Status: **Awaiting review**
* Impacted Platforms: Core

## Introduction

Supported version of Ubuntu and used technologies must advance.

## Motivation

Currently part of the code in SDL is hand made due to limitation on compiler version.

List of required features:
- Move semantics and rvalue reference.
  - Move constructors and assignment operators.
  - Emplace methods in the standard containers as vector::emplace_back, etc.
- Variadic templates
- Initializer list
- Static assertion
- Auto typed variables
- SFINAE
- Strongly typed enums
- Default and deleted function
- smart pointers - std::unique_ptr and std::shared_ptr

Future development of SDL also requires usage of advanced tools to introduce innovations into SDL development process.
Starting from 1.56.0 boost supports QNX with QCC 4.4.2.
Following are feature of BOOST which might be very helpful:
- boost::shared_ptr
- boost::file_system
- boost::date/time

## Proposed solution

TBD

## Detailed design

TBD

## Impact on existing code

TBD

## Alternatives considered

TBD
