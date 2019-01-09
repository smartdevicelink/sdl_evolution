# Android ManagerListener update

* Proposal: [SDL-NNNN](NNNN-android-manager-listener-update.md)
* Author: [SDL Developer](https://github.com/kshala-ford)
* Status: **Awaiting review**
* Impacted Platforms: [ Android ]

## Introduction

This proposal is related to Android 4.8 specifically updating the `SdlManagerListener` interface to match iOS `SDLManagerDelegate`.

## Motivation

During development of "SDL Localization" (#295) for Android I found that the proposals "Delegate Support for all onHMIStatus State Changes" (#101) and "Change Registration Manager" (#164) are not targeting Android. 

## Proposed solution

The proposed solution is to add more methods to the `SdlManagerListener` interface:

```java
public interface SdlManagerListener {
  :
  
  /**
   * Called when the HMI level of this application changes on the remote system. 
   */
  void onHMILevelChange(@Nullable HMILevel oldState, @NonNull HMILevel newState);
  
  /**
   * Called when the audio streaming state of this application changes on the remote system.
   */
  void onAudioStreamingStateChange(@Nullable AudioStreamingState oldState, @NonNull AudioStreamingState newState);
  
  /**
   * Called when the system context of this application changes on the remote system.
   */
  void onSystemContextChange(@Nullable SystemContext oldContext, @NonNull SystemContext newContext);
  
  /**
   * Called when the SDL manager detected a language mismatch. In this case the manager should update the app's configuration to the specified language. 
   * If the app supports the specified language it should return an Object of SdlManager.Updater, otherwise it should return null.
   *
   * @param language The language of the remote system. If the app returns an object of SdlManager.Updater the app will update to that language.
   * @return An object of SdlManager.Updater if the language is supported, otherwise null.
   */
  @Nullable SdlManager.Updater onConfigurationUpdate(@NonNull Language language);
}
```

### HMI status notifications

All parameters of the `OnHMIStatus` notification are stored in the SdlManager instance.

```java
public class SdlManager {
  // HMI level, audio streaming state and system context of the last status notification or null if not known/connected
  private @Nullable HMILevel hmiLevel; 
  private @Nullable AudioStreamingState audioStreamingState;
  private @Nullable SystemContext systemContext;
```

Internally the manager listens to OnHMIStatus and performs as followed:

```java
public void onNotified(RPCNotification notification) {
  OnHMIStatus status = (OnHMIStatus) notification;
  
  HMILevel newHmiLevel = status.getHmiLevel();
  if (newHmiLevel != null && !newHmiLevel.equals(hmiLevel)) {
    managerListener.onHMILevelChange(hmiLevel, newHMILevel);
  }
  hmiLevel = newHmiLevel;
  
  AudioStreamingState newAudioStreamingState = status.getAudioStreamingState();
  if (newAudioStreamingState != null && !newAudioStreamingState.equals(this.audioStreamingState)) {
    managerListener.onAudioStreamingStateChange(this.audioStreamingState, newAudioStreamingState);
  }
  this.audioStreamingState = newAudioStreamingState;
  
  SystemContext newSystemContext = status.getSystemContext())
  if (newSystemContext != null && !newSystemContext.equals(this.systemContext)) {
    managerListener.onSystemContextChange(this.systemContext, newSystemContext);
  }
  this.systemContext = newSystemContext;
}
```
### Language mismatch detected
    
The logic to detect language mismatch should be added right before the managers are initialized. This way a manager update is performed just in time.
    
```java
public void onProxyConnected() {
    List<Language> supportedLanguages = this.languagesSupported;
    Language desiredLanguage = this.hmiLanguage;
    Language actualLanguage = getRegisterAppInterfaceResponse().getLanguage();
    
    if (actualLanguage != null && !desiredLanguage.equals(actualLanguage) && supportedLanguages.contains(actualLanguage)) {
        SdlManager.Updater updater = managerListener.onConfigurationUpdate(actualLanguage);
        
        if (updater != null) {
            updater.update(actualLanguage);
        }
    }
    
    // first we need to check if the SDL language matches or if we need to update configuration
    DebugTool.logInfo("Proxy is connected. Initializing managers.");
    initialize();
}
``` 

### SdlManager.Updater

The updater will be a nested class which behaves similar to the static `Builder` subclass.

```java
public class SdlManager {
public class Updater {
    private @Nullable String appName;
    private @Nullable String shortAppName;
    private @Nullable List<TTSChunk> ttsName;
    private @Nullable List<String> voiceRecognitionCommandNames;

    public Updater(String appName, String shortAppName, List<TTSChunk> ttsName, List<String> voiceRecognitionCommandNames) {
        this.appName = appName;
        this.shortAppName = shortAppName;
        this.ttsName = ttsName;
        this.voiceRecognitionCommandNames = voiceRecognitionCommandNames;
        ChangeRegistration
    }

    public void setAppName(String appName) {
        this.appName = appName;
    }

    public void setShortAppName(String shortAppName) {
        this.shortAppName = shortAppName;
    }

    public void setTtsName(List<TTSChunk> ttsName) {
        this.ttsName = ttsName;
    }

    public void setVoiceRecognitionCommandNames(List<String> voiceRecognitionCommandNames) {
        this.voiceRecognitionCommandNames = voiceRecognitionCommandNames;
    }

    void update(Language language) {
        ChangeRegistration request = new ChangeRegistration(language, language);
        SdlManager.this.hmiLanguage = language;

        if (appName != null) {
            request.setAppName(appName);
            SdlManager.this.appName = appName;
        }

        if (shortAppName != null) {
            request.setNgnMediaScreenAppName(shortAppName);
            SdlManager.this.shortAppName = shortAppName;
        }

        if (ttsName != null) {
            request.setTtsName(ttsName);
            SdlManager.this.ttsChunks = new Vector<>(ttsName);
        }

        if (voiceRecognitionCommandNames != null) {
            request.setVrSynonyms(voiceRecognitionCommandNames);
            SdlManager.this.vrSynonyms = new Vector<>(voiceRecognitionCommandNames);
        }

        SdlManager.this.sendRPC(request);
    }
}
```

## Potential downsides

From a technical point of view there is no downside to the added features. However as Java interfaces force you to implement every single method which can be distracting. 

## Impact on existing code

The additional methods in the interface have impact to implementations of app developers and may be distracting. Besides of that there's no existing code changed.

## Alternatives considered

To avoid forcing app developers to implement the methods added to `SdlManagerListener` each method could be added to the SDL manager builder to allow the app developer to choose what methods are interesting to listen.

```java
public interface HMILevelListener {
   void onHMILevelChange(@Nullable HMILevel oldLevel, @NonNull HMILevel newLevel);
}

public interface AudioStreaminStateListener {
  void onAudioStreamingStateChange(@Nullable AudioStreamingState oldState, @NonNull AudioStreamingState newState);
}

public interface SystemContextListener {
  void onSystemContextChange(@Nullable SystemContext oldContext, @NonNull SystemContext newContext);
}

public class SdlManager {
    public interface ConfigurationUpdateListener {
        @Nullable SdlManager.Updater onConfigurationUpdate(@NonNull Language language);
    }
    
    private @Nullable HMILevelListener hmiLevelListener;
    private @Nullable AudioStreamingStateListener audioStreamingStateListener;
    private @Nullable SystemContextListener systemContextListener;
    private @Nullable ConfigurationUpdateListener configurationUpdateListener;
    :
    public static class Builder {
        :
        public void setHMILevelListener(HMILevelListener listener) {
          sdlManager.hmiLevelListener = listener;
        }
        public void setAudioStreamingStateListener(AudioStreamingStateListener listener) {
          sdlManager.audioStreamingStateListener = listener;
        }
        public void setSystemContextListener(SystemContextListener listener) {
          sdlManager.systemContextListener = listener;
        }
        public void setOnConfigurationUpdateListener(SdlManager.ConfigurationUpdateListener listener) {
          sdlManager.configurationUpdateListener = listener;
        }
    }
}
```

With this change the manager listens to OnHMIStatus and performs depending on the app developer choice:

```java
public void onNotified(RPCNotification notification) {
  OnHMIStatus status = (OnHMIStatus) notification;
  
  HMILevel newHmiLevel = status.getHmiLevel();
  if (hmiLevelListener != null && newHmiLevel != null && !newHmiLevel.equals(hmiLevel)) {
    hmiLevelListener.onHMILevelChange(this.hmiLevel, newHMILevel);
  }
  hmiLevel = newHmiLevel;
  
  AudioStreamingState newAudioStreamingState = status.getAudioStreamingState();
  if (audioStreamingStateListener != null && newAudioStreamingState != null && !newAudioStreamingState.equals(this.audioStreamingState)) {
    audioStreamingStateListener.onAudioStreamingStateChange(this.audioStreamingState, newAudioStreamingState);
  }
  this.audioStreamingState = newAudioStreamingState;
  
  SystemContext newSystemContext = status.getSystemContext())
  if (systemContextListener != null && newSystemContext != null && !newSystemContext.equals(this.systemContext)) {
    systemContextListener.onSystemContextChange(this.systemContext, newSystemContext);
  }
  this.systemContext = newSystemContext;
}
```