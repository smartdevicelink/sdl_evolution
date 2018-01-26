# Make 'audioPassThruCapabilities' of HMI an array

* Proposal: [SDL-nnnn](nnnn-hmi-audiopassthru-capability.md)
* Author: [Sho Amano](https://github.com/shoamano83)
* Status: **Awaiting Review**
* Impacted Platforms: [Core / RPC]

## Introduction

This document proposes to change `audioPassThruCapabilities` parameter in `UI.GetCapabilities` response and hmi\_capabilities.json file to an array.

## Motivation

In MOBILE\_API.xml, `audioPassThruCapabilities` parameter in `RegisterAppInterface` response is defined as an array. This makes sense since HMI can support more than one recording formats for AudioPassThru feature.

On the other hand, `audioPassThruCapabilities` parameter in `UI.GetCapabilities` response is not defined as an array in HMI\_API.xml. Therefore HMI can only provide one recording format, even if the head unit supports multiple ones.


## Proposed solution

To resolve the inconsistency, this document proposes to update HMI\_API.xml so that `audioPassThruCapabilities` parameter is defined as an array.

It is also proposed to update hmi\_capabilities.json file, so that head unit developers will be aware that HMI can return multiple recording capabilities.


## Detailed design

### Modification to HMI\_API.xml

```diff
-<interface name="UI" version="1.2.0" date="2017-09-05">
+<interface name="UI" version="1.3.0" date="2018-01-24">
 
   :
 
   <function name="GetCapabilities" messagetype="response">
 
     :
 
-    <param name="audioPassThruCapabilities" type="Common.AudioPassThruCapabilities" mandatory="true"/>
+    <param name="audioPassThruCapabilities" type="Common.AudioPassThruCapabilities" minsize="1" maxsize="100" array="true" mandatory="true"/>
```

Note: no change is required for MOBILE\_API.xml.


### Modification of Core

Update src/appMain/hmi\_capabilities.json file as follows:
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

Also, HMICapabilitiesImpl::load\_capabilities\_from\_file() should be update to read `audioPassThruCapabilities` as an array.


## Potential downsides

The author does not come up with any potential downsides.

## Impact on existing code

Core: only the code inside HMICapabilitiesImpl::load\_capabilities\_from\_file() is affected.

HMI: update on `UI.GetCapabilities` implementation is required as the change in HMI\_API.xml is not backward compatible. When new SDL Core is installed on the head unit, OEMs should update their HMIs at the same time.

## Alternatives considered

- Append an optional parameter in `UI.GetCapabilities` response, such as "audioPassThruCapabilities2", to keep backward compatibility. This seems more confusing to developers as we have two similar parameters, one is mandatory and another is optional.
- Keep current HMI\_API.xml. This approach does not support a head unit that is capable of (and wants to provide) multiple recording capabilities.
