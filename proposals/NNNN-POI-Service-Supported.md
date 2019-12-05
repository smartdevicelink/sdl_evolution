# POI Service Supported

* Proposal: [SDL-NNNN](NNNN-POI-Service-Supported.md)
* Author: [Shohei Kawano](https://github.com/Shohei-Kawano)
* Status: Awaiting review
* Impacted Platforms: [ Core / iOS / Java Suite / RPC ]

## Introduction

This proposal provides the function of sharing POI data between SDL Apps by `AppService`.  


## Motivation

Recently, IVI has moved from AVN (Audio & Visual Navigation) to DA (Display Audio).  
Therefore, when there is no Native Navigation, it is necessary to share POIs between SDL apps.  
The proposal of [SDL-0241 Commerce App Service](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0241-Commerce-App-Service.md) included a function to provide search data to other apps,   
but there was no specific use case and the function was excessive. In this proposal,   
only the minimum necessary POI exchange is provided for the App service.  
In the future, if someone wants to increase the data exchanged between apps,   
it is assumed that proposals and extensions will be made each time.  

***
[Assumed use case]
1. Launch POI app  
2. Search POI  
3. Show POI list  
4. Choose from POI list  
5. Set the chosen POI data to struct of `PoiServiceData->LocationDetails`  
6. Show popup message that is able to choose purpose from the following:  
 (a) Set as destination (Share the POI to SDL Navigation App)  
 (b) Call the phone number included in the POI  

When (a) is selected:
 7. If AppHMIType is "NAVIGATION", or if it is already LIMITED, go to (ii)10.  
 8. When there are multiple items including Native Navigation, popup is displayed.  
 9. Choose the Native Navigation or the app.  
  
  (i) When Native Navigation is selected.  
   10. Set POI to RPC `SendLocation->LocationDetails`.  
   11. Send RPC `SendLocation`  
   12. Show Native Navigation screen and find route.  
  
  (ii) When the SDL navigation app is selected or there is an app with `HMIStatus` already LIMITED.  
   10. Activate or change `HMIStatus` to FULL the target SDL Navigation App  
   11. Subscribe to App Service from Navi App  
   12. Navi App get `PoiServiceData->LocationDetails`.  
   13. Find route with Navi App.  
  
When (b) is selected  
 7. Set `PoiServiceData->LocationDetails->phoneNumber` to RPC `DialNumber->number`.  
 8. Send `DialNumber`.  
 9. Start phone call.  
***
Since this proposal is a proposal for sharing POI data, it is assumed that Navi App has already been started.  
So, navi selection and specified Nav iApp launch methods are not defined.  


## Proposed solution

Add new App Serivice Type for using this POI sharing method.  
  
Add POI element to AppServiceType enum of both Mobile API and HMI API.

Mobile API:
```xml
    <enum name="AppServiceType" platform="documentation" since="5.1">
         <element name = "MEDIA"/>
         <element name = "WEATHER"/>
         <element name = "NAVIGATION"/>
+        <element name = "POI"/>
    </enum>
```

HMI API:
```xml
    <enum name="AppServiceType">
         <element name="MEDIA"/>
         <element name="WEATHER"/>
         <element name="NAVIGATION"/>
+        <element name="POI"/>
    </enum>

```
The POI service is defined as a service that can provide searched information.  
As the information to be provided, the name, coordinates, address, outline of the place, and telephone number of the searched place are assumed.  
This information matches the parameter of structure `Location Details` defined in the navigation.  

Mobile API (struct):
```xml
<struct name="AppServiceManifest" since="5.1">	
	<description> This manifest contains all the information necessary for the service to be published, activated, and consumers able to interact with it </description>
	
	<param name="serviceName" type="String" mandatory="false">
	<description> Unique name of this service </description>
	</param>
	
	<param name="serviceType" type="String" mandatory="true">
	<description> The type of service that is to be offered by this app. See AppServiceType for known enum equivalent types. Parameter is a string to allow for new service types to be used by apps on older versions of SDL Core. </description>
	</param>
	
	<param name="serviceIcon" type="Image" mandatory="false">
	<description> The icon to be associated with this service. Most likely the same as the appIcon.</description>
	</param>
	
	<param name="allowAppConsumers" type="Boolean" mandatory="false" defvalue="false">
	<description> If true, app service consumers beyond the IVI system will be able to access this service. If false, only the IVI system will be able consume the service. If not provided, it is assumed to be false. </description>
	</param>
	
	<param name="rpcSpecVersion" type="SyncMsgVersion" mandatory="false">
	<description> This is the max RPC Spec version the app service understands. This is important during the RPC passthrough functionality. If not included, it is assumed the max version of the module is acceptable. </description>
	</param>
	
	<param name="handledRPCs" type="Integer" array="true" mandatory="false">
	<description> This field contains the Function IDs for the RPCs that this service intends to handle correctly. This means the service will provide meaningful responses. </description>
	</param>
	
	<param name="mediaServiceManifest" type="MediaServiceManifest" mandatory="false"/>
	<param name="weatherServiceManifest" type="WeatherServiceManifest" mandatory="false"/>
	<param name="navigationServiceManifest" type="NavigationServiceManifest" mandatory="false"/>
+	<param name="poiServiceManifest" type="PoiServiceManifest" mandatory="false"/>
</struct>	
	
<struct name="AppServiceData" since="5.1">	
	<description> Contains all the current data of the app service. The serviceType will link to which of the service data objects are included in this object (e.g. if the service type is MEDIA, the mediaServiceData param should be included).</description>
	
	<param name="serviceType" type="String" mandatory="true">
	<description>The type of service that is to be offered by this app. See AppServiceType for known enum equivalent types. Parameter is a string to allow for new service types to be used by apps on older versions of SDL Core.</description>
	</param>
	<param name="serviceID" type="String" mandatory="true"/>
	
	<param name="mediaServiceData" type="MediaServiceData" mandatory="false"/>
	<param name="weatherServiceData" type="WeatherServiceData" mandatory="false"/>
	<param name="navigationServiceData" type="NavigationServiceData" mandatory="false"/>
+	<param name="poiServiceData" type="PoiServiceData" mandatory="false"/>
</struct>	
	
+<struct name="PoiServiceManifest" since="5.1">	
+	<description> This manifest contains all the information necessary for the service to be published, activated, and consumers able to interact with it </description>
+	
+	<param name="poiInfoDataSupported" type="Boolean" mandatory="false">
+	<description> Informs the subscriber if this service can actually availble. </description>
+	</param>
+</param>	
	
+<struct name="PoiServiceData" since="5.1">	
+	<description> This data is related to what a POI(Points of Interest) service would provide. </description>
+	
+	<param name="poiInfoData" type="LocationDetails" mandatory="false">
+	<description> Information data of searched by POI. See LocationDetails </description>
+	</param>
+</param>	
```

HMI API(struct):
```xml
<struct name="AppServiceManifest" >	
	<description> This manifest contains all the information necessary for the service to be published, activated, and consumers able to interact with it </description>
	
	<param name="serviceName" type="String" mandatory="false">
	<description> Unique name of this service </description>
	</param>
	
	<param name="serviceType" type="String" mandatory="true">
	<description> The type of service that is to be offered by this app. See AppServiceType for known enum equivalent types. Parameter is a string to allow for new service types to be used by apps on older versions of SDL Core. </description>
	</param>
	
	<param name="serviceIcon" type="Common.Image" mandatory="false">
	<description> The icon to be associated with this service. Most likely the same as the appIcon.</description>
	</param>
	
	<param name="allowAppConsumers" type="Boolean" mandatory="false" defvalue="false">
	<description> If true, app service consumers beyond the IVI system will be able to access this service. If false, only the IVI system will be able consume the service. If not provided, it is assumed to be false. </description>
	</param>
	
	<param name="rpcSpecVersion" type="Common.SyncMsgVersion" mandatory="false">
	<description> This is the max RPC Spec version the app service understands. This is important during the RPC passthrough functionality. If not included, it is assumed the max version of the module is acceptable. </description>
	</param>
	
	<param name="handledRPCs" type="Integer" array="true" mandatory="false">
	<description> This field contains the Function IDs for the RPCs that this service intends to handle correctly. This means the service will provide meaningful responses. </description>
	</param>
	
	<param name="mediaServiceManifest" type="Common.MediaServiceManifest" mandatory="false"/>
	<param name="weatherServiceManifest" type="Common.WeatherServiceManifest" mandatory="false"/>
	<param name="navigationServiceManifest" type="Common.NavigationServiceManifest" mandatory="false"/>
+	<param name="poiServiceManifest" type="Common.PoiServiceManifest" mandatory="false"/>
</struct>	
	
<struct name="AppServiceData">	
	<description> Contains all the current data of the app service. The serviceType will link to which of the service data objects are included in this object (e.g. if the service type is MEDIA, the mediaServiceData param should be included).</description>
	
	<param name="serviceType" type="String" mandatory="true">
	<description>The type of service that is to be offered by this app. See AppServiceType for known enum equivalent types. Parameter is a string to allow for new service types to be used by apps on older versions of SDL Core.</description>
	</param>
	<param name="serviceID" type="String" mandatory="true"/>
	
	<param name="mediaServiceData" type="Common.MediaServiceData" mandatory="false"/>
	<param name="weatherServiceData" type="Common.WeatherServiceData" mandatory="false"/>
	<param name="navigationServiceData" type="Common.NavigationServiceData" mandatory="false"/>
+	<param name="poiServiceData" type="Common.PoiServiceData" mandatory="false"/>
</struct>	
	
+<struct name="PoiServiceManifest">	
+	<description> This manifest contains all the information necessary for the service to be published, activated, and consumers able to interact with it </description>
+	
+	<param name="poiInfoDataSupported" type="Boolean" mandatory="false">
+	<description> Informs the subscriber if this service is actually available. </description>
+	</param>
+</param>	
	
+<struct name="PoiServiceData">	
+	<description> This data is related to what a POI (Point of Interest) service would provide. </description>
+	
+	<param name="poiInfoData" type="LocationDetails" mandatory="false">
+	<description> Information data of searched POI. See LocationDetails </description>
+	</param>
+</param>	
```

## Potential downsides

Nothing.  

## Impact on existing code

As new application services are added, Core, iOS, Java Suite, and RPC need to be modified.  

## Alternatives considered

As new application services are added, Core, iOS, Java Suite, and RPC need to be modified.  
However, a similar proposal is already rejected in [SDL-0130-SendLocation-for-Mobile-Nav](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0130-SendLocation-for-Mobile-Nav.md).
