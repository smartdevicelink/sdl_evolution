# SetAudioStreamingIndicator RPC

* Proposal: [SDL-0109](0109-set-audio-streaming-indicator.md)
* Author: [Kujtim Shala](https://github.com/kshala-ford)
* Status: **In Review**
* Impacted Platforms: [Core / iOS / Android / RPC ]

## Introduction

The proposal is about adding a new RPC for media apps to indicate the action of a play/pause button.

## Motivation

Different to other common media protocols (BT audio, iAP etc.) SDL does not provide any information to identify the playback status of a media app. The SYNC3 HMI shows a circular button with a Play/Pause icon regardless of the current playback status. Unfortunately the head unit cannot identify the actual action of the Play/Pause button. Knowing the current playback status (e.g. "Playing") would not make clear if the app's action of the Play/Pause button would be "pause" or "stop".

In order to allow an app to indicate the action of the Play/Pause button a new RPC is required to tell the HMI what action the Play/Pause button would perform when pressed.

## Proposed solution

Referring to the enum `AudioStreamingState` SDL should provide another enum called `AudioStreamingIndicator`. This enum should be used in an RPC called `SetAudioStreamingIndicator`.

### HMI & Mobile API 

```xml
<enum name="AudioStreamingIndicator">
  <element name="PLAY_PAUSE">
    <description>Default playback indicator.</description>
  </element>
  <element name="PLAY">
    <description>Indicates that a button press of the Play/Pause button would start the playback.</description>
  </element>
  <element name="PAUSE">
    <description>Indicates that a button press of the Play/Pause button would pause the current playback.</description>
  </element>
  <element name="STOP">
    <description>Indicates that a button press of the Play/Pause button would stop the current playback.</description>
  </element>
</enum> 

<function name="SetAudioStreamingIndicator" messagetype="request">
  <param name="audioStreamingIndicator" type="AudioStreamingIndicator" mandatory="true" />
</function>
```

By default the playback indicator should be `PLAY_PAUSE` when:
- the media app is newly registered on the head unit (after `RegisterAppInterface`)
- the media app was closed by the user (App enteres `HMI_NONE`)

## Potential downsides

No downside identified

## Impact on existing code

As this proposal is only adding a single RPC with a new parameter no impact on existing code is expected.

## Alternatives considered

Two alternatives were originally considered but dropped as not being able to solve the actual problem.

### Playback status

As an alternative the app could provide the audio playback status instead of / in addition to the audio streaming indicator.

```xml
<enum name="AudioPlaybackStatus">
  <element nme="UNKNOWN">
    <description>The default status as long as the media source doesn't inform about the playback status.</description>
  </element>
  <element name="STOPPED"/>
  <element name="PAUSED"/>
  <element name="PLAYING"/>
  <element name="BUFFERING"/>
</enum>
``` 

This information might be interesting for testing purposes but it actually does not indicate the action of the Play/Pause button.

### Use media clock

Another alternative is to use the update mode of the media clock. However it's not possible to clearly indicate the action of the Play/Pause button. The HMI doesn't know if playback is paused or stopped. Furthermore it cannot differentiate between buffering (but audio playback suppose to continue) and paused playback if the media clock is paused. 

| Mode          | Status    | Indicator       | Issue                                                                         |
| ------------- | --------- | --------------- | ----------------------------------------------------------------------------- |
| Cleared       | Stopped   | Play            | All good                                                                      |
| Count up/down | Playing   | Pause or Stop?  | Not possible to differentiate between pause and stop                          |
| Paused        | Paused    | Play            | Conflicts with "buffering"                                                    |
| Paused        | Buffering | Pause or Stop?  | Conflicts with "Paused", Not possible to differentiate between pause and stop |

