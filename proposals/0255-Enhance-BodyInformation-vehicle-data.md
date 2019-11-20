# Enhance BodyInformation vehicle data

* Proposal: [SDL-0255](0255-Enhance-BodyInformation-vehicle-data.md)
* Author: [Ankur Tiwari](https://github.com/atiwari9)
* Status: **Accepted with Revisions**
* Impacted Platforms: [Core | HMI | iOS | Java Suite | RPC]

## Introduction

This proposal is to enhance `BodyInformation` with more params to get access to more door related signals.

## Motivation

In order to partner with more diverse app partners, we need to provide additional sets of vehicle data items through SDL. This goes in line with commitment to enhance SDL with even richer vehicle data content. We need to provide apps with doors' lock status along with if trunk/liftgate or hood/bonnet are ajar. This information is handy for all the apps but in particular the apps which provide safety information and insurance.

## Proposed Solution 

Following vehicle data params are added to `BodyInformation` struct:
* `doorsStatus`
* `gatesStatus`

Following vehicle data params are deprecated from `BodyInformation` struct:
* `driverDoorAjar`
* `passengerDoorAjar`
* `rearLeftDoorAjar`
* `rearRightDoorAjar`

#### Updates in MOBILE_API:

##### New Struct `DoorStatus` is needed:
```xml
<struct name="DoorStatus" since="X.x">
	<description>Describes the status of a parameter of door.</description>
	<param name="doorLocation" type="Grid" mandatory="true"/>
	<param name="doorStatus" type="DoorStatusType" mandatory="true"/>
</struct>
```
##### New enum `DoorStatusType` is needed:
```xml
<enum name="DoorStatusType" since="X.x">
	<element name="CLOSED"/>
	<element name="LOCKED"/>
	<element name="AJAR"/>
</enum>
```

##### New Struct `GateStatus` is needed:
```xml
<struct name="GateStatus" since="X.x">
	<description>Describes the status of a parameter of trunk/hood/etc.</description>
	<param name="gateType" type="GateType" mandatory="true"/>
	<param name="gateStatus" type="DoorStatusType" mandatory="true"/>
</struct>
```

##### New enum `GateType` is needed:
```xml
<enum name="GateType" since="X.x">
	<element name="FRONT"/>
	<element name="BACK"/>
	<element name="RIGHT"/>
	<element name="LEFT"/>
</enum>
```

##### Then `BodyInformation` Struct would be updated as:
```xml
<struct name="BodyInformation" since="2.0">
	<param name="parkBrakeActive" type="Boolean" mandatory="true">
		<description>If mechanical park brake is active, true. Otherwise false.</description>
	</param>
	<param name="ignitionStableStatus" type="IgnitionStableStatus" mandatory="true">
		<description>Provides information on status of ignition stable switch. See IgnitionStableStatus.</description>
	</param>
	<param name="ignitionStatus" type="IgnitionStatus" mandatory="true">
		<description>Provides information on current ignitiion status. See IgnitionStatus.</description>
	</param>
	<param name="driverDoorAjar" type="Boolean" mandatory="false" deprecated="true" since="X.x">
		<description>References signal "DrStatDrv_B_Actl". Deprecated starting with RPC Spec X.x.x.</description>
	</param>
	<param name="passengerDoorAjar" type="Boolean" mandatory="false" deprecated="true" since="X.x">
		<description>References signal "DrStatPsngr_B_Actl". Deprecated starting with RPC Spec X.x.x.</description>
	</param>
	<param name="rearLeftDoorAjar" type="Boolean" mandatory="false" deprecated="true" since="X.x">
		<description>References signal "DrStatRl_B_Actl". Deprecated starting with RPC Spec X.x.x.</description>
	</param>
	<param name="rearRightDoorAjar" type="Boolean" mandatory="false" deprecated="true" since="X.x">
		<description>References signal "DrStatRr_B_Actl". Deprecated starting with RPC Spec X.x.x.</description>
	</param>
+	<param name="doorsStatus" type="DoorStatus" array="true" minsize="0" maxsize="100" mandatory="false" since="X.x">
+		<description>Provides status for doors if Ajar/Closed/Locked</description>
+	</param>	
+	<param name="gatesStatus" type="GateStatus" array="true" minsize="0" maxsize="100" mandatory="false" since="X.x">
+		<description>Provides status for trunk/hood/etc. if Ajar/Closed/Locked</description>
+	</param>
</struct>
```

#### Updates in HMI_API:


##### New Struct `DoorStatus` is needed in `Common` interface:
```xml
<struct name="DoorStatus" since="X.x">
	<description>Describes the status of a parameter of door.</description>
	<param name="doorLocation" type="Common.Grid" mandatory="true"/>
	<param name="doorStatus" type="Common.DoorStatusType" mandatory="true"/>
</struct>
```
##### New enum `DoorStatusType` is needed in `Common` interface:
```xml
<enum name="DoorStatusType" since="X.x">
	<element name="CLOSED"/>
	<element name="LOCKED"/>
	<element name="AJAR"/>
</enum>
```

##### New Struct `GateStatus` is needed in `Common` interface:
```xml
<struct name="GateStatus" since="X.x">
	<description>Describes the status of a parameter of trunk/hood/etc.</description>
	<param name="gateType" type="Common.GateType" mandatory="true"/>
	<param name="gateStatus" type="Common.DoorStatusType" mandatory="true"/>
</struct>
```

##### New enum `GateType` is needed in `Common` interface:
```xml
<enum name="GateType" since="X.x">
	<element name="FRONT"/>
	<element name="BACK"/>
	<element name="RIGHT"/>
	<element name="LEFT"/>
</enum>
```

##### Then `BodyInformation` Struct in `Common` interface would be updated as:
```xml
<struct name="BodyInformation" since="2.0">
	<param name="parkBrakeActive" type="Boolean" mandatory="true">
		<description>If mechanical park brake is active, true. Otherwise false.</description>
	</param>
	<param name="ignitionStableStatus" type="Common.IgnitionStableStatus" mandatory="true">
		<description>Provides information on status of ignition stable switch. See IgnitionStableStatus.</description>
	</param>
	<param name="ignitionStatus" type="Common.IgnitionStatus" mandatory="true">
		<description>Provides information on current ignitiion status. See IgnitionStatus.</description>
	</param>
	<param name="driverDoorAjar" type="Boolean" mandatory="false" deprecated="true" since="X.x">
		<description>References signal "DrStatDrv_B_Actl". Deprecated starting with RPC Spec X.x.x.</description>
	</param>
	<param name="passengerDoorAjar" type="Boolean" mandatory="false" deprecated="true" since="X.x">
		<description>References signal "DrStatPsngr_B_Actl". Deprecated starting with RPC Spec X.x.x.</description>
	</param>
	<param name="rearLeftDoorAjar" type="Boolean" mandatory="false" deprecated="true" since="X.x">
		<description>References signal "DrStatRl_B_Actl". Deprecated starting with RPC Spec X.x.x.</description>
	</param>
	<param name="rearRightDoorAjar" type="Boolean" mandatory="false" deprecated="true" since="X.x">
		<description>References signal "DrStatRr_B_Actl". Deprecated starting with RPC Spec X.x.x.</description>
	</param>
+	<param name="doorsStatus" type="Common.DoorStatus" array="true" minsize="0" maxsize="100" mandatory="false" since="X.x">
+		<description>Provides status for doors if Ajar/Closed/Locked</description>
+	</param>	
+	<param name="gatesStatus" type="Common.GateStatus" array="true" minsize="0" maxsize="100" mandatory="false" since="X.x">
+		<description>Provides status for trunk/hood/etc. if Ajar/Closed/Locked</description>
+	</param>
</struct>
```

## Potential downsides

Some parameters are deprecated.

## Impact on existing code

* SDL Core needs to be updated as per new API.
* iOS/Java Suite need to be updated to support getters/setters as per new API.
* HMI needs to be updated to support new vehicle data params.

## Alternatives considered

* New params can be added as new vehicle data item as well, but that might cause confusion with similar sounding vehicle data items.
