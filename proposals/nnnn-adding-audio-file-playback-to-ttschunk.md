# Adding Audio File Playback to TTSChunk

* Proposal: [SDL-NNNN](NNNN-filename.md)
* Author: [Alex Muller](https://github.com/asm09fsu)
* Status: **Awaiting review**
* Review manager: TBD
* Impacted Platforms: Core / iOS / Android / RPC

## Introduction

More and more applications use sounds as a means to make a user feel more at home within their application, and allow the developer to have more customization of their User Experience. This proposal will allow developers to provide audio files uploaded to be played in conjunction with, or without, Text-to-Speech text, so that they may provide a more customized experience.

## Motivation

Expanding the TTSChunk struct to allow for audio files alongside text to speech greatly increases developers options of creating a great user experience, and also allows them to do it easily in an already existent structure. This becomes much more necessary for applications that are needing to be able to playback audio as a non-media application, for example digital assistants (Facebook M, Amazon Alexa, Google Now, Siri, Viv, etc.).

## Proposed solution

The solution works by expanding the capabilities of TTSChunk, with an additional SpeechCapabilities element that would point to a file previously uploaded to Core via a Putfile. With this addition, the ability to play and audio file along with speaking would impact  Alert, PerformAudioPassthrough, PerformInteraction, SetGlobalProperties and Speak.

## Detailed design

To allow for this, we would need to expand the `SpeechCapabilities` enum to support Files. Since `PRE_RECORDED` is used and relates to `PrerecordedSpeech`, we would add `FILES` as an element.

#### Mobile_API.xml
```
 <enum name="SpeechCapabilities">
    <description>Contains information about the TTS capabilities.</description>
    <element name="TEXT" internal_name="SC_TEXT"/>
    <element name="SAPI_PHONEMES" />
    <element name="LHPLUS_PHONEMES" />
    <element name="PRE_RECORDED" />
    <element name="SILENCE" />
	  <element name="FILE" />
  </enum>
```

The only part of TTSChunk that would change is the description to describe that you may also play back an uploaded audio file.
```
<struct name="TTSChunk">
    <description>A TTS chunk, that consists of the text/phonemes/file name to speak and the type (like text or SAPI)</description>
    <param name="text" minlength="0" maxlength="500" type="String">
      <description>
      	The text or phonemes to speak, or audio file to play.
      	May not be empty.
      </description>
    </param>
    <param name="type" type="SpeechCapabilities">
      <description>Describes, whether it is text or a specific phoneme set, or a file. See SpeechCapabilities</description>
    </param>
  </struct>
```

#### SDL Core
Core would need to be updated as well to support files in conjunction with normal TTSChunks. They should respect the order that the TTSChunks are passed in, as they already do. This new value should also be returned back in a successful RegisterAppInterface Response.

Core should support the following file types with the following properties:
- AUDIO_WAVE
	* Sample Rate: 16000 Hz
	* Bit Rate: 16
	* Mono Channel (1 Channel)
- AUDIO_MP3
	* Sample Rate: 44100 Hz
	* Bit Rate: 8 - 320
	* Mono Channel (1 Channel)
- AUDIO_AAC
	* Sample Rate: 44100 Hz
	* Bit Rate: 8 - 320
	* Mono Channel (1 Channel)

#### SDL iOS
The iOS library would need to have an additional class function added to `SDLSpeechCapabilities.h`
```
+ (SDLSpeechCapabilties*)FILE;
```
and `SDLSpeechCapabilities.m`
```
+ (SDLSpeechCapabilities *)FILE {
    if (SDLSpeechCapabilities_FILE == nil) {
        SDLSpeechCapabilities_FILE = [[SDLSpeechCapabilities alloc] initWithValue:@"FILE"];
    }
    return SDLSpeechCapabilities_FILE;
}
```

#### SDL Android
The Android library would need a single line added to `SpeechCapabilities.java`
```
public enum SpeechCapabilities {
	/**
	 * The SDL platform can speak text phrases.
	 *
	 * @since SmartDeviceLink 1.0
	 */
    TEXT,
    SAPI_PHONEMES,
    LHPLUS_PHONEMES,
    PRE_RECORDED,
    SILENCE,
	  FILE;		// <-- Added

   ...
}
```


## Impact on existing code

This should not have an impact on the existing code base. If a newer proxy sends this request to an unsupported Core, Core would respond with `INVALID_DATA`, and the developer should be aware of that. The developer will also receive back the available `SpeechCapabilities` of Core in a successful `RegisterAppInterface` Response, so they will know if it is supported or not, and to have a contingency plan if not.

If Core was to respond back with `SpeechCapabilities`, but the mobile side doesn't support it yet, no problems would arise, and a developer _could_ implement it themselves if they wished, although these would be developed simultaneously so this would most likely never happen.

## Alternatives considered

We could create an entirely new way of playing an uploaded audio file, however the use cases for playing an audio file luckily align with the currently used TTSChunk.
