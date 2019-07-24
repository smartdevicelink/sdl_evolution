# Custom Playback Rates for SetMediaClockTimer

* Proposal: [SDL-NNNN](NNNN-setmediaclocktimer-custom-playback-rates.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Awaiting review**
* Impacted Platforms: [Core / iOS / Java Suite / HMI / RPC]

## Introduction
This proposal adds the ability for a media app to set the media playback timer and bar to advance at a custom rate like 125% speed.

## Motivation
Many non-music audio apps, such as podcast and audiobook apps have features that allow users to playback the audio at a rate that is not 1.0. For example, a user can play a podcast at 125% speed. Competitors like Carplay have this ability built in, and without this ability, the playback timer gets out of sync every few seconds, requiring the developer to update manually update the timer.

## Proposed solution
The proposed solution is to add a new `SetMediaClockTimer` RPC parameter called `countRate` that can be set to modify the speed at which the playback timer advances.

### MOBILE_API
```xml
<function name="SetMediaClockTimer" functionID="SetMediaClockTimerID" messagetype="request" since="1.0">
    <description>Sets the initial media clock value and automatic update method.</description>
        
    <!-- New Parameter -->
    <param name="countRate" type="Float" minValue="0.1" maxValue="100.0" defvalue="1.0" mandatory="false" since="X.X">
        <description>
        The value of this parameter is the amount that the media clock timer will advance per 1.0 seconds of real time.
        
        Values less than 1.0 will therefore advance the timer slower than real-time, while values greater than 1.0 will advance the timer faster than real-time.

        e.g. If this parameter is set to `0.5`, the timer will advance one second per two seconds real-time, or at 50% speed. If this parameter is set to `2.0`, the timer will advance two seconds per one second real-time, or at 200% speed.
        </description>
    </param>
</function>
```

### HMI_API
The changes are identical to the above but applied to `UI.SetMediaClockTimer`.

## Potential downsides
1. There is no way for a head unit to declare its support for this feature, so any head unit implementing this version of SDL Core will _have_ to support this feature.

## Impact on existing code
This will be a minor version change. 

The app library screen manager will need an update if it supports a high-level API for the `SetMediaClockTimer` at that point. It doesn't currently however, so I cannot provide those changes in this proposal.

## Alternatives considered
No alternatives were considered.