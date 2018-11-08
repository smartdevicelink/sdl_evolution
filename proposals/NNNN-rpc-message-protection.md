# RPC message protection

* Proposal: [SDL-NNNN](NNNN-rpc-message-protection.md)
* Author: [Zhimin Yang](https://github.com/yang1070)
* Status: **Awaiting review**
* Impacted Platforms: [Core / Android/ iOS / RPC / Policy / SDL server]

## Introduction
This proposal proposes a design to protect (enable encryption for) RPC messages transmitted between a mobile application and SDL.

## Motivation
Security is good but it has cost. Each OEM can evaluate the risks and require certain RPC messages must be protected, which means the messages are encrypted and transmitted in a secured SDL service between an authenticated app and a vehicle head unit. How to authenticate a mobile app and how to set up a secured SDL service is out of the scope of this proposal. SDL supports it already. This proposal provides a solution to protect certain SDL RPC messages. It includes which RPCs need protection, when to start a secured SDL RPC service and what SDL shall do with these RPCs with the secured service.

## Proposed solution


RPCs that need protection and RPCs that do not need protection share the same RPC service 7. Currently, SDL Android API `SdlProxyBase.startProtectedRPCService` supports start a secure RPC service. SDL can keep the existing un-encrypted service open and running at the same time of starting enable the encrypted service. It does not need to stop the RPC service before startProtectedRPCService. SDL Android also supports setting a RPC message as encrypted or unencrypted with API `RPCStruct.setPayloadProtected(Boolean)`. Without any mobile proxy and sdl core change, android mobile apps and SDL can send/receive both encrypted and unencrypted messages (include requests/responses/notifications) in the same secured RPC service.

### Mobile app change
A mobile application shall start/restart RPC service 7 with encryption enabled (by app itself or by sdl proxy, either at the beginning or at certain stage after app registration). 


### Mobile API change
We add a new Boolean parameter to the existing `PermissionItem` date type. A list of `PermissionItem` will be received by the app via `OnPermissionsChange` notification, so that the app side knows which RPCs need protection.

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

### Mobile proxy change (Android and iOS)
SDL proxy shall support sending a PRC with both encrypted and unencrypted format as it currently does if the RPC service has encryption enabled. 

SDL proxy shall restart service 7 with encryption enabled after it receives an `OnPermissionsChange` notification and there is at least one RPC has `needProtection` with value `true` in the `PermissionItem`. 

SDL proxy shall only send encrypted RPC requests and receive encrypted RPC responses and notifications in an encryption enabled service if the corresponding RPC has `needProtection` tag with value `true`.

SDL proxy shall send/receive encrypted RPC requests/responses if the app chooses to `setPayloadProtected(true)` in an encryption enabled service even if the corresponding RPC has `needProtection` tag with value `false`.



### SDL core change

#### Proposed solution
Before the encryption of RPC service 7 is enabled, SDL rejects any RPC request if the RPC needs protection. (Please see policy updates for which RPC needs protection.) SDL continues processing a RPC request if the RPC does not need protection. SDL sends a notification only if the RPC does not need protection.

After the encryption of RPC service 7 is enabled, SDL rejects any unencrypted RPC request with unencrypted response if the RPC needs protection. SDL continues processing an unencrypted RPC request if the RPC does not need protection and responds with unencrypted response. SDL continues processing an encrypted RPC request if the RPC needs protection and responds with encrypted response. SDL sends an unencrypted notification if the RPC does not need protection. SDL sends an encrypted notification if the RPC needs protection. In addition, SDL shall continue processing an encrypted RPC request if the RPC does not need protection and responds with encrypted response.


#### Alternative solution:
- We require all applications to be authenticated and all RPC messages encrypted (i.e. SDL requires encryption for RPC service 7, app and SDL always sends and receives encrypted RPC messages. This can be done in smartdevicelink.ini file to configure service 7 must be protected.)

- We create a new secure RPC service 12, which is similar to the existing service 10 and service 11. We require certain RPCs (that need protection, include requests, responses and notifications) must be transmitted via this new SDL service.


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

If there are two or more instances of the same RPC in the policy for an app, one has `needProtection`=`true` and the others have `needProtection`=`false`, then the RPC shall have `needProtection`=`true`.

### SDL server updates:
SDL server need support the new parameter in the policy table.

## Potential downsides


None.

## Impact on existing code

As it is analyzed in the section of `Proposed solution`, the following components need update: Core, Mobile_API.xml, Android and iOS proxy, Policy server.

## Alternatives considered

We provide alternatives in the section of `Proposed solution`.


