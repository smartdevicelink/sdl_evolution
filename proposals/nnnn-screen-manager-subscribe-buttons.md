# Screen Manager Subscribe Buttons

* Proposal: [SDL-NNNN](NNNN-screen-manager-subscribe-buttons.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Awaiting review**
* Impacted Platforms: [iOS / Java Suite]

## Introduction
This proposal introduces a screen manager feature for developer to subscribe to hard buttons instead of sending subscribe / unsubscribe RPCs.

## Motivation
The screen manager has become the place where developers can go to manage all interface-related properties. As we continue to add high-level APIs for various UI-related RPCs, we should include even "easy" ones like `SubscribeButton`.

## Proposed solution
The proposed solution is to add new public APIs to `ScreenManager`:

##### iOS
```objc
typedef void (^SDLSubscribeButtonHandler)(SDLOnButtonPress *_Nullable buttonPress,  SDLOnButtonEvent *_Nullable buttonEvent, NSError *_Nullable error);

- (void)subscribeButton:(SDLButtonName)buttonName withBlock:(SDLRPCButtonNotificationHandler)block;
- (void)subscribeButton:(SDLButtonName)buttonName withObserver:(id<NSObject>)observer selector:(SEL)selector;

- (void)unsubscribeButton:(SDLButtonName)buttonName withCompletionHandler:(SDLScreenManagerUpdateCompletionHandler)block;
```

##### Android
```java
// TODO
```

There will still need to be storage for the blocks and observers, and this will be handled by a new sub-manager.

## Potential downsides
This introduces some complexity, but the amount is much less than other sub-managers.

## Impact on existing code
This would be a minor version change for the app libraries.

## Alternatives considered
No alternatives considered.