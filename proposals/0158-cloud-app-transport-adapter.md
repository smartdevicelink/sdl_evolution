# Cloud App Transport Adapter

* Proposal: [SDL-0158](0158-cloud-app-transport-adapter.md)
* Author: [Jack Byrne](https://github.com/JackLivio)
* Status: **In Review**
* Impacted Platforms: [Core]

## Introduction

This proposal will detail a possible solution for allowing  SDL-enabled cloud applications to be used in a vehicle. This proposal will cover the process of obtaining cloud application server endpoints, enabling which cloud apps should appear in the HMI app list, opening connections between Core and a cloud based app server, and how a cloud application can authenticate connected head units. 

The implementation of a SDL cloud app javascript library used to create SDL connected cloud applications will be covered by another proposal. 


## Motivation

### Background on SDL-enabled cloud applications:
- SDL cloud apps would still use the SDL RPC Service / protocol
- SDL cloud apps would integrate a proxy library that supports all Mobile API RPCs (implemented in Javascript)
- SDL cloud apps live in the "cloud", not in the car or phone
- Using a cloud app on the head unit would not require a mobile device, but would require the head unit to have an active data connection
- SDL Core initiates the connection to cloud application using endpoints supplied by policy table updates (OEMs control trusted app connections)
- User can select which cloud apps to display through an OEM App Store

## Proposed solution

### High level overview of connection process and authentication

1. User opens OEM App store containing the list of possible cloud applications. (Using mobile sdl app or embedded sdl app)
2. User chooses to enable a cloud application from the list
3. If the cloud application requires user authentication, the user will enter login information or complete OAuth Device Flow
4. Auth information is sent in a post request from OEM app store to cloud app server with hashed VIN
5. Cloud app verifies login credentials and stores hashed VIN for future use. 
6. Cloud app responds to OEM app store with a secret token that will be used to authenticate SDL Core's future websocket connection
7. User connects phone to headunit, OEM app registers and sends updated list of enabled cloud apps and corresponding secret tokens.
8. Core stores secret tokens in the policy table and updates the `enabled` field of the cloud apps listed in the policy table.
9. Core sends update app list to HMI to display cloud apps' availability
10. User activates cloud app, Core gets WS endpoint from policy table and opens WS connection passing the secret token supplied by oem app and the hashed VIN
11. Cloud app verifies the hashed VIN  and secret token are valid and accepts the connection


### Obtaining Cloud App IP Address and Port
Maintaining a list of urls for each cloud app will be similar to how policies for SDL applications are currently managed. When a policy table update is required, the sdl server will send an updated PT with a list of cloud apps and their websocket endpoints.

There will need to be three new fields introduced in the app_policies section of the policy table. 

This is what the app_policies section of a policy table that includes a cloud app endpoint might look like: 

```JSON
        "app_policies": {
            "default": {
                "keep_context": false,
                "steal_focus": false,
                "priority": "NONE",
                "default_hmi": "NONE",
                "groups": ["Base-4"]
            },
            "IOSApp12345": {
                "keep_context": true,
                "steal_focus": true,
                "priority": "NONE",
                "default_hmi": "NONE",
                "groups": ["Base-4", "Location-1", "Emergency-1"]
            },
            "WebAppID12345" : {
                "keep_context": true,
                "steal_focus": true,
                "priority": "NONE",
                "default_hmi": "NONE",
                "groups": ["Base-4"],
+               "endpoint": "https://fakesdlwebsocketurl.com:8080",
+               "certificate" : "-----BEGIN CERTIFICATE-----\n" ...,
+               "enabled" : false,
+               "authToken" : "ABCD12345"
            }
        }
```

The `endpoint` field includes the URL/IP and port that the SDL cloud app can be connected to. 

The `certificate` field is used for secured RPC service connections which equates to opening a secured websocket connection. 

The `enabled` field is by default set to false so the cloud app does not show on the HMI. If the user enables an app via the app store flow highlighted in the section above, then `enabled` will be set to true in the head units local policy table. When set to true, this cloud app will be included in the HMI RPC "UpdateAppList".

The `token` field is also obtained via the app store selection and authorization flow discussed above. This token is used to authenticate the head units websocket connection to the cloud app server. This field will most likely not be included in the sdl server PTU response. This field should be populated through the SetCloudAppProperties RPC

Endpoints can be added, removed, or updated via policy table updates. This means OEMs will be in control of the cloud apps that their head units attempt to connect to.

### Enabling Cloud Apps to Appear on SDL App List

Mobile API Changes

Add new RPC "SetCloudAppProperties". This RPC can be used by an OEM "App Store" in order to enable/disable a cloud app from appearing on the SDL HMI. This RPC will also deliver neccesary authentication information if the app requires it. 
```
    <function name="SetCloudAppProperties" functionID="SetCloudAppPropertiesID" messagetype="request">
        <description>
            RPC used to enable/disable a cloud application and set authentication data
        </description> 
        <param name="appName" type="String" maxlength="100" mandatory="true"></param>
        <param name="appID" type="String" maxlength="100" mandatory="true"></param>
        <param name="enabled" type="Boolean" mandatory="false">
            <description>If true, cloud app will be included in HMI RPC UpdateAppList</description>
        </param>
        <param name="cloudAppAuthToken" type="String" maxlength="100" mandatory="false">
            <description>Used to authenticate websocket connection on app activation</description>
        </param>
    </function>

    <function name="SetCloudAppProperties" functionID="RegisterAppInterfaceID" messagetype="response">
        <description>The response to registerAppInterface</description>
        <param name="success" type="Boolean" platform="documentation" mandatory="true">
            <description> true if successful; false, if failed </description>
        </param>
        <param name="resultCode" type="Result" platform="documentation" mandatory="true">
            <description>See Result</description>
            <element name="SUCCESS"/>
            <element name="INVALID_DATA"/>
            <element name="OUT_OF_MEMORY"/>
            <element name="TOO_MANY_PENDING_REQUESTS"/>
            <element name="GENERIC_ERROR"/>
            <element name="DUPLICATE_NAME"/>
            <element name="TOO_MANY_APPLICATIONS"/>
            <element name="APPLICATION_REGISTERED_ALREADY"/>
            <element name="UNSUPPORTED_VERSION"/>
            <element name="WRONG_LANGUAGE"/>
            <element name="DISALLOWED"/>
            <element name="WARNINGS"/>
            <element name="RESUME_FAILED"/>
        </param>
    </function>
```
HMI API Changes

Update to UpdateAppList description
```
<function name="UpdateAppList" messagetype="request">
      <description>Issued by SDL to notify HMI about new applications registered or enabled cloud apps.</description>
      ...
</function>
```
Update HMIApplication Struct 
```
<struct name="HMIApplication">
    ....
    <param name="isCloudApplication" type="Boolean" mandatory="false"></param>
    <param name="cloudConnectionStatus" type="CloudConnectionStatus" mandatory="false"></param>
</struct>
```

A new enum CloudConnectionStatus will be used to allow the HMI to notify the user about the status of a cloud app connection.
```
<enum name="CloudConnectionStatus">
    <element name="NOT_CONNECTED" value="0"/><description>No active websocket session or ongoing connection attempts</description>
    <element name="CONNECTED" value="1"/><description>Websocket is active</description>
    <element name="RETRY" value="2"/><description>Websocket connection failed and retry attempts are ongoing</description>
</enum>
```
### Retry Sequence

The config file smartDeviceLink.ini should be updated to include two fields that relate to connection retry attempts for cloud connections

```
[Cloud App Connections]
; Value in milliseconds for time between retry attempts on a failed websocket connection
CloudAppRetryTimeout = 1000 
; MaxNn number of retry attempts for a cloud websocket connection
CloudAppMaxRetryAttempts = 5
```

While Core is attempting to retry opening the websocket connections, Core will send the HMI an UpdateAppList RPC with the HMIApplication CloudConnectionStatus enum of "CONNECTING". The HMI may choose how it wants to display to the user that connection attempts to the cloud app are ongoing.

If the CloudAppMaxRetryAttempts value is reached, Core will stop attempting to open the websocket connection and send an UpdateAppList RPC with the HMIApplication CloudConnectionStatus enum of "NOT_CONNECTED". Future connection attempts can be initiated by the user if they activate the app again.

If the websocket connection attempt is successful, Core will send the CloudConnectionStatus enum "CONNECTED" via UpdateAppList.

#### Transport Adapter Connection Flow

App Activation: User selects the cloud app from the app list on the HMI and the websocket connection to the cloud server is opened and auth information is sent.

![alt text](../assets/proposals/0158-cloud-app-transport-adapter/cloud_app_activation.png "App Activation")

The behavior of displaying a cloud app before registration is to prevent unnecessary websocket connections when an app is not in use. Also if an application is put into hmi status NONE, then the websocket connection will be closed until the user activates the application again.

### Hashed VIN

Since Core itself does not store the VIN, the hashed VIN must be supplied by the HMI. The path to where this value can be found on disk should be set in the smartDeviceLink.ini config file.
```
[Cloud App Connections]
...
;File path that contains the Hashed VIN to be used in cloud app authentication
HashedVINPath=cloud_id.data
```
How this value is set is meant to be open ended as each OEM might have a different preference on how to set a unique value for headunits that attempt cloud app connections. 

## Potential downsides

Requires OEM to develop an App store via a mobile SDL app or an embedded SDL app. 

OEM must maintain extra set of policy related data (Endpoints and certificates). If an endpoint becomes outdated, head units will try to connect to an unknown endpoint. 

Adding a new Javascript proxy library means another major repository must be developed and maintained. This effort requires new feature development, issue tracking/bug fixes, creating documentation.

## Impact on existing code

### SDL Core

#### New Device Type

A new enum must be added to DeviceType to differentiate cloud app connections from app connections located in the vehicle. 

```c++
enum DeviceType {
  CLOUD,
  AOA,
  PASA_AOA,
  BLUETOOTH,
  PASA_BLUETOOTH,
  MME,
  IOS_BT,
  IOS_USB,
  TCP,
  UNKNOWN
};
```

#### Websocket Client Transport Adapter
Core will need a new transport adapter that initiates websocket client connections to a remote endpoint. I suggest creating a transport adapter that integrates this library: [Boost Beast](https://github.com/boostorg/beast) for handling the websocket connections.  

### Policies

app_policies section of policy table related classes must be expanded to support new optional endpoint and ssl_certificate fields. 

types.h
```
struct PolicyBase : CompositeType {
 public:
  Strings groups;
  Optional<Strings> preconsented_groups;
  Enum<Priority> priority;
  Enum<HmiLevel> default_hmi;
  Boolean keep_context;
  Boolean steal_focus;
  Optional<String<0, 255> > cloud_app_endpoint;
  Optional<String<0, 65535> > ssl_certificate;
```

policy_table_interface_ext.xml
```
    <struct name="ApplicationParams">
        <param name="groups" type="Strings" />
        <param name="nicknames" type="Strings" mandatory="false" />
        <param name="preconsented_groups" type="Strings" mandatory="false" />
        <param name="AppHMIType" type="AppHMITypes" mandatory="false" />
        <param name="priority" type="Priority" />
        <param name="default_hmi" type="HmiLevel" />
        <param name="keep_context" type="Boolean" />
        <param name="steal_focus" type="Boolean" />
        <param name="memory_kb" type="Integer" minvalue="1" maxvalue="65225" mandatory="false"/>
        <param name="watchdog_timer_ms" type="Integer" minvalue="1"
            maxvalue="65225" mandatory="false"/>
        <param name="cloud_app_endpoint", type="String", minlength="0" maxlength="255", mandatory="false">
        <param name="certificate" type="String" minlength="0" maxlength="65535"
            mandatory="false" />
        <param name="enabled" type="Boolean" mandatory="false" />
        <param name="authToken" type="String" minlength="0" maxlength="65535"
            mandatory="false"/>
    </struct>
```
This feature should be supported by both regular and external policy build configurations.

### SDL Server

SDL Server must create an interface for managing additional policy data. Interface should allow for adding, updating, and revoking endpoint urls and SSL certificates. This work should be minimal since it's only two extra parameters.

## Alternatives considered

Since there are many aspects to this proposal, I have considered a few alternatives.

### Using Tokens Supplied by Policy Server to Authenticate

1. Core gets cloud app endpoints and associated tokens from policy server after a policy table update. 
2. Core opens a websocket connection for each cloud app endpoint located in the policy table. 
3. Core sends the VIN and token to the application and waits for the application to respond with data.
4. The cloud application server sends a request to the policy server to identify the incoming connection via the received VIN and token. 
5. If the policy server verifies that the VIN and token pair is valid, the cloud app will send a start service request to Core.

This method would remove the need for requiring the OEM App Store mobile application to connect to SDL Core.

### Using the Mobile Device to Connect

If future vehicles will not have dedicated LTE connections, then the mobile device could be used as the proxy for connecting cloud apps to Core. The phone would connect to Core using traditional SDL transports, and then also maintain a socket connection with the cloud application. Any data sent from Core/Cloud App would be passed through the phone. 

### Separating Policies and Cloud App Endpoints

A separate server could be developed to maintain cloud app endpoints if we believe that this type of logic and data is outside of the scope of policies.
