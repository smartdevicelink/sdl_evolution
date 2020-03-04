# ShowConstantTBT Description Update

* Proposal: [SDL-NNNN](NNNN-ConstantTBT-Update.md)

* Author: [Michael Crimando](https://github.com/MichaelCrimando)
* Status: **Awaiting review**
* Impacted Platforms: [RPC]

## Introduction

 This proposal is to update the descriptions of `ShowConstantTBT`'s parameters `distanceToManeuver` and `distanceToManeuverScale` so we get consistent use of them across all OEMs and Navigation apps. 

## Motivation

In the future, there will be a need for Navigation apps to show a progress bar to an upcoming turn in the HMI.  In order to display this, `ShowConstantTBT` has had parameters of `distanceToManeuver` and `distanceToManeuverScale` in place since SDL 1.0. However, the description on them isn't entirely clear.  This proposal is to update the descriptions so we get consistent use of them across all OEMs and apps. 

Current descriptions in MOBILE API:
```xml
        <param name="distanceToManeuver" type="Float" minvalue="0" maxvalue="1000000000" mandatory="false" since="2.0">
            <description>
                Fraction of distance till next maneuver (starting from when AlertManeuver is triggered).
                Used to calculate progress bar.
            </description>
        </param>
        <param name="distanceToManeuverScale" type="Float" minvalue="0" maxvalue="1000000000" mandatory="false" since="2.0">
            <description>
                Distance till next maneuver (starting from) from previous maneuver.
                Used to calculate progress bar.
            </description>
        </param>
```

Current descriptions in HMI API:
```xml
 <function name="ShowConstantTBT" messagetype="request">
  .
  .
  .
    <param name="distanceToManeuver" type="Float" minvalue="0" maxvalue="1000000000" mandatory="true">
      <description>Fraction of distance till next maneuver (from previous maneuver).</description>
      <description>May be used to calculate progress bar.</description>
    </param>
    <param name="distanceToManeuverScale" type="Float" minvalue="0" maxvalue="1000000000" mandatory="true">
      <description>Fraction of distance till next maneuver (starting from when AlertManeuver is triggered).</description>
      <description>May be used to calculate progress bar.</description>
    </param>
  </function>
```

## Proposed solution
In both the API documents change it to be:
```xml
 <function name="ShowConstantTBT" messagetype="request">
  .
  .
  .
    <param name="distanceToManeuver" type="Float" minvalue="0" maxvalue="1000000000" mandatory="true">
      <description>Distance (in meters) until next maneuver. May be used to calculate progress bar.</description>
    </param>
    <param name="distanceToManeuverScale" type="Float" minvalue="0" maxvalue="1000000000" mandatory="true">
      <description>Distance (in meters) from previous maneuver to next maneuver. May be used to calculate progress bar.</description>
    </param>
  </function>
```

## Potential downsides

If any apps or OEMs implemented this a certain way, this logic may not match what they did.

## Impact on existing code

None

## Alternatives considered

Change both sets of descriptions to not mention meters.  Plus add in a way for for the app to label the units in showConstantTBT
```xml
 <function name="ShowConstantTBT" messagetype="request">
  .
  .
  .
    <param name="distanceToManeuver" type="Float" minvalue="0" maxvalue="1000000000" mandatory="true">
      <description>Distance units until next maneuver. May be used to calculate progress bar.</description>
    </param>
    <param name="distanceToManeuverScale" type="Float" minvalue="0" maxvalue="1000000000" mandatory="true">
      <description>Distance units from previous maneuver to next maneuver. May be used to calculate progress bar.</description>
    </param>
  </function>
```
