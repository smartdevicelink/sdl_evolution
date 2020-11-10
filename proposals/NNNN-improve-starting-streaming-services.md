# Improve starting streaming services

* Proposal: [NNNN](NNNN-improve-starting-streaming-services.md)
* Author: [Kujtim Shala](https://github.com/smartdevicelink/kshala-ford)
* Status: **Awaiting review**
* Impacted Platforms: [ iOS / Java Suite / JavaScript Suite ]

## Introduction

In the process of analyzing mobile navigation streaming issues, we have identified several issues and unaligned implementations between SDL Core and the app libraries. This proposal addresses difficulties to handle failed `StartService` attempts for video and audio services including:
1. synchronizing `StartService` requests
2. resetting SSL connection upon failures
3. retrying mechanism for starting services

## Motivation

With current SDL implementation, if the app sends `StartService` with `encrypted=1` and Core's `SSLMode` is set to `CLIENT`, Core starts a TLS handshake to authenticate the app which is required to send encrypted data on the service session. If this service is successfully started, Core will remember the handshake for the current transport connection. If Core receives a second `StartService` request with `encrypted=1` it will not restart another TLS handshake. However, if the first `StartService` failed, Core will reset the SSL connection and restart a TLS handshake for the next `StartService` request.

The video and audio streaming managers of the SDL app libraries try to start their service sessions concurrently, which is a challenge to synchronize with the security manager's SSL connection. The security manager can be seen as a single resource where its access needs to be synchronized. Properly recovering from issues when the system fails to establish secured service sessions is very difficult. The SSL connection cannot be restarted safely if another `StartService` request was sent.

The service can fail for many different reasons. Possible failure reasons can be:
- a missing permission due to missing policy update
- invalid certificates pending to be updated
- discrepancy in clock time causing handshake to fail

With the procedure of starting services being synchronized and the ability to reset SSL connections, a retry mechanism can be established to improve the user experience launching apps especially for mobile navigation.

## Proposed solution

The solution is to synchronize attempts to start services so that only one starting service is processing. This is essential for services which require encryption/protection as those initiate a TLS handshake on the app's transport session. If the library should start a protected service, it has to ensure the responsible security manager is started. If the attempt to establish a protected service failed due to a `StartServiceNAK`, the library must reset the SSL connection of the security manager instance. This can be done by stopping the security manager. It should be automatically restarted upon the next `StartService` request. This ensures a fluent operation of the security manager across any protected service (including RPC). The next request must not be sent within two seconds after the previous attempt failed to avoid unnecessary load for the IVI.

If the app enters a streamable state (reentered `HMI_FULL` and/or `OnHMIStatus.videoStreamingState` is `STREAMABLE`) the library starts the video manager first followed by the audio manager. If the video manager received NAK for the video service, the library should not start the audio manager's audio service. Instead, the library should retry the video service after two seconds of waiting and hold back the audio manager from starting. No other `StarService` request should be sent during this time. The infinite retry method is justified due to the app being in a streamable state (`HMI_FULL` etc.). No other application would be interfering during this time unless the app leaves the streamable state. 

The library should retry until the app leaves the streamable state. If the app left the streamable state during the two seconds, the library must prevent sending the `StartService` request and stop the retry process.

## Potential downsides

In certain situations where the retry mechanism occurs, the proposed solution can increase the time until the app has started the video and audio stream for up to two seconds. However, the app libraries gain a lot of stability for error cases, which is much more valuable.

It can be possible that this retry mechanism puts some stress on existing infotainment systems as they were never tested against this method. However, the current behavior of the app libraries to stop after one failure would leave the user in an unacceptable state with a non-functional app. Therefore a retry mechanism can only improve the user experience.

## Impact on existing code

The proposal doesn't change when the video or audio manager becomes streamable. The app library should still listen for SDL Core information when the app becomes streamable. This proposal only synchronizes `StartService` requests and adds a retry mechanism to overcome failed attempts.

All app libraries require changes on the video and audio managers. Instead of actively sending `StartService` requests, both managers have to wait for another source to trigger the starting routine. The implementation details are up to the SDLC Project Maintainer and the implementers. The iOS library already contains a general streaming manager called `SDLStreamingMediaManager` which could take the role of starting the video and audio manager. A similar manager could be added to the Java Suite and JavaScript Suite libraries, taking over the responsibilities from the SDL manager.

It is necessary to properly test starting the handshake process every two seconds. Numerous Ford IVIs were tested with one second of delay. Faster attempts caused SDL Core crashes on the IVI resulting in no app support whatsoever. It is possible that RPCs or a policy update can increase the stress as well and could cause crashes even with >1 second of delay. In rare cases, testing showed undefined behavior with one second of delay if the app is also sending voice commands or choice sets. More testing is needed to gain confidence of a faster retry mechanism. New head units should be tested against one second as well to ensure that the retry delay can be reduced in future. Other SDLC members who use SDL security should also make sure their IVIs are supporting the retry mechanism.

## Alternatives considered

The SDL protocol implementation in the app libraries can be synchronized with a lock, mutex or semaphore allowing only one secured `StartService` attempt. This method was not considered as the main solution because such locks generally block an entire thread and they require logic for cancellation. The main solution is considered to be more aligned with the SDL app libraries current implementations and the state machines.

An alternative to the infinite retry mechanism is to limit the retries to N times and increase the wait delay over time to avoid unnecessary stress to the infotainment system. This alternative is at the cost of a good user experience and more delay.
