# App Services

* Proposal: [SDL-0167](0167-app-services.md)
* Author: [Joey Grover](https://github.com/joeygrover)
* Status: **Deferred**
* Impacted Platforms: [iOS / Android / Core]



## Introduction

SmartDeviceLink has always been limited to a 1 - 1 relationship between module and smartphone apps. However, to create truly compelling experiences this should be expanded. This proposal will aim to introduce a paradigm that allows apps to advertise a "service" they offer that the module and other apps can leverage. This allows users to augment their vehicle's IVI system with off-board solutions. This proposal also details how SDL apps can communicate with each other through the module. 

This proposal is extremely lengthy as it is a big feature. The recommended review process would be to review the high level process first (publish, subscribe, etc). Then following the agreement on how services work in general, moving to review each service type for its exhaustiveness of functionality per that specific service.

## Motivation

SDL is becoming a much more integrated solution with an expanding ecosystem. While the initial problem SDL set out to solve has been accomplished, we're looking for new ways to make the ecosystem even more compelling and to create an immersive user experience. One of the biggest steps we can take forward is creating a way for apps to offer augmented services to not only the onboard embedded system, but to other SDL connected apps. 


## Proposed solution

After apps are registered on the module, they will have the opportunity to publish a service they wish to offer. If the request is successful and the service has indicated they allow app consumers, all other SDL connected apps will be notified that the new service is available for subscriptions.

Once other apps either use the `getSystemCapability` functionality or they are notified of an app service being offered they can they start to request data. This is done through new RPCs that will get the current data provided by the service and allow the service consumer to subscribe to future updates from the app service provider.

Services will be expected to handle a subset of RPCs according to their service type for basic interaction. For example, Media services will be expected to handle `ButtonPress` RPCs and Navigation services should handle things like `SendLocation`. Each service will define what RPCs it agrees to handle in the `AppServiceManifest` they provide along with the specific manifest param that is defined by their service type.

Along with this basic, standardized set of control requests from app service consumers, we will implement a way for services to expose their native URI scheme for more in-depth actions. These will be exposed with a URI prefix and array of possible URI scheme parameters. SDL makes no guarantees that these actions will be executed as the app service consumer intends, it is therefore the responsibility of the app service provider to ensure standardized URI schemes and intuitive parameters. 

App service providers will be defined into specific types of service. Only one service of each service type can be active at a time. Similar to the HMI status of apps where only one can be in `HMI_FULL` at any given time.


### Service Types
-------

Services will be defined to a few high level categories so that we can support the most services in a generic way. We will discuss this briefly before moving into how most of this system works.

##### AppServiceType enum

```xml
<enum name="AppServiceType">
	 <element name = "MEDIA"/>
	 <element name = "WEATHER"/>
	 <element name = "NAVIGATION"/>
	 <element name = "VOICE_ASSISTANT"/>
	 <element name = "GENERIC"/>
	 <element name = "COMMUNICATION_VOIP"/> <!-- Currently no specific definitions -->
	 <element name = "MESSAGING"/>			<!-- Currently no specific definitions -->
 	 <element name = "TTS"/> 				<!-- Currently no specific definitions -->

</enum>
```

Each service type will have two structs specifically defined for them.

1. `___ServiceManifest` - This struct will contain parameters that are only relevant for that specific service. For example, the `VoiceAssistantManifest` includes a `wakeWords` param that wouldn't make sense for any other service.
2. `___ServiceData` - This is all the data the service provides. It will always be specific to that service. 

Some services will need more structs defined to help standardize the data that is sent and received.


#### Media

A media service is defined as a service that is currently the audio source for the module. 


###### Struct:

```xml
	<struct name="MediaServiceManifest">
	
	</struct>

	<struct name="MediaServiceData">
		<description> This data is related to what a media service would provide</description>
		<param name="mediaTitle" type="String" mandatory="false"/>
		<param name="mediaArtist" type="String" mandatory="false"/>
		<param name="mediaAlbum" type="String" mandatory="false"/>
		<param name="mediaYear" type="String" mandatory="false"/>
		<param name="mediaGenre" type="String" mandatory="false"/>
		<param name="mediaStation" type="String" mandatory="false"/>
		<param name="rating" type="int" minvalue ="0" maxvalue="100" mandatory="false"/>
		<param name="mediaImageName" type="String" mandatory="false">

	</struct>
    
```

###### RPCs to be handled:

- Button Press: 
  - OK
  - SEEKLEFT
  - SEEKRIGHT
  - TUNEUP
  - TUNEDOWN
  - SHUFFLE
  - REPEAT


#### Weather
A weather service is defined as a service that can provide weather data. 

```xml

	<struct name="WeatherServiceManifest">
		<param name="currentForecastSupported type="Boolean" mandatory="false"/>
		<param name="maxMultidayForecastAmount" type="Integer" mandatory="false"/>
		<param name="weatherForLocationSupported" type="Boolean" mandatory="false"/>
	</struct>

	<struct name="WeatherServiceData">
		<description> This data is related to what a weather service would provide</description>
		<param name="currentForecast" type="DailyForecast" mandatory="false"/>
		<param name="multidayForecast" type="DailyForecast" array="true" minsize="1" mandatory="false">
			<description> This array should be ordered with the first object being the current day</description>
		</param>
	</struct>
	
	<struct name="DailyForecast">
		<param name="currentTemperature" type="Temperature" mandatory="false"/>
		<param name="maximumTemperature" type="Temperature" mandatory="false"/>
		<param name="minimumTemperature" type="Temperature" mandatory="false"/>
		<param name="weatherTerm" type="String" mandatory="false"/>
		<param name="humidity" type="String" mandatory="false"/>
		<param name="weatherImageName" type="String" mandatory="false">
	</struct>
    
```


#### Navigation
A navigation service is defined as a service that is currently listed as the navigation provider. 

```xml
	<struct name="NavigationServiceManifest">
		<param name="acceptsWayPoints" type="Boolean" mandatory="false"/>
	</struct>

	<struct name="NavigationServiceData">
		<description> This data is related to what a navigation service would provide</description>
		
		<param name="waypoints" type="LocationDetails" array="true" minsize="2" mandatory="false">
			<description> This array should be ordered with the first object being the start location of the current trip and the last object the final destination. </description>
		</param>
		
		<param name="eta" type="DateTime" mandatory="false"/>

	</struct>
	
    
```

###### RPCs to be handled:
 - SendLocation
 - GetWayPoints


#### Voice Assistant
A voice assistant service is defined as a service that is currently acting as the voice assistant provider. This provider needs to be flushed out with a lot of extra details as its functionality is far reaching.

```xml

	<struct name="VoiceAssistantServiceManifest">
		<param name="wakeWords" type="String" array="true" minsize="1" mandatory="false"/>
		
	</struct>
	
	<struct name="VoiceAssistantServiceData">
		<description> This data is related to what a voice assistant service would provide</description>

	</struct>

	<enum name="VoiceAssistantTrigger">
		<element name="PUSH_TO_TALK_BUTTON"/>
		<element name="WAKE_WORD"/>
	</enum>
```

##### New RPCs for Voice Assistant

```xml
	<function name="OnVoiceAssistantActivated" functionID="OnVoiceAssistantActivatedID" messagetype="notification">
		<param name="triggerSource" type="VoiceAssistantTrigger" mandatory="true">
			<description>Informs the voice assistant of which source triggered the event.</description>
		</param>
		<param name="triggerInfo" type="String" mandatory="false">
			<description>Any extra information about the trigger. This should include the wake word used and any other speech strings recognized.</description>
		</param>
	
	</function>
	
	<struct name="VRSynonym">
		<param name="synonym" type="String" mandatory="true"/>
		<param name="id" type="Integer" mandatory="true"/>
	</struct>
	
	<function name="UpdateVRSynonyms" functionID="UpdateVRSynonymsID" messagetype="request">
			<param name="vrSynonyms" type="VRSynonym" array="true" mandatory="true"/>
			<param name="shouldAdd" type="Boolean" mandatory="true">
				<description>Set to true if the synonyms should be added. Set to false if they should be removed</description>
			</param>
	</function>
	
	
	<function name="UpdateVRSynonyms" functionID="UpdateVRSynonymsID" messagetype="response">
		<param name="success" type="Boolean" platform="documentation" mandatory="true">
			<description> true, if successful; false, if failed </description>
		</param>
       
		<param name="resultCode" type="Result" platform="documentation" mandatory="true">
			<description>See Result</description>
			<element name="SUCCESS"/>
			<element name="INVALID_DATA"/>
			<element name="OUT_OF_MEMORY"/>
			<element name="TOO_MANY_PENDING_REQUESTS"/>
			<element name="APPLICATION_NOT_REGISTERED"/>
			<element name="GENERIC_ERROR"/>
		</param>
	
		<param name="info" type="String" maxlength="1000" mandatory="false" platform="documentation">
			<description>Provides additional human readable info regarding the result.</description>
		</param>
	</function>
	
	<function name="OnVRChoiceSelected" functionID="OnVoiceAssistantActivatedID" messagetype="notification">
			<param name="vrSynonymSelected" type="VRSynonym" mandatory="true"/>
	</function>
    
```

###### RPCs to be handled:
- OnVoiceAssistantActivated
- UpdateVRSynonyms

### Flows
-------

This section will cover how some of the important flows will take place.

#### App Service Provider

First we can start with an app publishing their service and that information propagating to other apps.

![Packet Structure](../assets/proposals/0167-app-services/provider.png "App Service Provider")

##### Defining the service - `AppServiceManifest`
When an app wishes to publish a service to the system it must first define what type of service it is and create a `AppServiceManifest` object that will be passed to the module.

The `AppServiceManifest` is essentially detailing everything about a particular service offering. It contains info specific to the service (service name, id, etc) as well as what capabilities it offers.

```xml
	<struct name="AppServiceManifest">
		<param name="serviceName" type="String" mandatory="false"/>
		<param name="serviceId" type="String" mandatory="true"/>
		<param name="serviceType" type="AppServiceType" mandatory="true">
			<description>The type of service that is to be offered by this app</description>
		</param>
		
		<param name="serviceIcon" type="String" mandatory="false">
			<description> The file name of the icon to be associated with this service. Most likely the same as the appIcon.</description>
		</param>
		
		<param name="allowAppConsumers" type="Boolean" mandatory="false"/>

				
		<param name="uriPrefix" type="String" mandatory="false"/>
		<param name="uriActions" type="JSONObject" mandatory="false">
		
		<param name="serviceActive" type="Boolean" mandatory="false"/>
		
		<param name="rpcSpecVersion" type="SyncMsgVersion" mandatory="false"/>
		<param name="handledRPCs" type="FunctionID" array="true" mandatory="false">
			<description> This field contains the Function IDs for the RPCs that this service intends to handle correctly. This means the service will provide meaningful responses. </description>
		</param>
		
		<param name="mediaServiceManifest" type="MediaServiceManifest" mandatory="false"/>
		<param name="weatherServiceManifest" type="WeatherServiceManifest" mandatory="false"/>
		<param name="navigationServiceManifest" type="NavigationServiceManifest" mandatory="false"/>
		<param name="voiceAssistantServiceManifest" type="VoiceAssistantServiceManifest" mandatory="false"/>

	</struct>
	
```

Based on the specific type of service being offered, an additional manifest struct should be included. These structs are very specific to the service that is being offered. These are defined in the previous section  [Service Types](#service-types).


##### Publishing the service - `PublishAppService`
The next action the App Service has to take is publishing their service. This is performed after the `RegisterAppInterface` response is received. The `PublishAppService` request contains the previously created `AppServiceManifest` object that will inform the system of the capabilities and info about this service.


```xml
<function name="PublishAppService" functionID="PublishAppServiceID" messagetype="request">
	<description>Registers a service offered by this app on the module</description>

	<param name="appServiceManifest" type="AppServiceManifest" mandatory="false"/>

	
</function>


<function name="PublishAppService" functionID="PublishAppServiceID" messagetype="response">
	<description>Response to the request to register a service offered by this app on the module</description>

	<param name="success" type="Boolean" platform="documentation" mandatory="true">
		<description> true, if successful; false, if failed </description>
	</param>
       
	<param name="resultCode" type="Result" platform="documentation" mandatory="true">
		<description>See Result</description>
		<element name="SUCCESS"/>
		<element name="INVALID_DATA"/>
		<element name="OUT_OF_MEMORY"/>
		<element name="TOO_MANY_PENDING_REQUESTS"/>
		<element name="APPLICATION_NOT_REGISTERED"/>
		<element name="GENERIC_ERROR"/>
	</param>
	
	<param name="info" type="String" maxlength="1000" mandatory="false" platform="documentation">
		<description>Provides additional human readable info regarding the result.</description>
	</param>
</function>

```

##### Notifying potential consumers - `OnAppServiceRecordUpdated`

Once the service is published to the module, the module will be responsible for ensuring that other connected apps are notified that a new service has registered. This is done through the `OnAppServicePublished` notification. This contains the same manifest that was provided by the original app service provider. 


```xml
<enum name="ServiceUpdateReason">
	 <element name = "PUBLISHED"/>
	 <element name = "REMOVED"/>
	 <element name = "ACTIVATED"/>
	 <element name = "DEACTIVATED"/>
	 <element name = "MANIFEST_UPDATE"/>
</enum>

<struct name="AppServiceRecord">
	<param name="serviceManifest" type="AppServiceManifest" mandatory="true"/>
	<param name="servicePublished" type="Boolean" mandatory="true"/>
	<param name="serviceActive" type="Boolean" mandatory="true"/>
</struct>

<function name="OnAppServiceRecordUpdated" functionID="OnAppServiceRecordUpdatedID" messagetype="notification">
	<description> This notification includes the data that is updated from the specific service</description>
	<param name="appServiceRecord" type="AppServiceRecord" mandatory="true"/>
	<param name="updateReason" type="ServiceUpdateReason" mandatory="true"/>
</function>

```

##### Notifying provider of removal

If for any reason the module determines that an app service provider is no longer to be published and is to be removed it will notify the app service provider through an `OnAppServiceRecordUpdated` with the `servicePublished` boolean set to false. It will be the responsibility of the app service provider to then tear down their service resources on the mobile device side. 

If the service wishes to reregister it can follow the normal flow, pending the `updateResult` param in the notification.


#### App Service Consumer

This section will cover how another app can consume the newly published app service.

![App Service Consumer](../assets/proposals/0167-app-services/consumer.png "App Service Consumer")


##### Get service capabilities

If the app wants to use services published on the device, it must first ensure the feature is supported. This requires a modification to the System Capability functionality.

###### New SystemCapabilityType

```xml
<enum name="SystemCapabilityType">
   	...
	<element name="APP_SERVICES"/>
</enum>
```

###### Added Capability for App Services

```xml
   
<struct name="SystemCapability">
	...
	<param name="appServicesCapabilities" type="AppServicesCapabilities" mandatory="false"/>
</struct>
    
<struct name="AppServicesCapabilities">
	<param name="supported" type="Boolean" mandatory="true"/>
   	<param name="appServices" type="AppServiceRecord" array="true" mandatory="false"/>
</struct>

```
##### Get service data

The app service consumer can then decide which services it wants to get more info from and even subscribe to for future updates from the service.

When requesting the data from the app service the developer can expect the data to be in the form of an `AppServiceData` object. This struct will hold all the data related to the specific app service's current state. The serviceType param will indicate which param of the service datas are included.

###### AppServiceData
```xml
<struct name="AppServiceData">
	<param name="serviceType" type="AppServiceType" mandatory="true"/>
	<param name="serviceId" type="String" mandatory="true"/>
		
	<param name="mediaServiceData" type="MediaServiceData" mandatory="false"/>
	<param name="weatherServiceData" type="WeatherServiceData" mandatory="false"/>
	<param name="navigationServiceData" type="NavigationServiceData" mandatory="false"/>
	<param name="voiceAssistantServiceData" type="MediaServiceData" mandatory="false"/>

</struct>
```

The specific service data structs were discussed previously in the [Service Types](#service-types) section.


Now that we know what to expect in terms of the actual data, the next piece will be to actually retrieve the data. This is done through a `GetAppServiceData` request. The request contains two params, one to indicate the service type and a second to indicate if the consumer would like to subscribe to future updates from the app service provider.

###### GetAppServiceData

```xml
<function name="GetAppServiceData" functionID="GetAppServiceDataID" messagetype="request">
	<description> This request asks the module for current data related to the specific service. It also includes an option to subscribe to that service for future updates</description>
	
	<param name="serviceType" type="AppServiceType" mandatory="true"/>
	
	<param name="subscribe" type="Boolean" mandatory="false"/>
	
</function>

<function name="GetAppServiceData" functionID="GetAppServiceDataID" messagetype="response">
	<description> This response includes the data that is requested from the specific service</description>
	
	<param name="serviceData" type="AppServiceData" mandatory="true"/>
		
</function>
```

##### Subscribed services

If the app service consumer subscribed to updates from the app service provider they will recieve those updates through an `OnAppServiceData ` notification. This notification will simply contain an `AppServiceData` struct with the updated data.

###### OnAppServiceData

```xml
<function name="OnAppServiceData" functionID="OnAppServiceDataID" messagetype="notification">
	<description> This notification includes the data that is updated from the specific service</description>
	
	<param name="serviceData" type="AppServiceData" mandatory="true"/>
	
</function>
```

#### App Service Media

One of the aspects to publishing services will be to include data beyond simple text strings. For our observed use cases this will likely be simple icons/small images, for example, app icons, weather icons, or album art.  This will require the app service provider to push the files to the module. This is done through the normal PutFile means.

![App Service Media](../assets/proposals/0167-app-services/file_transfer.png "App Service Media")


When an app service consumer receives an `AppServiceData` object that contains file names of the media that the app service provider intends to share they will need to send a `GetFile` request. The structure of the `GetFile` request/response pair is very similar to that of the `PutFile` pair.

```xml
<function name="GetFile" functionID="GetFileID" messagetype="request">
	<description> This request is sent to the module to retrieve a file</description>

	<param name="syncFileName" type="String" maxlength="255" mandatory="true"/>
	<param name="appServiceId" type="String" mandatory="false"/>

	<param name="fileType" type="FileType" mandatory="false">
		<description>Selected file type.</description>
	</param>
	
	
	<param name="offset" type="Integer" minvalue="0" maxvalue="2000000000" mandatory="false">
		<description>Optional offset in bytes for resuming partial data chunks</description>
	</param>
	
	<param name="length" type="Integer" minvalue="0" maxvalue="2000000000" mandatory="false">
		<description>Optional length in bytes for resuming partial data chunks if offset is set to 0, then length is the total length of the file to be downloaded</description>
	</param>
		
</function>

<function name="GetFile" functionID="GetFileID" messagetype="response">
	<description> This response includes the data that is requested from the specific service</description>
	
	<param name="success" type="Boolean" platform="documentation" mandatory="true">
		<description> true, if successful; false, if failed </description>
	</param>
       
	<param name="resultCode" type="Result" platform="documentation" mandatory="true">
		<description>See Result</description>
		<element name="SUCCESS"/>
		<element name="INVALID_DATA"/>
		<element name="OUT_OF_MEMORY"/>
		<element name="TOO_MANY_PENDING_REQUESTS"/>
		<element name="APPLICATION_NOT_REGISTERED"/>
		<element name="GENERIC_ERROR"/>
	</param>
	
	<param name="info" type="String" maxlength="1000" mandatory="false" platform="documentation">
		<description>Provides additional human readable info regarding the result.</description>
	</param>
	
	<param name="offset" type="Integer" minvalue="0" maxvalue="2000000000" mandatory="false">
		<description>Optional offset in bytes for resuming partial data chunks</description>
	</param>
	
	<param name="length" type="Integer" minvalue="0" maxvalue="2000000000" mandatory="false">
		<description>Optional length in bytes for resuming partial data chunks if offset is set to 0, then length is the total length of the file to be downloaded</description>
	</param>

	
</function>
```

#### App Service Actions - `PerformAppServiceInteraction`

App service providers will likely have different actions exposed to the module and app service consumers. It will be difficult to standardize these actions by RPC versions and can easily become stale. Therefore, we introduce a best-effort attempt to take actions on a service. 

The `PerformAppServiceInteraction` request will be sent to the service that has the matching `appServiceId`. The `serviceUri` should be the fully qualified URI with all parameters that are necessary for the given action. The URI prefix and actions list will be contained in the app service provider's manifest. SDL takes no steps to validate an app service provider's action sheet JSON object. In the future, plug in libraries could be added to handle these sheets on a provider by provider bases. 

An app service consumer can also request for this service to become the active service of its respective type. If the app service consumer currently has an HMI state of HMI_FULL this request can be performed without user interaction. If the app is currently not in that state, the HMI should present the user with a choice to allow this app service provider to become the active service of its specified type. If the app service provider is not allowed to become active, the request will not be sent to it and an unsuccessful response will be sent to the requester. 

SDL should make no guarantees that:

1. App service providers offer URI prefix and actions sheet
2. App service providers will correctly respond to the requests
3. The requested app service provider will become the active service of that type
4. The `serviceUri` will be correctly formatted from the app service consumer

```xml
<function name="PerformAppServiceInteraction" functionID="PerformAppServiceInteractionID" messagetype="request">

	<param name="serviceUri" type="String"  mandatory="true"/>
	<param name="appServiceId" type="String" mandatory="false"/>
	<param name="requestServiceActive" type="Boolean" mandatory="false"/>

		
</function>

<function name="PerformAppServiceInteraction" functionID="PerformAppServiceInteractionID" messagetype="response">

	<param name="success" type="Boolean" platform="documentation" mandatory="true">
		<description> true, if successful; false, if failed </description>
	</param>
       
	<param name="resultCode" type="Result" platform="documentation" mandatory="true">
		<description>See Result</description>
		<element name="SUCCESS"/>
		<element name="INVALID_DATA"/>
		<element name="OUT_OF_MEMORY"/>
		<element name="TOO_MANY_PENDING_REQUESTS"/>
		<element name="APPLICATION_NOT_REGISTERED"/>
		<element name="GENERIC_ERROR"/>
	</param>
	
	<param name="info" type="String" maxlength="1000" mandatory="false" platform="documentation">
		<description>Provides additional human readable info regarding the result.</description>
	</param>

	
</function>
```

### Core

Core will have to manage which services are currently published and which of those are considered active. If a user wishes to select an app service over an onboard service there should be an easy way to perform this action on the IVI system.


##### Activating Service Providers

Enabling services will be a major UX concern for Core and HMI portions. A set of guidelines should exist to ensure the consumer will understand what's happening and how to change service providers.

1. App service providers may become "Activated" if they are the only service to register. 
2. If multiple app service providers of the same type register and the user has not previously selected an app service provider of that type, the first service to register will be activated by default.
3. When an app service provider is changed to be the "Activated" service of that type, the user should be notified.
4. The user should have the ability to select default service types through the IVI system based on records of app services that have connected. All selection screens must adhere to driver distraction guidelines per the region in which it is used.
5. If an app service provider has been selected as default but does not register, rule 2 will then be the fallback.
6. If an app service consumer wishes to activate a different app service provider than the currently selected app service provider, the HMI must present the user with a notification/choice to allow the new app service provider over the previously selected one.


##### Adaptation to new services

Core should be setup in a way that it can handle new services as we create them. It should not ignore service publications that it doesn't know about. Instead, each publish request will contain a set of RPCs that that service can handle. The user should then have the choice of whether to have the IVI system handle the RPC or the service. 


##### RPC passing

Once a service has become the active service provider, the intersection of RPCs the app service provider supports and the expected supported RPCs based on service type should be sent to the app service provider for processing.


![RPC Passthrough](../assets/proposals/0167-app-services/rpc_passthrough.png "RPC Passthrough Example")

###### RPC Response Timeout

The RPC response timeout should have its threshold increased when forwarding a packet to be handled by an app service provider. While processing the initial RPC request, once Core recognizes that the packet is to be forwarded the timeout for the specific request should be increased. 


###### Unknown RPC Params

Core will need to parse and store received params even if they are not listed in that version of Core's supported RPC spec. This will allow the services to be updated and function on any Core that supports the base feature. That will keep the service feature fresh and useful on older units. Essentially Core should be able to store the params received into a key/value map and form the base RPC structs and request/responses using all entries in that map.


##### Policy Table

The IVI system can enable/disable app service providers from offering their services and consumers from using them through additions to the policy table. New functional groups will be introduced for `AppServiceProvider` and `AppServiceConsumer`. Furthermore, the functional groups can become more granular to provide access to publishing/consuming of specific app service types.


## Potential downsides

- The size of this change is very large, and will have a widespread effect on different aspects of all the code. This will be a complex change that will require a lot of testing.
- RemoteControl functionality already has a subset of this feature included in the Radio module. This will cause some clashing between the two paradigms.


## Impact on existing code

Each affected platform will need to have RPCs added. Some platforms might need additional logic to be able to send notifications instead of just requests as well.

### Core

Core will have the biggest changes necessary. A new AppServiceManager will need to be created to manage all the published services and all the clients subscribed. The entire feature should be designed to take advantage of the plug-in architecture that is used by the Remote Control feature. Core changes might require a separate proposal to ensure the architecture lines up with the SDLC's expectations. 

### Mobile Libraries

The mobile libraries will need a nice, developer friendly manager to handle publishing their service. These managers will need to have their own proposal as this one simply is proposing to create the functionality between the systems.

### Policy Server

New functional groups should be created based on [this section](#policy-table).




## Alternatives considered

- Instead of strict struct definitions, we could create very loosely defined key value pair maps. The keys would be obtained from the metadataTags enum.
- Instead of a string of a name to designate an image file that should be retrieved from the service data, actually attach the raw bytes in a parameter. 
- Voice Assistant services could simply get `AddCommands` sent to them, and a new notification for `OnCommand` could be sent. This might get difficult as the app service provider would receive such RPC requests from multiple different apps. The RPC itself could be reused with a new ID being issued in the `AddCommand`. The Core module would then be responsible for the translations.
- Separate spec specifically for services. There seems to be nearly enough complexity to warrant a separate spec that contains all the service related RPCs. This spec would be versioned separately from the Mobile API RPC spec. 
- In addition to previous bullet, it almost seems as if the service RPCs could be sent over a new AppService channel separate from the RPC and bulk channels.
- For icon/images, the raw data could simply be sent in the Service Data packets. This would eliminate the `GetFile` RPC and possibly a lot of extra logic in Core. However, this would introduce new challenges to Core/HMI if those systems also "subscribed" to these services. They would have to know how to handle the raw data, or have their messages customized. It will also get complicated when dealing with services like Weather. For each day forecast there is likely an icon to be used so the attaching all the image data to the bulk data is not really an option.
- Instead of exposing a URI prefix and URI schemes to app service consumers, it is possible to send all commands (`AddCommand`, `InteractionChoiceSets`, etc) to the app consumers and reuse the same functionality that is exposed to the module. The issue, however, is that this would be an extreme burden on the traffic of the protocol.
- Potential other cases to cover:
     - App Service Provider requests to change its declared manifest through new request/response pair. `OnAppServiceRecordUpdate` would be sent to all consumers after change was accepted. 
     - Certain providers could be responsible for sending specific RPC notifications (eg Nav - OnWayPoints changed)
     - Update app service consumers when a new service has been activated over a different app service provider
     - Add an additional RPC to be more specific about notifying an App Service Provider they were removed.

