# HMI Application Custom Sounds Proposal 
* Proposal: [SDL-NNNN](NNNN-filename.md)
* Author: [Emily Lerner](https://github.com/eslerner)
* Status: **Awaiting Review**
* Impacted Platforms: [Web]

## Introduction
This proposal is only intended to receive feedback on an important SDL question: 

**Should HMI noise ownership be on the OEM's side or on the Application Team's side?**

**Note:** This proposal was created considering the best practices for audible feeback via touch or haptic input during video projection but may apply to much broader applications (*example use cases: audio cues to the user to signify the start or end of voice recognition, onButtonPress, whenever a sound should be defined so that there are not duplicate sounds*). 

## Motivation
**It is necessary to define the best practices for the current implementation of VPM.**

1. OEM’s have chosen specific noises for their respective head units based on their own research and testing. App partners have done the same in their respective applications. It is important to determine who has ownership for in-vehicle sounds.
2. There are cases in applications such as Waze, where application sound notifications serve as powerful branding and marketing tools due to their instantaneous user-recognition; app-partners may feel strongly about using their in-house noises for automotive applications. 
3. Autonomous vehicles move in-vehicle experience from task-assistance to entertainment / personal-assistance. This increased user focus on in-vehicle applications makes in-vehicle branding noises invaluable *(Facebook message noises, Apple iPhone ringtones, and Skype call sounds)*. 

## Proposed solution

**Application Partners shall control all in-vehicle noises.**

OEM's will not always know what is being projected to the head unit; this will make noise flags, noise triggers, and noise accuracy difficult to handle on the OEM side. This makes Application Partner control advantageous. 

## Potential downsides
1. OEM will not have total control of in-vehicle experience, since app partners will control in-vehicle noises.
2. App Partner may pick a sound that is inappropriate for in-vehicle use *(such as emergency response / natural disaster sirens)*. Best practices for in-vehicle sound should be shared with App Partners. 
3. There could be a problem such as latency in sound *(when the user pressed the button vs. when the sound is actually played)*.

## Impact on existing code
No impact on existing code; applications will handle sound using haptic information. 

## Alternatives considered

**Alternative #1:** 
A handshake shall be created to allow SDL Application Developers to control noises during the use of their respective applications. RPC’s will need to be defined and structured. This only applies to future implementations of SDL VPM.

**Alternative #2:** 
OEM shall control all in-vehicle sounds. This will be difficult since OEM's will not always know what is being projected to the screen during the use of the App-Partner application. This could make for a bad user experience.  
