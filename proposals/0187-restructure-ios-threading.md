# Restructure iOS Threading and Queueing

* Proposal: [SDL-0187](0187-restructure-ios-threading.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **In Review**
* Impacted Platforms: iOS

## Introduction

This change targets the iOS library and restructures the existing threading / asynchronicity into a more manageable, consistent, and understandable system.

## Motivation

The approach to threading in the iOS library has so far been fairly arbitrary. New queues are created as needed, and they are held in various locations. As the manager systems have become more complex, code executing on queues has begun targeting other queues, we have begun using higher-level operation queues, callbacks have occurred for the developer on various queues, and in general the system has become much more complex. 

We should simplify and restructure our threading approach in order to make the library more maintainable into the future.

## Proposed solution

(Note the below solution is heavily dependent on understanding iOS threading, particularly the `libdispatch` system)

To remedy this situation, I recommend using an "execution context" approach to queueing and reducing the number of separate "base" queues we use. [This blog post](https://gist.github.com/tclementdev/6af616354912b0347cdf6db159c37057) gives some tips gleaned from the knowledge of the `libdispatch` maintainer at Apple. We should try to reduce the number of separate queues we use and instead have queues targeting our few "deeper" queues.

### Execution Contexts

The proposed execution contexts are:

* Serial Queue "com.sdl.transport" - protocol and transport related code outside of the actual transmission threads.
* Serial Queue "com.sdl.processing.serial" - general SDL related code, including logging, RPC processing, lifecycle, etc.
* Concurrent Queue "com.sdl.processing.concurrent" - general SDL processes that await callbacks, such as sending RPCs, will occur in this queue, otherwise we would be blocked from doing any work on the serial processing queue while waiting for RPC responses from the head unit.
* Serial Queue "com.sdl.callback" - All callbacks to the developer will occur on this queue

Additional queues may be (and will be) created, however, they should use an underlying queue of one of the 4 above execution context queues.

We should begin preferring `NSOperationQueue` above large stretches of `dispatch_async` code, especially those that run a fair amount (I'm thinking of the `SDLTouchManager` currently, though that may be too intensive for the additional overhead of `SDLTouchManager`).

These queues will run with the `userInitiated` QOS and will be set into `SDLGlobals` for use everywhere.

## Potential downsides

Restructuring threading can be complex, and as we try to reduce the number of queues we're using, and therefore the number of threads, we will need to be careful to measure performance in complex apps (including video streaming & touch) in order to make sure we are seeing at minimum consistent performance, though I would expect an improvement. This will be a significant amount of work to audit and ensure we are consistently dispatching to the right queues and preventing deadlocks.

## Impact on existing code

This will not make any public API changes, however, it restructures the internals enough that, even though this is in some sense maintenance and a bug, it should be addressed with a proposal.

## Alternatives considered

* We could try to move more entirely into `NSOperationQueue`, however, some of our work doesn't make sense in that context.
