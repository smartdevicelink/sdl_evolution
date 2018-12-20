# Read Generic Network Signal data

* Proposal: [SDL-0173](0173-Read-Generic-Network-Signal-data.md)
* Author: [Ankur Tiwari](https://github.com/ATIWARI9)
* Status: **In Review**
* Impacted Platforms: [Core / iOS / Android / RPC]

## Introduction

This proposal is to make vehicle data APIs (GetVehicleData/SubscribeVehicleData/UnsubscribeVehicleData/OnVehicleData) more flexible to allow additional new vehicle data items, while maintaining the security access via policies.

## Motivation

* Vehicles are getting more capable now than ever with advanced sensors and connectivity options. This generates tremendous amount of usable data for mobile apps in connectivity and mobility solutions domain. In order to keep up with varying demand and changing trends, SDL needs to be able to upscale with access to new vehicle data parameters without having to wait for a lengthy software build cycle for head units.
* Right now, we have a finite set of vehicle data params, even though the underlying implementation at head unit side can potentially provide more than currently defined in API. With this new implementation, we can tap in to that potential and can get access to more vehicle data elements, as it would be possible to read all the available vehicle data.

## Proposed solution

Solution is to replace the way vehicle data items are validated for _GetVehicleData/SubscribeVehicleData/UnsubscribeVehicleData/OnVehicleData_ APIs. 

Instead of validating vehicle data items against APIs XML, SDL would rely on a dedicated vehicle data items schema as below:
```
{
	"id":"VehicleDataItem",
	"dataType":"SDLDataType",
	"reference":"OEMDataRef",
	"array":true/false,
	"mandatory":true/false
}
```
* VehicleDataItem - is the vehicle data item in question. e.g. gps, speed etc. SDL would use this as the vehicle data param for requests from the app and to validate policies permissions.
* SDLDataType - is the return data type of the vehicle data item. It can be a generic SDL data type e.g. integer, string, float, etc. OR an enumeration defined in APIs XML. For the vehicle data item that has sub-params, this would be struct.
* OEMDataRef - is a reference for the OEM mapping table which defines signal attributes for this vehicle data items. OEMs may use this table to differentiate between various vehicle and SW configurations. SDL will pass along this reference to HMI, and then HMI would be responsible to resolve this reference using the OEM specific mapping table.

* _array_ : To speciify if the vehicle data item/param response is an array.
* _mandatory_ : To specify if the vehicle data param is mandatory to be included in response for overall vehicle data item.

* _id_ is required for top level vehicle data items while _dataType_ & _reference_ are required fields for vehicle data and sub-params, _array_ and _mandatory_ can be omitted. If omitted, _array_ defaults to *false* and _mandatory_ defaults to *true*

#### Schema file location and updates
A base JSON schema file for SDL core and proxy will be kept locally and an additional one in the OEM cloud. OEMs can update the schema file with OEM specific items, which SDL core would be able to download over the cloud along with policy updates; SDL proxy would be able to download via a URL passed to the app from HMI as an _endpoint_ shown below:
```
"endpoints": {
    "0x07": {
        "default": ["http://x.x.x.x:3000/api/1/policies/proprietary"]
     },
     "0x04": {
         "default": ["http://x.x.x.x:3000/api/1/softwareUpdate"]
     },
     "queryAppsUrl": {
         "default": ["http://sdl.shaid.server"]
     },
     "lock_screen_icon_url": {
         "default": ["http://i.imgur.com/TgkvOIZ.png"]
     },
     "extended_vehicle_data_url": {
         "default": ["http://x.x.x.x:3000/api/1/vehicledata/"]
     }
}
```
This new design would ensure flexibility to add OEM specific vehicle data items while maintaining access control via policies the same it is done today.

### Example of sample schema addition to policy table for SDL core update:
```json
....
      "BaseBeforeDataConsent"
        ]
      }
    },
	"VehicleDataItems":
	[
		{
			"id":"rpm",
			"dataType":"Integer",
			"reference":"OEM_REF_RPM",
			"array":false,
			"mandatory":true
		},
		{
			"id":"headLampStatus",
			"dataType":"Struct",
			"reference":"OEM_REF_STRUCT",
			"ambientLightSensorStatus":{
				"dataType":"AmbientLightStatus",
				"reference":"OEM_REF_AMB_LIGHT",
				"mandatory":false
			},
			"highBeamsOn":{
				"dataType":"Boolean",
				"reference":"OEM_REF_HIGH_BEAM"
			},
			"lowBeamsOn":{
				"dataType":"Boolean",
				"reference":"OEM_REF_LOW_BEAM"
			}
		},
		{
			"id":"engineState",
			"dataType":"Struct",
			"reference":"OEM_REF_STRUCT",
			"engineCoolantTemp" : {
				"dataType":"Integer",
				"reference":"OEM_REF_ENG_COOL_TEMP",
				"array":false,
				"mandatory":false
			},
			"engineO2Sat":{
				"dataType":"Float",
				"reference":"OEM_REF_ENG_O2_SAT",				
				"mandatory":false
			},
			"engineState":{
				"dataType":"String",
				"reference":"OEM_REF_ENG_STATE"
			},
			"engineServiceRequired":{
				"dataType":"Boolean",
				"reference":"OEM_REF_ENG_SER_REQ",
				"array":false,
				"mandatory":false
			}
		},
		{
			"id":"messageName",
			"dataType":"String",
			"reference":"OEM_REF_MSG",
			"array":false,
			"mandatory":true
		}
	]
....
```

#### Note: Only 2 levels of nesting allowed for vehicle data items/Sub items. i.e. vehicle data item can have params e.g. "headLampStatus" has "highBeamsOn" as param from above schema. But params can't have sub-params, e.g. "highBeamsOn" can't have any further nesting of params.

### Vehicle data items can be arranged in structures. See below example for existing vehicle data item _rpm_

Sample Value for map:
```json
{
	"id":"rpm",
	"dataType":"Integer",
	"reference":"OEM_REF_RPM",
	"array":false,
	"mandatory":true
}
```
Sample response from module:
```json
{
	"rpm":844
}
```
Structure in API:
```
<param name="rpm" type="Integer" minvalue="0" maxvalue="20000" mandatory="false">
	<description>The number of revolutions per minute of the engine</description>
</param>
```
* Structure defines the data type as Integer and a reference as OEM_REF_RPM
* OEM_REF_RPM (or a more suitable nomenclature)
  * This acts as a key for OEM side mapping to signal information associated with RPM. 
  * The mapping table for this reference is purely on the OEM side. OEMs may choose to implement it on the HMI layer, fetch it over the cloud or both.
  * Mapping table defines OEM specific encoding for various identifier attributes, SW versions & configurations as needed, e.g.:
    * OEM_REF_RPM :: hev#veh_actl_spd#veh_status_msg#HS3#500ms
    * OR a JSON sub structure in table. Again, it is up to OEM to decide and implement
* HMI sends response as integer for RPM

### For complex data items, a substructure is provided as shown in below example for _headLampStatus_:

Sample Value for map:
```json
{
	"id":"headLampStatus",
	"dataType":"Struct",
	"reference":"OEM_REF_STRUCT",
	"ambientLightSensorStatus":{
		"dataType":"AmbientLightStatus",
		"reference":"OEM_REF_AMB_LIGHT",
		"mandatory":false
	},
	"highBeamsOn":{
		"dataType":"Boolean",
		"reference":"OEM_REF_HIGH_BEAM"
	},
	"lowBeamsOn":{
		"dataType":"Boolean",
		"reference":"OEM_REF_LOW_BEAM"
	}
}
```
Sample Response from module:
```json
{
	"headLampStatus":{
		"ambientLightSensorStatus":"NIGHT",
		"highBeamsOn":false,
		"lowBeamsOn":true
   }
}
```
Structure in API:
```
<struct name="HeadLampStatus">
	<param name="lowBeamsOn" type="Boolean" mandatory="true">
		<description>Status of the low beam lamps.  References signal "HeadLampLoActv_B_Stat".</description>
	</param>
	<param name="highBeamsOn" type="Boolean" mandatory="true">
		<description>Status of the high beam lamps.  References signal "HeadLghtHiOn_B_Stat".</description>
	</param>
	<param name="ambientLightSensorStatus" type="AmbientLightStatus" mandatory="false">
		<description>Status of the ambient light sensor.</description>
	</param>
</struct>

    
<enum name="AmbientLightStatus">
	<description>Reflects the status of the ambient light sensor.</description>
	<element name="NIGHT" />
	<element name="TWILIGHT_1" />
	<element name="TWILIGHT_2" />
	<element name="TWILIGHT_3" />
	<element name="TWILIGHT_4" />
	<element name="DAY" />
	<element name="UNKNOWN" internal_name="ALS_UNKNOWN" />
	<element name="INVALID" />
</enum> 

```

* There are 3 sub items, “ambientLightSensorStatus”, “highBeamsOn” and “lowBeamsOn”. Each of these individual data types and references
* Note that “ambientLightSensorStatus” has data type as “AmbientLightStatus”. This enumeration is read from the existing Mobile API.
  * This can be extrapolated to all existing data types. For new data types enumerations, we’d still either need to add to Mobile API or create a new structure for vehicle data enumerations.

### Next example touches on a *new* OEM specific vehicle data item, _engineState_

Sample value for map:
```json
{
	"id":"engineState",
	"dataType":"Struct",
	"reference":"OEM_REF_STRUCT",
	"engineCoolantTemp" : {
		"dataType":"Integer",
		"reference":"OEM_REF_ENG_COOL_TEMP",
		"array":false,
		"mandatory":false
	},
	"engineO2Sat":{
		"dataType":"Float",
		"reference":"OEM_REF_ENG_O2_SAT",				
		"mandatory":false
	},
	"engineState":{
		"dataType":"String",
		"reference":"OEM_REF_ENG_STATE"
	},
	"engineServiceRequired":{
		"dataType":"Boolean",
		"reference":"OEM_REF_ENG_SER_REQ",
		"array":false,
		"mandatory":false
	}
}
```
Sample response from module:
```json
{
	"engineState": {
		"engineCoolantTemp":140,
		"engineO2Sat":95.5,
		"engineState":"NORMAL",
		"engineServiceRequired":false
	}
}
```
#### engineState would ideally be an enum if it was a Standardized data type. But since this it OEM example of vehicle data on the fly, we can use String data type.

* _engineState_ would need to be added to both SDL core and proxy schema. Once the new schema is downloaded by both core and proxy, an app may request _engineState_ vehicle data item.
* This shows the capability to add a new vehicle data item, which OEMs can utilize to update the file on the cloud. SDL can get updates on this files along with PT updates, thus new vehicle data would be able to be processed.
* Again, each sub items have individual data types and references. So as long as the OEM updates the reference file, mobile apps can access the new data.

### Also, this approach can also be used to read entire 8 bytes CAN message itself

Sample value for map:
```json
{
	"id":"messageName",
	"dataType":"String",
	"reference":"OEM_REF_MSG",
	"array":false,
	"mandatory":true
}
```
Sample response from module:
```json
{
	"messageName": "AB 04 D1 9E 84 5C B8 22"
}
```
* The Data type is the string so that it can accommodate a byte string for CAN message. OEM_REF_MSG points to a message definition in the OEM mapping table.
### Integer, Float, String can use the common range values defined in HMI/Mobile API
### Access to data items would still be controlled using Policies the same way. OEM would need to add new vehicle data items to policies.

## Impact on existing code
* SDL core would need to add support to download and parse the new JSON schema for vehicle data. SDL would either keep the existing vehicle data items in HMI/Mobile API and only use this approach for new vehicle data items or totally replace the way vehicle data items are compiled and validated by SDL. Instead of using the hard coded xml file, valid vehicle data type would be fetched from mapping file over the cloud. (there would be a local copy for the initial build). The interface between SDL and HMI needs to be updated while passing _GetVehicleData/SubscribeVehicleData/UnsubscribeVehicleData/OnVehicleData_ requests to include return data type and reference keys.

* SDL Proxy needs to be able to download the new JSON schema for vehicle data and add a manager to allow requests for new vehicle data items in a systematic way.

* APIs would need a new Request/Response API to act as the Generic Request Response for _GetVehicleData/SubscribeVehicleData/UnsubscribeVehicleData_

## Alternatives considered
* Instead of using JSON to define vehicle data items schema, SDL can use either of following:
  * XML:
    * This would reuse the XML based design with adding "reference" as another attribute or as a sub-element. Instead of sending a JSON file from cloud to the headunit, SDL would send a XML file that would be like a subset of the mobile API. 
    * But this would need changes on the policy table server side as the policy server is configured to serve JSON as part of policy table update.
  * Precompiled library plug-ins:
    * Another idea is to automatically generate code and compile this code into a dynamic link library. Instead of sending a JSON or XML file, this library would be transferred to headunit as part of policy update or OTA. Core would load this library and execute this library for vehicle data.
    * But this might cause overhead to maintain and support dlls for multiple Operating Systems.
* Check history of this proposal for _GetGenericNetworkData_ submitted originally.

