# Read Generic Network Signal data

* Proposal: [SDL-NNNN](NNNN-Read-Generic-Network-Signal-data.md)
* Author: [Ankur Tiwari](https://github.com/ATIWARI9)
* Status: **Awaiting review**
* Impacted Platforms: [Core / iOS / Android / RPC]

## Introduction

To enable OEM proprietary mobile apps to read raw CAN/Network data by specifying uniquely identifiable network data attributes. This expands the utilization of SDL APIs to read all the network signals available to head unit.

## Motivation

* Vehicles are getting more capable now than ever with advanced sensors and connectivity options. This generates tremendous amount of usable data for mobile apps in connectivity and mobility solutions domain. In order to keep up with varying demand and changing trends, SDL needs to be able to upscale   with access to new vehicle data parameters without having to wait for lengthy software build cycle for head units.
* Right now, we have finite set of vehicle data params, even though the underlying implementation at head unit side can potentially provide more than currently defined in API. With this new implementation, we can tap in to that potential and can get access to more vehicle data elements, as it would be possible to read all the available vehicle data.

## Proposed solution

Solution is to provide a Generic RPC, which can GET/SUBSCRIBE/UNSUBSCRIBE to any available Vehicle Data. 
* Mobile app would pass a unique identifier and optionally an array of attributes through this RPC. These attributes are required to identify vehicle data requested by the app.
* These attributes are proprietary for OEMs, so Mobile app needs to have access to proprietary interface definitions for vehicle data/service layer with which SDL interfaces to access vehicle data.
* OEM implementation needs to enforce tracking of “unique identifier” to avoid duplicate subscriptions and to optimize subscription requests from multiple apps.
* Mobile App is responsible to keep track of vehicle data it requests with help of field called "Id".
* Mobile App can pick from three modes:
  * GET		: Used for one time request to read current state/value of vehicle data
  * SUBSCRIBE	: Used to receive updates to vehicle data for the period of subscription
  * UNSUBSCRIBE: Used to stop the updated to vehicle data which was subscribed earlier

**Request XML:**
```
<function name="GenericNetworkData" functionID="GenericNetworkDataID" messagetype="request">
    <description>Vehicle network data request</description>

    <param name="id" type="String" maxlength="100" mandatory="true">
		<description>
			Parameter ID for the requested vehicle data.	
			Should not be Blank or contain whitespaces.
			Same ID can be used for GET/SUBSCRIBE/UNSUBSCIRBE requests for same vehicle data.
			Refer to OEM specific vehicle data identifier list for information on format of identifier and mapping of vehicle data.
		</description>
    </param>

	<param name="networkDataRequestMode" type="NetworkDataRequestMode" mandatory="true">
		<description>
			Enumeration to control the network data request type.
			GET
			SUBSCRIBE
			UNSUBSCRIBE
		</description>
    </param>
	
   <param name="networkDataAttribute" type="String" maxlength="500" minsize="1" maxsize="100" array="true" mandatory="false">
		<description>
			String Array of additional Network Data Attributes which identify network data as per OEM implementation 			
		</description>
    </param>
	
</function>

<enum name="NetworkDataRequestMode">
	<description>Describes how the GenericNetworkData should behave on the platform</description>
	<element name="GET">
		<description>Denotes that the request type is single read request for network data</description>
	</element>
	<element name="SUBSCRIBE" >
		<description>Denotes that the request type is to receive network data update with every change
		Request is ignored if requested network data is already subscribed 		
		</description>
	</element>
	<element name="UNSUBSCRIBE" >
		<description>Denotes that the request type is to end the previous network data subscription
		Request is ignored if requested network data is NOT already subscribed
		</description>
	</element>
</enum>
```

Head unit, would in turn GET/SUBCRIBE/UNSUBSCRIBE the vehicle data from underlying vehicle service layers. 
* Mobile app will receive the response with confirmation of successful operation and a result code.
* Response will contain the mode for the vehicle data response
  * GET		: Result code in this mode represents if current vehicle data read operation is successful or not
  * SUBSCRIBE	: Result code in this mode represents if Subscribe operation is successful or not
  * UNSUBSCRIBE: Result code in this mode represents if Unsubscribe operation is successful or not
* Response will contain an array of network data. Network data element in the array will contain "id" (which mobile app had set while requesting for data) and value of the vehicle data.
* Mobile app will be responsible for decoding the String value of vehicle data in to usable form by applying conversions as defined by OEM proprietary spec sheet for corresponding vehicle data.
* Response will also contain an optional “info” field. This field contains additional human readable information regarding the request/response

**Response XML:**
```
 <function name="GenericNetworkData" functionID="GenericNetworkDataID" messagetype="response">

    <param name="success" type="Boolean" platform="documentation">
		<description> true, if successful; false, if failed </description>
	  </param>

    <param name="resultCode" type="Result" platform="documentation">
      <description>See Result</description>
      <element name="SUCCESS"/>
	  <element name="IGNORED"/>
      <element name="INVALID_DATA"/>
      <element name="OUT_OF_MEMORY"/>
      <element name="TOO_MANY_PENDING_REQUESTS"/>
      <element name="APPLICATION_NOT_REGISTERED"/>
      <element name="GENERIC_ERROR"/>
	  <element name="TIMED_OUT"/>
      <element name="REJECTED"/>
      <element name="DISALLOWED"/>
      <element name="USER_DISALLOWED"/>
      <element name="TRUNCATED_DATA"/>
    </param>

	<param name="networkDataRequestMode" type="NetworkDataRequestMode" mandatory="true">
      <description>
      	Enumeration to control the network data request type.
      	GET
		SUBSCRIBE
		UNSUBSCRIBE
      </description>
    </param>
	
    <param name="info" type="String" maxlength="1000" mandatory="false" platform="documentation">
      <description>Provides additional human readable info regarding the result.</description>
    </param>

    <param name="networkData" type="NetworkData" mandatory="false" array="false">
      <description>
      	Returned Network Data value for a paramId
      </description>
    </param>

  </function>

<struct name="NetworkData">
	 <param name="id" type="String" maxlength="100" mandatory="true">
		<description>
			Unique Parameter ID for the request.			
			Should not be Blank or contain whitespaces.
			Should not be same as existing active GET/SUBSCRIBE/UNSUBSCIRBE request
		</description>
    </param>
		
	<param name="value" type="Integer" minvalue="0" maxvalue="255" minsize="1" maxsize="512" array="true" mandatory="true">
      <description>
      	Network data byte array for corresponding vehicle data.
      </description>
    </param>
	
</struct>
```

In case of successful subscription, mobile app will receive periodic updates for requested vehicle data through OnGenericNetworkData notification.
* Response will contain an array of network data. Network data element in the array will contain "id" (which mobile app had set while requesting for data) and value of the vehicle data.
* Mobile app will be responsible for decoding the String value of vehicle data in to usable form by applying conversions as defined by OEM proprietary spec sheet for corresponding vehicle data.
* Response will also contain an optional “info” field. This field contains additional human readable information regarding the request/response

```
<function name="OnGenericNetworkData" functionID="OnGenericNetworkDataID" messagetype="notification">
    <description>Callback for the periodic and non-periodic generic vehicle data read function.</description>
    
	<param name="networkData" type="NetworkData" mandatory="false" minsize="1" maxsize="500" array="true">
      <description>
      	Returned Network Data value
      </description>
    </param>  

	<param name="info" type="String" maxlength="1000" mandatory="false" platform="documentation">
      <description>Provides additional human readable info regarding the notification.</description>
    </param>	
	
</function>
```

## Potential downsides

* This approach has underlying assumption that Mobile app would have access to OEM specific proprietary interface details.
  * This is acceptable since we target only OEM proprietary Mobile apps to utilize this feature. Moreover, benefits of access to more vehicle data params outweigh this limitation.
* Mobile app is responsible for maintaining the network definitions as well as decoding the raw value received from vehicle.
  * Alternate way would be to maintain all the network signal definitions at head unit side. Which means it might not be scalable with any changes/additions to network signal definitions with introduction of newer vehicle architectures/features. On the contrary, Mobile app will maintain only the required network signal definitions, which will be significantly smaller than entire suite of network definitions.

## Impact on existing code

SDL needs to track requests by NetworkDataIdentifier per app and work through the business logic of duplicate requests. SDL would also need to distribute the received data to apps which have subscribed. 

## Alternatives considered

* Add additional parameter in existing GetVehicleData/SunscribeVehicleData/UnsubscribeVehicleData RPCs:
  * networkDataRequest - which specifies paramId and NetworkDataAttribute String array to identify the network data item

```
<function name="GetVehicleData" functionID="GetVehicleDataID" messagetype="request">
    <description>Non periodic vehicle data read request.</description>

    <param name="gps" type="Boolean" mandatory="false">
      <description>See GPSData</description>
    </param>
    
	<!-- Not showing other params -->
	
	<param name="networkDataRequest" type="NetworkDataRequest" mandatory="false">	
      <description>Request Generic Network data</description>
    </param>
</function>
  
  
<struct name="NetworkDataRequest">
	<param name="paramId" type="Integer" minvalue="1" maxvalue="65535" mandatory="true">
      <description>Paramter ID for the request.</description>
    </param>
	
	<param name="NetworkDataAttribute" type="String" maxlength="500" minsize="1" maxsize="100" array="true" mandatory="true">
      <description>Array of Network Data Attributes which uniquely identify network data as per OEM implementation 
	  Should be uniquely identifiable network data item, else response would be INVALID_DATA
	  </description>
    </param>
</struct>
```

* For GetVehicleData response/OnVehicleData, add additional response structure:
  * networkData - It has a paramId and value returned from vehicle. Value returned will be a Hex string.
  
```
<function name="GetVehicleData" functionID="GetVehicleDataID" messagetype="response">

    <param name="success" type="Boolean" platform="documentation">
		<description> true, if successful; false, if failed </description>
	</param>

    <param name="resultCode" type="Result" platform="documentation">
      <description>See Result</description>
      <element name="SUCCESS"/>
      <element name="INVALID_DATA"/>
      <element name="OUT_OF_MEMORY"/>
      <element name="TOO_MANY_PENDING_REQUESTS"/>
      <element name="APPLICATION_NOT_REGISTERED"/>
      <element name="GENERIC_ERROR"/>
      <element name="REJECTED"/>
      <element name="VEHICLE_DATA_NOT_AVAILABLE"/>
      <element name="USER_DISALLOWED"/>
    </param>

    <param name="info" type="String" maxlength="1000" mandatory="false" platform="documentation">
      <description>Provides additional human readable info regarding the result.</description>
    </param>

    <param name="gps" type="GPSData" mandatory="false">
      <description>See GPSData</description>
    </param>
        
	<!-- Not showing other params -->
	
	<param name="networkData" type="NetworkData" mandatory="false" minsize="1" maxsize="500" maxLength="200" array="true">
      <description>
      	Returned Network Data value for a paramId
      </description>
    </param> 

</function>

<function name="OnVehicleData" functionID="OnVehicleDataID" messagetype="notification">
    <description>Callback for the periodic and non periodic vehicle data read function.</description>
    <param name="gps" type="GPSData" mandatory="false">
      <description>See GPSData</description>
    </param>
     
	<!-- Not showing other params -->
	
	<param name="networkData" type="NetworkData" mandatory="false" minsize="1" maxsize="500" maxLength="200" array="true">
      <description>
      	Returned Network Data value for a paramId
      </description>
    </param> 
	
  </function>
  
  
<struct name="NetworkData">
	<param name="paramId" type="Integer" minvalue="1" maxvalue="65535" mandatory="true">
      <description>Parameter ID for the request.</description>
    </param>
	
	<param name="value" type="String" mandatory="false" maxlength="200" array="false">
      <description>
      	Raw Network data HEX string as returned from vehicle.
      </description>
    </param>
</struct>
```

The reason we did not choose this approach is that this will need changing to exiting behavior of GetVehicleData/SubscribeVehicleData/UnsubscribeVehicleData/OnVehicleData. E.g.:
* Need to change the behavior to NOT send Ignore response when multiple Subscribe requests are sent for param “networkDataRequest”
* All existing params are of type Boolean, this new param will need to be structure.
* Addition of new response structure “networkData”
