# Clarification of audio format details of AudioPassThru

* Proposal: [SDL-0139](0139-apt-clarification.md)
* Author: [Sho Amano](https://github.com/shoamano83)
* Status: **In Review**
* Impacted Platforms: [Document / Core / RPC]

## Introduction

The aim of this proposal is to clarify the details of audio data format of AudioPassThru recording.

## Motivation

The author noticed that the format of audio data recorded by AudioPassThru (APT) feature has inconsistency between SDL Core and Ford TDK. SDL Core appends a Resource Interchange File Format (RIFF) header at the front of audio data, while TDK doesn't. Livio and Ford teams helped the author on #ford Slack channel to determine that TDK's format is the correct one.

The author thinks it is a good idea to clarify this kind of specification in a document, so that we can avoid further confusions of app developers. Also, Core implementation should be fixed to align with TDK.


## Proposed solution

We should clarify that audio data recorded by AudioPassThru does not have RIFF header at the beginning. Also, since RIFF header is not available, we should clarify the details of audio data format.

This document proposes to add following details of audio data format recorded by AudioPassThru feature in an official document:
1. The audio data does not have RIFF header at the beginning.
2. The audio data is linear PCM (i.e. not compressed like Adaptive DPCM)
3. The audio data contains only one channel (i.e. it is monaural)
4. For 8-bit width configuration, the audio samples are unsigned. For 16-bit width configuration, the audio samples are signed, and are in little endian.
5. 44kHz sampling rate actually means 44100Hz. 22kHz sampling rate means 22050Hz.

Rationale:
1. This is the correct audio data format confirmed by Livio and Ford teams.
2. Linear PCM is a very common format for multimedia. Also, audio data recorded by TDK can be played back if we append properly configured RIFF header of linear PCM.
3. It has been confirmed by Ford team that TDK outputs in monaural. Also, as far as the author knows most head units are equipped with one-channel microphone.
4. These are the common configurations for LPCM files, and the author assumes that AudioPassThru follows them.
5. Again, 44100Hz and 22050Hz are widely used for recording sampling rate, so the author assumes that AudioPassThru also uses these sampling rates.

Also, Core implementation should be fixed to remove RIFF header from recorded data and make sure it outputs in monaural.


## Detailed design

### Modification to documents

As for now, the best document that explains AudioPassThru feature in detail is the iOS guide:
https://smartdevicelink.com/en/guides/iOS/getting-in-car-microphone-audio/

Add following description in the page, probably under "Gathering Audio Data" section:
```
The format of audio data is described as follows:
- It does not include any header like RIFF header at the beginning.
- The audio sample is in linear PCM format.
- The audio data includes only one channel (i.e. monaural).
- For bit rates of 8 bits, the audio samples are unsigned. For bit rates of 16 bits, the audio samples are signed and are in little endian.
```


### Modification to MOBILE\_API.xml and HMI\_API.xml

Update some comment fields in the interface files. Suggested changes for MOBILE\_API.xml is shown below. Same changes should go into HMI\_API.xml.

```diff
     <enum name="SamplingRate">
         <description>Describes different sampling options for PerformAudioPassThru.</description>
-        <element name="8KHZ" internal_name="SamplingRate_8KHZ"/>
-        <element name="16KHZ" internal_name="SamplingRate_16KHZ"/>
-        <element name="22KHZ" internal_name="SamplingRate_22KHZ"/>
-        <element name="44KHZ" internal_name="SamplingRate_44KHZ"/>
+        <element name="8KHZ" internal_name="SamplingRate_8KHZ">
+            <description>Sampling rate of 8000 Hz.</description>
+        </element>
+        <element name="16KHZ" internal_name="SamplingRate_16KHZ">
+            <description>Sampling rate of 16000 Hz.</description>
+        </element>
+        <element name="22KHZ" internal_name="SamplingRate_22KHZ">
+            <description>Sampling rate of 22050 Hz.</description>
+        </element>
+        <element name="44KHZ" internal_name="SamplingRate_44KHZ">
+            <description>Sampling rate of 44100 Hz.</description>
+        </element>
     </enum>
 
     :
 
     <enum name="BitsPerSample">
         <description>Describes different quality options for PerformAudioPassThru.</description>
-        <element name="8_BIT" internal_name="BitsPerSample_8_BIT"/>
-        <element name="16_BIT" internal_name="BitsPerSample_16_BIT"/>
+        <element name="8_BIT" internal_name="BitsPerSample_8_BIT">
+            <description>Audio sample is 8 bits wide, unsigned.</description>
+        </element>
+        <element name="16_BIT" internal_name="BitsPerSample_16_BIT">
+            <description>Audio sample is 16 bits wide, signed, and in little endian.</description>
+        </element>
     </enum>
 
     :
 
     <enum name="AudioType">
         <description>Describes different audio type options for PerformAudioPassThru.</description>
-        <element name="PCM" />
+        <element name="PCM">
+            <description>Linear PCM.</description>
+        </element>
     </enum>
 
     :
 
    <struct name="AudioPassThruCapabilities">
         <description>
             Describes different audio type configurations for PerformAudioPassThru.
             e.g. {8kHz,8-bit,PCM}
+            The audio is recorded in monaural.
         </description>
        <param name="samplingRate" type="SamplingRate" mandatory="true"/>
        <param name="bitsPerSample" type="BitsPerSample" mandatory="true"/>
        <param name="audioType" type="AudioType" mandatory="true"/>
    </struct>
```

### Modification of Core

- Update `AudioStreamSenderThread` class to skip RIFF header when it reads the audio data (either recorded or prepared) from file.
- Update the GStreamer pipeline in `FromMicToFileRecorderThread` class to make sure that it always outputs audio in monaural.


## Potential downsides

The author does not come up with any potential downsides.


## Impact on existing code

- The changes in interface files do not have an impact on any implementation.
- The changes in Core are small and have an impact on only AudioPassThru feature.
- If a mobile developer is testing its AudioPassThru feature only against SDL Core and/or Ford emulator and not against TDK, then s/he needs to update the implementation to support the correct audio format.


## Out of scope of this proposal

It looks like Ford emulator also appends a RIFF header in front of the audio data. Since it is not maintained by SDLC, discussion related to it is out of the scope.


## Alternatives considered

Instead of fixing the audio stream to be monaural, extend `AudioPassThruCapabilities` struct to include information of the number of channels in the audio stream. The author did not investigate whether this change keeps backward compatibility. If such information is required, another proposal can be developed in future.

