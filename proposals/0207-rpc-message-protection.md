# RPC message protection

* Proposal: [SDL-0207](0207-rpc-message-protection.md)
* Author: [Zhimin Yang](https://github.com/yang1070)
* Status: **Returned for Revisions**
* Impacted Platforms: [Core / Android/ iOS / RPC / SDL Policy server]

## Introduction
This proposal proposes a design to protect (enable encryption for) RPC messages transmitted between a mobile application and the SDL.

## Motivation
Security is good but it has costs. Each OEM can evaluate the risks and protect certain RPC messages. This means the application and SDL transmit encrypted messages in a protected RPC service between an authenticated app and a vehicle head unit.

Note: How to authenticate a mobile app and how to set up a protected SDL service is out of the scope of this proposal.

SDL supports this by integrating a security library in the mobile app. This proposal provides a solution to protect certain SDL RPC messages. This includes-which RPCs need protection, when to start a protected SDL RPC service and what SDL shall do with these RPCs with this protected service.


## Proposed solution

RPCs that need protection and RPCs that do not need protection share the same RPC service 7 with encryption enabled. 

### Background

SDL can require a service must be protected in the `smartdevicelink.ini` file by a configuration `ForceProtectedService`. It can validate and deny the start service request with encryption bit not set if the service number is listed under `ForceProtectedService`. However, it cannot start a protected service by itself. The application side (the mobile proxy) shall initiate a protected service by sending a `StartService` request with encryption bit set.

Currently, SDL Android API `SdlProxyBase.startProtectedRPCService` supports start a protected RPC service. SDL can keep the existing un-encrypted service open and running at the same time of starting enable the encrypted service. It does not need to stop the RPC service before `startProtectedRPCService`. SDL Android also supports setting a RPC message as encrypted or unencrypted with API `RPCStruct.setPayloadProtected(Boolean)`. Without any mobile proxy and SDL core change, android mobile apps and the SDL can send/receive both encrypted and unencrypted messages (include requests/responses/notifications) in the same protected RPC service. 

It is an undocumented implementation that SDL protocol allows sending a `StartService` control message with encryption bit set or not set on a service that has started already. We propose to update the protocol spec that sending a `StartService` for a service that has already been started but now with the encryption bit set should work.


### Mobile app change
A mobile application only shall adopt a security library from an OEM if it uses any RPC that requires encryption in the policy for that OEM. The mobile proxy and the security library shall take care of the encryption and decryption. There shall be no other burden of work for app developers.


### Mobile API change
We add a new Boolean parameter to the existing `PermissionItem` data type. A list of `PermissionItem` will be received by the app via `OnPermissionsChange` notification, so that the app side knows which RPCs need protection. Please note, to follow the naming conventions, we use `needProtection` in RPC messages and use `need_protection` in policy configuration. However, they shall refer to the same thing. 

```xml
<struct name="PermissionItem" since="2.0">
    <param name="rpcName" type="String" maxlength="100" mandatory="true">
        <description>Name of the individual RPC in the policy table.</description>
    </param>
    <param name="hmiPermissions" type="HMIPermissions"  mandatory="true"/>
    <param name="parameterPermissions" type="ParameterPermissions"  mandatory="true"/>
+   <param name="needProtection" type="Boolean"  mandatory="false" since="5.1"/>
</struct>
```

We also add a new result code. SDL sends this code to a mobile app when it receives an un-encrypted PRC request message that needs protection.
```xml
<enum name="Result" internal_scope="base" since="1.0">
...
    <element name="ENCRYPTION_NEEDED" since="5.1">
        <description>SDL receives an un-encrypted PRC request that needs protection. </description>
    </element>
</enum>
```

In this proposal, we say a RPC message needs encryption/protection if the RPC has `needProtection` with value `true` in the `PermissionItem`. We say a RPC message does not need encryption/protection if the RPC has `needProtection` with value `false` or the `needProtection` does not exist in the `PermissionItem`. 


Here we list existing related RPC and data types for completeness of understanding.
```xml
<function name="OnPermissionsChange" functionID="OnPermissionsChangeID" messagetype="notification" since="2.0">
    <description>Provides update to app of which policy-table-enabled functions are available</description>
    <param name="permissionItem" type="PermissionItem" minsize="0" maxsize="500" array="true" mandatory="true">
        <description>Change in permissions for a given set of RPCs</description>
    </param>
</function>

<struct name="HMIPermissions" since="2.0">
    <param name="allowed" type="HMILevel" minsize="0" maxsize="100" array="true" mandatory="true">
        <description>A set of all HMI levels that are permitted for this given RPC.</description>
    </param>
    <param name="userDisallowed" type="HMILevel" minsize="0" maxsize="100" array="true" mandatory="true">
        <description>A set of all HMI levels that are prohibited for this given RPC.</description>
    </param>
</struct>

<struct name="ParameterPermissions" since="2.0">
    <param name="allowed" type="String" minsize="0" maxsize="100" maxlength = "100" array="true" mandatory="true">
        <description>A set of all parameters that are permitted for this given RPC.</description>
    </param>
    <param name="userDisallowed" type="String" minsize="0" maxsize="100" maxlength = "100" array="true" mandatory="true">
        <description>A set of all parameters that are prohibited for this given RPC.</description>
    </param>
</struct>
```

### Mobile proxy change (Android and iOS)
SDL proxy shall support sending a PRC with both encrypted and unencrypted format as it currently does if the RPC service has encryption enabled. 

SDL proxy may start service seven with encryption enabled in several situations. 
- 1. Before mobile proxy sends the first RPC message that need encryption. This works similar to delay loading of a dynamic library. Mobile proxy enables encryption for RPC service only when it really needs encryption. This is the latest time. This option may cause a delay. Because the channel is not ready, it must wait the encryption gets enabled in order to send an encrypted message.
- 2. After mobile proxy receives an `OnPermissionsChange` notification and there is at least one RPC that needs encryption. In this case, proxy enables encryption for any potential usage. This is the earliest time that the app/proxy knows it may need encryption.
- 3. Sometime in between. For example, when the driver activates the app and HMI brings the app to foreground. Because it may take sometime to get RPC service encryption enabled for the first time, and there is no overhead after that, we recommend the proxy enable encryption after the app is activated (SDL proxy receives `OnHMIStatus` notification with `hmiLevel=FULL\LIMITED\BACKGROUND`, but not `NONE`) and there is at least one RPC that needs protection.

When the mobile proxy receives `OnPermissionsChange` message, it shall remember the list of RPCs that need encryption for later use.

Mobile proxy shall only send encrypted RPC requests and receive encrypted RPC responses and notifications in an encryption enabled service if the corresponding RPC needs encryption.

Mobile proxy shall send/receive encrypted RPC requests/responses if the app chooses to `setPayloadProtected(true)` in an encryption enabled service even if the corresponding RPC does not need encryption.

### Sample security library for Android
Although how to integrating a security library in the mobile apps and how to set up a protected SDL service is out of the scope of this proposal, we will provide a sample android security library to support testing the implementation of the proposal.

### SDL core change

#### Proposed solution
Before the encryption of RPC service 7 is enabled, SDL rejects any RPC request with result code `ENCRYPTION_NEEDED` if the RPC needs protection. (Please see policy updates for which RPC needs protection.) SDL continues processing a RPC request if the RPC does not need protection. SDL sends a notification only if the notification RPC does not need protection.

After the encryption of RPC service 7 is enabled, SDL rejects any unencrypted RPC request with result code `ENCRYPTION_NEEDED` with unencrypted response if the RPC needs protection. SDL continues processing an unencrypted RPC request if the RPC does not need protection and responds with unencrypted response. SDL continues processing an encrypted RPC request if the RPC needs protection and responds with encrypted response. SDL sends an unencrypted notification if the RPC does not need protection. SDL sends an encrypted notification if the RPC needs protection. In addition, SDL shall continue processing an encrypted RPC request if the RPC does not need protection and responds with encrypted response.


#### Alternative solution:
- We require all applications to be authenticated and all RPC messages encrypted (i.e. SDL requires encryption for RPC service 7, apps and SDL always sends and receives encrypted RPC messages. This can be done in smartdevicelink.ini file to configure service 7 must be protected.)

- We create a new protected RPC service 12, which is similar to the existing service 10 and service 11. We require all RPC messages that need protection (include requests, responses and notifications) must be transmitted via this new SDL service.


### Policy updates:
- Proposed solution: add a Boolean flag `need_protection` to each RPC to indicate whether the RPC needs protection or not. For example,  
```json
"RemoteControl": {
    "rpcs": {
        "GetInteriorVehicleData": {
            "hmi_levels": ["BACKGROUND", "FULL", "LIMITED"],
            "need_protection" : true
        },
        "SetInteriorVehicleData": {
            "hmi_levels": ["BACKGROUND", "FULL", "LIMITED"],
            "need_protection" : true
        },
        ...,
        "OnRCStatus": {
            "hmi_levels": ["BACKGROUND", "FULL", "LIMITED", "NONE"],
            "need_protection" : false
        }
    }
}
```


- Alternative solution: add a Boolean flag `need_protection` to a function group to indicate whether all the RPCs within this function group need protection not. For example, 
```json
"RemoteControl": {
    "rpcs": {
        "GetInteriorVehicleData": {
            "hmi_levels": ["BACKGROUND", "FULL", "LIMITED"]
        },
        "GetInteriorVehicleData": {
            "hmi_levels": ["BACKGROUND", "FULL", "LIMITED"]
        },
        ...
    },
    "need_protection" : true
}
```
In the alternative solution, even the flag is defined in the function group level, SDL still need to translate it to each RPC because there is no concept of `function group` in `OnPermissionsChange` RPC. We lose the flexibility of configuring some RPCs need protection and some RPCs does not need protection in the same function group. Therefore, we choose the proposed solution. 

If `need_protection`=`true` in policy, the corresponding RPC must be sent/received in an encryption enabled SDL service. That means the app has been authenticated via TLS/DTLS handshake and RPC request and response messages are encrypted. If `need_protection`=`false` or `need_protection` does not exist for the RPC(s) in policy, the corresponding RPC messages shall not be encrypted, and can be transmitted in both encryption enabled and disabled SDL services.

Multiple function groups can include the same RPC; each group has its own flag for the RPC. If there are two or more instances of the same RPC in different groups in the policy for an app, one has `need_protection`=`true` and the others have `need_protection`=`false`, then the RPC shall have `needProtection`=`true` in the `OnPermissionsChange` for the app.

### SDL server updates:
The SDL server needs to support the new parameter in the policy table. However, defining which RPCs require encryption on a per-app basis would create a lot of Policy Server overhead about OEM app administration (UI/UX), database schema/storage, and policy table generation and migration. The SDL Policy Server code base will not be receiving this feature in full. 
Instead, the SDL Policy Server shall give OEMs the option to select which RPCs they need to be encrypted that will affect **ALL** of their partner apps. An OEM need to make their own changes if they want to support configuration on a per-app basis.


## Potential downsides
The proxy and SDL can send the following RPC messages before the encryption of RPC service 7 is enabled. 
- `RegisterAppInterface`
- `SystemRequest`
- `OnPermissionsChange` 
- `OnSystemRequest`
- `PutFile`

There are two possible methods to deal with it. In the first method, some special logic (exceptions) is needed. The SDL core and mobile proxy can send and receive the above RPC messages un-encrypted if the encryption of RPC service is not enabled even those RPCs have `need_protection`=`true`. Once the encryption of RPC service is enabled, the SDL core and mobile proxy shall send encrypted messages. In the second method, these RPCs shall not be listed as `need_protection`=`true` in a policy configuration. For the simplicity, we recommend the second method. 

## Impact on existing code

As it is analyzed in the section of `Proposed solution`, the following components need update: Core, Mobile_API.xml, Android and iOS proxy, Policy server.

## Alternatives considered

Instead of adding a new `need_protection` item for each RPC in function groups, we add a parameter `need_protection` to each app in policy configuration, and add a parameter `needProtection` for the whole app in RPC `OnPermissionsChange`. Therefore, instead of a group of RPCs need encryption, all RPCs of an app need encryption. The workflow is as the following. 

An OEM can choose to require either all RPCs of the app or none RPCs of the app to be encryption enabled. This is accomplished by configuring the policy of an application. When the app registers with the SDL for the first time, SDL triggers a policy update. SDL gets the configuration from the updated policy and sends an `OnPermissionsChange` notification with `needProtection=true` to the app. When the mobile proxy within the app receives the message, it sends `StartService` with encryption bit set to trigger the process of enabling encryption of the existing RPC service. Once the process is done and the encryption is enabled, all RPC messages shall be encrypted. The RPC messages sent before the encryption is enabled shall remain un-encrypted. SDL shall reject all un-encrypted messages with result code `ENCRYPTION_NEEDED` if the encryption of RPC service has been enabled. SDL shall reject most un-encrypted messages (except the RPCs that are sent before `OnPermissionsChange`) with result code `ENCRYPTION_NEEDED` if the encryption of RPC service has not been enabled to prevent version rollback attack or downgrade attack. Otherwise, a malicious app may never start enabling the encryption of RPC service.

```xml
<function name="OnPermissionsChange" functionID="OnPermissionsChangeID" messagetype="notification" since="2.0">
    <description>Provides update to app of which policy-table-enabled functions are available</description>
    <param name="permissionItem" type="PermissionItem" minsize="0" maxsize="500" array="true" mandatory="true">
        <description>Change in permissions for a given set of RPCs</description>
    </param>
+   <param name="needProtection" type="Boolean"  mandatory="false" since="5.1"/>
</function>
```

```json
"app_policies": {
    "default": {
+     "need_protection": false,
      "keep_context": false,
      "steal_focus": false,
      "priority": "NONE",
      "default_hmi": "NONE",
      "groups": [
        "Base-4"
      ]
    },
    "appid_123456789": {
+     "need_protection": true,
      "keep_context": false,
      "steal_focus": true,
      "priority": "NONE",
      "default_hmi": "NONE",
      "groups": [
        "Base-4", "RemoteControl"
      ]
    },
    ...
}
```

Similar to the WWW is moving from HTTP to HTTPS, we believe the trend for the SDL is to move from un-encrypted messages to all messages encrypted in the future. However, not all existing head unit hardware are capable of encrypting all RPC messages with an acceptable performance. Updating the hardware may take a long time and with a high cost. At the same time, we do have a need to encrypt remote control related RPCs that have a high risk for the new apps on the existing hardware. That is the main reason we prefer the solution of encrypting select RPCs to the solution of encrypting all RPCs.

