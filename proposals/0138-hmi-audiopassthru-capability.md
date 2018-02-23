# Make 'audioPassThruCapabilities' of HMI an array

* Proposal: [SDL-0138](0138-hmi-audiopassthru-capability.md)
* Author: [Sho Amano](https://github.com/shoamano83)
* Status: **Accepted**
* Impacted Platforms: [Core / RPC]

## Introduction

This document proposes to update AudioPassThru capability parameter in `UI.GetCapabilities` response and hmi\_capabilities.json file to an array.

## Motivation

In MOBILE\_API.xml, `audioPassThruCapabilities` parameter in `RegisterAppInterface` response is defined as an array. This makes sense since HMI can support more than one recording formats for AudioPassThru feature.

On the other hand, `audioPassThruCapabilities` parameter in `UI.GetCapabilities` response is not defined as an array in HMI\_API.xml. Therefore HMI can only provide one recording format, even if the head unit supports multiple ones.


## Proposed solution

To resolve the inconsistency, this document proposes to append a parameter called `audioPassThruCapabilitiesList` in HMI\_API.xml. The parameter is defined as an array.

Note that the old `audioPassThruCapabilities` parameter is left intact so that we do not break compatibility. SDL Core tries to read both `audioPassThruCapabilitiesList` and `audioPassThruCapabilities` parameters. If `audioPassThruCapabilitiesList` is available, Core uses it instead of `audioPassThruCapabilities`.

It is also proposed to update hmi\_capabilities.json file, so that head unit developers will be aware that HMI can return multiple recording capabilities.


## Detailed design

### Modification to HMI\_API.xml

```diff
-<interface name="UI" version="1.2.0" date="2017-09-05">
+<interface name="UI" version="1.3.0" date="2018-02-13">
 
   :
 
   <function name="GetCapabilities" messagetype="response">
 
     :
 
-    <param name="audioPassThruCapabilities" type="Common.AudioPassThruCapabilities" mandatory="true"/>
+    <param name="audioPassThruCapabilities" type="Common.AudioPassThruCapabilities" mandatory="true">
+      <description>
+        Describes an audio configuration that the system supports for PerformAudioPassThru.
+        Note: please fill out both audioPassThruCapabilities and audioPassThruCapabilitiesList parameters, as:
+        - Newer SDL Core uses audioPassThruCapabilitiesList instead of audioPassThruCapabilities.
+        - audioPassThruCapabilities is a mandatory field and cannot be omitted.
+      </description>
+    </param>
+    <param name="audioPassThruCapabilitiesList" type="Common.AudioPassThruCapabilities" minsize="1" maxsize="100" array="true">
+      <description>Describes the audio configurations that the system supports for PerformAudioPassThru.</description>
+    </param>
```

Note: no change is required for MOBILE\_API.xml.


### Modification of Core

The logic to acquire AudioPassThru capability information is updated to check `audioPassThruCapabilitiesList` first, then `audioPassThruCapabilities`.

Also, update src/appMain/hmi\_capabilities.json file as follows:
```diff
 {
     "UI": {
 
         :
 
-        "audioPassThruCapabilities": {
+        "audioPassThruCapabilities": [{
             "samplingRate": "44KHZ",
             "bitsPerSample": "RATE_8_BIT",
             "audioType": "PCM"
-        },
+        }],
```

HMICapabilitiesImpl::load\_capabilities\_from\_file() should be update to read `audioPassThruCapabilities` as an array.


## Potential downsides

The author does not come up with any potential downsides.

## Impact on existing code

Core: the logic to acquire AudioPassThru parameter from HMI and from hmi\_capabilities.json file is affected.

HMI: not affected. However, it is recommended to update its implementation to use new `audioPassThruCapabilitiesList` parameter.

## Alternatives considered

- Change `audioPassThruCapabilities` parameter to an array.<br>
  Originally the author created this proposal based on this idea and received concerns that it breaks compatibility.
- Keep current HMI\_API.xml. This approach does not support a head unit that is capable of (and wants to provide) multiple recording capabilities.
