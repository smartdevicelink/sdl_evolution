# Media Skip Indicators

* Proposal: [SDL-0198](0198-media-skip-indicators.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Accepted with Revisions**
* Impacted Platforms: [Core / HMI / iOS / Android / RPC]

## Introduction
This feature is similar to [SDL-0109 Audio Streaming Indicator](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0109-set-audio-streaming-indicator.md) except that it affects the next and previous buttons. These buttons should have the ability to show time skip buttons that are commonly used by podcast & audiobook media.

## Motivation
Competitive systems have the ability to show time skip buttons for podcast and audiobook media that desire them. These kinds of buttons reduce confusion with the driver by showing them what will be happening when they skip forward and back. Current systems can only show a skip track button, which works for music, but less so for podcasts and audiobooks.

## Proposed solution
The proposed solution, similar to [SDL-0109](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0109-set-audio-streaming-indicator.md) is to update
the `SetMediaClockTimer` RPC to alter these buttons on the UI, assuming the developer is subscribed.

```xml
<enum name="SeekIndicatorType">
    <element name="TRACK">
    <element name="TIME">
</enum>

<struct name="SeekStreamingIndicator">
    <description>
        The seek next / skip previous subscription buttons' content
    </description> 

    <param name="type" type="SeekIndicatorType" mandatory="true" />
    <param name="seekTime" type="Int" minValue="1" maxValue="99" mandatory="false">
        <description>If the type is TIME, this number of seconds may be present alongside the skip indicator. It will indicate the number of seconds that the currently playing media will skip forward or backward.</description>
    </param>
</struct>

<function name="SetMediaClockTimer" messagetype="request">
  <!-- Additions -->
  <param name="forwardSeekIndicator" type="SeekStreamingIndicator" mandatory="false" />
  <param name="backSeekIndicator" type="SeekStreamingIndicator" mandatory="false" />
</function>
```

By default the seek indicators should be `TRACK` when:

* the media app is newly registered on the head unit (after `RegisterAppInterface` and the button subscription)
* the media app was closed by the user (App enters `HMI_NONE`)
* the app sends `SetMediaClockTimer` with `forwardSeekIndicator` and / or `backSeekIndicator` not set to any value.

Additional changes to the HMI spec will be required to indicate that the HMI should alter the seek indicators.

## Potential downsides
This is additional design that HMIs may take into account (it is optional, but very useful for developers). No additional downsides were identified.

## Impact on existing code
This will be a minor version change across platforms.

## Alternatives considered
1. An additional RPC could be added to change these subscription buttons, but the choice was made to keep it in line with SDL-0109.
