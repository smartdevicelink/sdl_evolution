# Updating Mobile Version Dependencies

* Proposal: [SDL-0146](0146-updating-mobile-version-dependencies.md)
* Author: [Joel Fischer](https://github.com/joeljfischer), [Joey Grover](https://github.com/joeygrover)
* Status: **Accepted with Revisions**
* Impacted Platforms: [Meta]

## Introduction

This proposal sets a meta requirement on when mobile platform dependencies should be updated.

## Motivation

We've updated the base iOS platform dependency version in the past and it was agreed that we need a stricter set of rules on when platform dependency updates should occur.

## Proposed solution

The proposed solution is the following guideline:

* If a platform dependency update would cover 90% of users, a proposal may be entered with reasons for the update and the proposal considered. If a proposed version would not cover 90% of users, no proposal may be entered.

The [Android platform versions website](https://developer.android.com/about/dashboards/index.html) and [iOS platform versions website](https://developer.apple.com/support/app-store/) are to be used for making these determinations.

### Android
So, for example, if a proposal is entered and accepted, this guideline means that v4.4 (94.3% usage) is the highest version permitted to be the base Android platform version.

### iOS
This guideline means that iOS 10 is the highest version permitted to be the base iOS platform version (iOS 10 has greater than 93% usage).

## Potential downsides

None the authors can see.

## Impact on existing code

This is a meta change, no code will be impacted.

## Alternatives considered

Various other methods could be used to determine version updates.
