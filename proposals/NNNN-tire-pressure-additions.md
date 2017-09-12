```
# Tire pressure additions

* Proposal: [SDL-NNNN](NNNN-tire-pressure-additions.md)
* Author: [Kujtim Shala](https://github.com/kshala-ford)
* Status: **Awaiting review**
* Impacted Platforms: [Core / iOS / Android / RPC ]

## Introduction

The proposal is about extending the existing tire pressure API by providing the actual pressure value and the TPMS status of an actual tire.

## Motivation

The public API does not provide a sufficient information about the tire status and pressure. Apps that evaluate vehile information want to use the tire status from TPMS and the actual pressure. 

## Proposed solution

The proposed solution is to simply extend `SingleTireStatus`

```xml
<enum name="TPMS">
<element name="UNKNOWN">
  <description>If set the status of the tire is not known.</description>
</element>
<element name="SYSTEM_FAULT">
  <description>TPMS does not function.</description>
</element>
<element name="SENSOR_FAULT">
  <description>The sensor of the tire does not function.</description>
</element>
<element name="LOW">
  <description>TPMS is reporting a low tire pressure for the tire.</description>
</element>
<element name="SYSTEM_ACTIVE">
  <description>TPMS is active and the tire pressure is monitored.</description>
</element>
<element name="TRAIN">
  <description>TPMS is reporting that the tire must be trained.</description>
</element>
<element name="TRAINING_COMPLETE">
  <description>TPMS reports the training for the tire is completed.</description>
</element>
<element name="NOT_TRAINED">
  <description>TPMS reports the tire is not trained.</description>
</element>
</enum>

<struct name="SingleTireStatus">
  <param name="status" type="ComponentVolumeStatus"> <!-- Candidate to be deprecated -->
    <description>See ComponentVolumeStatus.</description>
  </param>
  <param name="tpms" type="TPMS" mandatory="false">
    <description>
      The status of TPMS according to the particular tire.
    </description>
  </param>
  <param name="pressure" type="Float" mandatory="false" minvalue="0" maxvalue="2000">
    <description>The pressure value of the particular tire in kilo pascal.</description>
  </param>
</struct>
```

## Potential downsides

As the proposal is only adding additional parameters inside the `tirePressure` vehicle data there's no potential downside identified.

## Impact on existing code

The proposal requires minor changes to Core and the libraries. It's not of a breaking change.

## Alternatives considered

As an alternative the `status` parameter could be extended to include TPMS parameters. However as `ComponentVolumeStatus` is used to indicate the state of fuel level it should not be changed.
