# Add a Mechanism to Avoid Deadlock

* Proposal: [SDL-0299](0299-Avoid-Deadlock.md)
* Author: [Yuki Shoda](https://github.com/Yuki-Shoda)
* Status: **Returned for Revisions**
* Impacted Platforms: [iOS]

## Introduction
This proposal is to avoid deadlock by adding a mechanism that stops Audio Streaming under certain conditions when the app on Handset (HS) side moves to background.

## Motivation
When using SDL Core 4.5, and SDL iOS (v6.3.1 or later), a deadlock may occur when Audio Streaming is played while Video Streaming is stopped.
Due to this support (https://github.com/smartdevicelink/sdl_ios/pull/1235/) in the current SDL iOS (v6.3.1 or later),  Audio Streaming continues to play when the app on HS side moves to background.
For this reason (#1235), a deadlock may occur.
To avoid the deadlock, it is desirable to add a mechanism where the negotiated RPC spec version is judged by the Proxy and stops Audio Streaming when the app on HS side moves to background.

## Proposed solution
The negotiated RPC spec version and the manufacturer name are checked by the proxy, when the app on the HS side moves to background. If the negotiated RPC spec version is 5.0 or older and the manufacturer name is not `Ford`, then Audio Streaming is stopped.

## Potential downsides
None

## Impact on existing code
This will be a minor version change to the iOS Library.

## Alternatives considered
- Update the modified SDL Core to HU
-> It will be difficult because updating the HU is not realistic.

- Add an API, which sets whether to use AudioStreaming on the app side or not, to the library and supported by each app vendor
-> Deadlock will still occur in unsupported apps because there is no way to enforce.
