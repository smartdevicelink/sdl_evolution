# Enable OEM-exclusive apps support

* Proposal: [SDL-NNNN](NNNN-vehicle-type-filter.md)
* Author: [Ashwin Karemore](https://github.com/ashwink11)
* Status: **Under review**
* Impacted Platforms: [Core / iOS / Java Suite / Protocol]

## Introduction

This feature will enable SDL adapters to provide exclusive apps to their users depending on vehicle type. The proposal describes a way to share vehicle type information before sending the Register App Interface request.

## Motivation

The proposal tries to mitigate the below issues.

### Handling Proprietary app registrations

In the current implementation of the SDL, vehicle information is shared with the `Register app interface` response. If there are any apps, that work with specific OEMs, they would need to send the `Register app interface` RPC to know vehicle details. If the vehicle details do not match with the supported vehicle types, they would need to implement some mechanism to unregister the app. This behavior would cause an app to be shown on SDL enabled system for some time until the app unregisters itself from the IVI system. The users would see that apps were shown in the IVI system for a moment and are removed within seconds. By providing vehicle type information before app registration we could solve this issue, the app will not register on IVI if vehicle type is not supported, allowing app partners and SDL adapters to provide exclusive apps experience to their users depending on vehicle type information. 

### App name issue in two notifications shown with Android apps

The exclusive apps should not host `SDL Router service` on unsupported SDL systems. The android system requires all apps using foreground services to show a notification. The SDL enabled android app can have two foreground services. The `SDL router service` is started by the android proxy and another foreground service will be started by an SDL enabled app.

The `SDL router service` has no information on what head unit it is connecting with when a transport connection is made. Other SDL apps bind to available router service and use this connection. This behavior could lead to cases where a proprietary app creates an `SDL router service` when connected to an unsupported SDL enabled system. This started service will need to show a foreground notification with the app name, giving the user the impression that the proprietary app is working with an unsupported SDL enabled system.

For example, A proprietary app from an OEM creates Router service and the mobile device is connected to another OEMs' SDL enabled IVI system. The user would perceive that the proprietary app is doing something in the background, when connected to SDL enabled IVI system from another OEM.

Please refer below screenshots.

- Notification 1: Created by OEM App.
- Notification 2: Created by SDL Android SDK for `SDL Router Service`.

__Note the app name being shown in both notifications. In the below picture, the `SDL App` is using the “SDL Router Service” created by the `OEM App`.__

<img src="../assets/proposals/NNNN-vehicle-type-filter/two_noti.png" alt="App name in notifications" width="500"/>


The only way to remove notifications from OEM App when it connects to another vehicle is to force stop both the services so, that both notifications are removed. In this case, other apps connected through the `OEM Apps'` router service will also get disconnected. This is not a recommended approach. If the OEM app wants to unregisters itself from the SDL enabled IVI system, it will stop the service created by an app. The `SDL router service` from the OEM app will keep running.

Please refer below screenshot. The `SDL Router Service` is hosted by the OEM app, the `Notification 2` with the app name will be shown to the user, giving the impression that the `OEM App` is still working. If the OEM App starts showing notifications when connected to another OEM's vehicle, this would confuse users. They would probably think that `OEM App` on their mobile device is working with another OEMs SDL enabled IVI system. This proposal will define ways to mitigate this issue.

<img src="../assets/proposals/NNNN-vehicle-type-filter/one_noti.png" alt="App name in SDL router service notifications" width="500"/>

This proposal tries to address the router service notification issue by defining the vehicle type filter. So, we could have an app that could specifically connect to certain vehicles. For example, an App that is designed only for Mustang vehicles.

### Configuring lock screen with Vehicle name or brand logo 

 This would help apps to show the vehicle brand logo depending on vehicle type its connected too. In the current implementation, the lock screen configuration is set along with the SDL lifecycle/manager configuration. Hence while configuring the lock screen, the app does not know to which vehicle its connecting too. The apps cannot change the configuration of the lock screen once the app receives the `Register app interface` response with vehicle details. Some of the apps expressed their interest to show the vehicle brand logo on the lock screen of the app depending on vehicle type information, which is not possible with the current implementation of SDL due to reasons described above. 
 
## Proposed solution

This proposal will describe additional information exchange in the protocol layer and changes in Android and iOS proxy. 

### Protocol Layer changes

In the current implementation, every app is responsible for negotiating the maximum supported protocol version. The IVI can share vehicle type information with the proxy after protocol version negotiation. To share this info, we would need to define the new protocol message.

#### Frame Info Definitions

| Frame Info Value| Name | Description |
|------------|------|-------------|
| 0x0A| Get Vehicle Type | Requests vehicle type information|
| 0x0B | Get Vehicle Type ACK |Acknowledges that the specific information has been shared successfully |
| 0x0C | Get Vehicle Type NAK | Negatively acknowledges that the specific information *can not* be shared.


1. If the system supports the `Get Vehicle type` protocol message, the proxy will send it after version negotiation.
2. If the system does not support the `Get Vehicle type` protocol message, the proxy will send `Register App Interface` RPC after version negotiation and continue use case.

#### Messaging from the app to IVI

<table width="100%">
  <tr>
    <th>Version</th>
    <th>E</th>
    <th>Frame Type</th>
    <th>Service Type</th>
    <th>Frame Info</th>
    <th>Session Id</th>
    <th>Data Size</th>
    <th>Message ID</th>
  </tr>
  <tr>
    <td>5.x</td>
    <td>no</td>
    <td>Control</td>
    <td>Control</td>
    <td>Get Vehicle Type</td>
    <td>Assigned Session</td>
    <td>0</td>
    <td>n</td>
  </tr>
  <tr>
    <td>0b0101</td>
    <td>0b0</td>
    <td>0b000</td>
    <td>0x00</td>
    <td>0x0A</td>
    <td>0x01</td>
    <td>0x00000000</td>
    <td>0x0000000n</td>
  </tr>
</table>

#### Messaging from the IVI to the app

##### Success message: IVI sends vehile type info

If IVI can share vehicle type info, it will send the following protocol message.

<table width="100%">
  <tr>
    <th>Version</th>
    <th>E</th>
    <th>Frame Type</th>
    <th>Service Type</th>
    <th>Frame Info</th>
    <th>Session Id</th>
    <th>Data Size</th>
    <th>Message ID</th>
  </tr>
  <tr>
    <td>5.x</td>
    <td>no</td>
    <td>Control</td>
    <td>Control</td>
    <td>Get Vehicle Type ACK</td>
    <td>Assigned Session</td>
    <td>BSON object Size</td>
    <td>n</td>
  </tr>
  <tr>
    <td>0b0101</td>
    <td>0b0</td>
    <td>0b000</td>
    <td>0x00</td>
    <td>0x0B</td>
    <td>0x01</td>
    <td>0x00000XXX</td>
    <td>0x0000000n</td>
  </tr>
</table>

The BSON payload of this message will have the following info.

| Tag Name| Type | Description |
|------------|------|-------------|
|make|String| Vehicle make |
|model|String| Vehicle model |
|model year|String| Vehicle model year |
|trim|String| Vehicle trim |
|systemSoftwareVersion|String| Vehicle system software version |
|systemHardwareVersion|String| Vehicle system hardware version |
|rpcSpecVersion|String| RPC message spec version |

##### Failure message: IVI does not sends vehile type info

If IVI can not share vehicle type info, it will send the following protocol message.

<table width="100%">
  <tr>
    <th>Version</th>
    <th>E</th>
    <th>Frame Type</th>
    <th>Service Type</th>
    <th>Frame Info</th>
    <th>Session Id</th>
    <th>Data Size</th>
    <th>Message ID</th>
  </tr>
  <tr>
    <td>5.x</td>
    <td>no</td>
    <td>Control</td>
    <td>Control</td>
    <td>Get Vehicle Type NACK</td>
    <td>Assigned Session</td>
    <td>0</td>
    <td>n</td>
  </tr>
  <tr>
    <td>0b0101</td>
    <td>0b0</td>
    <td>0b000</td>
    <td>0x00</td>
    <td>0x0C</td>
    <td>0x01</td>
    <td>0x00000000</td>
    <td>0x0000000n</td>
  </tr>
</table>

### Android Proxy changes

The android proxy will need to implement the above protocol changes. In addition to implementing a protocol message, the proxy will need the additional implementation to propagate vehicle type info to the application layer.

#### Defining resource file for supported vehicle type

1. The mobile apps can define an XML for supported vehicles in resources of the project. The XML resource file can be called as `supported_vehicle_type.xml`.
2. The structure of the resource file can be as follows.

```xml
<?xml version="1.0" encoding="utf-8"?>
<resource>
    <vehicle-type
        make="Ford"
        model="Mustang"
        modelYear="2019"
        trim="GT"/>
</resource>
```
3. If an app defines a `vehicle-type` element, then it should always have a `make` attribute, all other attributes are optional. However, if the app developers want to use `model year` or `trim`, they should define `make` and `model` attributes as well. The proxy will check only the defined attributes. The below example shows a valid vehicle type resource file.

```xml
<?xml version="1.0" encoding="utf-8"?>
<resource>
<!-- Vehicle filter for vehicle make-->
    <vehicle-type
        make="Ford"/>
</resource>
```

```xml
<?xml version="1.0" encoding="utf-8"?>
<resource>
<!-- Vehicle filter for vehicle make and model-->
    <vehicle-type
        make="Ford"
        model="Mustang"/>
</resource>
```
```xml
<?xml version="1.0" encoding="utf-8"?>
<resource>
<!-- Vehicle filter for vehicle make, model and model year-->
    <vehicle-type
        make="Ford"
        model="Mustang"
        modelYear="2019"/>
</resource>
```
```xml
<?xml version="1.0" encoding="utf-8"?>
<resource>
<!-- Vehicle filter for vehicle make, model and trim-->
    <vehicle-type
        make="Ford"
        model="Mustang"
        trim="GT"/>
</resource>
```
```xml
<?xml version="1.0" encoding="utf-8"?>
<resource>
<!-- Vehicle filter for vehicle make-->
    <vehicle-type
        make="Ford"/>
    <vehicle-type
        make="OEM1"/>
    <vehicle-type
        make="OEM2"/>
</resource>
```
4. If the supported vehicle type list is not defined, the proxy can start `SDL router service` for all SDL enabled IVI system.

#### Meta-data for SDL router service

1. This resource file needs to be referenced in the manifest file of the project as `meta-data` for `Sdl router service`.
2. When the proxy receives `Get vehicle type ACK`, it will check if the vehicle type information is defined in the provided supported vehicle type list.
3. If the vehicle filter is not defined, the proxy can skip the check. In this case, the SDL router service is supported for all SDL enabled system.

#### Determine Vehicle type info

1. In the current implementation, all SDL apps need to start version negotiations and register themselves on SDL enabled system. This proposal recommends starting RPC service by the SDL router service to get vehicle type information from SDL enabled IVI system before notifying clients about SDL connection.
2. If the protocol version supports `Get vehicle type`, SDL router service will send the `Get vehicle type` protocol message.
3. If the SDL router service supports the connected IVI system, then the SDL router service will notify the client and provide vehicle type information. The router service will also transfer RPC session information to application hosting router service, since, every app is responsible for version negotiations and starting RPC session, the host application will use the same session information to communicate further with the SDL system. 
4. If the vehicle type is not supported by the SDL router service, the proxy will deploy the next router service. The exclusive apps will not register on the SDL enabled system.
5. The proxy determines appropriate router service to deploy based on vehicle type information received in `Get vehicle type ACK` protocol message. The proxy will check the metadata of the supported vehicle type list to determine the next router service to deploy. The deployed router service will also receive vehicle type information.
6. The next router service deployed will not start the RPC session if vehicle type information is available. It will forward vehicle type info to its clients.
7. It is necessary to check support for `Get vehicle type` protocol message and vehicle type info before notifying the client with SDL enabled callback. If clients are informed before checking the mentioned info, the exclusive apps could end up registering on an unintended SDL enabled IVI system. 
8. If the `Get vehicle type` message is not supported by the protocol version, the exclusive apps will try deploying the next router service. The exclusive apps will host router service only if there are no SDL app available on the users' device to host router service. The exclusive apps, in this case, will rely on vehicle type info received in the Register App interface response. In such a case, if vehicle type is not supported, the exclusive apps will be allowed to unregister apps from the SDL system and stop SDL router service.
9. If `Get vehicle type` message response is NACK, the exclusive apps will not register on SDL system.

![Sequence Diagram](../assets/proposals/NNNN-vehicle-type-filter/android.png) 

### iOS Proxy changes

The iOS proxy will need to implement the above-mentioned protocol changes. In addition to implementing a protocol message, the proxy will need the additional implementation to propagate vehicle type info to the application layer.


#### Defining supported vehicle type in Info.plist

1. The supported vehicle list can be defined in Info.plist as below. All the attributes in this list are optional, however, if the app includes `SDLSupportedVehicleTypes` in Info.plist, at least one array element with one key-value in the dictionary should be defined.
2. If an app defines an `SDLSupportedVehicleTypes` key, then it should always have `make` key-value pair in dictionary. All other attributes are optional if `make` is defined. However, if the app developers want to use `model year` or `trim`, they should define `make` and `model` key-value pairs as well. The proxy will check only the defined attributes.
The below example shows a valid vehicle type filters.

```xml
<key>SDLSupportedVehicleTypes</key>
    <array>
        <dict>
            <key>make</key>
            <string>Ford</string>
            <key>model</key>
            <string>Mustang</string>
            <key>modelYear</key>
            <string>2019</string>
            <key>trim</key>
            <string>GT</string>
        </dict>
        <dict>
            <key>make</key>
            <string>OEM1</string>
            <key>model</key>
            <string>OEM model</string>
            <key>modelYear</key>
            <string>2019</string>
            <key>trim</key>
            <string>trim info</string>
        </dict>
    </array>
```
```xml
<key>SDLSupportedVehicleTypes</key>
    <array>
        <dict>
            <key>make</key>
            <string>Ford</string>
            <key>model</key>
            <string>Mustang</string>
        </dict>
    </array>
```
```xml
<key>SDLSupportedVehicleTypes</key>
    <array>
        <dict>
            <key>make</key>
            <string>Ford</string>
            <key>model</key>
            <string>Mustang</string>
            <key>modelYear</key>
            <string>2019</string>
        </dict>
        <dict>
            <key>make</key>
            <string>OEM1</string>
            <key>model</key>
            <string>OEM model</string>
            <key>modelYear</key>
            <string>2019</string>
        </dict>
    </array>
```

```xml
<key>SDLSupportedVehicleTypes</key>
    <array>
        <dict>
            <key>make</key>
            <string>Ford</string>
            <key>model</key>
            <string>Mustang</string>
            <key>trim</key>
            <string>GT</string>
        </dict>
        <dict>
            <key>make</key>
            <string>OEM1</string>
            <key>model</key>
            <string>OEM model</string>
            <key>trim</key>
            <string>trim info</string>
        </dict>
    </array>
```
```xml
<key>SDLSupportedVehicleTypes</key>
    <array>
        <dict>
            <key>make</key>
            <string>Ford</string>
        </dict>
        <dict>
            <key>make</key>
            <string>OEM1</string>
        </dict>
    </array>
```
#### Determine Vehicle type info

1. After version negotiations and starting RPC service, the proxy should check if `Get vehicle type` is supported by the SDL enabled IVI system.
2. If the protocol version supports `Get vehicle type`, the proxy will send the `Get vehicle type` protocol message.
3. On receiving vehicle type information, proxy will check `SDLSupportedVehicleTypes` keys to check supported vehicle type.
4. If the vehicle type is supported, the proxy should also notify the app about the connected vehicle type so that the app can configure SDL as required. The iOS proxy can implement `OnSDLEnabled` notification similar to that of an android proxy to notify the app about SDL connection with the supported vehicle. The app can provide life cycle configuration to the proxy on receiving `OnSDLEnabled` notification. 
5. If the proxy determines from `Get vehicle type` ACK that the vehicle type is not supported, the proxy will end the RPC session. The application layer will not be notified about the vehicle type.
6. If the protocol version does not support the `Get vehicle type` protocol message, the SDL proxy will continue with the app registration and it will rely on vehicle type information received in Register App interface response. If vehicle type is not supported, the exclusive apps will be allowed to unregister from SDL enabled system.
7. If `Get vehicle type` message response is NACK, the proxy will end RPC session and the app will not be registered on the SDL system.

![Sequence Diagram](../assets/proposals/NNNN-vehicle-type-filter/ios.png)

## Potential downsides

The Android SDL router service after transport connection needs to start RPC service. If the SDL router service does not start RPC service and relies on the client to send the `Get vehicle type` protocol message, the connected client would start another foreground service. This would force the connected app to show two notifications to users while determining vehicle type information and will need to terminate services if the app does not support SDL enabled IVI system. 

## Impact on existing code

Above mentioned changes need to be implemented in SDL Core, the android proxy and iOS proxy.

## Alternatives considered

### GetVehicleType as an RPC instead of Protocol message
1. As per current implementation, the RAI is the first RPC sent to SDL enabled IVI system and the vehicle type information is available to the app in its response. 
2. If `GetVehicleType` is an RPC, this behavior needs to be changed. The app should be able to use `GetVehicleType` RPC before `RegisterAppInterface` RPC.
3. Since the RPC message version is sent to the app in `RAI response`, the app, when connected to older SDL enabled IVI, would not know if `GetVehicleType` RPC is supported or not.
4. If `GetVehicleType` is an RPC and it sent first, the app would need to depend on timeout to know the support for `GetVehicleType` RPC when connected to older SDL enable IVI system. This behavior would add delays in app registration on the SDL system.
5. If `GetVehicleType` is an RPC, the exclusive apps could potentially show two notifications described above for Android apps before terminating them. Terminating router service hosted by exclusive apps will unregister all apps using it.

### Soft-Registrations of an App
1. The app sends the RAI Request and receives its Response.
2. The HMI does not register the app until the app completes its validation.
3. On completing validation, the app sends some indication for hard app registration. The app will be shown on SDL to enable the IVI system. The type of notification to the SDL enabled IVI system needs to be defined.
4. This solution would solve the proprietary app registrations. In this case, as well, the exclusive apps could potentially show two notifications described above for Android apps before terminating them. Terminating router service hosted by exclusive apps will unregister all apps using it.

### Creating Generic SDL App to create SDL router service

1. The user will need to download an additional app for the SDL connection.
2. This would affect App discoverability, as the users would potentially never know about such app and never find apps in SDL enabled system. 

### App sending list of supported vehicle types in Register App Interface

1. This solution would solve the proprietary app registrations.
2. The HMI does not register the app until the app completes its validation.
3. The exclusive apps could potentially show two notifications described above for Android apps before terminating them. 
4. If the vehicle type is not supported and the app needs to deploy another router service it would not know supported SDL router service for the SDL system.
5. In this case, as well, the exclusive apps could potentially show two notifications described above for Android apps before terminating them. Terminating router service hosted by exclusive apps will unregister all apps using it.