# ScreenManager Alert Handling

* Proposal: [SDL-NNNN](NNNN-screen-manager-alerts.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Awaiting review**
* Impacted Platforms: [iOS / Android / Web]

## Introduction
This proposal adds alert management and handling to the screen manager API.

## Motivation
The screen manager should be capable of handling all screen related RPCs and features. Text, graphics, soft buttons, menus, and choice interactions are currently handled, but alerts are not.

## Proposed solution
The proposed solution is to add a new private `SDLAlertManager` sub-manager to the screen manager to handle alert-related capabilities, soft button image uploads, text concatination, etc. The `SDLScreenManager` itself will then provide a simple public API for presenting alerts to the screen.

We will also need to create an alternate alert object to handle soft button objects instead of standard soft buttons.

```objc
@interface SDLAlertView: NSObject

/**
 * Set this to change the default timeout for all alerts. If a timeout is not set on an individual choice set object (or if it is set to 0.0), then it will use this timeout instead. See `timeout` for more details. If this is not set by you, it will default to 5 seconds. The max is 10 seconds.
 */
@property (class, assign, nonatomic) NSTimeInterval defaultTimeout;

/**
 * The lines of text for display on the alert. If fewer than three alert lines are available on the head unit, the screen manager will automatically concatenate some of the lines together.
 */
@property (nullable, strong, nonatomic, readonly) NSString *alertText1;
@property (nullable, strong, nonatomic, readonly) NSString *alertText2;
@property (nullable, strong, nonatomic, readonly) NSString *alertText3;

/**
 * Maps to Alert.duration. Defaults to `defaultTimeout`. Minimum 3 seconds, maximum 10 seconds.
 */
@property (assign, nonatomic, readonly) NSTimeInterval timeout;

/**
 * Maps to Alert.ttsChunks. This text is spoken when the alert appears.
 */
@property (nullable, copy, nonatomic, readonly) NSArray<SDLTTSChunk *> *prompt;

/**
 * Whether the alert tone should be played before the prompt (if any) is spoken. Defaults to NO.
 */
@property (assign, nonatomic, readonly) BOOL playTone;

/**
 * If supported, the alert GUI will display some sort of indefinite progress indicator animation. Defaults to NO.
 */
@property (assign, nonatomic, readonly) BOOL showProgressIndicator;

/**
 * Soft buttons the user may select to perform actions. Only one `SDLSoftButtonState` per object is supported; if objects contain multiple states, an exception will be thrown.
 */
@property (nullable, copy, nonatomic, readonly) NSArray<SDLSoftButtonObject *> *softButtons;

@end
```

And below are the screen manager API additions:

```objc
@interface SDLScreenManager: NSObject
/** Everything already there **/

/**
 * Present the alert on the screen. The handler will be called when the alert either dismisses from the screen or it has failed to present. If the error value in the handler is present, then the alert failed to appear, if not, then the alert dismissed without user touch or error. The error will contain `userInfo` with information on how long to wait before retrying.
 */
- (void)presentAlert:(SDLAlertView *)alert withCompletionHandler:(nullable SDLScreenManagerUpdateCompletionHandler)handler;

@end
```

Additional notes on implementation:
- The internal alert manager will observe the screen context to know when the alert has been presented, and then call the `completionHandler`.
- The internal alert manager will always send the alert, even if the system context is not MAIN. If the `AlertResponse` returns an failure to present, it will call the `completionHandler` with the error.
- The developer will not be notified when the alert appears on the screen, assuming no error occurred.

## Potential downsides
This proposal provides a manager-level API for alerts. There is a [higher-level accepted proposal](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0201-high-level-interface-overlay-controllers.md) for dealing with alerts as well. We would be providing two separate APIs for alerts. However, (1) they are on different layers (one manager, one high-level), and we do this already for other APIs (like perform interactions). Furthermore, (2) the high-level API is intended to use the managers, and having this API available would make the high-level API easier to implement. Finally, (3) the high-level API requires a complete rewrite from developers for their SDL integration, while this API is purely additive.

## Impact on existing code
This is a minor version change for all proxy libraries.

## Alternatives considered
1. We could change the completion handler to a delegate in order to cover more cases, like so:

```objc
@protocol SDLAlertViewDelegate <NSObject>

- (void)alertView:(SDLAlertView *)alertView didFailToAppearWithError:(NSError *)error
- (void)alertViewDidAppear:(SDLAlertView *)alertView;
- (void)alertViewDidDismiss:(SDLAlertView *)alertView;

@end
```

The alert view would then have a new required delegate property, and the screen manager API would not take a completion handler.

2. We could add a second block handler to the `presentAlert` call to allow the developer to be notified when the alert appears as well as dismisses.