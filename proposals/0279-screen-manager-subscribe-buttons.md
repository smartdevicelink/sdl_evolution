# Screen Manager Subscribe Buttons

* Proposal: [SDL-0279](0279-screen-manager-subscribe-buttons.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Accepted with Revisions**
* Impacted Platforms: [iOS / Java Suite / JavaScript Suite]

## Introduction
This proposal introduces a screen manager feature for developers to subscribe to hard buttons instead of sending subscribe / unsubscribe RPCs.

## Motivation
The screen manager has become the place where developers can go to manage all interface-related properties. As we continue to add high-level APIs for various UI-related RPCs, we should include even "easy" ones like `SubscribeButton`.

## Proposed solution
The proposed solution is to add new public APIs to `ScreenManager`:

### iOS
```objc
typedef void (^SDLSubscribeButtonHandler)(SDLOnButtonPress *_Nullable buttonPress, SDLOnButtonEvent *_Nullable buttonEvent, NSError *_Nullable error);

- (nullable id<NSObject>)subscribeButton:(SDLButtonName)buttonName withUpdateHandler:(nullable SDLSubscribeButtonHandler)updateHandler;
- (BOOL)subscribeButton:(SDLButtonName)buttonName withObserver:(id<NSObject>)observer selector:(SEL)selector;
- (BOOL)unsubscribeButton:(SDLButtonName)buttonName withObserver:(id<NSObject>)observer withCompletionHandler:(nullable SDLScreenManagerUpdateCompletionHandler)completionHandler;
```

### Java Suite
The Java Suite APIs are set up in a similar way to the iOS APIs above. Any necessary changes are at the discretion of the Project Maintainer.

```java
public interface OnButtonListener {
    void onPress(ButtonName buttonName, OnButtonPress buttonPress);
    void onEvent(ButtonName buttonName, OnButtonEvent buttonEvent);
    void onError(String info);
}

public boolean addButtonListener(ButtonName buttonName, OnButtonListener listener);
public boolean removeButtonListener(ButtonName buttonName, OnButtonListener listener);
```

### JavaScript Suite
The JavaScript Suite APIs would be set up in a similar way to the iOS and Java Suite APIs above. Any necessary changes are at the discretion of the Project Maintainer. However larger changes that would impact the iOS or Java Suite code above (such as adding or removing a method) will require proposal revisions.

### Implementation Notes
* There will still need to be storage for the blocks and observers, and this will be handled by a new sub-manager.
* When the first subscription is added for a button, the `SubscribeButton` RPC will be sent, when the last subscription is removed, the `UnsubscribeButton` RPC will be sent.
* When subscribing, the return value will indicate whether or not the manager can attempt the subscription. The value `true` (or an observer `id` in the case of the iOS `subscribeButton:withUpdateHandler` method) will be returned if the manager is attempting the subscription or is already subscribed, or `false` (or `nil` in the case of the iOS `subscribeButton:withUpdateHandler` method) if the manager can't attempt the subscription for some reason (e.g. the app does not have the correct permissions to send the subscribe button).
* When unsubscribing, the return value will indicate whether or not the manager can attempt the unsubscription. The value `true` will be returned if the manager is attempting the unsubscription, or `false` if the manager is not subscribed to said button or if the manager can not attempt the unsubscription for some reason (i.e. the app does not have the correct permissions to send the unsubscribe request).

## Potential downsides
This introduces some complexity and using the `SubscribeButton` RPC isn't very difficult. However, the author believes that the `ScreenManager` should handle even "easy" RPCs because the RPC API in general isn't intuitive to app developers.

## Impact on existing code
This would be a minor version change for the app libraries.

## Alternatives considered
No alternatives considered.
