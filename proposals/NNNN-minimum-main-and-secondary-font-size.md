# Minimum Main and Secondary Font Size
* Proposal: [SDL-NNNN](NNNN-NNNN-minimum-main-and-secondary-font-size.md)
* Author: [Michael Crimando](https://github.com/MichaelCrimando), [Kujtim Shala](https://github.com/kshala-ford)
* Status: **Awaiting review**
* Impacted Platforms: [Core / iOS / Android / RPC]

## Introduction

This proposal is about adding parameters to `VideoStreamingCapabilities` for minimum main and secondary font size 
for the purpose of ensuring a sufficient and readable font size while projecting.

## Motivation

Today navigation app developers create a video stream using the screen resolution in pixel without knowing the screen size/pixel density. 
This can result into differnt font sizes on screens with the same size but different resolutions.
This can be an issue following NHTSA driver distraction guidelines.
OEMs may also have font size requirements to ensure that text displayed on the screen is readable.

## Proposed solution

The idea is to include the minimum font size for
- main text 
- secondary/conditional text

### Mobile API & HMI changes

```xml
<struct name="VideoStreamingCapability">
  <param name="minimumMainFontSize" type="Float" mandatory="false">
    <description>
      The minimum font size for text.
      Mainly every text should be at a minimum of this font size except text
      that is minor supporting information. 
      Size is in points (1/72 inch).
    </description>
  </param>
  <param name="minimumConditionalFontSize" type="Float" mandatory="false">
    <description>
      The minimum font size for subtext.
      Every text that does not meet the requirements of main text can be
      presented at a minimum of this font size.
      Size is in points (1/72 inch).
    </description>
  </param>
</struct>
```

### Core changes

Core receives the values from the HMI and passes them on to the app.

### iOS & Android changes

Both libraries require two new properties added to the `VideoStreamingCapability` class.

## Potential downsides

No downsides are expected by this proposal.

## Impact on existing code

The requested change would require a minor version increase. 
There's no impact expected to existing code outside of `VideoStreamingCapability`.

## Alternatives considered

An alternative could be to use `ScreenParams` sent back by `RegisterAppInterfaceResponse`:

```xml
<struct name="ScreenParams">
  <param name="minimumMainFontSize" type="Float" mandatory="false">
    <description>
      The minimum font size for text.
      Mainly every text should be at a minimum of this font size except text
      that is minor supporting information. 
      Size is in points (1/72 inch).
    </description>
  </param>
  <param name="minimumConditionalFontSize" type="Float" mandatory="false">
    <description>
      The minimum font size for subtext.
      Every text that does not meet the requirements of main text can be
      presented at a minimum of this font size.
      Size is in points (1/72 inch).
    </description>
  </param>
</struct>
```

Another alternative could be to provide font size requirements to the app developer through the online documentation.
