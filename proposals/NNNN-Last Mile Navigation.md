# Last Mile Navigation

* Proposal: NNNN-Last Mile Navigation
* Author: [Robin Kurian]
* Status: "Awaiting Review"
* Review manager: TBD
* Impacted Platforms: iOS, Android, Core

## Introduction
The aim of this feature is to get information on the destination and waypoints set on the native navigation source so that a Mobile App can provide last mile connectivity to the user’s target location.
Eg: User has set his destination as a busy business location on the native navigation source. As the user nears his final destination he is unable to find a parking spot nearby and has to park further away. The app has details of his destination and provides navigation guidance (walking route, bus route etc) to his end destination point.

## Motivation
While in-vehicle navigation systems provide connectivity to the end point of a route, they may not be able to provide routing information to the final destination which could be fulfilled by a navigation application on the user’s mobile device.

## Proposed solution
The solution proposed here is for an app to request 1-time information on the current waypoints set on the native navigation system and also for the ability for the app to be informed about the changes in the waypoint data. In this way the app is aware of the user’s route and end point and can provide routing details to the user’s end point when the user gets off the vehicle.

_Use case 1 :_ 

|Item|Description|
|---|---|
|Use Case|Get Destination & Waypoints|
|Actors|Mobile App|
|Pre Conditions|<ul><li>Mobile App has successfully registered on the system</li><li>The Mobile App has the necessary permissions for requesting data</li><li>The system supports a native Navigation source</li><li>An active route is set on the native Navigation source</li></ul>|
|Scenario Description|A Mobile App sends a request to get the details of the destination and waypoints set on the system so that it can provide last mile connectivity.|
|Post-conditions|The system responds by acknowledging the request and provides the details of the destination and waypoints currently set on the system.|
|Variations/Exceptional Use cases|<ul><li>Get Destination & Waypoints when system does not support a native Navigation source.</li><li>Get Destination & Waypoints when there is no route currently active</li></ul>|

_Use case 2 :_ 

|Item|Description|
|---|---|
|Use Case|Get Destination & Waypoints when system does not support a native Navigation source|
|Actors|Mobile App|
|Pre Conditions|<ul><li>Mobile App has successfully registered on the system</li><li>The Mobile App has the necessary permissions for requesting data</li><li>The system does not support a native Navigation source </li></ul>|
|Scenario Description|A Mobile App sends a request to get the details of the destination and waypoints set on the system so that it can provide last mile connectivity.|
|Post-conditions|The system responds informing the Mobile App that the resource is unsupported and no details on the destination or waypoints are provided.|
|Variations/Exceptional Use cases|NA|

_Use case 3 :_ 

|Item|Description|
|---|---|
|Use Case|Get Destination & Waypoints when there is no route currently active|
|Actors|Mobile App|
|Pre Conditions|<ul><li>Mobile App has successfully registered on the system</li><li>The Mobile App has the necessary permissions for requesting data</li><li>The system supports a native Navigation source</li><li>No route is set on the native Navigation source</li></ul>|
|Scenario Description|A Mobile App sends a request to get the details of the destination and waypoints set on the system so that it can provide last mile connectivity.|
|Post-conditions|The system responds by acknowledging the request but does not provide any details of the destination and waypoints since there is no route currently set on the system.|
|Variations/Exceptional Use cases|NA|

_Use case 4 :_ 

|Item|Description|
|---|---|
|Use Case|Subscribe to Destination & Waypoints|
|Actors|Mobile App|
|Pre Conditions|<ul><li>Mobile App has successfully registered on the system</li><li>The Mobile App has the necessary permissions for requesting data</li><li>The system supports a native Navigation source</li><li>No route is set on the native Navigation source</li><li>An active route is set on the native Navigation source</li></ul>|
|Scenario Description|A Mobile App subscribes to getting notified about any changes to the destination or waypoints.|
|Post-conditions|<ul><li>The system responds by acknowledging the subscription request</li><li>The details of the destination & waypoints currently set on the native Navigation source is send as a notification to the Mobile App.</li><li>When there is any change to the destination/waypoints (such as when user cancels a route or when a waypoint is crossed etc) the system notifies the app with the details of the destination and waypoints</li></ul>|
|Variations/Exceptional Use cases|<ul><li>Subscribe to Destination & Waypoints when system does not support a native Navigation source</li><li>Subscribe to Destination & Waypoints when there is no route currently active</li><li>Notify changes to Destination or Waypoints</li></ul>|

_Use case 5 :_ 

|Item|Description|
|---|---|
|Use Case|Subscribe to Destination & Waypoints when system does not support a native Navigation source|
|Actors|Mobile App|
|Pre Conditions|<ul><li>Mobile App has successfully registered on the system</li><li>The Mobile App has the necessary permissions for requesting data</li><li>The system does not support a native Navigation source </li></ul>|
|Scenario Description|A Mobile App subscribes to getting notified about any changes to the destination or waypoints.|
|Post-conditions|The system responds informing the Mobile App that the resource is unsupported and the request for subscription is not successful.|
|Variations/Exceptional Use cases|NA|

_Use case 6 :_ 

|Item|Description|
|---|---|
|Use Case|Subscribe to Destination & Waypoints when there is no route currently active|
|Actors|Mobile App|
|Pre Conditions|<ul><li>Mobile App has successfully registered on the system</li><li>The Mobile App has the necessary permissions for requesting data</li><li>The system supports a native Navigation source</li><li>No route is set on the native Navigation source</li></ul>|
|Scenario Description|A Mobile App subscribes to getting notified about any changes to the destination or waypoints.|
|Post-conditions|<ul><li>The system responds by acknowledging the subscription request.</li><li>No notification with details of the Destination/Waypoints are sent to the Mobile App since there is no active route set</li><li>When there is any change to the destination/waypoints (such as when user sets a route), the system notifies the app with the details of the destination and waypoints</li></ul>|
|Variations/Exceptional Use cases|NA|

_Use case 7 :_ 

|Item|Description|
|---|---|
|Use Case|Unsubscribe from Destination & Waypoints|
|Actors|Mobile App|
|Pre Conditions|<ul><li>Mobile App has successfully registered on the system</li><li>The Mobile App has the necessary permissions for requesting data</li><li>The system supports a native Navigation source</li><li>The Mobile App has previously successfully subscribed to getting notifications to changes to Destination or Waypoints</li></ul>|
|Scenario Description|A Mobile App unsubscribes from getting notified about any changes to the destination or waypoints.|
|Post-conditions|<ul><li>The system responds by acknowledging the un-subscription request.</li><li>The system no longer sends notification to the Mobile App when changes to the Destination or Waypoints occur.</li><li>Notify changes to Destination or Waypoints</li></ul>|
|Variations/Exceptional Use cases|NA|

_Use case 8 :_ 

|Item|Description|
|---|---|
|Use Case|Notify changes to Destination or Waypoints|
|Actors|Mobile App|
|Pre Conditions|<ul><li>Mobile App has successfully registered on the system</li><li>The Mobile App has the necessary permissions for requesting data</li><li>The system supports a native Navigation source</li><li>The Mobile App has previously successfully subscribed to getting notifications to changes to Destination or Waypoints</li></ul>|
|Scenario Description|The Destination or Waypoints data changes (by way of user setting a new route, cancelling a route, crossing a waypoint, arriving at destination etc)|
|Post-conditions|The system notifies the app with the details of the destination and waypoints|
|Variations/Exceptional Use cases|NA|

## Detailed Design
### Additions to Mobile_API
```xml
<element name="GetWayPointsID" value="41" hexvalue="29" />
<element name="SubscribeWayPointsID" value="42" hexvalue="2A" />
<element name="UnsubscribeWayPointsID" value="43" hexvalue="2B" />
<element name="OnWayPointChangeID" value="32785" hexvalue="8011" />

<function name="GetWayPoints" functionID="GetWayPointsID" messagetype="request">		
	<description>Request for getting waypoint/destination data.</description>	
	<param name="wayPointType" type="WayPointType " mandatory="true">	
<description>To request for either the destination only or for all waypoints including destination</description>
	</param>	
</function>		
	
<function name="GetWayPoints" functionID="GetWayPointsID" messagetype="response">		
	<param name="success" type="Boolean" platform="documentation">	
		<description> true, if successful; false, if failed </description>
	</param>	
	<param name="resultCode" type="Result" platform="documentation">	
		<description>See Result</description>
		<element name="SUCCESS"/>
		<element name="INVALID_DATA"/>
		<element name="TIMED_OUT"/>
		<element name="GENERIC_ERROR"/>
		<element name="REJECTED"/>
		<element name="UNSUPPORTED_RESOURCE"/>
		<element name="IGNORED"/>
		<element name="IN_USE"/>
		<element name="DISALLOWED"/>
	</param>	
<param name="info" type="String" maxlength="1000" mandatory="false" platform="documentation">	
<description>Provides additional human readable info regarding the result.</description>
	</param>	
<param name="wayPoints" type="LocationDetails" mandatory="false" array="true" minsize="1" maxsize="10">	
		<description>See LocationDetails</description>
	</param>	
</function>		

<function name="SubscribeWayPoints" functionID="SubscribeWayPointsID" messagetype="request">	
	<description>To subscribe in getting changes for Waypoints/destinations</description>
</function>	
	
<function name="SubscribeWayPoints" functionID="SubscribeWayPointsID" messagetype="response">		
  <param name="success" type="Boolean" platform="documentation">	
		<description> true, if successful; false, if failed </description>
	</param>	
	<param name="resultCode" type="Result" platform="documentation">	
		<description>See Result</description>
		<element name="SUCCESS"/>
		<element name="INVALID_DATA"/>
		<element name="GENERIC_ERROR"/>
		<element name="REJECTED"/>
		<element name="UNSUPPORTED_RESOURCE"/>
		<element name="IGNORED"/>
		<element name="DISALLOWED"/>
	</param>	
  <param name="info" type="String" maxlength="1000" mandatory="false" platform="documentation">	
     <description>Provides additional human readable info regarding the result.</description>
	</param>	
</function>		

<function name="UnsubscribeWayPoints" functionID="UnsubscribeWayPointsID" messagetype="request">	
	<description>Request to unsubscribe from WayPoints and Destination</description>
</function>	

<function name="UnsubscribeWayPoints" functionID="UnsubscribeWayPointsID" messagetype="response">		
	<param name="success" type="Boolean" platform="documentation">	
		<description> true, if successful; false, if failed </description>
	</param>	
	<param name="resultCode" type="Result" platform="documentation">	
		<description>See Result</description>
		<element name="SUCCESS"/>
		<element name="INVALID_DATA"/>
		<element name="GENERIC_ERROR"/>
		<element name="REJECTED"/>
		<element name="UNSUPPORTED_RESOURCE"/>
		<element name="IGNORED"/>
		<element name="DISALLOWED"/>
	</param>	
<param name="info" type="String" maxlength="1000" mandatory="false" platform="documentation">	
<description>Provides additional human readable info regarding the result.</description>
	</param>	
</function>		
	
<function name="OnWayPointChange" functionID="OnWayPointChangeID" messagetype="notification">		
<description>Notification which provides the entire LocationDetails when there is a change to any waypoints or destination.</description>	
<param name="wayPoints" type="LocationDetails" mandatory="true" array="true" minsize="1" maxsize="10">	
		<description>See LocationDetails</description>
	</param>	
</function>
```
### Additions to HMI_API
```xml
<function name="GetWayPoints" messagetype="request">
 <description>Request for getting waypoint/destination data.</description>
    	<param name="appID" type="Integer" mandatory="true">
      		<description>ID of the application.</description>
    	</param>
<param name="wayPointType" type="Common.WayPointType" defvalue="ALL" mandatory="true">
<description>To request for either the destination only or for all waypoints including destination</description>
    	</param>
</function>

 <function name="GetWayPoints" messagetype="response">
 <param name="wayPoints" type="Common.LocationDetails" mandatory="false" array="true" minsize="1" maxsize="10">
 <description>See LocationDetails</description>
</param>
</function>

<function name="OnWayPointChange" messagetype="notification">
<description>Notification which provides the entire LocationDetails when there is a change to any waypoints or destination.</description>
<param name="wayPoints" type="Common.LocationDetails" mandatory="true" array="true" minsize="1" maxsize="10">
<description>See LocationDetails</description>
</param>
</function>

<function name="SubscribeWayPoints" messagetype="request">
<description>To subscribe in getting changes for Waypoints/destinations</description>
</function>

<function name="SubscribeWayPoints" messagetype="response">
</function>

<function name="UnsubscribeWayPoints" messagetype="request">
<description>Request to unsubscribe from WayPoints and Destination</description>
</function>

<function name="UnsubscribeWayPoints" messagetype="response">
 </function>
```
## Impact on existing code
SDL Core changes:
*	Add WayPoints RPCs in Commands component
*	Add run-time WayPoint subscriptions storing in Application Manager component
*	Add storing WayPoint  subscriptions between shutdown cycles in Resumption component
HMI changes:
*	New HMI APIs support	
Mobile iOS/Android SDK changes:
*	New Mobile APIs support

   Since these are the newly-added APIs – we assume both mobile and HMI will continue working/compiling as assigned even if integrated with SDL supporting these new changes:  
*	Mobile app that does not support these APIs is not impacted 
*	HMI that does not support these new APIs can simply ignore them (SDL will respond with “GENERIC_ERROR” to mobile app) 
*	HMI that partially supports them can respond with “UNSUPPORTED_RESOURCE” (SDL will transfer it to mobile app)
