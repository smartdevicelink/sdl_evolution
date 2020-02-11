# Modify the range of APT's maxDuration

* Proposal: [SDL-NNNN](NNNN-modify-the-range-of-APT's-maxDuration.md)
* Author: [zhouxin627](https://github.com/zhouxin627)
* Status: **Awaiting review**
* Impacted Platforms: [RPC]

## Introduction
This proposal modifies the range of APT's maxDuration.

## Motivation
In the [PerformAudioPassThru section](https://smartdevicelink.com/en/guides/hmi/ui/performaudiopassthru/) of the HMI Documentation, the value range of `PerformAudioPassThru.maxDuration` is defined as 1-1000000ms.


In practical use, if the `PerformAudioPassThru.maxDuration` is set too small, for instance, 1ms, then it is obviously not enough for the HU to handle APT.

For example, this is an issue if `PerformAudioPassThru.maxDuration` is set to 1ms.


### Reproduction Steps
1. Send a TTS (TTS1)
2. TTS1 is speaking
3. Send an APT RPC with TTS (TTS2), and the maxduration is set to 1ms

### Expect Result
1. TTS1 stops
2. APT ONS appears and TTS2 starts
3. TTS2 stops and APT ONS disappears

### Observed Result
1. TTS1 stops
2. The APT ONS appears and disappears instantly, but the TTS2 is still playing.


SDL Core measures the timeout with the duration set by APT, and SDL Core's processing time is also included in the timeout. When the duration of APT is set too short, SDL Core may be processing the interrupt operation of TTS1. And then, when TTS2 has not stopped, the ONS has disappeared already.


It is a misunderstanding that the specification itself can set the max duration of APT to 500ms or less. As for the user, the possible consuming time of speaking is usually 3000ms or more.



## Proposed solution
Similar to the duration of Alert (3000ms-10000ms), we can uniformly spec the range of APT's `maxDuration` from 3000ms to 1000000ms.

Definition of Alert:
https://www.smartdevicelink.com/zh-hans/guides/hmi/ui/alert/

### Detailed design
#### MOBILE_API Updates
Change the `minvalue` of `maxDuration` from 1 to 3000.
```xml
        <param name="samplingRate" type="SamplingRate" mandatory="true">
            <description> This value shall be allowed at 8 kHz or 16 or 22 or 44 kHz.</description>
        </param>
-       <param name="maxDuration" type="Integer" minvalue="1" maxvalue="1000000" mandatory="true">
+       <param name="maxDuration" type="Integer" minvalue="3000" maxvalue="1000000" mandatory="true">
            <description>The maximum duration of audio recording in milliseconds. </description>
        </param>
        <param name="bitsPerSample" type="BitsPerSample" mandatory="true">
```

#### HMI_API Updates
Change the `minvalue` of `maxDuration` from 1 to 3000.
```xml
            audioPassThruDisplayText1: First line of text displayed during audio capture.
            audioPassThruDisplayText2: Second line of text displayed during audio capture.</description>
    </param>
-   <param name="maxDuration" type="Integer" minvalue="1" maxvalue="1000000" mandatory="true">
+   <param name="maxDuration" type="Integer" minvalue="3000" maxvalue="1000000" mandatory="true">
      <description>The maximum duration of audio recording in milliseconds. If not provided, the recording should be performed until EndAudioPassThru arrives.</description>
    </param>
    <param name="muteAudio" type="Boolean" mandatory="true">
```

## Potential downsides
No downsides were identified.

## Impact on existing code
This proposal has no breaking change, so there should be no impact on existing code.

## Alternatives considered
No alternatives were identified.
