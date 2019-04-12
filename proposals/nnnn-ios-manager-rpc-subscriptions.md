# Add iOS SDLManager RPC Subscriptions

* Proposal: [SDL-NNNN](NNNN-ios-manager-rpc-subscriptions.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Awaiting review**
* Impacted Platforms: [iOS]

## Introduction
This proposal improves subscribing to RPC requests, responses, and notifications on proxy platforms.

## Motivation
When developing applications, most of the time you no longer need to directly subscribe to all RPCs of a particular type. This is due to responses being directly tied to a request and the `sendRequest:withResponseHandler:` method (iOS, Android has a close equivalent). However, in some cases, such as RPC notifications, the developer still needs to directly subscribe to the raw request.

Currently, the process on iOS is slightly more cumbersome than on Android. On iOS, you need some "secret knowledge," that all RPC requests, responses, and notifications are posted as iOS `Notification`s through the `NotificationCenter`. However, this is often confusing for developers, and Android has a simpler solution. Their `SDLManager` class has methods `addOnRPCNotificationListener` and `removeOnRPCNotificationListener`. iOS should expose methods like these to make clearer how to listen for a raw RPC.

## Proposed solution
The proposed solution is to add similar methods to the iOS `SDLManager`:

```objc
@interface SDLManager
// Everything already there

typedef void (^SDLRPCUpdatedBlock) (__kindof SDLRPCMessage *, NSError *__nullable error);

/**
 * Subscribe to callbacks about a particular RPC request, notification, or response with a block callback.
 *
 * @param rpcName The name of the RPC request, response, or notification to subscribe to.
 * @param type The type of the RPC you want to subscribe to. While notification `rpcName`s are unique, requests and responses are not. This means that we need to differentiate between them when subscribing.
 * @param block The block that will be called every time an RPC of the name and type specified is received.
 * @return An object that can be passed to `unsubscribeFromRPC:ofType:withObserver:` to unsubscribe the block.
 */
- (id)subscribeToRPC:(SDLRPCFunctionName)rpcName ofType:(SDLRPCMessageType)type withBlock:(SDLRPCUpdatedBlock)block;

/**
 * Subscribe to callbacks about a particular RPC request, notification, or response with a selector callback.
 * 
 * The selector supports the following parameters:
 *
 * 1. One parameter e.g. `- (void)registerAppInterfaceResponse:(SDLRegisterAppInterfaceResponse *)response;`
 * 2. Two parameters e.g. `- (void)registerAppInterfaceResponse:(SDLRegisterAppInterfaceResponse *)response error:(nullable NSError *)error;`
 *
 * Note that using this method to get a response instead of the `sendRequest:withResponseHandler:` method of getting a response, you will not be notifed of any `SDLGenericResponse` errors where the head unit doesn't understand the request.
 *
 * The error will be called if `response.success` is `NO` and will be filled with the info field.
 *
 * @param rpcName The name of the RPC request, response, or notification to subscribe to.
 * @param type The type of the RPC you want to subscribe to. While notification `rpcName`s are unique, requests and responses are not. This means that we need to differentiate between them when subscribing.
 * @param observer The object that will have its selector called every time an RPC of the name and type specified is received.
 * @param selector The selector on `observer` that will be called every time an RPC of the name and type specified is received.
 */
- (void)subscribeToRPC:(SDLRPCFunctionName)rpcName ofType:(SDLRPCMessageType)type withObserver:(id)observer selector:(SEL)selector;

/**
 * Unsubscribe to callbacks about a particular RPC request, notification, or response.
 *
 * @param rpcName The name of the RPC request, response, or notification to unsubscribe from.
 * @param type The type of the RPC you want to subscribe to. While notification `rpcName`s are unique, requests and responses are not. This means that we need to differentiate between them when subscribing.
 * @param observer The object representing a block callback or selector callback to be unsubscribed
 */
- (void)unsubscribeFromRPC:(SDLRPCFunctionName)rpcName ofType:(SDLRPCMessageType)type withObserver:(id)observer;

@end
```

## Potential downsides
This proposal creates a second method of doing the same thing: subscribing to RPCs. We already support using `NotificationCenter`. This second method does not conflict with the first method, but is more complicated to implement. However, it will make it clearer and simpler for developers to implement.

## Impact on existing code
This is a minor version change for the iOS library.

## Alternatives considered
1. We could only provide _either_ a block method _or_ a selector method, but because the API was designed to be close to `NotificationCenter`'s API, we provide both.

2. We could implement an API that mirror's the Android API 1-1. However, the Android API uses very Java syntax that doesn't fit with iOS API or the rest of the iOS SDL library. Additionally, the Android API has two separate methods, one for notifications, and one for other RPCs. That should not be necessary in the iOS library. Finally, this API is similar enough to the Android API to be clear to developers on each platform how they work.