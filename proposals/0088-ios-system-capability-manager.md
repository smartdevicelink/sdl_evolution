# iOS System Capability Manager

* Proposal: [SDL-0088](0088-ios-system-capability-manager.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **In Review**
* Impacted Platforms: iOS

## Introduction

This is the iOS parallel proposal for [SDL-0079](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0079-system_capability_manager.md). It proposes building a centralized store for all capabilities.

## Motivation

Our motivation is the same as that described in the [motivation of SDL-0079](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0079-system_capability_manager.md#motivation). With the addition of the [System Capability Query](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0055-system_capabilities_query.md), capabilities have been spread out among multiple RPCs, and we need a central, high-level, and simple way to retrieve these capabilities.

## Proposed solution

The proposed solution parallels and is similar to the [Android solution](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0079-system_capability_manager.md#proposed-solution).

This manager would pull together `DisplayCapabilities`, `HMICapabilities`, `SoftButtonCapabilities`, `ButtonCapabilities`, `PresetBankCapabilities`, `HMIZoneCapabilities`, `SpeechCapabilities`, `PrerecordedSpeech`, `VRCapabilities`, `AudioPassThruCapabilities`, `pcmStreamCapabilities`, `navigationCapability`, `phoneCapability`, `videoStreamingCapability`, and `remoteControlCapability`.

This manager would watch for RPCs from `RegisterAppInterfaceResponse` and `SetDisplayLayoutResponse` to fill in most of the data. The remaining data come from `GetSystemCapabilities` RPC responses.

```objc
@interface SDLSystemCapabilityManager

@property (strong, nonatomic, readonly) SDLDisplayCapabilities *displayCapabilities;
@property (strong, nonatomic, readonly) SDLHMICapabilities *hmiCapabilities;
@property (copy, nonatomic, readonly) NSArray<SDLSoftButtonCapabilities *> *softButtonCapabilities;
@property (copy, nonatomic, readonly) NSArray<SDLButtonCapabilities *> *buttonCapabilities;
@property (strong, nonatomic, readonly) SDLPresetBankCapabilities *presetBankCapabilities;
@property (copy, nonatomic, readonly) NSArray<SDLHMIZoneCapabilities *> *hmiZoneCapabilities;
@property (copy, nonatomic, readonly) NSArray<SDLSpeechCapabilities *> *speechCapabilities;
@property (copy, nonatomic, readonly) NSArray<SDLPrerecordedSpeech *> *prerecordedSpeech;
@property (copy, nonatomic, readonly) NSArray<SDLVRCapabilities *> *vrCapabilities;
@property (copy, nonatomic, readonly) NSArray<SDLAudioPassThruCapabilities *> *audioPassThruCapabilities;
@property (copy, nonatomic, readonly) NSArray<SDLAudioPassThruCapabilities *> *pcmStreamCapabilities;
@property (strong, nonatomic, readonly) SDLNavigationCapability *navigationCapability;
@property (strong, nonatomic, readonly) SDLPhoneCapability *phoneCapability;
@property (strong, nonatomic, readonly) SDLVideoStreamingCapability *videoStreamingCapability;
@property (strong, nonatomic, readonly) SDLRemoteControlCapability *remoteControlCapability;

/**
 Retrieve a capability type from the remote system. This is necessary to retrieve the values of `navigationCapability`, `phoneCapability`, `videoStreamingCapability`, and `remoteControlCapability`. If you do not call this method first, those values will be nil. After calling this method, assuming there is no error in the handler, you may retrieve the capability you requested from the manager within the handler.

 @param type The type of capability to retrieve
 @param handler The handler to be called when the retrieval is complete
 */
- (void)updateCapabilityType:(SDLSystemCapabilityType)type completionHandler:(SDLUpdateCapabilityHandler)handler;

typedef void (^SDLUpdateCapabilityHandler)(NSError *error);

@end
```

## Potential downsides

The largest potential downside is that developers won't understand how to use the `navigationCapability`, `phoneCapability`, `videoStreamingCapability`, and `remoteControlCapability`. These will be `nil` until the developer calls `updateCapabilityType:completionHandler`, at which point the result will be cached (assuming there was not an error). This may be confusing to a developer since all the other capabilities will not be nil.

A second downside rears its head, though it is one that has implications for other managers. While not defined by SDL, some implementations place limits on how many RPCs may be sent in an HMI `NONE` state. Therefore we are faced with a question, should we allow developers to call `update` in the `NONE` state? In other manager we currently do allow it because it is not defined by the SDLC if or what that limit should be. Therefore, for this current proposal, it is allowed, but if performed by the developer, may cause difficult to debug issues.

## Impact on existing code

This will be a purely additive (minor version) change.

## Alternatives considered

The primary alternative considered was to remove the `updateCapabilityType:completionHandler` method. Instead, when the app leaves HMI `NONE`, the manager will retrieve all system capabilities and cache them within the properties. This was deemed less usable due to the confusion caused by the properties being `nil` until the app left HMI `NONE`.
