# Add a mechanism to avoid Deadlock

* Proposal: [SDL-NNNN](NNNN-Avoid-Deadlock.md)
* Author: [Yuki Shoda](https://github.com/Yuki-Shoda)
* Status: Awaiting review
* Impacted Platforms: [iOS]

## Introduction
This proposal is to avoid deadlock by adding a mechanism that stops Audio Streaming under certain conditions when the app on HS side moves to background.

## Motivation
In a combination of HU, which uses SDL Core4.5,  and sdl_ios (v6.3.1 or later), a DeadLock may occur when AudioStreaming is played while VideoStreaming is stopped.
Due to this support (https://github.com/smartdevicelink/sdl_ios/pull/1235/) in the current sdl_ios (v6.3.1 or later),  AudioStreaming continues to play when the app on HS side moves to Background.
For this reason (#1235), a deadlock may occur.
To avoid the deadlock, it is desirable to add a mechanism where the protocol version is judged by the Proxy and stops AudioStreaming when the app on HS side move to background.

## Proposed solution
The protocol version is checked by the proxy, when the app on the HS side moves to background. If the protocol version is 5.0.0 or older, then AudioStreaming is stopped.

## Potential downsides
None

## Impact on existing code
There is only changes in code due to the added function, and does not affect the existing code.

## Alternatives considered
- Update the modified SDL Core to HU
-> It will be difficult because update to HU is not realistic.

- Add an API, which sets whether to use AudioStreaming on the app side or not, to the library and supported by each app vendor
-> Deadlock will still occur in unsupported app because there is no enforcement force.
