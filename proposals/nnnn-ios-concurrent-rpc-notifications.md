# SDL iOS Move RPC Notifications to a Concurrent Background Queue

* Proposal: [SDL-NNNN](NNNN-ios-concurrent-rpc-notifications.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Awaiting review**
* Impacted Platforms: iOS

## Introduction

This proposal seeks to move iOS RPC notifications from being sent on the main thread to a concurrent background queue.

## Motivation

Currently, RPC `NSNotification`s which are used for RPC responses and notifications, use the main thread to notify SDL and the developer of their arrival. This results in most of SDL running on the main thread as the developer will generally do all of their logic in the thread which the RPC is returned on. This isn't a huge issue unless many RPCs are being returned simultaneously or the UI thread is doing a lot of work. Unfortunately, this is exactly what is happening during many video streaming situations.

## Proposed solution

This proposal ensures that RPC reception is entirely off the main thread, and making it concurrent means that developers will respond to RPC responses and notifications concurrently, vastly improving speed, especially in resource constrained conditions such as video streaming (which must often run on the main thread).

`SDLNotificationDispatcher` creates a new property with a concurrent queue:

```objc
_rpcResponseQueue = dispatch_queue_create("com.smartdevicelink.rpcNotificationQueue", DISPATCH_QUEUE_CONCURRENT);
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

1. The primary potential downside lies in if a developer is counting on the code being serial. Because SDL is inherently asynchronous, this issue is significantly mitigated. In other words, the developer should already know that just because they sent one RPC before another does not necessarily mean they will receive the response of RPC 1 before RPC 2. The likelihood of this happening, while still high, is diminished in the new code, and if developers are counting on it, this could be an issue.

  * An important caveat must be placed here, this **does not** mean that the remote system will receive requests out of order, or that the SDL library will process them out of order, just that at the last point in the chain, the developer may receive them out of order.

2. If the developer is assuming that several RPC callbacks all happen on the same thread, they no longer will. Therefore, they will have to run synchronization code themselves.

  * This is an unlikely requirement for the developer, and easy for them to workaround (by doing their own synchronization) if necessary.

These caveats are not considered to overcome the benefit provided by this change. This change greatly speeds up SDL integrations and is, in nearly all cases, invisible to the developer. We have tested with a large, complex integration which needed no code changes and experienced an immediately noticable speed increase.

## Impact on existing code

The rest of the SDL library continues to run without significant alteration, just with a significant speed up. Some UI lockscreen code that previously was always automatically run on the main thread has to be manually moved there. Nothing within this proposal requires a minor or major version change.

## Alternatives considered

1. Move the responses to a background serial queue instead of a concurrent queue. This will force response notifications to be fired in order, with one completing before another happens (like it does now, but on a background thread instead of the main thread). This was seriously considered, but the additional performance benefit of concurrent usage was considered to be more beneficial than any potential downsides.