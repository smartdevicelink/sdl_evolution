# WebEngine support for SDL JavaScript

* Proposal: [SDL-NNNN](NNNN-sdl-js-pwa.md)
* Author: [Kujtim Shala](https://github.com/kshala-ford)
* Status: **Awaiting review**
* Impacted Platforms: [ Core / RPC / JavaScript / Server / Local ]

## Introduction

This proposal is adding a new transport to the SDL JavaScript library to support (progressive) web apps running on a browser.

## Motivation

Allowing new user facing applications to run in a vehicle is a big opportunity for SmartDeviceLink to enhance the user experience. Recent browsers allow a hardware independent runtime environment for apps with application management, sandboxing together with decent performance.

## Proposed solution

The proposed solution is to allow apps running in a browser and connect to SDL Core using WebSockets. The browser can be on the local host or in the local network where SDL Core is hosted. The proposed solution based on the cloud app transport adapter with additions to support apps running locally in a sandboxed (browser) environment.

### High level overview 

1. Apps should be made available to the user through an OEM store. The user should be able to install or uninstall apps from the store.
2. An app should be a compressed bundle of application files, such as html, css or script files. At minimum it requires the "index.html" file and a manifest.json file with the html file to refer to.
3. The manifest.sjon file should contain:
   1. app ID,
   2. app version,
   5. per supporting locale:
      1. nick names
      2. short name
      3. VR app names
      4. TTS app name
   6. a main/default locale
   7. a relative path to an app icon in the app bundle
4. The OEM store's backend should store the compressed app.
5. If the user chooses to install an app the store should download and decompress the app to the application storage of the system.
6. The OEM may choose to 
   1. either operate the app as a local web page (file://somewhere/helloSDL/index.html)
   2. or run a single http server instance which acts as an app host (https://localhost/helloSDL/index.html)
   3. or run an http server instance for each installed app where each app get's a local port (https://localhost:4711/index.html)
7. The OEM store uses `SetCloudAppProperties` using the manifest data. The store will set "enabled" parameter to "true" so that this app get's included in the HMI RPC "UpdateAppList".
8. The OEM store may be setting an auth token if the app requires the store to perform the auth process.
9. An app should be able to update the auth token while being registered/activated.
10. The OEM store should be notified about the auth token change.
11. For local apps the "endpoint" parameter will be empty/omitted. Instead the HMI is responsible to launch local apps.
12. If a user selects a local app, which is not running (not connected to Core) Core should use HMI_API to activate the app.
13. Core should use BasicCommunication.ActivateApp to tell the HMI to launch the app. 
14. The HMI should know that it's the local app and that it needs to be launched to the browser.
15. If the user activates the app, HMI should launch the app in the browser.
16. Launching the app should should include SDL Core's hostname and port as GET parameters (.../index.html?ws-host=localhost&ws-port=123456)
17. After the app is launched it will initiate the SDL library to connect using the GET parametes hostname and port.

### OEM store

There should be an OEM owned app which allows users to discover available apps but also install and uninstall apps. The app appearence and behavior is OEM specific however it should be able to communicate with SDL Core using the HMI API in order to control the available cloud and local apps.

#### Changing App properties

The RPC `SetCloudAppProperties` should be extended with a few additional parameters to allow an app and the system to use voice control. 

### Server and Cloud Transport

```xml
<enum name="AppPlatformType">
    <description>Enumeration of possible platforms an SDL app can exist.</description>
    <element name="MOBILE" />
    <element name="CLOUD" />
    <element name="LOCAL" />
</enum>

<struct name="CloudAppProperties" since="5.1">
<param name="nicknames" type="String" minlength="0" maxlength="100" array="true" minsize="0" maxsize="100" mandatory="false">
    <description>An array of app names a cloud app is allowed to register with. If included in a SetCloudAppProperties request, this value will overwrite the existing "nicknames" field in the app policies section of the policy table.</description>
</param>
+ <param name="ttsAppName" type="TTSChunk" minsize="1" maxsize="100" array="true" mandatory="false" since="5.x">
+    <description>The app name as text-to-speech to be used by the system's voice engine.</description>
+ </param>
+ <param name="vrAppName" type="String" maxlength="40" minsize="1" maxsize="100" array="true" mandatory="false" since="5.x">
+    <description>App names for the voice engine to be recognized with this app.</description>
+ </param>

<param name="appID" type="String" maxlength="100" mandatory="true"/>
<param name="enabled" type="Boolean" mandatory="false">
    <description>If true, cloud app will be included in HMI RPC UpdateAppList</description>
</param>
+ </param>

+ <param name="hybridAppPreference" type="HybridAppPreference" maxlength="100" mandatory="false" deprecated="true" since="5.x">
+   <history>
+     <param name="hybridAppPreference" type="HybridAppPreference" maxlength="100" mandatory="false" since="5.1" />
+   </history>
+   <description>Specifies the user preference to use the cloud app version or mobile app version when both are available</description>
+ </param>

+ <param name="appPlatformPriority" type="AppPlatformType" maxlength="100" mandatory="false">
+   <description>Specifies the user preference in a priority order of the app platform if more than one are available.</description>
+  <param>
</struct>
```

The OEM store would set cloud app properties based on the current system language. If the system language changes the OEM store would update the app properties to the new language.

The flag "greyOut" allows SDL Core to show an app in a dimmed state whlie the app is in the download and installation progress.

The app developer portal should allow a developer to specify an app as a local app. Also as the app platforms increase a new way to specify preferences should be introduced. with `appPlatformPriority` the developer and the OEM have the possibilities to prefer the SDL app from a specific platform over the other.

The RPC `SetCloudAppProperties` and all related items should also be included in the HMI_API in order to allow settings app properties from the mobile side but also from the system side (if the OEM store is embedded).

** HMI_API **

```xml
<interface name="BasicCommunication" ...>
<struct name="CloudAppProperties">
  <param name="nicknames" type="String" minlength="0" maxlength="100" array="true" minsize="0" maxsize="100" mandatory="false">
    <description>An array of app names a cloud app is allowed to register with. If included in a SetCloudAppProperties request, this value will overwrite the existing "nicknames" field in the app policies section of the policy table.</description>
  </param>
  <param name="ttsAppName" type="TTSChunk" minsize="1" maxsize="100" array="true" mandatory="false" since="5.x">
    <description>The app name as text-to-speech to be used by the system's voice engine.</description>
  </param>
  <param name="vrAppName" type="String" maxlength="40" minsize="1" maxsize="100" array="true" mandatory="false" since="5.x">
    <description>App names for the voice engine to be recognized with this app.</description>
  </param>
  <param name="appID" type="String" maxlength="100" mandatory="true"></param>
  <param name="enabled" type="Boolean" mandatory="false">
    <description>If true, cloud app will be included in HMI RPC UpdateAppList</description>
  </param>
  <param name="authToken" type="String" maxlength="65535" mandatory="false">
    <description>Used to authenticate websocket connection on app activation</description>
  </param>
  <param name="cloudTransportType" type="String" maxlength="100" mandatory="false">
    <description>Specifies the connection type Core should use</description>
  </param>
  <param name="endpoint" type="String" maxlength="65535" mandatory="false"></param>
</struct>

<function name="SetCloudAppProperties" messagetype="request">
  <description>
    HMI > SDL. RPC used to enable/disable a cloud application and set authentication data
  </description>
  <param name="properties" type="CloudAppProperties" mandatory="true">
    <description> The new cloud application properties </description>
  </param>
</function>

<function name="SetCloudAppProperties" messagetype="response">
  <description>The response to SetCloudAppProperties</description>
  <param name="success" type="Boolean" platform="documentation" mandatory="true">
    <description> true if successful; false if failed </description>
  </param>
  <param name="resultCode" type="Result" platform="documentation" mandatory="true">
    <description>See Result</description>
    <element name="SUCCESS"/>
    <element name="INVALID_DATA"/>
    <element name="OUT_OF_MEMORY"/>
    <element name="TOO_MANY_PENDING_REQUESTS"/>
    <element name="GENERIC_ERROR"/>
    <element name="DISALLOWED"/>
    <element name="WARNINGS"/>
  </param>
</function>

<function name="GetCloudAppProperties" messagetype="request">
  <description>
    HMI > SDL. RPC used to get the current properties of a cloud application
  </description> 
  <param name="appID" type="String" maxlength="100" mandatory="true"></param>
</function>

<function name="GetCloudAppProperties" messagetype="response">
  <description>The response to GetCloudAppProperties</description>
  <param name="properties" type="CloudAppProperties" mandatory="false">
    <description> The requested cloud application properties </description>
  </param>
  <param name="success" type="Boolean" platform="documentation" mandatory="true">
    <description> true if successful; false if failed </description>
  </param>
  <param name="resultCode" type="Result" platform="documentation" mandatory="true">
    <description>See Result</description>
    <element name="SUCCESS"/>
    <element name="INVALID_DATA"/>
    <element name="OUT_OF_MEMORY"/>
    <element name="TOO_MANY_PENDING_REQUESTS"/>
    <element name="GENERIC_ERROR"/>
    <element name="DISALLOWED"/>
    <element name="WARNINGS"/>
  </param>
</function>
```

### Policy table update

With app properties being set by the OEM store, SDL Core may require a policy table update. The [HMI documentation for OnSystemRequest](https://smartdevicelink.com/en/docs/hmi/master/basiccommunication/onsystemrequest/) shows sequence diagrams of how the update can be performed today. With the transport adapter the vehicle has the own modem to communicate over the internet, therefore can be able to perform the update without the need of a mobile app. 

The cloud app transport adapter proposal includes a use case that describes how a policy server with transport adapter enhancements can update the policy table (see [here](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0158-cloud-app-transport-adapter.md#example-use-case-2)).

In addition to the existing update procedures, the HMI should be able to perform an update request without sending a system request back to SDL Core. 

![Diagram PTU external proprietary over modem](../assets/proposals/NNNN-sdl-js-pwa/diagram_PolicyUpdate_external_proprietary_enhanced.png)

> Diagram showing an additional way to perform a policy table update using the vehicle modem.

### Local web app installation

If a user selects an app from the OEM store to be installed, the OEM store would notify SDL Core about the new app. The new app should appear in a dimmed state during the installation. 

![Flow of installing a web app](../assets/proposals/NNNN-sdl-js-pwa/install-web-app.png)

> Flow of installing a web app on the infotainment system.

### Local web app activation

![Flow of user activating a web app](../assets/proposals/NNNN-sdl-js-pwa/activate-web-app.png)

> Flow of how a user activates a web app and how it gets visible on the screen.

### WebSocket transport

This proposal introduces a new runtime environment; the browser. Data communication protocols are very limited in a browser environment. Therefore a new transport implementation should be introduced to SDL Core and the JavaScript library. 

The transport for Core should be a WebSocket server which listens to a port specified in the smartDeviceLink.ini file. While SDL Core is operating the server should be permanently available and listen for connections on the specified port. Another ini configuration should allow binding the socket to the localloop address or any address. This increases security in production environment and allows remote connection in development systems.

On the library side a new transport based on a WebSocket client should be created using the [WebSocket API](https://developer.mozilla.org/en-US/docs/Web/API/Websockets_API). This transport requires a hostname or ip address with a port to connect to Core's WebSocket server.

### JavaScript library

As described above the JavaScript library should be extended with a new transport. The library should also be extended to be exportable to a single .js file that can be included in an HTML file. This export could be done per library release using Webpack.

This new transport should be specific to browsers and should not be included for the Node.js platform. In order to improve simple "plug-an-play" of the library, the .js file should include only this single transport.

### App presentation

There should be two different graphical user interfaces available to browser based apps. The traditional template based user interface and the approach using the browser's document object (HTML).

#### Templates

Independent of the web app's location this user interface should be the default. With the web app becoming active on the HMI, the HMI must load the default/current template and present content as provided by the app using the `Show` RPC.

#### Open HMI

A new App HMI type called `OPEN_HMI` should be introduced. When apps with this HMI type are activated, the HMI should make the web page of this app visible on the screen. This web page will become the main window of the application. The window capabilities of this open main window will be empty except of the window ID and physical button capabilities. `Show` requests that address the main window won't have any affect to the HMI. If the app sends this request, Core should return an unsuccessful response with the result code `RESOURCE_NOT_AVAILABLE`. The info field should note that the app is registered with an open HMI. Widgets are still available and can be controlled using `Show`. Any overlay like Alert, ChoiceSets, Slider etc. are also available to the application.

**Mobile and HMI API**

```xml
<enum name="AppHMIType" since="2.0">
  :
  <element name="OPEN_HMI" since="5.x">
</enum>
```

## Potential downsides

The upside of apps running on a browser is that it comes with an extremely flexible html based user interface and with a very sandboxed runtime environment. This sandbox is also a downside as WebSocket client is the only possible transport for SDL apps in a browser.

## Impact on existing code

1. This proposal is using many pieces of the cloud app transport adapter but outside of a cloud app.
2. The transport adapter needs to support both WebSocket Client<->Server sequences.
3. Core needs a new transport type to support a WebSocket Server.
4. The JavaScript library needs a new transport type to support WebSocket Client.

## Alternatives considered

No other altnernatives considered.
