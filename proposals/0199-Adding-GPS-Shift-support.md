# Adding GPS Shift support

* Proposal: [SDL-0199](0199-Adding-GPS-Shift-support.md)
* Author: [Ankur Tiwari](https://github.com/ATIWARI9)
* Status: **In Review**
* Impacted Platforms: [Core / iOS / Android / RPC]

## Introduction

To add _shifted_ param for GPS data struct so that HMI can communicate to app when GPS data is shifted using an algorithm

## Motivation

China region needs GPS data to be corrected using proprietary algorithm to bridge the gap between different standards used. HMI would need to communicate the same to phone app as GPS data shift is applied based on location (e.g. Hong Kong, Macau do not need the correction).

## Proposed solution

Add new param _shifted_ in _GPSData_ struct as follows:

* HMI API (in _Common_ interface)

```
<struct name="GPSData">
	<description>Struct with the GPS data.</description>
	<param name="longitudeDegrees" type="Float" minvalue="-180" maxvalue="180" mandatory="false">
	</param>
	<param name="latitudeDegrees" type="Float" minvalue="-90" maxvalue="90" mandatory="false">
	</param>
	.
	.
	.
	.
	<param name="speed" type="Float" minvalue="0" maxvalue="500" mandatory="false">
		<description>The speed in KPH</description>
	</param>
	<param name="shifted" type="Boolean" mandatory="false" since="x.y">
		<description>
		  True, if GPS lat/long, time, and altitude have been purposefully shifted (requires a proprietary algorithm to unshift).
		  False, if the GPS data is raw and un-shifted.
		  If not provided, then value is assumed False.
		</description>
	</param>
</struct>
```

* Mobile API

```
<struct name="GPSData">
	<description>Struct with the GPS data.</description>
	<param name="longitudeDegrees" type="Float" minvalue="-180" maxvalue="180" mandatory="true">
	</param>
	<param name="latitudeDegrees" type="Float" minvalue="-90" maxvalue="90" mandatory="true">
	</param>
	.
	.
	.
	.
	<param name="speed" type="Float" minvalue="0" maxvalue="500" mandatory="true">
            <description>The speed in KPH</description>
	</param>
	<param name="shifted" type="Boolean" mandatory="false" since="x.y">
		<description>
		  True, if GPS lat/long, time, and altitude have been purposefully shifted (requires a proprietary algorithm to unshift).
		  False, if the GPS data is raw and un-shifted.
		  If not provided, then value is assumed False.
		</description>
	</param>
</struct>
```

## Potential downsides
None

## Impact on existing code

SDL core and proxy would need update.

## Alternatives considered
To not send the shifted information, but then it'd not be possible for phone app to know if it needs to compensate for shifted/unshifted GPS data.
