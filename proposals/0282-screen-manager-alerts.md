# Screen Manager Alert Manager

* Proposal: [SDL-0282](0282-screen-manager-alerts.md)
* Author: [Joel Fischer (https://github.com/joeljfischer), Nicole Yarroch (https://github.com/NicoleYarroch), Julian Kast (https://github.com/JulianKast)]
* Status: **Accepted with Revisions**
* Impacted Platforms: [iOS / Java Suite / JavaScript Suite]

## Introduction
This proposal adds alert management (based on the Alert RPC) to the screen manager API.

## Motivation
The screen manager should be capable of handling all screen related RPCs and features. Template text, template graphics, template soft buttons, menus, and choice interactions are currently handled, but alerts are not.

## Proposed solution
The proposed solution is to add a new private `SDLAlertManager` sub-manager to the screen manager to handle alert-related capabilities, soft buttons and their images, text concatenation, etc. The `SDLScreenManager` itself will then provide a simple public API for presenting alerts to the screen.

### Audio Processing
In order to support `Alert`'s complicated audio processing and to simplify `TTSChunk`'s various options, we will add a class that handles initializing all audio-related parameters.

##### iOS
 ```objc
 @interface SDLAudioData: NSObject
/**
 The text-to-speech prompts that will used and/or audio files that will be played. The audio prompts and files will be played in the same order they are added.
 */
@property (nullable, copy, nonatomic, readonly) NSArray<SDLTTSChunk *> *audioData;

/**
 Initialize with an SDLFile holding data or pointing to a file on the file system. When this object is passed to an `Alert` or `Speak`, the file will be uploaded if it is not already, then played if the system supports that feature.

 Only available on systems supporting RPC Spec v5.0+.

 @param audioFile The audio file to be played by the system
 */
- (instancetype)initWithAudioFile:(SDLFile *)audioFile;

/**
 Initialize with a string to be spoken by the system speech synthesizer.

 @param spokenString The string to be spoken by the system speech synthesizer
 */
- (instancetype)initWithSpeechSynthesizerString:(NSString *)spokenString;

/**
 Initialize with a string to be spoken by the system speech synthesizer using a phonetic string.

 @param spokenString The string to be spoken by the system speech synthesizer
 @param phoneticType Must be one of `SAPI_PHONEMES`, `LHPLUS_PHONEMES`, `TEXT`, or `PRE_RECORDED` or no object will be created
 */
- (instancetype)initWithPhoneticSpeechSynthesizerString:(NSString *)phoneticString phoneticType:(SDLSpeechCapabilities)phoneticType;

/**
 Add additional SDLFiles holding data or pointing to a file on the file system. When this object is passed to an `Alert` or `Speak`, the file will be uploaded if it is not already, then played if the system supports that feature.

 @param audioFiles An array of audio file to be played by the system
 */
 - (void)addAudioFiles:(NSArray<SDLFile *> *)audioFiles;

/**
 Create additional strings to be spoken by the system speech synthesizer.
 
 @param spokenStrings The strings to be spoken by the system speech synthesizer
 */
 - (void)addSpeechSynthesizerStrings:(NSArray<NSString *> *)spokenStrings;

/**
 Create additional strings to be spoken by the system speech synthesizer using a phonetic string.

 @param phoneticStrings The strings to be spoken by the system speech synthesizer
 @param phoneticType Must be one of `SAPI_PHONEMES`, `LHPLUS_PHONEMES`, `TEXT`, or `PRE_RECORDED` or no object will be created
 */
 - (void)addPhoneticSpeechSynthesizerStrings:(NSArray<NSString *> *)phoneticStrings phoneticType:(SDLSpeechCapabilities)phoneticType;
```

```objc
@interface SDLAlertAudioData: SDLAudioData
/**
 Whether the alert tone should be played before the prompt is spoken. Defaults to NO.
 */
@property (assign, nonatomic) BOOL playTone;
```

##### Java
```java
public class AudioData {
    private List<TTSChunk> audioData;

    AudioData(@NonNull SdlFile audioFile)
    AudioData(@NonNull String spokenString)
    AudioData(@NonNull String phoneticString, @NonNull SpeechCapabilities phoneticType)

    // All vars have getters but no setters

    public void addAudioFiles(@NonNull List<SdlFile> audioFiles) {}
    public void addSpeechSynthesizerStrings(@NonNull List<String> spokenString) {}
    public void addPhoneticSpeechSynthesizerStrings(@NonNull List<String> phoneticString, @NonNull SpeechCapabilities phoneticType) {}
}
```

```java
public class AlertAudioData extends AudioData implements Cloneable {
    private boolean playTone;

    // All vars have getters and setters
    AlertAudioData(@NonNull SdlFile audioFile)
    AlertAudioData(@NonNull String spokenString)
    AlertAudioData(@NonNull String phoneticString, @NonNull SpeechCapabilities phoneticType)

    // Creates a deep copy of the object
    @Override
    public AlertAudioData clone() {}
}
```

### Manager Alert API
The next object is the alert view itself that developers will construct and pass to the Screen Manager.

##### iOS
```objc
@interface SDLAlertView: NSObject
/**
 Set this to change the default timeout for all alerts. If a timeout is not set on an individual alert object (or if it is set to 0.0), then it will use this timeout instead. See `timeout` for more details. If this is not set by you, it will default to 5 seconds. The minimum is 3 seconds, the maximum is 10 seconds
 Please note that if a button is added to the alert, the defaultTimeout and timeout values will be ignored.
 */
@property (class, assign, nonatomic) NSTimeInterval defaultTimeout;

/**
 Maps to Alert.alertText1. The primary line of text for display on the alert. If fewer than three alert lines are available on the head unit, the screen manager will automatically concatenate some of the lines together.
 */
@property (nullable, strong, nonatomic) NSString *text;

/**
 Maps to Alert.alertText2. The secondary line of text for display on the alert. If fewer than three alert lines are available on the head unit, the screen manager will automatically concatenate some of the lines together.
 */
@property (nullable, strong, nonatomic) NSString *secondaryText;

/**
 Maps to Alert.alertText3. The tertiary line of text for display on the alert. If fewer than three alert lines are available on the head unit, the screen manager will automatically concatenate some of the lines together.
 */
@property (nullable, strong, nonatomic) NSString *tertiaryText;

/**
 Maps to Alert.duration. Defaults to `defaultTimeout`. Defaults to 0, which will use `defaultTimeout`. If this is set below the minimum, it will be capped at 3 seconds. Minimum 3 seconds, maximum 10 seconds. If this is set above the maximum, it will be capped at 10 seconds. Defaults to 0.
 Please note that if a button is added to the alert, the defaultTimeout and timeout values will be ignored.
 */
@property (assign, nonatomic) NSTimeInterval timeout;

/**
 Maps to Alert.ttsChunks and Alert.playTone. This text is spoken when the alert appears.
 */
@property (nullable, copy, nonatomic) SDLAlertAudioData *audio;

/**
 Maps to Alert.progressIndicator. If supported, the alert GUI will display some sort of indefinite waiting / refresh / loading indicator animation. Defaults to NO.
 */
@property (assign, nonatomic) BOOL showWaitIndicator;

/**
 Maps to Alert.softButtons. Soft buttons the user may select to perform actions. Only one `SDLSoftButtonState` per object is supported; if any soft button object contains multiple states, an exception will be thrown.
 */
@property (nullable, copy, nonatomic) NSArray<SDLSoftButtonObject *> *softButtons;

/**
 Maps to Alert.alertIcon. An artwork that will be displayed when the icon appears. This will be uploaded prior to the appearance of the alert if necessary. This will not be uploaded if the head unit does not declare support for alertIcon.
*/
@property (nullable, copy, nonatomic) SDLArtwork *icon;

- (instancetype)initWithText:(NSString *)text buttons:(NSArray<SDLSoftButtonObject *> *)softButtons;

- (instancetype)initWithText:(nullable NSString *)text secondaryText:(nullable NSString *)secondaryText tertiaryText:(nullable NSString *)tertiaryText timeout:(nullable NSNumber<SDLFloat> *)timeout showWaitIndicator:(nullable NSNumber<SDLBool> *)showWaitIndicator audioIndication:(nullable SDLAlertAudioData *)audio buttons:(nullable NSArray<SDLSoftButtonObject *> *)softButtons icon:(nullable SDLArtwork *)icon;

/**
 Cancels the alert. If the alert has not yet been sent to Core, it will not be sent. If the alert is already presented on Core, the alert will be immediately dismissed. Canceling an already presented alert will only work if connected to modules supporting RPC Spec v.6.0+. On older versions of Core, the alert will not be dismissed.
*/
- (void)cancel;

@end
```

##### Java
```java
public class AlertView {
    private static Integer defaultTimeout = 5;

    private String text, secondaryText, tertiaryText;
    private Integer timeout;
    private AlertAudioData audio;
    private boolean showWaitIndicator;
    private List<SoftButtonObject> softButtons;
    private SdlArtwork icon;

    private AlertView() { }

    public static class Builder {
        AlertView alertView;
        void Builder() {
            alertView = new AlertView()
        }

        Builder setText(String text) { /* Imp */ }
        Builder setSecondaryText(String text) { /* Imp */ }
        Builder setTertiaryText(String text) { /* Imp */ }
        Builder setDefaultTimeout(int defaultTimeout) { /* Imp */ }
        Builder setTimeout(int timeout) { /* Imp */ }
        Builder setSoftButtons(List<SoftButtonObject> softButtons) { /* Imp */ }
        Builder setAudio(AlertAudioData audio) { /* Imp */ }
        Builder setIcon(SdlArtwork icon) { /* Imp */ }
        Builder setShowWaitIndicator(boolean showWaitIndicator)  { /* Imp */ }
    }

    // All vars have getters and setters to match iOS read / write

    public void cancel() {}

    // Creates a deep copy of the object
    @Override
    public AlertView clone() {}
}
```

And then the additions to the screen manager public API itself to present the alert.

##### iOS
```objc
@interface SDLScreenManager: NSObject
// Everything already there

/**
 Present the alert on the screen. To replace a currently presenting alert with a new alert, you must first call `cancel` on the currently presenting alert before sending the new alert. Otherwise the newest alert will only be presented when the module dismisses the currently presented alert (either due to the timeout or the user selecting a button on the alert). Please note that cancelling a currently presented alert will only work on modules supporting RPC Spec v.6.0+.
 
 If the alert contains an audio indication with a file that needs to be uploaded, it will be uploaded before presenting the alert. If the alert contains soft buttons with images, they will be uploaded before presenting the alert. If the alert contains an icon, that will be uploaded before presenting the alert.
 
 The handler will be called when the alert either dismisses from the screen or it has failed to present. If the error value in the handler is present, then the alert failed to appear or was aborted, if not, then the alert dismissed without error. The `userInfo` object on the error contais an `error` key with more information about the error. If the alert failed to present, the `userInfo` object will contain a `tryAgainTime` key with information on how long to wait before trying to send another alert. The value for `tryAgainTime` may be `nil` if the module did not return a value in its response.
 */
- (void)presentAlert:(SDLAlertView *)alert withCompletionHandler:(nullable SDLScreenManagerUpdateCompletionHandler)handler;

@end
```

##### Java
```java
public class BaseScreenManager {

    public void presentAlert(AlertView alert, AlertCompletionListener listener)
}
```

```java
public interface AlertCompletionListener {
    /**
     * Returns whether an Alert operation was successful or not along with tryAgainTime
     * @param success - Boolean that is True if Operation was a success, False otherwise.
     * @param tryAgainTime - Amount of time (in seconds) that an app must wait before resending an alert.
     */
    void onComplete(boolean success, Integer tryAgainTime);
}
```

### JavaScript Suite APIs
Due to the size of the iOS APIs and the similarity between the iOS, Java Suite and eventual JavaScript Suite APIs, this proposal does not present the public APIs of the JavaScript Suite APIs – especially because the JavaScript Suite APIs do not currently have a screen manager layer. The JavaScript Suite APIs should mirror the iOS and Java Suite API appropriately and is up to the maintainers' discretion. However, if any changes needed to be made such that they impacted the iOS / Java Suite API (such as the alteration, addition, or removal of a method or property), then a proposal revision would be needed.

### Additional Implementation Notes
- The internal alert manager will observe the `AlertResponse` to know when the alert has finished presenting, and then call the `completionHandler`.
- The internal alert manager will always send the alert, even if the system context is not MAIN. If the `AlertResponse` returns a failure to present, it will call the `completionHandler` with the error.
- The developer will not be notified when the alert appears on the screen, assuming no error occurred – see alternative #1 for possible ways to do that.
- The `SDLAlertManager` sub-manager will use queues to manage alert related requests, similar to the implementation in the `SDLChoiceSetManager`. The queue is serial and if an alert is sent while another alert is currently presented, the newest alert will not be sent until the module dismisses the previous alert.
- If any image fails to upload, the presentation of the alert should continue without an error.
- If an audio file is supposed to be played and fails to upload, the presentation of the alert will fail _if_ there is no text attached to the alert. If text is present on the alert and the audio file fails to upload, the presentation of the alert should continue and no error should be returned.
- The alert view should be copied as soon as `presentAlert` is called in order to prevent the developer from changing the properties of the view after they call the method.

## Potential downsides
The creation of the alert sub-manager will be complex because it has to handle the creation of soft buttons and manage their IDs alongside the soft button manager. It will also have to upload the icon image, soft button images, and audio files. However, this is all complexity that every SDL developer must currently consider when developing their app. This is especially difficult for them because they don't usually have to deal with uploading images and waiting until the upload is done.

## Impact on existing code
This is a minor version change for all app libraries.

## Alternatives considered
1. We could change the completion handler to a delegate in order to cover more cases, like so:

```objc
@protocol SDLAlertViewDelegate <NSObject>

- (void)alertView:(SDLAlertView *)alertView didFailToAppearWithError:(NSError *)error;
- (void)alertViewDidAppear:(SDLAlertView *)alertView withWarning:(nullable NSError *)warning; // The problem is that this is partly a guess based on system context going from X -> ALERT
- (void)alertViewDidDismiss:(SDLAlertView *)alertView;

@end
```

The alert view would then have a new required delegate property (though conformance to each method would be optional), and the screen manager API would not take a completion handler. This would be a more robust, but complicated API.

2. We could add a second block handler to the `presentAlert` call to allow the developer to be notified when the alert appears as well as dismisses.
