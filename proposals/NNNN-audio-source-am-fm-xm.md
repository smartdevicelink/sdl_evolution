# Audio Source AM/FM/XM

* Proposal: [SDL-NNNN](NNNN-audio-source-am-fm-xm.md)
* Author: [Zhimin Yang](https://github.com/smartdevicelink/yang1070)
* Status: **Awaiting review**
* Impacted Platforms: [iOS / Android / RPC / Core / Web Hmi ]

## Introduction

SDL remote control allows a mobile application to change the current audio source. When an application sets the audio source to `RADIO_TUNER`, the vehicle is supposed to use the last known/used radio band (AM/FM/XM) and frequency/station of the tuner. However, the application has no knowledge of last used radio band before sending such a request. The vehicle may or may not store the last used radio band. Therefore, the result of setting the audio source to `RADIO_TUNER` is unknown to the application. It is better for an application to set the audio source directly to `AM`, `FM` or `XM` (XM is for SiriusXM).

## Motivation
To give applications direct control of which radio band or SiriusXM radio they want to set as the audio source, we split `RADIO_TUNER` with detailed options.


## Proposed solution

In this proposal, we propose to replace the `RADIO_TUNER` with three enumeration elements `AM`, `FM` and `XM`.
We have the same changes for both the mobile_api and hmi_api.

```xml
  <enum name="PrimaryAudioSource">
    <description>Reflects the current primary audio source (if selected).</description>
    ...
    <element name="MOBILE_APP">
    </element>
-    <element name="RADIO_TUNER">
-      <description>Radio may be on AM, FM or XM</description>
-    </element>
+    <element name="AM">
+    </element>
+    <element name="FM">
+    </element>
+    <element name="XM">
+    </element>
+    <element name="DAB">
+    </element>
  </enum>
```

Because the parameters (audio source, radio band, and radio frequency) belong to two different remote control moubleTypes, in order to set the audio source to a specific radio station or radio frequency, a mobile application needs to send two `setInteriorVehicleData` requests in sequence. The firsts request sets the audio source to `AM`/`FM`/`XM` with targeted `moduleType=AUDIO`. The second request sets the desired frequency of `AM`/`FM` radio or station number of `XM` radio with targeted `moduleType=RADIO`. This is true regardless of this proposal.


## Potential downsides

None

## Impact on existing code

The impact on the existing code is small. The mobile proxy libs need to allow the new enumeration values. Core needs to rebuild with updated interface xml files. Web hmi needs to accept the new values and set the correct audio source.


## Alternatives considered
The previous assumption of any `RADIO` operation is that radio is turned on and is the current audio source of the vehicle's infotainment system. Otherwise, the operation will fail, as radio is not ready. That's why we need two requests to finish the task. A request to turn on the radio and set audio source. A request to change radio settings. Now we might change that to one request. If a `setInteriorVehicleData` request with targeted `moduleType=RADIO` and parameter `radioEnabled=true` and other parameters like `band` and frequency, the vehicle HMI (not SDL) will turn on the radio, sets it as the audio source if the current audio source is not the desired `AM`/ `FM`/ `XM` radio in the request, and then change the frequency. The advantage is that the application does not need to send a separate request to change audio source first. The disadvantages are (1) we change how the `RADIO` module works as we accept requests when radio is not ready. (2) We still do not know the required radio band if a request does not specify it (that is a valid request because no parameters are mandatory). The same problem addressed in this proposal is not solved. (3) Other parameters related to audio source switching, like `keepContext` in `AUDIO`, are not available in `RADIO` module. 

We think this is outside the scope of SDL. It is up to each OEM to decide how their vehicle HMI will do when receiving such a request.

