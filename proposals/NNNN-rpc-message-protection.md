# RPC message protection

* Proposal: [SDL-NNNN](NNNN-rpc-message-protection.md)
* Author: [Zhimin Yang](https://github.com/yang1070)
* Status: **Awaiting review**
* Impacted Platforms: [Core / Android/ iOS / RPC / SDL Policy server]

## Introduction
This proposal proposes a design to protect (enable encryption for) RPC messages transmitted between a mobile application and the SDL.

## Motivation
Security is good but it has cost. Each OEM can evaluate the risks and require certain RPC messages must be protected, which means the messages are encrypted and transmitted in a protected SDL service between an authenticated app and a vehicle head unit. How to authenticate a mobile app and how to set up a protected SDL service is out of the scope of this proposal. SDL supports it by integrating a security library in the mobile app. This proposal provides a solution to protect certain SDL RPC messages. It includes which RPCs need protection, when to start a protected SDL RPC service and what SDL shall do with these RPCs with the protected service.

## Proposed solution

RPCs that need protection and RPCs that do not need protection share the same RPC service 7 with encryption enabled. 

### Background

SDL can require a service must be protected in the `smartdevicelink.ini` file by a configuration `ForceProtectedService`. It can validate and deny the start service request. However, it cannot start a protected service by itself. The application side shall initiate a protected service.

Currently, SDL Android API `SdlProxyBase.startProtectedRPCService` supports start a protected RPC service. SDL can keep the existing un-encrypted service open and running at the same time of starting enable the encrypted service. It does not need to stop the RPC service before `startProtectedRPCService`. SDL Android also supports setting a RPC message as encrypted or unencrypted with API `RPCStruct.setPayloadProtected(Boolean)`. Without any mobile proxy and SDL core change, android mobile apps and the SDL can send/receive both encrypted and unencrypted messages (include requests/responses/notifications) in the same protected RPC service.


### Mobile app change
A mobile application shall start/restart RPC service 7 with encryption enabled (by app itself or by SDL proxy, either at certain stage after app registration or when the app is activated in HMI by the driver or just before sending the first RPC message that needs encryption). 


### Mobile API change
We add a new Boolean parameter to the existing `PermissionItem` data type. A list of `PermissionItem` will be received by the app via `OnPermissionsChange` notification, so that the app side knows which RPCs need protection.

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

We also add a new result code. SDL sends this code to a mobile app when it receives a un-encrypted PRC request message that needs protection.
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

SDL proxy may restart service 7 with encryption enabled in several situations. 
-	1. Before mobile proxy sends the first RPC message that need encryption. This works like delay loading of a dynamic library. Only when encryption is truly needed, proxy enables encryption for RPC service.  This is the latest time. 
-	2. After mobile proxy receives an `OnPermissionsChange` notification and there is at least one RPC needs encryption. In this case, proxy enables encryption for any potential usage. This is earliest time that the app/proxy knows it may need encryption. 
-	3. Sometime in between. For example, when the driver activates the app and HMI brings the app to foreground (SDL proxy receives `OnHMIStatus` notification with `hmiLevel=FULL`). Due to the fact that it may take a long time (up to a minute) to get RPC service enabled, and there is no overhead after that, we strongly recommend proxy enable encryption after the app get activated and there is at least one RPC need protection.


Mobile proxy shall only send encrypted RPC requests and receive encrypted RPC responses and notifications in an encryption enabled service if the corresponding RPC needs encryption.

Mobile proxy shall send/receive encrypted RPC requests/responses if the app chooses to `setPayloadProtected(true)` in an encryption enabled service even if the corresponding RPC does not need encryption.



### SDL core change

#### Proposed solution
Before the encryption of RPC service 7 is enabled, SDL rejects any RPC request with result code `ENCRYPTION_NEEDED` if the RPC needs protection. (Please see policy updates for which RPC needs protection.) SDL continues processing a RPC request if the RPC does not need protection. SDL sends a notification only if the notification RPC does not need protection.

After the encryption of RPC service 7 is enabled, SDL rejects any unencrypted RPC request with result code `ENCRYPTION_NEEDED` with unencrypted response if the RPC needs protection. SDL continues processing an unencrypted RPC request if the RPC does not need protection and responds with unencrypted response. SDL continues processing an encrypted RPC request if the RPC needs protection and responds with encrypted response. SDL sends an unencrypted notification if the RPC does not need protection. SDL sends an encrypted notification if the RPC needs protection. In addition, SDL shall continue processing an encrypted RPC request if the RPC does not need protection and responds with encrypted response.


#### Alternative solution:
- We require all applications to be authenticated and all RPC messages encrypted (i.e. SDL requires encryption for RPC service 7, apps and SDL always sends and receives encrypted RPC messages. This can be done in smartdevicelink.ini file to configure service 7 must be protected.)

- We create a new protected RPC service 12, which is similar to the existing service 10 and service 11. We require all RPC messages that need protection (include requests, responses and notifications) must be transmitted via this new SDL service.


### Policy updates:
- Proposed solution: add a Boolean flag `needProtection` to each RPC to indicate whether the RPC needs protection or not. For example,  
```json
"RemoteControl": {
    "rpcs": {
        "GetInteriorVehicleData": {
            "hmi_levels": ["BACKGROUND", "FULL", "LIMITED"],
            "needProtection" : true
        },
        "SetInteriorVehicleData": {
            "hmi_levels": ["BACKGROUND", "FULL", "LIMITED"],
            "needProtection" : true
        },
        ...,
        "OnRCStatus": {
            "hmi_levels": ["BACKGROUND", "FULL", "LIMITED", "NONE"],
            "needProtection" : false
        }
    }
}
```


- Alternative solution: add a Boolean flag `needProtection` to a function group to indicate whether all the RPCs within this function group need protection not. For example, 
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
    "needProtection" : true
}
```

If `needProtection`=`true` in policy, the corresponding RPC must be sent/received in an encryption enabled SDL service. That means the app has been authenticated via TLS/DTLS handshake and RPC request and response messages are encrypted. If `needProtection`=`false` or `needProtection` does not exist for the RPC(s) in policy, the corresponding RPC messages shall not be encrypted, and can be transmitted in both encryption enabled and disabled SDL services.

Multiple function groups can include the same RPC, each group has its own flag for the RPC. If there are two or more instances of the same RPC in different groups in the policy for an app, one has `needProtection`=`true` and the others have `needProtection`=`false`, then the RPC shall have `needProtection`=`true` for the app.

### SDL server updates:
SDL server need support the new parameter in the policy table.

## Potential downsides
The following RPC messages need to be sent before the encryption of RPC service 7 is enabled. 
- `RegisterAppInterface`
- `SystemRequest`
- `OnPermissionsChange` 
- `OnSystemRequest`

There are two possible methods to deal with it. In the first method, some special logic (exceptions) is needed. The SDL core and mobile proxy can send and receive the above RPC messages un-encrypted if the encryption of RPC service is not enabled even those RPCs have `needProtection`=`true`. Once the encryption of RPC service is enabled, the SDL core and mobile proxy shall send encrypted messages. In the second method, these RPCs shall not be listed as `needProtection`=`true` in a policy configuration. For the simplicity, we recommend the second method. 

## Impact on existing code

As it is analyzed in the section of `Proposed solution`, the following components need update: Core, Mobile_API.xml, Android and iOS proxy, Policy server.

## Alternatives considered


In addition to adding a new `needProtection` item for each RPC, we add the following changes.

- Add a new `protected` parameter to `ParameterPermissions` in mobile API.
- Add a new `protected_parameters` parameter to policy.
- Change the definition of RPC needs encryption/protection.

```xml
<struct name="ParameterPermissions" since="2.0">
    <param name="allowed" type="String" minsize="0" maxsize="100" maxlength = "100" array="true" mandatory="true">
        <description>A set of all parameters that are permitted for this given RPC.</description>
    </param>
    <param name="userDisallowed" type="String" minsize="0" maxsize="100" maxlength = "100" array="true" mandatory="true">
        <description>A set of all parameters that are prohibited for this given RPC.</description>
    </param>
+   <param name="protected" type="String" minsize="0" maxsize="100" maxlength = "100" array="true" mandatory="false" since="5.1">
+       <description>A set of all parameters that are permitted and need protection for this given RPC. It is a subset of allowed.</description>
+   </param>
</struct>
```

In this case, we say a RPC message needs encryption/protection if the RPC has `needProtection` with value `true` `or` the RPC message include any parameter listed in the `protected` parameters. We say a RPC message does not need encryption/protection if the RPC has `needProtection` with value `false` `and` the RPC message does not include any parameter in the `protected` array. 

```json
"Location-1": {
    "rpcs": {
        "GetVehicleData": {
            "hmi_levels": ["BACKGROUND", "FULL", "LIMITED"],
            "parameters": ["gps", "speed"],
            "protected_parameters": ["gps"],
            "needProtection" : false
        },
        ...
    }
}
```


```json
"VehicleInfo-3": {
    "user_consent_prompt": "VehicleInfo",
    "rpcs": {
        "GetVehicleData": {
        "hmi_levels": ["BACKGROUND", "FULL", "LIMITED"],
        "parameters": ["bodyInformation", "deviceStatus", "engineOilLife", "engineTorque", "externalTemperature", "turnSignal", "fuelLevel", "fuelLevel_State", "headLampStatus","instantFuelConsumption", "fuelRange", "odometer", "tirePressure", "vin", "wiperStatus"]
        ---note no "protected_parameters" here
        "needProtection" : true
        },
        ...
    }
}
```

SDL shall translate the parameters from `protected_parameters` in policy into `protected` array in `ParameterPermissions` within `OnPermissionsChange` message.

This allows policy to configure protected parameters and un-protected parameters in the same RPC within a group. This may not be necessary. Similar to the WWW is moving from HTTP to HTTPS, we believe the trend for the SDL is to move from un-encrypted messages to encrypted messages if security is a concern. If an app is able to encrypt a message, why it sends un-encrypted messages just for certain parameters.
Because each application will have its own permissions. Application's permissions are an aggregation of all RPCs from the function groups that the app belongs to. OEM can carefully design function groups by putting parameters that need protection and parameters that do not need protection in separate groups, so that "protected_parameters" is not needed. In this way, the existing apps use the old existing function groups with RPCs that do not need protection. The new apps use new function groups with RPC protection needed.
