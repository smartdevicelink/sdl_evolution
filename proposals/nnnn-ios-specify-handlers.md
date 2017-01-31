# Increase Specificity of Handler Events

* Proposal: [SDL-NNNN](nnnn-ios-specify-button-events.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Awaiting review**
* Impacted Platforms: iOS

## Introduction
The purpose of this proposal is to make notification handlers more specific. Currently, the developer is required to know how to cast a notification parameter within the handler in order to properly use that notification. This proposal changes handlers to provide greater specificity on all RPCs that support them, as well as to separate out button handlers into two separate types. This will involve major version changes to remove old versions of the handlers that will no longer be supported.

## Background
Handlers are a concept introduced in SDL iOS v4.3 as a method of adding lambdas, known as blocks in Obj-C, to specific types of notifications so that a developer does not have to do the hard work of correlating these two concepts. So, a developer could add a handler to a Soft Button, for example, at the time he creates the RPC, and that code within the handler will be run when an event happens to the soft button, such as a button press.

## Motivation
Currently, handlers are rather generic and in some cases, quite confusing. There is currently only one type of handler, and only one handler is allowed. The current API makes use of a protocol `SDLRequestHandler` to specify which RPCs support handlers.

```objc
@protocol SDLRequestHandler <NSObject>

/**
 *  The handler that is added to any RPC implementing this protocol.
 */
@property (nullable, copy, nonatomic) SDLRPCNotificationHandler handler;

/**
 *  A special init function on any RPC implementing this protocol.
 *
 *  @param handler The handler to be called at specified times, such as events for buttons.
 *
 *  @return An instance of the class implementing this protocol.
 */
- (instancetype)initWithHandler:(nullable SDLRPCNotificationHandler)handler;

@end
```

However, this protocol is never really used for anything outside of defining what handlers look like on RPCs. This forces all RPCs supporting handlers to be generic, being defined as the following:

```objc
typedef void (^SDLRPCNotificationHandler)(__kindof SDLRPCNotification *notification);
```

The developer must be aware of what subclass of `SDLRPCNotification` will be passed into the handler he is dealing with, cast it, and then use it. In some cases, such as with buttons, there could be multiple different subclasses of `SDLRPCNotification` that could get passed: `SDLOnButtonPress` and `SDLOnButtonEvent`. This means the developer must check for each case, even if he only ever cares about one of them (and most will only ever care about `SDLOnButtonPress`).

This situation can lead to confusion and questions, and we should try to clarify if possible.

## Proposed solution
The proposed solution is to scrap `SDLRequestHandler` and `SDLRPCNotificationHandler` and to provide more specific handlers on each RPC that supports them.

The current list of RPC classes the support a handler are:
```
SDLAddCommand
SDLSoftButton
SDLSubscribeButton
```

```objc
typedef void (^SDLRPCNotificationHandler)(__kindof SDLRPCNotification *notification);
```

will be replaced with three different handlers:

```objc
typedef void (^SDLRPCCommandNotificationHandler)(SDLOnCommand *notification);
typedef void (^SDLRPCButtonEventNotificationHandler)(SDLOnButtonEvent *notification);
typedef void (^SDLRPCButtonPressNotificationHandler)(SDLOnButtonPress *notification);
```

The first will apply to `SDLAddCommand`, the latter two to `SDLSoftButton` and `SDLSubscribeButton`.

### SDLAddCommand
SDLAddCommand currently has several init methods:

```objc
- (instancetype)initWithHandler:(nullable SDLRPCNotificationHandler)handler;

- (instancetype)initWithId:(UInt32)commandId vrCommands:(nullable NSArray<NSString *> *)vrCommands handler:(nullable SDLRPCNotificationHandler)handler;

- (instancetype)initWithId:(UInt32)commandId vrCommands:(nullable NSArray<NSString *> *)vrCommands menuName:(NSString *)menuName handler:(SDLRPCNotificationHandler)handler;

- (instancetype)initWithId:(UInt32)commandId vrCommands:(nullable NSArray<NSString *> *)vrCommands menuName:(NSString *)menuName parentId:(UInt32)parentId position:(UInt16)position iconValue:(NSString *)iconValue iconType:(SDLImageType)iconType handler:(nullable SDLRPCNotificationHandler)handler;
```

Each of the `SDLRPCNotificationHandler` parameters will be replaced with an `SDLRPCCommandNotificationHandler` parameter instead. It also has a public `SDLRPCNotificationHandler` property:

```objc
@property (nullable, copy, nonatomic) SDLRPCNotificationHandler handler;
```

This will also be replaced with an `SDLRPCCommandNotificationHandler` property.

### SDLSubscribeButton and SDLSoftButton
These classes also have init methods with handlers, however, because the handler for these classes will be split into two handlers, one for `SDLOnButtonPress` and one for `SDLOnButtonEvent`, only the `SDLRPCButtonPressNotificationHandler` will be present in init methods because it is the far more common use case. Both `SDLRPCButtonPressNotificationHandler` and `SDLRPCButtonEventNotificationHandler` will be present as properties, however, so developers may still use whichever they wish.

## Impact on existing code
This is a major version change as a result of removing the existing `SDLRPCNotificationHandler` block and `SDLRequestHandler` protocol and altering the `init` methods of the classes implementing the handlers. Developers would have to switch to using the more specific blocks and would have to remove some of their code that involved downcasting the `SDLRPCNotification` into its specific class.

This could be done in two stages, one as a minor change, and the other as a major change, in order to make developers aware of the coming change. This would involve deprecating the existing block, protocol, and methods, and replacing them with the new ones. This would be more complicated to implement, as the code that deals with storing and running the handlers would become somewhat larger and more complicated until the old code was removed.

## Alternatives considered
One alternative considered was adding the new methods to the existing `SDLRequestHandler` protocol as optional, but this was judged as unnecessary and more complicated than removing the unneeded protocol entirely.

The original idea was also to merely update the button handlers to be separated into `onButtonPress` and `onButtonEvent` handlers while leaving the `onCommand` handlers alone, but it was judged that expanding this proposal to more clearly specify `onCommand` handlers as well would be useful for developers.
