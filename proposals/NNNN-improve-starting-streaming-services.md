# Improve starting streaming services

* Proposal: [NNNN](NNNN-improve-starting-streaming-services.md)
* Author: [Kujtim Shala](https://github.com/smartdevicelink/kshala-ford)
* Status: **Awaiting review**
* Impacted Platforms: [ iOS / Java Suite ]

## Introduction

In the process of analyzing issues around mobile navigation apps not connecting properly we have identified several issues and unaligned implementations between SDL Core and the libraries. This proposal addresses difficulties to handle failed `StartService` attempts for video and audio services including
1. synchronizing `StartService` requests
2. reset SSL connection upon failures
3. retry mechanism for starting services

## Motivation

With current SDL implementation, Core starts a TLS handshake if Core's `SSLMode` is set to `CLIENT` and the app sends `StartService` with `encrypted=1` for a service which requires protection. If this service is successfully started, Core will remember the handshake for the current transport connection. If Core receives a second `StartService` request with `encrypted=1` it will not restart another TLS handshake. However, if the first StartService failed, Core will reset the SSL connection and restart a TLS handshake for the second `StartService` request.

The video and audio streaming managers of the SDL libraries try to start their service sessions concurrently which is a challenge to synchronize with the security manager's SSL connection. The security manager can be seen as a single resource where it's access need to be synchronized. Properly recovering from issues when the system fails to establish secured service sessions is very difficult. The SSL connection cannot be restarted safely if another `StartService` request was send. 

Once the managers are synchronized and the SSL connection can be restarted upon failures, a retry mechanism can be established to improve the user experience launching especially mobile navigation apps.

## Proposed solution

The solution is to have the general streaming manager be responsible for when the video and audio streaming manager should be started. It should start the video manager first followed by the audio manager allowing the library's SDL protocol implementation to safely start the security manager. If one manager fails to establish a secured service session, the SDL protocol implementation must stop the security manager instance to reset the SSL connection. 

If the video manager failed to start the service session the general streaming manager should not continue with the audio manager. Instead the general streaming manager should abort the current starting attempt, wait for one second and then retry starting with the video manager again. This retry mechanism should stop after 5 unsuccessful attempts and the general streaming manager should stop the video and audio manager and the security manager. Once the app reenters a streamable state (reentered `HMI_FULL` and/or `OnHMIStatus.videoStreamingState` is `STREAMABLE`) the general streaming manager should reattempt starting the managers and repeat the retry mechanism if needed.

## Potential downsides

The proposed solution may minimally increase the time by a few milliseconds until the app has started the video and audio stream due to `StartService` being send sequentially. However, the libraries gain a lot of stability for error cases which is much more valuable.

## Impact on existing code

The proposal doesn't change when the video or audio manager becomes streamable. Both managers should still listen for SDL Core information when they become streamable. This proposal only changes when the managers eventually start the service sessions.

Both libraries require changes on the video and audio managers. Instead of actively sending `StartService` requests both managers have to wait for another source to trigger the starting routine. The implementation details are up to the project maintainers and the implementors but the author's recommendation is to have the video and audio manager inform the general manager when they are ready to be started. This way almost the the entire existing implementation could remain. Still, this should be seen as an implementation detail.

The iOS library already contains a general streaming manager called `SDLStreamingMediaManager` which could take the role of starting the video and audio manager.

A similar manager should be added to the Java Suite taking over the responsibilities from the SDL manager.

## Alternatives considered

The SDL protocol implementation in the libraries can be synchronized with a lock, mutex or semaphore allowing only one secured `StartService` attempt. This method was not considered as the main solution because such locks generally block an entire thread and they require logic for cancellation. The main solution is considered to be more aligned with the SDL library implementation and the state machines.
