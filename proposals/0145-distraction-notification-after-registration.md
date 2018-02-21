# Driver Distraction Notification Upon Registration

* Proposal: [SDL-0145](0145-distraction-notification-after-registration.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **In Review**
* Impacted Platforms: [Core]

## Introduction

This document proposes that Core send an additional Driver Distraction Notification just after registration to ensure that the mobile device knows the distraction status at all times.

## Motivation

Currently, apps have no way of knowing the driver distraction status until it changes. This forces the mobile libraries to initially consider it locked.

## Proposed solution

The proposed solution is very simple. Immediately after an app registers, Core should send that app an `OnDriverDistraction`. We already do this with `OnHMIStatus`, for example.

## Potential downsides

The author can think of no potential downsides.

## Impact on existing code

This should not require even a minor version change.

## Alternatives considered

1. It could happen at a different time, for example, after an app reaches its first non-`NONE` HMI state.
