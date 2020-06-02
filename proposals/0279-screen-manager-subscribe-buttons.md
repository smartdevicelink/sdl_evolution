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

- (id<NSObject>)subscribeButton:(SDLButtonName)buttonName withUpdateHandler:(SDLSubscribeButtonHandler)updateHandler;
- (void)subscribeButton:(SDLButtonName)buttonName withObserver:(id<NSObject>)observer selector:(SEL)selector;
- (void)unsubscribeButton:(SDLButtonName)buttonName withObserver:(id<NSObject>)observer withCompletionHandler:(SDLScreenManagerUpdateCompletionHandler)completionHandler;
```

### Java Suite
The Java Suite APIs are set up in a similar way to the iOS APIs above. Any necessary changes are at the discretion of the Project Maintainer.

```java
public interface OnButtonListener {
    void onPress(ButtonName buttonName, OnButtonPress buttonPress);
    void onEvent(ButtonName buttonName, OnButtonEvent buttonEvent);
    void onError(String info);
}

public void addButtonListener(ButtonName buttonName, OnButtonListener listener);
public void removeButtonListener(ButtonName buttonName, OnButtonListener listener);
```

### JavaScript Suite
The JavaScript Suite APIs would be set up in a similar way to the iOS and Java Suite APIs above. Any necessary changes are at the discretion of the Project Maintainer. However larger changes that would impact the iOS or Java Suite code above (such as adding or removing a method) will require proposal revisions.

### Implementation Notes
* There will still need to be storage for the blocks and observers, and this will be handled by a new sub-manager.
* When the first subscription is added for a button, the `SubscribeButton` RPC will be sent, when the last subscription is removed, the `UnsubscribeButton` RPC will be sent.
* The sub-manager will not attempt to check for correct permissions and will just send the request. Any errors returned by core will be passed to the observer via the `error`  parameter on the `handler`/`listener`. 
*  The iOS selector can have the following arguments:
    1. A selector with no parameters. The observer will be notified when a button press occurs (they will not know if a short or long press has occured).
    2. A selector with one parameter, (`SDLButtonName`). The observer will be notified when a button press occurs (they will not know if a short or long press has occurred).
    3. A selector with two parameters, (`SDLButtonName`, `NSError`). The observer will be notified when a button press occurs (they will not know if a short or long press has occurred).
    4. A selector with three parameters,  (`SDLButtonName`, `NSError`, `SDLOnButtonPress`). The observer will be notified when a long or short button press occurs, but not a button event.
    5. A selector with four parameters, (`SDLButtonName`, `NSError`, `SDLOnButtonPress`, `SDLOnButtonEvent`). The observer will be notified when any button press or any button event occurs.

## Potential downsides
This introduces some complexity and using the `SubscribeButton` RPC isn't very difficult. However, the author believes that the `ScreenManager` should handle even "easy" RPCs because the RPC API in general isn't intuitive to app developers.

## Impact on existing code
This would be a minor version change for the app libraries.

## Alternatives considered
No alternatives considered.
