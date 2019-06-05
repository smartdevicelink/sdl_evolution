# Add Currently Playing Media Image to MediaServiceData

* Proposal: [SDL-0239](0239-media-service-data-progress-bar-improvements.md)
* Author: [Jack Byrne](https://github.com/jacklivio)
* Status: **In Review**
* Impacted Platforms: [Core / iOS / Java Suite / RPC]

## Introduction

This proposal adds new parameters to the media service data to allow the app consumers to know the playback status and progress of a selected track.

## Motivation

The motivation for the proposal came from creating an implementation of a media type app service consumer that displays the progress bar data from an active media service provider.

Currently app service providers can notify consumers about a track's playback progress via `trackPlaybackProgress` and `trackPlaybackDuration`. However, if an app consumer wants to display progress using these parameters, it would require the app provider to send an `OnAppServiceData` RPC with updated information every second.

Also, there are no parameters in the media service data struct that tell the consumer if the track is playing, paused, or stopped. 

## Proposed solution
1. Add a new parameter `updateMode` to the media service data struct. The use of this parameter follows the usage of `updateMode` in the `SetMediaClockTimer` RPC.
2. Add a new parameter `audioStreamingIndicator` to the media service data struct. The use of this parameter follows the usage of `audioStreamingIndicator` in the `SetMediaClockTimer` RPC.

```xml
<struct name="MediaServiceData" since="5.1">
    <!-- All existing parameters here -->

    <param name="updateMode" type="UpdateMode" mandatory="false" since="X.X">
        <description>
            Enumeration to control the media clock.
        </description>
    </param>
    <param name="audioStreamingIndicator" type="AudioStreamingIndicator" mandatory="false" since="X.X">
        <description>
            Enumeration for the indicator icon on a play/pause button. see AudioStreamingIndicator.
        </description>
    </param>
</struct>
```

## Potential downsides
No downsides were identified

## Impact on existing code
This is a minor version change to the RPC spec, Core, and proxy libraries.

## Alternatives considered
No alternatives were identified.
