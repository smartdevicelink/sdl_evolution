# SendLocation Updates

* Proposal: [SDL 0004](0004-SendLocation Updates.md)
* Author: Robin Kurian
* Status: **Accepted with Revisions**
* Impacted Platforms: iOS, Android, Core, RPC

## Introduction
The SendLocation RPC allows an application to set a location on the head unit by sending latitude and longitude along with other information about that location.  This is a proposal to expand the capability of the SendLocation RPC to include searchable address format, delivery mode for deciding how the head unit should process the information and date-time information to support the delivery mode.

## Motivation
The in-vehicle navigation system uses the latitude and longitude values for plotting the route to the location. The navigation system also has the ability of plotting routes based on the address which could provide a more accurate route. 

At present when the SendLocation is sent, the head unit displays the location information and asks the user to accept the location or to reject it. We imagine cases where a user has already set a location on his mobile device while not connected to the vehicle and wants to be routed to that location when connected to the vehicle without being asked to reconfirm the location. Also users may choose a list of locations to visit while not connected to the vehicle and want to view the list in the vehicle to choose a destination. An auxiliary data to the list would be time stamp (date/time) which can be shown on the head-unit/ used by the head-unit for sorting the list.

## Proposed Solution
The solution proposed here is to expand the SendLocation RPC with:

a.	Address parameter - For sending address of the location
* countryName - Name of the country – localized
* countryCode - Name of country (ISO 3166-2)
* postalCode - PLZ, ZIP, PIN, CAP etc.
* administrativeArea - Portion of country (e.g. state)
* subAdministrativeArea – Portion of administrativeArea (e.g. county)
* locality – Hypernym for city/village
* subLocality – Hypernym for district
* thoroughfare - Hypernym for street, road etc.
* subThoroughfare - Portion of thoroughfare (e.g. house number)

b.	deliveryMode parameter - Provides information for the head unit to decide how to process the location
* PROMPT – Head unit may display the location information on its UI (default mode)
* DESTINATION – Head unit may set the location as the destination on the in-vehicle navigation system directly without prompting the user
* QUEUE – Head unit may add the location information to a queue for retrieval at a later point of time.

c.	timestamp parameter
* Date and Time details

## Detailed Design

### Changes to Mobile API
```xml
<function name="SendLocation" functionID="SendLocationID" messagetype="request">
  <param name="longitudeDegrees" type="Double" minvalue="-180" maxvalue="180" mandatory="true">
  </param>
  <param name="latitudeDegrees" type="Double" minvalue="-90" maxvalue="90" mandatory="true">
  </param>
  <param name="locationName" type="String" maxlength="500" mandatory="false">
    <description>
    Name / title of intended location
    </description>
  </param>
  <param name="locationDescription" type="String" maxlength="500" mandatory="false">
    <description>
    Description intended location / establishment (if applicable)
    </description>
  </param>
  <param name="addressLines" type="String" maxlength="500" minsize="0" maxsize="4" array="true" mandatory="false">
    <description>
    Location address (if applicable)
    </description>
  </param>
  <param name="phoneNumber" type="String" maxlength="500" mandatory="false">
    <description>
    Phone number of intended location / establishment (if applicable)
    </description>
  </param>
  <param name="locationImage" type="Image" mandatory="false">
    <description>
    Image / icon of intended location (if applicable and supported)
    </description>
  </param>
  <param name="deliveryMode" type="DeliveryMode" defvalue="PROMPT" mandatory="false">
    <description>
    Prompt =>User should be prompted on HMI.
    Destination => Set the location as destination.
    Queue =>Add the current location to navigation queue.
    </description>
  </param>	 
  <param name="timeStamp" type="DateTime" mandatory="false">
    <description>
		See DateTime 
    </description>
  </param>	 
  <param name="address" type="OASISAddress" mandatory="false">
		<description>Address to be used for setting destination</description>
  </param>
</function>

<function name="SendLocation" functionID="SendLocationID" messagetype="response" >
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
    <element name="UNSUPPORTED_RESOURCE"/>
		<element name="USER_DISALLOWED"/>		
    <element name="DISALLOWED"/>
    <element name="ABORTED"/>
    <element name="SAVED"/>
  </param>
  <param name="info" type="String" maxlength="1000" mandatory="false" platform="documentation">
    <description>Provides additional human readable info regarding the result.</description>
  </param>     
</function>	

<enum name="DeliveryMode">
  <description>The mode in which the sendLocation request is sent.</description>
  <element name="PROMPT" />
  <element name="DESTINATION" />
  <element name="QUEUE" />
</enum>

<struct name="DateTime">				
	<param name="millisecond" type="Integer" minvalue="0" maxvalue="999" mandatory="false">
	   <description>Milliseconds </description>		
	</param>		 
	<param name="second" type="Integer" minvalue="0" maxvalue="60" mandatory="false">
    <description>Seconds part of time</description>		
	</param>			
	<param name="minute" type="Integer" minvalue="0" maxvalue="59" mandatory="false">
	  <description>Minutes part of time</description>		
	</param>			
	<param name="hour" type="Integer" minvalue="0" maxvalue="23" mandatory="false">
    <description>Hours part of time. Note that this structure accepts time only in 24 Hr format</description>		
	</param>			
  <param name="day" type="Integer" minvalue="1" maxvalue="31" mandatory="false">
    <description>Day of the month</description>		
	</param>			
	<param name="month" type="Integer" minvalue="1" maxvalue="12" mandatory="false">
	  <description>Month of the year</description>		
	</param>			
	<param name="year" type="Integer" maxvalue="4095" mandatory="false">			
		<description>The year in YYYY format</description>		
	</param>			
	<param name="tz_hour" type="Integer" minvalue="-12" maxvalue="14" mandatory="false">
	   <description>Time zone offset in Hours with regard to UTC.</description>		
	</param>			
	<param name="tz_minute" type="Integer" minvalue="0" maxvalue="999" mandatory="false">
	   <description>Time zone offset in Min with regard to UTC. </description>		
	</param>			
</struct>				

<struct name="OASISAddress">		
  <param name="countryName" minlength="0" maxlength="200" type="String" mandatory="false">	
	  <description>Name of the country (localized)</description>
	</param>	
	<param name="countryCode" minlength="0" maxlength="200" type="String" mandatory="false">	
		<description>Name of country (ISO 3166-2)</description>
	</param>	
	<param name="postalCode" minlength="0" maxlength="200" type="String" mandatory="false">	
		<description>(PLZ, ZIP, PIN, CAP etc.)</description>
	</param>	
  <param name="administrativeArea" minlength="0" maxlength="200" type="String" mandatory="false">	
		<description>Portion of country (e.g. state)</description>
	</param>	
<param name="subAdministrativeArea" minlength="0" maxlength="200" type="String" mandatory="false">	
		<description>Portion of administrativeArea (e.g. county)</description>
	</param>	
	<param name="locality" minlength="0" maxlength="200" type="String" mandatory="false">	
		<description>Hypernym for city/village</description>
	</param>	
	<param name="subLocality" minlength="0" maxlength="200" type="String" mandatory="false">	
		<description>Hypernym for district</description>
	</param>	
  <param name="thoroughfare" minlength="0" maxlength="200" type="String" mandatory="false">	
		<description>Hypernym for street, road etc.</description>
	</param>	
  <param name="subThoroughfare" minlength="0" maxlength="200" type="String" mandatory="false">	
		<description>Portion of thoroughfare (e.g. house number)</description>
	</param>	
</struct>
```

### Additions to HMI API
```xml
<function name="SendLocation" messagetype="request">
  <description>That allows the app to send a destination to the embedded nav system.</description>
  <param name="appID" type="Integer" mandatory="true">
    <description>ID of application related to this RPC.</description>
  </param>
  <param name="longitudeDegrees" type="Double" minvalue="-180" maxvalue="180" mandatory="true">
  </param>
  <param name="latitudeDegrees" type="Double" minvalue="-90" maxvalue="90" mandatory="true">
  </param>
  <param name="locationName" type="String" maxlength="500" mandatory="false">
    <description>Name / title of intended location</description>
  </param>
  <param name="locationDescription" type="String" maxlength="500" mandatory="false">
    <description>Description intended location / establishment (if applicable)</description>
  </param>
  <param name="addressLines" type="String" maxlength="500" minsize="0" maxsize="4" array="true" mandatory="false">
    <description>Location address (if applicable)</description>
  </param>
  <param name="phoneNumber" type="String" maxlength="500" mandatory="false">
    <description>Phone number of intended location / establishment (if applicable)</description>
  </param>
  <param name="locationImage" type="Common.Image" mandatory="false">
    <description>Image / icon of intended location (if applicable and supported)</description>
  </param>
  <param name="deliveryMode" type="Common.DeliveryMode" mandatory="false">
    <description>Defines the mode of prompt for user</description>
  </param>
  <param name="timeStamp" type="Common.DateTime" mandatory="false">
    <description>
    See DateTime
    </description>
  </param>
  <param name="address" type="Common.OASISAddress" mandatory="false">
    <description>Address to be used for setting destination</description>
  </param>
</function>

<function name="SendLocation" messagetype="response" >
</function>	

<enum name="DeliveryMode">
  <description>The mode in which the SendLocation request is sent</description>
  <element name="PROMPT" />
  <element name="DESTINATION" />
  <element name="QUEUE" />
</enum>

<struct name="DateTime">
	<param name="millisecond" type="Integer" minvalue="0" maxvalue="999" mandatory="false">
	  <description>Milliseconds </description>		
	</param>		 
  <param name="second" type="Integer" minvalue="0" maxvalue="60" mandatory="false">
     <description>Seconds part of time</description>
   </param>
   <param name="minute" type="Integer" minvalue="0" maxvalue="59" mandatory="false">
     <description>Minutes part of time</description>
   </param>
   <param name="hour" type="Integer" minvalue="0" maxvalue="23" mandatory="false">
     <description>Hours part of time. Note that this structure accepts time only in 24 Hr format</description>
   </param>
   <param name="day" type="Integer" minvalue="1" maxvalue="31" mandatory="false">
     <description>Day of the month</description>
   </param>
   <param name="month" type="Integer" minvalue="1" maxvalue="12" mandatory="false">
     <description>Month of the year</description>
   </param>
   <param name="year" type="Integer" maxvalue="4095" mandatory="false">
     <description>The year in YYYY format</description>
   </param>
   <param name="tz_hour" type="Integer" minvalue="-12" maxvalue="14" defvalue="0" mandatory="false">
     <description>Time zone offset in Hours with regard to UTC.</description>
   </param>
   <param name="tz_minute" type="Integer" minvalue="0" maxvalue="59" defvalue="0" mandatory="false">
     <description>Time zone offset in Min with regard to UTC.</description>
   </param>
</struct>

<struct name="OASISAddress">
  <param name="countryName" minlength="0" maxlength="200" type="String" mandatory="false">
    <description>Name of the country (localized)</description>
  </param>
  <param name="countryCode" minlength="0" maxlength="200" type="String" mandatory="false">
    <description>Name of country (ISO 3166-2)</description>
  </param>
  <param name="postalCode" minlength="0" maxlength="200" type="String" mandatory="false">
    <description>(PLZ, ZIP, PIN, CAP etc.)</description>
  </param>
  <param name="administrativeArea" minlength="0" maxlength="200" type="String" mandatory="false">
    <description>Portion of country (e.g. state)</description>
  </param>
  <param name="subAdministrativeArea" minlength="0" maxlength="200" type="String" mandatory="false">
    <description>Portion of administrativeArea (e.g. county)</description>
  </param>
  <param name="locality" minlength="0" maxlength="200" type="String" mandatory="false">
    <description>Hypernym for city/village</description>
  </param>
  <param name="subLocality" minlength="0" maxlength="200" type="String" mandatory="false">
    <description>Hypernym for district</description>
  </param>
  <param name="thoroughfare" minlength="0" maxlength="200" type="String" mandatory="false">
    <description>Hypernym for street, road etc.</description>
  </param>
  <param name="subThoroughfare" minlength="0" maxlength="200" type="String" mandatory="false">
    <description>Portion of thoroughfare (e.g. house number)</description>
  </param>
</struct>
```
## Impact on existing code
SDL Core changes:
*	Update SendLocation  behavior in Commands component
*	Check allowance of SendLocation by "deliveryMode" value  in Policy component

HMI changes:
* Support new HMI API parameters

Policy Cloud changes:
* Update data base structure (new RPCs in groups of permissions)

Mobile iOS/Android SDK changes:
* Support new mobile API parameters

Since these are the optional newly-added parameters – we assume both mobile and HMI will continue working/compiling as assigned even if integrated with SDL supporting these new changes:
*	Mobile app that does not support these params is not impacted 
*	HMI that does not support these params can simply ignore them (note: app will not know whether the whole information was processed by HMI) 
*	HMI that partially supports them can respond with “WARNINGS” and “info: <new params> were not processed”” (SDL will transfer it to mobile app)
