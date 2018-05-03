# Remote Control – Lights – More Names and Status Values

* Proposal: [SDL-0165](0165-rc-lights-more-names-and-status-values.md)
* Author: [Zhimin Yang](https://github.com/smartdevicelink/yang1070)
* Status: **Accepted with Revisions**
* Impacted Platforms: [Core / iOS / Android / RPC]

## Introduction

The light status signal in the vehicle can provide more values than just ON / OFF for certain lights. Some vehicles can provide the status of more lights than currently defined light names. This proposal adds some new light status values and some new light names to allow an application to get the status of additional lights.

## Motivation

During the development of RC feature light module, we find there are several cases not covered by the previous RC proposals.

- The light status signal in the vehicle can provide more values than currently defined ON / OFF value for certain lights. 

- Some vehicles can provide the status of lights which are not defined in the light names.

- We assumed a RC application can always control the ON/OFF status of a light if the light name is listed in the `supportedLights`, which is in the `LightControlCapabilities`. However, a vehicle may not allow an application to control certain lights but may provide the status of such lights. That means the status of those lights is read-only. The vehicle shall allow the application to know this fact via the capabilities.

## Proposed solution
This proposal adds some new read-only values (`RAMP_UP `, `RAMP_DOWN`, `UNKNOWN`, `INVALID`) to the `LightStatus` enumeration and a few more values to the `LightName` enumeration such that an application can get the status of additional lights. 

In addition, the proposal adds a Boolean flag `statusAvailable` to the `LightCapabilities` data type to indicate if an application can control the ON/OFF status of a light. If `statusAvailable` = `true`, the application is allowed to change the ON/OFF status of a light with a `SetInteriorVehicleData` request. If `statusAvailable` = `false`, the application is not allowed to change the ON/OFF status of a light and SDL shall reject such request with result code `READ_ONLY`.

Note that the application shall not use the newly added read-only status values in a `SetInteriorVehicleData` request. If the application uses a `LightStatus` enum value that meant to be read-only, SDL shall reject the request with result code `READ_ONLY`, and info="The LightStatus enum passed is READ ONLY and cannot be written.". If the application uses a light name that is not in the supported `LightName` list returned by the capabilities, SDL shall use result code `UNSUPPORTED_RESOURCE`, and info="The requested LightName is not supported by the vehicle.".

 
#### Mobile API Change

```xml
  <enum name="LightName">
    ......
+   <element name="REAR_CARGO_LIGHTS" value="512">
+     <description>
+       Cargo lamps eluminate the cargo area.
+     </description>
+   </element>
+   <element name="REAR_TRUCK_BED_LIGHTS" value="513">
+     <description>
+       Truck bed lamps light up the bed of the truck.
+     </description>
+   </element>
+   <element name="REAR_TRAILER_LIGHTS" value="514">
+     <description>
+       Trailer lights are lamps mounted on a trailer hitch.
+     </description>
+   </element>
+   <element name="LEFT_SPOT_LIGHTS" value="515">
+     <description>
+       It is the spotlights mounted on the left side of a vehicle.
+     </description>
+   </element>
+   <element name="RIGHT_SPOT_LIGHTS" value="516">
+     <description>
+       It is the spotlights mounted on the right side of a vehicle.
+     </description>
+   </element>
+   <element name="LEFT_PUDDLE_LIGHTS" value="517">
+     <description>
+       Puddle lamps illuminate the ground beside the door as the customer is opening or approaching the door.
+     </description>
+   </element>
+   <element name="RIGHT_PUDDLE_LIGHTS" value="518">
+     <description>
+       Puddle lamps illuminate the ground beside the door as the customer is opening or approaching the door.
+     </description>
+   </element>
    ......  
  </enum>
  
  <enum name="LightStatus">
    <element name="ON"/>
    <element name="OFF"/>
+   <element name="RAMP_UP"/>
+   <element name="RAMP_DOWN"/>
+   <element name="UNKNOWN"/>
+   <element name="INVALID"/>
  </enum>
  
  <struct name="LightCapabilities">
    <param name="name" type="LightName" mandatory="true" />
-    <!-- Assuming light ON/OFF status is always available -->
+    <param name="statusAvailable" type="Boolean" mandatory="false">
+      <description>
+        Indicates if the status (ON/OFF) can be set remotely. App shall not use read-only values (RAMP_UP/RAMP_DOWN/UNKNOWN/INVALID) in a setInteriorVehicleData request.
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
