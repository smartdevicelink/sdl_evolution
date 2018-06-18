# Broaden Choice Uniqueness

* Proposal: [SDL-NNNN](NNNN-broaden-choice-uniqueness.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Awaiting review**
* Impacted Platforms: [Core / iOS / Android]

## Introduction

This proposal broadens choice and sub-menu uniqueness to allow `PerformInteraction` and sub-menu `AddCommand` primary text to be identical. 

## Motivation

Currently `PerformInteraction` choices and sub-menu `AddCommand`s must have unique primary text (Choice.menuName, AddCommand.menuParams.menuName), however, this is an unnecessary and harmful restriction that should be lifted. For example, if a POI or Navigation app wishes to display a list of nearby restaurants, they cannot use the primary text for the restaurant name if there are multiple "McDonalds" restaurants. This restriction is harmful to the usability of such apps.

## Proposed solution

The primary text is not used as any sort of a key (the `choiceId` / `cmdId` is), and so this restriction can be removed in Core's code. The choice set managers must then also be updated to work in a backwards compatible manner with the lifting of this restriction.

## Potential downsides

The author could find no downsides. No RPC changes are necessary.

## Impact on existing code

Android and iOS may have to update documentation and perform updates to the choice set managers to account for this restriction on some head units but not others.

## Alternatives considered

No alternatives were identified.