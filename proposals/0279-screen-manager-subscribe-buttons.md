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
typedef void (^SDLSubscribeButtonHandler)(SDLOnButtonPress *_Nullable buttonPress,  SDLOnButtonEvent *_Nullable buttonEvent, NSError *_Nullable error);

- (id<NSObject>)subscribeButton:(SDLButtonName)buttonName withBlock:(SDLRPCButtonNotificationHandler)block;
- (void)subscribeButton:(SDLButtonName)buttonName withObserver:(id<NSObject>)observer selector:(SEL)selector;

- (void)unsubscribeButtonWithObserver:(id<NSObject>)observer withCompletionHandler:(SDLScreenManagerUpdateCompletionHandler)block;
```

### Java Suite
The Java Suite APIs are set up in a similar way to the iOS APIs above. Any necessary changes are at the discretion of the Project Maintainer.

```java
public interface OnButtonListener {
    void onPress(ButtonName buttonName, OnButtonPress buttonPress);
    void onEvent(ButtonName buttonName, OnButtonEvent buttonEvent);
    void onError(String info);
}

public void subscribeButton(ButtonName buttonName, OnButtonListener listener);
public void unsubscribeButtonListener(OnButtonListener listener);
```

### JavaScript Suite
The JavaScript Suite APIs would be set up in a similar way to the iOS and Java Suite APIs above. Any necessary changes are at the discretion of the Project Maintainer. However larger changes that would impact the iOS or Java Suite code above (such as adding or removing a method) will require proposal revisions.

### Implementation Notes
* There will still need to be storage for the blocks and observers, and this will be handled by a new sub-manager.
* When the first subscription is added for a button, the `SubscribeButton` RPC should be sent, when the last subscription is removed, the `UnsubscribeButton` RPC should be sent.

## Potential downsides
This introduces some complexity and using the `SubscribeButton` RPC isn't very difficult. However, the author believes that the `ScreenManager` should handle even "easy" RPCs because the RPC API in general isn't intuitive to app developers.

## Impact on existing code
This would be a minor version change for the app libraries.

## Alternatives considered
No alternatives considered.
