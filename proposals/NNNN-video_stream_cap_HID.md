# Haptic Spatial Data Support Capabilities

* Proposal: [SDL-NNNN](NNNN-video_stream_cap_HID)
* Author: [Joey Grover](https://github.com/joeygrover)
* Status: **Awaiting Review**
* Impacted Platforms: [RPC/Android/iOS/Core]

## Introduction

With the acceptance of [0075 Human Interface Device Support](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0075-HID-Support-Plug-in.md) we introduced a new feature that should be settable by the module that implements it.
 
## Motivation
There should be proper informing of whether or not the module supports the HID functionality. This will help reduce traffic if the system doesn't support it.

## Proposed solution
Add a single param to the `VideoStreamingCapability` struct:

```xml
    <struct name="VideoStreamingCapability">
        <description>Contains information about this system's video streaming capabilities.</description>
        ....
        <param name="hapticSpatialDataSupported" type="Boolean" mandatory="false">
            <description>True if the system can utilize the haptic spatial data from the source being streamed. </description>
        </param>
    
    </struct>

```

## Potential downsides
N/A


## Impact on existing code
- Shouldn't affect existing code as it is not implemented yet or been released. It will simply be the addition of another parameter to an existing struct.

## Alternatives considered
- Not introducing the param and letting the proxies send the HID data regardless.

