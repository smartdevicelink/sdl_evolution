# SDL iOS Move RPC Notifications to a Serial Background Queue

* Proposal: [SDL-0112](0112-ios-serial-rpc-notifications.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Accepted with Revisions**
* Impacted Platforms: iOS

## Introduction

This proposal seeks to move iOS RPC notifications from being sent on the main thread to a serial background queue.

## Motivation

Currently, RPC `NSNotification`s which are used for RPC responses and notifications, use the main thread to notify SDL and the developer of their arrival. This results in most of SDL running on the main thread as the developer will generally do all of their logic in the thread which the RPC is returned on. This isn't a huge issue unless many RPCs are being returned simultaneously or the UI thread is doing a lot of work. Unfortunately, this is exactly what is happening during many video streaming situations.

## Proposed solution

This proposal ensures that RPC reception is entirely off the main thread, this should improve speed, especially in resource constrained conditions such as video streaming (which must often run on the main thread) because it can run on a separate CPU core.

`SDLNotificationDispatcher` creates a new property with a concurrent queue:

```objc
_rpcResponseQueue = dispatch_queue_create("com.sdl.rpcNotificationQueue", DISPATCH_QUEUE_SERIAL);
```

Posting of notifications changes from:

```objc
dispatch_async(dispatch_get_main_queue(), ^{
```

to:

```objc
dispatch_async(_rpcResponseQueue, ^{
```

## Potential downsides

1. If there is code that previously assumed to run on the main thread, it no longer will and that code will have to manually change queues back to the main queue for that code (e.g. UI code).

## Impact on existing code

The rest of the SDL library continues to run without significant alteration, just with a significant speed up. Some UI lockscreen code that previously was always automatically run on the main thread has to be manually moved there. Nothing within this proposal requires a minor or major version change.

## Alternatives considered

1. Move the responses to a background concurrent queue instead of a serial queue. This was the original proposal. It would offer additional performance benefits, but at too great a risk to out of order events that must be serialized – such as audio pass thru notifications.
