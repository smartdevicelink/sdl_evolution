# parameter _enableSeek_ at _SetMediaClockTimer_ RPC

* Proposal: [SDL-NNNN](NNNN-enableSeek_at_SetMediaClockTimer.md)
* Author: [Melnyk Tetiana](https://github.com/TMelnyk)
* Status: **Awaiting review**
* Impacted Platforms: Core / Android / iOS / RPC

## Introduction

The proposal is to support new parameter _enableSeek_ and transfer _OnSeekMediaClockTimer_ notification from HMI to mobile application.

## Motivation

**Required for FORD.**   
**Required additional clarification from FORD.**
A notification will be provided if the user touches (or seeks) to a particular position on the HMI mediaclock timer. The notification will contain a starttime with the position the user has seeked to.

## Proposed solution

SDL transfers _OnSeekMediaClockTimer_ notification from HMI to mobile application independently on value of _enableSeek_ (true or false) parameter at _SetMediaClockTimer_request_.   

## Detailed design

TBD

## Impact on existing code

TBD

## Alternatives considered

TBD
