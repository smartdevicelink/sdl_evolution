# Updating DOP value range for GPS notification

* Proposal: [SDL-NNNN](NNNN-Updating-DOP-value-range-for-GPS-notification.md)
* Author: [Ankur Tiwari](https://github.ford.com/ATIWARI9)
* Status: **Awaiting review**
* Impacted Platforms: [Core / iOS / Android / RPC ]

## Introduction

This proposal is to update the range and make these fields non mandatory for DOP values in GPS notification for GetVehicleData and OnVehicleData RPCs.

## Motivation

Current range for vdop/hdop/pdop values is 0-10. GPS sensor can provide DOP values way more than that. This causes SDL to ignore GPS data with DOP values more than 10 even if the GPS switches to Dead Reckoning based solution. Since the range of DOP is determined by actual sensor itself, we should not limit it as SDL/Proxy side.

## Proposed solution

To increase the maxvalue for vdop, pdop and hdop parameters to 65535 from 10 in GetVehicleData response and onVehicleData notification. Since DOP cannot reach that high value, this will ensure that gps notifications are NOT filtered out due to DOP.
And to make the hdop, pdop, vdop fields non mandatory for both HMI and Mobile APIs so that SDL allows the GPS notification without these params as well in case GPS sensor omits these parameters.

**Proposed Mobile API changes:**
```
  <struct name="GPSData">
    <description>Struct with the GPS data.</description>
	<param name="longitudeDegrees" type="Float" minvalue="-180" maxvalue="180">
	</param>
	<param name="latitudeDegrees" type="Float" minvalue="-90" maxvalue="90">
	</param>
    <param name="utcYear" type="Integer" minvalue="2010" maxvalue="2100" mandatory="false">
    	<description>The current UTC year.</description>
    </param>
    <param name="utcMonth" type="Integer" minvalue="1" maxvalue="12" mandatory="false">
    	<description>The current UTC month.</description>
    </param>
    <param name="utcDay" type="Integer" minvalue="1" maxvalue="31" mandatory="false">
    	<description>The current UTC day.</description>
    </param>
    <param name="utcHours" type="Integer" minvalue="0" maxvalue="23" mandatory="false">
    	<description>The current UTC hour.</description>
    </param>
    <param name="utcMinutes" type="Integer" minvalue="0" maxvalue="59" mandatory="false">
    	<description>The current UTC minute.</description>
    </param>
    <param name="utcSeconds" type="Integer" minvalue="0" maxvalue="59" mandatory="false">
    	<description>The current UTC second.</description>
    </param>
    <param name="compassDirection" type="CompassDirection" mandatory="false">
    	<description>See CompassDirection.</description>
    </param>
    <param name="pdop" type="Float" minvalue="0" mandatory="false" since="X.Y">
    	<description>PDOP.  If undefined or unavailable, then value shall be set to 0.</description>
	<history>
    		<param name="pdop" type="Float" minvalue="0" maxvalue="65535" defvalue="0" mandatory="false" until="X.Y">
    		</param>
	</history>
    </param>
    <param name="hdop" type="Float" minvalue="0" mandatory="false" since="X.Y">
    	<description>HDOP.  If value is unknown, value shall be set to 0.</description>
	<history>
    		<param name="hdop" type="Float" minvalue="0" maxvalue="65535" defvalue="0" mandatory="false" until="X.Y">
    		</param>
	</history>
    </param>
    <param name="vdop" type="Float" minvalue="0" mandatory="false" since="X.Y">
    	<description>VDOP.  If value is unknown, value shall be set to 0.</description>
	<history>
    		<param name="vdop" type="Float" minvalue="0" maxvalue="65535" defvalue="0" mandatory="false" until="X.Y">
    		</param>
	</history>
    </param>
    <param name="actual" type="Boolean" mandatory="false">
    	<description>
    		True, if actual.
    		False, if inferred.
    	</description>
    </param>
    <param name="satellites" type="Integer" minvalue="0" maxvalue="31" mandatory="false">
    	<description>Number of satellites in view</description>
    </param>
    <param name="dimension" type="Dimension" mandatory="false">
    	<description>See Dimension</description>
    </param>
    <param name="altitude" type="Float" minvalue="-10000" maxvalue="10000" mandatory="false">
    	<description>Altitude in meters</description>
    </param>
	<param name="heading" type="Float" minvalue="0" maxvalue="359.99" mandatory="false">
    	<description>The heading. North is 0. Resolution is 0.01</description>
    </param>
    <param name="speed" type="Float" minvalue="0" maxvalue="500" mandatory="false">
    	<description>The speed in KPH</description>
    </param>
    <param name="shifted" type="Boolean" mandatory="false">
    	<description>
    		True, if GPS lat/long, time, and altitude have been purposefully shifted (requiring a proprietary algorithm to unshift).
    		False, if the GPS data is raw and un-shifted.
    		If not provided, then value is assumed False.
    	</description>
    </param>
  </struct>

  <struct name="VehicleDataResult">
    <description>Individual published data request result</description>
    <param name="dataType" type="VehicleDataType">
      <description>Defined published data element type.</description>
    </param>
    <param name="resultCode" type="VehicleDataResultCode">
      <description>Published data result code.</description>
    </param>
  </struct>
```

## Potential downsides

None

## Impact on existing code

* RPC needs to be updated with new parameter
* SDL core and mobile proxy lib need updates

## Alternatives considered

* Instead of increasing the maxvalue range, the maxvalue can be removed altogether
  *	Not sure if SDL/Proxy would need this value set.
* To NOT send DOP values from Sensor when Dead Reckoning is being used
  * Data is directly sourced from sensor, so there is no business logic applied to it beforehand.
  
