# SDL local apps using WebSocket, JavaScript and (Progressive) Web Apps

* Proposal: [SDL-NNNN](NNNN-sdl-js-pwa.md)
* Author: [Kujtim Shala](https://github.com/kshala-ford)
* Status: **Awaiting review**
* Impacted Platforms: [ Core / RPC / JavaScript / Server / Local ]

## Introduction

This proposal is adding a new transport to the SDL JavaScript library to support (progressive) web apps running on a browser.

## Motivation

Allowing new user facing applications to run in a vehicle is a big opportunity for SmartDeviceLink to enhance the user experience. Recent browsers allow a hardware independent runtime environment for apps with application management, sandboxing together with decent performance.

## Proposed solution

The proposed solution is to allow apps running in a browser and connect to SDL Core using WebSockets. The browser can be on the local host or in the local network where SDL Core is hosted. The solution includes the cloud app transport adapter with additions to support apps running locally in a sandboxed (browser) environment.

### High level overview 

1. Apps should be made available to the user through an OEM store. The user should be able to install or uninstall apps from the store.
2. An app should be a compressed bundle of application files, such as html, css or script files. At minimum it requires the "index.html" file and a manifest.json file with the html file to refer to.
3. The manifest.sjon file should contain:
   1. app ID,
   2. app version,
   3. app vendor,
   4. app publisher,
   5. per supporting locale:
      1. nick names
      2. short name <- Should be added to sdl policy?
      3. VR app names <- Should be added to sdl policy?
      4. TTS app name <- Should be added to sdl policy?
   6. a main/default locale
   7. a relative path to an app icon in the app bundle
   8. permission groups known to be used
4. The OEM store's backend should store the compressed app.
5. If the user chooses to install an app the store should download and decompress the app to the application storage.
6. The OEM may choose to 
   1. either operate the app as a local web page (file://somewhere/helloSDL/index.html)
   2. or run a single http server instance which acts as an app host (https://localhost:443/helloSDL/index.html)
   3. or run an http server instance for each installed app where each app get's a local port (https://localhost:4711/index.html)
7. The OEM store uses `SetCloudAppProperties` using the manifest data. The store will set "enabled" parameter to "true" so that this app get's included in the HMI RPC "UpdateAppList".
8. The OEM store may be setting an auth token if the app requires the store to perform the auth process.
9.  For local apps the "endpoint" parameter will be empty/omitted. Instead the HMI is responsible to launch local apps.
10. If a user selects a local app, which is not running (not connected to Core) Core should use HMI_API to activate the app.
11. Core should use BasicCommunication.ActivateApp to tell the HMI to launch the app. 
12. The HMI should know that it's the local app and that it needs to be launched to the browser.
13. An app should be able to update the auth token while being registered/activated.
14. The OEM store should be notified about the auth token change.
15. If the user activates the app, HMI should launch the app in the browser.
16. After the app is launched it will initiate the SDL library to connect.

### WebSocket transport

This proposal introduces a new runtime environment; the browser. Data communication protocols are very limited in a browser environment. Therefore a new transport implementation should be introduced to SDL Core and the JavaScript library. 

The transport for Core should be a WebSocket server which listens to a port specified in the smartDeviceLink.ini file. While SDL Core is operating the server should be permanently available and listen for connections on the specified port. Another ini configuration should allow binding the socket to the localloop address or any address. This increases security in production environment and allows remote connection in development systems.

On the library side a new transport based on a WebSocket client should be created using the [WebSocket API](https://developer.mozilla.org/en-US/docs/Web/API/Websockets_API). This transport requires a hostname or ip address with a port to connect to Core's WebSocket server.

### JavaScript library

As described above the JavaScript library should be extended with a new transport. The library should also be extended to be exportable as a .js file that can be included in an HTML file (e.g. <script src="sdl.js" /> element). This export could be done per library release using Webpack.

### App presentation

There should be two different graphical user interfaces available to browser based apps. The traditional template based user interface and the approach using the browser's document object (HTML).

#### Templates

Independent of the web app's location this user interface should be the default. With the web app becoming active on the HMI, the HMI must load the default/current template and present content as provided by the app using the `Show` RPC.

#### Open HMI

A new App HMI type called `OPEN_HMI` should be introduced to allow a web app on the local host using the document object of the browser. This means that the HMI is not only responsible of activating the app through the HMI_API, it also makes the web page of the web app visible on the HMI instead of the template. The web app running on the browser is responsible of the user interface. 

After registration the new display capabilities won't include the default main window. `Show` requests that address the predefined default main window won't have any affect to the HMI. If the app sends this request, Core should return an unsuccessful response with the result code `RESOURCE_NOT_AVAILABLE`. The info field should note that the app is registered with an open HMI. Widgets are still available and can be controlled using `Show`. Any overlay like Alert, ChoiceSets, Slider etc. are also available and should be presented on top of the browser (not inside the browser UI).

**Mobile and HMI API**

```xml
<enum name="AppHMIType" since="2.0">
  :
  <element name="OPEN_HMI" since="5.x">
</enum>
```

### Server and Cloud Transport

The app developer portal and SHAID should allow a developer to specify an app as a local app. 

```xml
<enum name="HybridAppPreference">
    <description>Enumeration for the user's preference of which app type to use when both are available</description>
    <element name="MOBILE" />
    <element name="CLOUD" />
    <element name="LOCAL" />
    <element name="BOTH" /> <!-- TODO IDENTIFY POTENTIAL CONFLICT WITH THIS ELEMENT -->
</enum>
```

## Potential downsides

The upside of apps running on a browser is that it comes with an extremely flexible html based user interface and with a very sandboxed runtime environment. This is also the downside as 

## Impact on existing code

1. This proposal is using many pieces of the cloud app transport adapter but outside of a cloud app.
2. Core needs a new transport type to support a WebSocket Server.
3. The JavaScript library needs a new transport type to support WebSocket Client.

## Alternatives considered

Describe alternative approaches to addressing the same problem, and why you chose this approach instead.
