# RPC message protection

* Proposal: [SDL-0207](0207-rpc-message-protection.md)
* Author: [Zhimin Yang](https://github.com/yang1070)
* Status: **Deferred**
* Impacted Platforms: [Core / Android/ iOS / RPC / SDL Policy server]

## Introduction
This proposal proposes a design to protect (enable encryption for) RPC messages transmitted between a mobile application and the SDL.

## Motivation
Security is good but it has costs. Each OEM can evaluate the risks and protect certain RPC messages. This means the application and SDL transmit encrypted messages in a protected RPC service between an authenticated app and a vehicle head unit.

Note: How to authenticate a mobile app and how to set up a protected SDL service is out of the scope of this proposal.

SDL supports this by integrating a security library in the mobile app. This proposal provides a solution to protect certain SDL RPC messages. This includes-which RPCs need protection, when to start a protected SDL RPC service and what SDL shall do with these RPCs with this protected service.


## Proposed solution

Reuse the current framework of secure video/audio services, extend that to RPC service. RPCs that need protection and RPCs that do not need protection share the same RPC service 7 with encryption enabled. 

### Background

SDL can require a service must be protected in the `smartdevicelink.ini` file by a configuration `ForceProtectedService`. It can validate and deny the start service request with encryption bit not set if the service number is listed under `ForceProtectedService`. However, it cannot start a protected service by itself. The application side (the mobile proxy) shall initiate a protected service by sending a `StartService` request with encryption bit set.

Currently, SDL Android API `SdlProxyBase.startProtectedRPCService` supports starting a protected RPC service. SDL can keep the existing un-encrypted service open and running at the same time as starting the enable of encrypted service. It does not need to stop the RPC service before `startProtectedRPCService`. 

SDL Android also supports setting an RPC message as encrypted or unencrypted with API `RPCStruct.setPayloadProtected(Boolean)`. Without any mobile proxy and SDL core change, android mobile apps and SDL can send/receive both encrypted and unencrypted messages (include requests/responses/notifications) in the same protected RPC service. 


It is an undocumented implementation that the SDL protocol allows sending a `StartService` control message with encryption bit set or not set on a service that has started already. This proposal is to update the protocol spec to allow sending a `StartService` for a service that has already been started, but now the encryption bit set should work.


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
- 1. Before mobile proxy sends the first RPC message that needs encryption. This works similar to delaying the loading of a dynamic library. Mobile proxy enables encryption for the RPC service only when it really needs encryption. This is the latest time. This option may cause a delay. Since the channel is not ready, it must wait until the encryption gets enabled in order to send an encrypted message.
- 2. After mobile proxy receives an `OnPermissionsChange` notification and there is at least one RPC that needs encryption. In this case, proxy enables encryption for any potential usage. This is the earliest time that the app/proxy knows it may need encryption.
- 3. Sometime in between. For example, when the driver activates the app and HMI brings the app to foreground. Because it may take some time to get RPC service encryption enabled for the first time, and there is no overhead after that, we recommend the proxy enable encryption after the app is activated (SDL proxy receives `OnHMIStatus` notification with `hmiLevel=FULL\LIMITED\BACKGROUND`, but not `NONE`) and there is at least one RPC that needs protection.

When the mobile proxy receives `OnPermissionsChange` message, it shall remember the list of RPCs that need encryption for later use.

Mobile proxy shall only send encrypted RPC requests and receive encrypted RPC responses and notifications in an encryption enabled service if the corresponding RPC needs encryption.

Mobile proxy shall send/receive encrypted RPC requests/responses if the app chooses to `setPayloadProtected(true)` in an encryption enabled service even if the corresponding RPC does not need encryption.


### SDL core change

#### Proposed solution
Before the encryption of RPC service 7 is enabled (encryption is not available), SDL Core rejects any RPC request with result code `ENCRYPTION_NEEDED` if the RPC needs protection. (Please see policy updates for which RPC needs protection.) SDL Core continues processing a RPC request if the RPC does not need protection. SDL Core sends a notification only if the notification RPC does not need protection.

After the encryption of RPC service 7 is enabled (encryption is available), SDL Core rejects any unencrypted RPC request with result code `ENCRYPTION_NEEDED` with the unencrypted response if the RPC needs protection. SDL Core continues processing an unencrypted RPC request if the RPC does not need protection and responds with an unencrypted response. SDL Core continues processing an encrypted RPC request if the RPC needs protection and responds with an encrypted response. SDL Core sends an unencrypted notification if the RPC does not need protection. SDL Core sends an encrypted notification if the RPC needs protection. In addition, SDL Core shall continue processing an encrypted RPC request if the RPC does not need protection and responds with an encrypted response.


#### Alternative solution:
- All applications are required to be authenticated and all RPC messages encrypted (i.e. SDL requires encryption for RPC service 7, apps, and SDL always sends and receives encrypted RPC messages. This can be done in smartdevicelink.ini file to configure service 7 to require protection and encryption.)

- A new protected RPC service 12 is created, which is similar to the existing service 10 and service 11. The RPC service 12 would require that all RPC messages that need protection (include requests, responses and notifications) must be transmitted via this new SDL service.


### Policy updates:

#### Proposed solution
Add an optional Boolean flag `need_protection` to a function group to indicate whether all the RPCs within this function group need protection not. For example, 

```json
"RemoteControl": {
+   "need_protection" : true,
    "rpcs": {
        "GetInteriorVehicleData": {
            "hmi_levels": ["BACKGROUND", "FULL", "LIMITED"]
        },
        "GetInteriorVehicleData": {
            "hmi_levels": ["BACKGROUND", "FULL", "LIMITED"]
        },
        ...
    }
}
```

Note that even the flag is defined in the function group level in the Policy Table, SDL core still needs to cascade this flag from the function group level to each RPC because there is no concept of `function group` in `OnPermissionsChange` notification.


If `need_protection`=`true` for a function group in the Policy Table, all the RPCs within that function group must be sent/received in an encryption enabled SDL service. This means the app has been authenticated via TLS handshake and RPC request and response messages are encrypted. If `need_protection`=`false` or `need_protection` does not exist for a function group in the Policy Table, the RPC messages of that function group shall not be encrypted and can be transmitted in both encryption enabled and disabled SDL services.

Multiple function groups can include the same RPC; each group has its own flag for the protection. If an app has access to multiple functional groups containing the same RPC and at least one of the groups requires encryption, then the RPC shall require encryption. Which means that SDL shall send an `OnPermissionsChange` to the app with `needProtection`=`true` for the RPC.

-  Alternative solution 1 : add a Boolean flag `need_protection` to each RPC to indicate whether the RPC needs protection or not. For example,  
```json
"RemoteControl": {
    "rpcs": {
        "GetInteriorVehicleData": {
            "hmi_levels": ["BACKGROUND", "FULL", "LIMITED"],
+           "need_protection" : true
        },
        "SetInteriorVehicleData": {
            "hmi_levels": ["BACKGROUND", "FULL", "LIMITED"],
+           "need_protection" : true
        },
        ...,
        "OnRCStatus": {
            "hmi_levels": ["BACKGROUND", "FULL", "LIMITED", "NONE"],
+           "need_protection" : false
        }
    }
}
```

In this alternative solution,  SDL has the flexibility of configuring the protection for some RPCs and also having some RPCs that do not need protection in the same function group. However, it will make policy table more complex and the payload size of policy table update larger.


-  Alternative solution 2 : add a Boolean flag `need_protection` to each app in the Policy Table configuration and add a parameter `needProtection` for the whole app in the RPC `OnPermissionsChange`. Therefore, instead of a group of RPCs needing encryption, all the RPCs of an app need encryption. The workflow is as follows:


An OEM can choose to require either all RPCs of the app or no RPCs of the app to be encryption enabled. This is accomplished by configuring the policy of an application. When the app registers with the SDL for the first time, SDL triggers a policy update. SDL gets the configuration from the updated policy and sends an `OnPermissionsChange` notification with `needProtection=true` to the app. When the mobile proxy within the app receives the message, it sends `StartService` with encryption bit set to trigger the process of enabling encryption of the existing RPC service. Once the process is done and the encryption is enabled, all RPC messages shall be encrypted. The RPC messages sent before the encryption is enabled shall remain un-encrypted. SDL shall reject all un-encrypted messages with result code `ENCRYPTION_NEEDED` if the encryption of RPC service has been enabled. SDL shall reject most un-encrypted messages (except the RPCs that are sent before `OnPermissionsChange`) with result code `ENCRYPTION_NEEDED` if the encryption of RPC service has not been enabled to prevent version rollback attack or downgrade attack. Otherwise, a malicious app may never start enabling the encryption of RPC service.

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

In this alternative solution, OEMs are forced to choose either no encryption at all or almost all messages get encrypted. OEMs lose the flexibility to configure which function group of RPCs need encryption. Not all OEMs are ready to encrypt all RPC messages for a variety of reasons. At the same time, there is a need to encrypt remote control related RPCs that have a high risk for the new apps on the existing hardware. This proposal proposes the solution of encrypting select RPCs rather than encrypting all RPCs.

### SDL server updates:
The SDL server may support the new parameter in the policy table. 


## Potential downsides
Mobile Proxy and SDL Core can send the following RPC messages before the encryption of RPC service 7 is enabled. 
- `RegisterAppInterface`
- `SystemRequest`
- `OnPermissionsChange` 
- `OnSystemRequest`
- `PutFile`

There are two possible methods to deal with this downside:

In the first method, some special logic (exception) is needed. SDL core and mobile proxy can send and receive the above RPC messages un-encrypted if the encryption of the RPC service is not enabled regardless those RPCs have `need_protection`=`true` or not. Once the encryption of RPC service is enabled, SDL core and mobile proxy shall send encrypted messages if those RPCs have `need_protection`=`true`. 

In the second method, these RPCs shall not be listed in a function group with `need_protection`=`true` in a Policy Table configuration. This proposal recommends the first method (exception list method).


Similar to the WWW moving from HTTP to HTTPS, the trend for SDL should be to move from un-encrypted messages to all messages encrypted in the future. A long term solution which encrypts all messages including RegisterAppInterface, SystemRequest, OnSystemRequest and OnPermissionsChange will be developed in a separate proposal.


## Impact on existing code

As it is analyzed in the section of `Proposed solution`, the following components need to be updated: Core, Mobile_API.xml, Android and iOS proxy, Policy server.

## Alternatives considered
The alternatives have been discussed in the above sections.




