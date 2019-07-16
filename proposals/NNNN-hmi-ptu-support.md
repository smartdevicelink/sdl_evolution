# HMI Policy Table Update using vehicle modem

* Proposal: [SDL-NNNN](NNNN-hmi-ptu-support.md)
* Author: [SDL Developer](https://github.com/kshala-ford)
* Status: **Awaiting review**
* Impacted Platforms: [Core / HMI]

## Introduction

This proposal describes an enhanced policy table update sequence where policy snapshots are sent by the HMI directly using the system (in-vehicle) modem.

## Motivation

SDL core doesn't expect the system to be capable of a direct policy update using the system (in-vehicle) modem. As of today it is waiting for an HMI system request.

## Proposed solution

The solution is to ensure Core accepts policy table updates from the HMI without a prior system request sent to mobile apps.

## Potential downsides

Describe any potential downsides or known objections to the course of action presented in this proposal, then provide counter-arguments to these objections. You should anticipate possible objections that may come up in review and provide an initial response here. Explain why the positives of the proposal outweigh the downsides, or why the downside under discussion is not a large enough issue to prevent the proposal from being accepted.

## Impact on existing code

Describe the impact that this change will have on existing code. Will some SDL integrations stop compiling due to this change? Will applications still compile but produce different behavior than they used to? Is it possible to migrate existing SDL code to use a new feature or API automatically?

## Alternatives considered

Describe alternative approaches to addressing the same problem, and why you chose this approach instead.
