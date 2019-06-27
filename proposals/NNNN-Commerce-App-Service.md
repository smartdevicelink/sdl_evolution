# Commerce App Service

* Proposal: [SDL-NNNN](NNNN-Commerce-App-Service.md)
* Author: [Kevin Burdette](https://github.com/khburdette)
* Status: **Awaiting review**
* Impacted Platforms: [Core / iOS / Java Suite / RPC]

## Introduction

We want to add a new app service that can provide a better search experience by letting other apps feed data into a search

## Motivation

When a list of search results is displayed, generally the only options are to add it as a destination or add it as a waypoint. We would like the ability to get information from other apps that could be helpful in displaying more options. For example, when you search for "coffee", the app performing the search could get softbuttons like "order now" that would allow you to also order your coffee.

## Proposed solution

### Service Type

Introducing a new commerce app service type to be able to handle this new functionality.

##### AppServiceType enum

_Same for both MOBILE\_API and HMI\_API._

```xml
<enum name="AppServiceType" platform="documentation">
	 ...
	 <element name = "COMMERCE"/>
</enum>
```

#### COMMERCE

This will be how the providers send their POIs.

###### Struct:

```xml
<struct name="SearchServiceManifest">
    <param name="acceptsPOISearch" type="Boolean" mandatory="false">
        <description>  Informs the subscriber if this service accepts a POI search. </description>
    </param>
</struct>

<struct name="SearchServiceData">
    <description> This data is related to what a commerce service would provide. </description>

	<param name="POIs" type="POI" array="true" mandatory="true">
		<description> Array of POIs. </description>
	</param>
    
    <param name="image" type="Image" mandatory="false">
		<description> Optional image to be displayed in the search results. </description>
    </param>

	<param name="softButtons" type="Softbutton" mandatory="false">
		<description> Soft buttons applicable for the POIs. </description>
	</param>
</struct>

<struct name="POI">
    <param name="Name" type="String" array="true" mandatory="false">
		<description> Optional name to display in the search results. </description>
    </param>

    <param name="GPS" type="GPSData" mandatory="true" </param>
</struct>
```

###### RPCs to be handled:
 - POISearch

#### PerformAppServiceInteraction Uri

This will tell the provider app which POI was selected
```
openApp: POISelected: ButtonSelected:
```

### POISearch RPC

This new RPC is necessary for a consumer app to be able to search for POIs.

```xml
<element name="POISearchID" value="??" hexvalue="??" since="??" />

<function name="POISearch" functionID="SendPOIsID" messagetype="request">
	<description> This request is sent to the module to send POIs. </description>

    <param name="keywords" type="String" array="true" mandatory="true">
        <description> This is an array of search words that the user is searching for. </description>
    </param>

    <param name="searchCenter" type="GPSData" mandatory="true">
        <description> This is center of where the user is searching. </description>
    </param>

    <param name="searchRadius" type="Float" mandatory="true">
        <description> This is radius of where to search. </description>
    </param>
</function>

<function name="POISearch" functionID="SendPOIsID" messagetype="response" since="??">
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
        <element name="REJECTED"/>
        <element name="DISALLOWED"/>
        <element name="UNSUPPORTED_REQUEST"/>
        <element name="UNSUPPORTED_RESOURCE"/>
    </param>
    <param name="info" type="String" maxlength="1000" mandatory="false" platform="documentation">
        <description>Provides additional human readable info regarding the result.</description>
    </param>
</function>
```

## Potential downsides

This requires a modification to how app services currently behaves. Instead of having only 1 active service provider, there would need to be several providers.

## Impact on existing code

Adding a new app service

Adding a new RPC

## Alternatives considered

We considered who should be the consumer and who should be the provider.
