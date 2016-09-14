# iOS Library Remove Siphon Server
* Proposal: [SDL-NNNN](NNNN-filename.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Awaiting review**
* Impacted Platforms: iOS

## Introduction
This proposal is to make major changes by removing the "siphon server" aspect from the SDL libraries.

## Motivation
The siphon server is a legacy piece that is Ford proprietary (that is, only Ford employees can use it) which allows them to view SDL logs on a Windows (only) computer over a TCP connection. This feature should be removed for a variety of reasons. First, the feature is proprietary to Ford, and this is an open-source project. Second, this feature has been superceded by the Relay app, which does the same job much better. Third, after asking about this feature among Ford employees, half didn't know what it was and the other half hadn't used it in a long time.

## Proposed Solution
The proposed solution is simply to remove it and not replace it. The Relay app captures the same use case (a desire to see logs while connected to a physical head unit over USB IAP) while doing the job much better. For example, the Relay app allows the use of debugging with breakpoints, and as of iOS 10 + macOS Sierra, a variety of additional `os_log` tools. Further improvements could be made in SDL logging to improve for example, filtering and sorting to match what exists in iOS 10 + macOS Sierra.

## Potential Downsides
The only downside is that the better debugging capabilities of Relay requires the app to be built in Xcode. This means that another company could not provide Ford with an app with Siphon turned on for Ford to debug. However, since this is a proprietary solution, it should nonetheless be removed until, if needed, it is replaced with an open solution. iOS 10's new logging would allow us to pass around `.logarchive` files to try to debug that way, if necessary, however, iOS 10's very good new logging APIs would need to be implemented, and they only work on iOS 10+ and macOS Sierra+ devices.

## Impact on existing code
This would be a major change removing several public files and methods.

## Alternatives considered
We could leave it as is, but this is judged to be a poor option.
