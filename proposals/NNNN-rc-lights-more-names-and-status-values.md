# Remote Control – Lights – More Names and Status Values

* Proposal: [SDL-NNNN](NNNN-rc-lights-more-names-and-status-values.md)
* Author: [Zhimin Yang](https://github.com/smartdevicelink/yang1070)
* Status: **Awaiting review**
* Impacted Platforms: [Core / iOS / Android / RPC]

## Introduction

The light status signal in the vehicle can provide more values than just ON / OFF for certain lights. Some vehicles can provide the status of more lights than currently defined light names. This proposal adds three new light status values and some new light names to allow an application to get the status of additional lights.

## Motivation

During the development of RC feature light module, we find there are several cases not covered by the previous RC proposals.

- The light status signal in the vehicle can provide more values than currently defined ON / OFF value for certain lights. 

- Some vehicles can provide the status of lights which are not defined in the light names.

- We assumed a RC application can always control the ON/OFF status of a light if the light name is listed in the `supportedLights`, which is in the `LightControlCapabilities`. However, a vehicle may not allow an application to control certain lights but may provide the status of such lights. That means the status of those lights is read-only. The vehicle shall allow the application to know this fact via the capabilities.

## Proposed solution
This proposal adds three new read-only values (`UNKNOWN`, `RAMP_UP `, `RAMP_DOWN`) to the `LightStatus` enumeration and a few more values to the `LightName` enumeration such that an application can get the status of additional lights. 
In addition, the proposal adds a Boolean flag `statusAvailable` to the `LightCapabilities` data type to indicate if an application can control the ON/OFF status of a light. If `statusAvailable` = `true`, the application is allowed to change the ON/OFF status of a light with a `SetInteriorVehicleData` request. Note that the application shall not use the three newly added status values in a `SetInteriorVehicleData` request.


#### Mobile API Change

```xml
  <enum name="LightName">
    ......
+   <element name="REAR_CARGO_LIGHTS" value="512"/>
+   <element name="REAR_TRUCK_BED_LIGHTS" value="513"/>
+   <element name="REAR_TRAILER_ASSIST_LIGHTS" value="514"/>
+   <element name="LEFT_SPOT_LIGHTS" value="515"/>
+   <element name="RIGHT_SPOT_LIGHTS" value="516"/>
+   <element name="LEFT_PUDDLE_LIGHTS" value="517"/>
+   <element name="RIGHT_PUDDLE_LIGHTS" value="518">
    ......  
  </enum>
  
  <enum name="LightStatus">
    <element name="ON"/>
    <element name="OFF"/>
+   <element name="RAMP_UP"/>
+   <element name="RAMP_DOWN"/>
+   <element name="UNKNOWN"/>
  </enum>
  
  <struct name="LightCapabilities">
    <param name="name" type="LightName" mandatory="true" />
-    <!-- Assuming light ON/OFF status is always available -->
+    <param name="statusAvailable" type="Boolean" mandatory="false">
+      <description>
+        Indicates if the status (ON/OFF) can be set remotely. App shall not use other values (RAMP_UP/RAMP_DOWN/UNKNOWN) in a setInteriorVehicleData request.
+      </description>
+    </param>
  ......
  </struct>
```

#### HMI API Change
The changes are the same as that of the mobile API.



## Potential downsides

None

## Impacts on existing code

- The affected data types need to be updated within the RPC.
- SDL core and mobile proxy lib need updates to support new parameter values.


## Alternatives considered

None
