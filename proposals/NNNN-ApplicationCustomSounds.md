#HMI Custom Sound Application Proposal 
* Proposal: [SDL-NNNN](NNNN-filename.md)
* Author: [Emily Lerner](https://github.com/eslerner)
* Status: **Awaiting review**
* Impacted Platforms: [Web]

## Introduction

This proposal is only intended to bring attention to, and receive feedback on an important SDL question: Should HMI noise ownership be on OEM-side or application team side? In other words, this is a best practice proposal.

This proposal was created considering audible feeback via touch or haptic input during video projection but may apply to much broader applications (use cases: audio cues to the user to signify the start or end of voice recognition, onButtonPress, whenever a sound should be defined so that there are not duplicate sounds). 

## Motivation
We need to define best practice for the current implementation of VPM. 

Right now, OEM’s have chosen specific noises for their respective head units based on tedious customer discovery surveys and testing. Noises selected for in-vehicle purposes minimize driver distraction while providing important customer notifications to maximize HMI user-experience. 

There are cases in applications such as Waze, where application sound notifications serve as powerful branding and marketing tools due to their instantaneous user-recognition. Companies may feel strongly about using their in-house noises for automotive applications. 

Autonomous vehicles move in-vehicle experience from task-assistance to entertainment / personal-assistance.
Increased user focus on in-vehicle applications makes in-vehicle branding noises invaluable. Some epitomical examples of application branded noises include Facebook message noises, Apple iPhone ringtones, and Skype call sounds. 



## Proposed solution

OEM’s shall control all user feedback / haptic noises. 

## Potential downsides

Application design teams may feel a loss of in-vehicle branding opportunity. 

## Impact on existing code

No impact on existing code. 

## Alternatives considered

**Alternative #1:** A handshake shall be created to allow SDL Application Developers to control noises in their respective application. 
RPC’s will need to be defined and structured. This only applies to future implementations of SDL VPM. 

**Alternative #2:** Application shall control all sounds. OEM noises shall not be implemented on 3rd party applications by default. Applications can use the playtone RPC to trigger the HMI if they do not want to use their own sounds. 