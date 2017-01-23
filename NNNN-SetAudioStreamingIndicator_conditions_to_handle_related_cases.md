# SetAudioStreamingIndicator: Conditions for SDL to handle related cases

* Proposal: [SDL-NNNN](NNNN-SetAudioStreamingIndicator_conditions_to_handle_related_cases.md)
* Author: [Melnyk Tetiana](https://github.com/TMelnyk)
* Status: **Awaiting review**
* Impacted Platforms: Core / RPC

## Introduction

This proposal is to support and process per the similar logic new _SetAudioStreamingIndicator_ RPC.

## Motivation

**Required for FORD.**   
_SetAudioStreamingIndicator_ RPC should describe the indicator of streaming audio to the user. 
The proposal new RPC sets the icon properly to the current audio playback of the application and provides additional human readable info regarding the result, received from SDL.

## Proposed solution

1. The Play/Pause button of the media app shall be able to show one of the following icons:
   - Play/Pause (currently used icon)
   - Play (a play only icon)
   - Pause (a pause only icon)
   - Buffering (an icon that indicates that audio playback is buffering)
2. The icon of the Play/Pause button shall be modifiable by the media app by sending a RPC Request called _SetAudioPlayingState_.
3. The RPC Request _SetAudioPlayingState_ must have a parameter called _audioPlayingState_. This parameter must be of the enum _AudioPlayingState_.
4. The enum _AudioPlayingState_ must have the following values:
   - PLAY_PAUSE (to set the button to the play/pause icon)
   - PLAY (to set the button to the play icon)
   - PAUSE (to set the button to the pause icon)
   - BUFFERING (to set the button to the buffering icon)
5. The RPC Response _SetAudioPlayingStateResponse_ must return:
   - SUCCESS when the Play/Pause button is set to the desired icon
   - IGNORED when the Play/Pause button was already set to the desired icon
   - DISALLOWED when the RPC is used in an invalid HMI level.
6. The RPC _SetAudioPlayingState_ shall be
   - ALLOWED within the HMI levels: FULL, LIMITED, BACKGROUND
   - DISALLOWED within the HMI levels: NONE_
7. The RPC _SetAudioPlayingState_ shall be added to the _base-x_ (currently it is _base-4_) functional group.
8. The default icon for the Play/Pause button shall be the Play/Pause icon (PLAY_PAUSE).
9. The default icon must be set to the button when
   - the media app is newly registered on the head unit (after RegisterAppInterface).
   - the media app was closed by the user (App enters HMI_NONE).

## Detailed design

TBD

## Impact on existing code

TBD

## Alternatives considered

TBD
