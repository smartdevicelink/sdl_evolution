# Sequentially Send Multiple RPCs - iOS

* Proposal: [SDL-0087](0087-send-multiple-rpcs-ios.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **In Review**
* Impacted Platforms: iOS

## Introduction

This proposes to add an API allowing the developer to sequentially send multiple RPCs and to be notified when all have completed sending.

## Motivation

There are times that the developer may not care about the results of individual RPC sends, and / or may need to send a number of RPCs and cares when the whole lot have completed sending. This is currently frustrating and difficult as all the RPCs must be sent individually, and there is no API for knowing when all have completed.

## Proposed solution

The solution is to add a few new methods to `SDLManager`:

```objc
/**
 A completion handler called after a sequential or simultaneous set of requests have completed sending.

 @param success True if every request succeeded, false if any failed. See the progress handler for more details on failures.
 */
typedef void (^SDLMultipleRequestCompletionHandler)(BOOL success);

/**
 A handler called after each response to a request comes in in a multiple request send.

 @param request The request that received a response
 @param response The response received
 @param error The error that occurred during the request if any occurred.
 @param percentComplete The percentage of requests that have received a response
 @return Return NO to cancel any requests that have not yet been sent. This is really only useful for a sequential send (sendSequentialRequests:progressHandler:completionHandler:). Return YES to continue sending requests.
 */
typedef BOOL (^SDLMultipleRequestProgressHandler)(__kindof SDLRPCRequest *request, __kindof SDLRPCResponse *response, NSError *__nullable error, float percentComplete);

/**
 Send all of the requests given as quickly as possible, but in order. Call the completionHandler after all requests have either failed or given a response.

 @param requests The requests to be sent
 @param progressHandler A handler called every time a response is received
 @param completionHandler A handler to call when all requests have been responded to
 */
- (void)sendRequests:(NSArray<SDLRPCRequest *> *)requests progressHandler:(nullable SDLMultipleRequestProgressHandler)progressHandler completionHandler:(nullable SDLMultipleRequestCompletionHandler)completionHandler;

/**
 Send all of the requests one at a time, with the next one going out only after the previous one has received a response. Call the completionHandler after all requests have either failed or given a response.

 @param requests The requests to be sent
 @param progressHandler A handler called every time a response is received
 @param completionHandler A handler to call when all requests have been responded to
 */
- (void)sendSequentialRequests:(NSArray<SDLRPCRequest *> *)requests progressHandler:(nullable SDLMultipleRequestProgressHandler)progressHandler completionHandler:(nullable SDLMultipleRequestCompletionHandler)completionHandler NS_SWIFT_NAME(sendSequential(requests:progressHandler:completionHandler:));
```

### Internals

Internally, this has not yet been implemented, so at best the following is a guess of how the above interface will be implemented. A new private class, `SDLSendRPCRequestOperation` (subclassing `NSOperation`) will be created to encapsulate the code for sending multiple RPC requests. This will execute on an `NSOperationQueue`, very similarly to the `SDLFileManager`'s method of managing file uploads. Each will contain an internal queue of RPC requests, and will send them depending on whether it is `sendRequests:` or `sendSequentialRequests:` (for the difference, read the code documentation above). This operation will then call the progress handler and completion handler as appropriate. The operation makes this highly encapsulated and modular.

## Potential downsides

There are no major downsides to this proposal. It is a set of convenience additions to make developers code easier and simpler. It will be somewhat complex code, but it would be better for us to develop it than to have developers need to re-implement every time.

## Impact on existing code

This is a purely additive change and will have no impact on existing developers. This would be a minor version change.

## Alternatives considered

There are no alternatives to this approach. There could be suggestions for changes to the API, which I would welcome debate on if needed.
