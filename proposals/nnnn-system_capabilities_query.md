# System Capabilities Query

* Proposal: [SDL-nnnn](nnnn-system_capabilities_query.md)
* Author: [Joey Grover](https://github.com/joeygrover)
* Status: **Awaiting Review**
* Impacted Platforms: Android, iOS, Core, RPC

## Introduction

This proposal is to define how to convey more detailed information to the developer about the currently connected system's capabilities. 

## Motivation

Currently the `RegisterAppInterface` response houses most of the information about the system. This is quickly growing and showing signs it isn't scalable.

To mitigate this issue of a single bloated RPC we need to find a way to more intelligibly convey system capabilities.

## Proposed solution

The solution is to create a new RPC that can house many different structs to describe a particular capability. We will also leverage the already existing parameter and struct in the `RegisterAppInterface` response, `HMICapabilities`, where we list capabilities that can be queried. Then we introduce a new request/response pair called `SystemCapabilityQuery`. This RPC would have a modular design that can support a multitude of different capabilities and be easy to expand upon in the future.

The high level flow would be as followed:

1. App connects to module and sends `RegisterAppInterface`
2. Module accepts registration, builds `RegisterAppInterface` response with included system capabilities that can be queried.
3. App receives `RegisterAppInterface` response, sees capability 'X' is available on module.
4. App sends a `GetSystemCapability` with capability type 'X'
5. Module receives `GetSystemCapability`, puts together `SystemCapability` object with data for capability type 'X' and sends `GetSystemCapability` response with it to app
6. App receives  `GetSystemCapability` response, performs action based on received capabilities for specific capability. 

### RPC Spec changes

#### `HMICapabilities`
Current :

```xml
  <struct name="HMICapabilities">
    <param name="navigation" type="Boolean" mandatory="false">
      <description>Availability of build in Nav. True: Available, False: Not Available</description>
    </param>
    <param name="phoneCall" type="Boolean" mandatory="false">
      <description>Availability of build in phone. True: Available, False: Not Available </description>
    </param>
  </struct>
```

Expanded:

```xml
<struct name="HMICapabilities">
    <param name="navigation" type="Boolean" mandatory="false">
        <description>Availability of build in Nav. True: Available, False: Not Available</description>
    </param>
    <param name="phoneCall" type="Boolean" mandatory="false">
        <description>Availability of build in phone. True: Available, False: Not Available </description>
    </param>
    <param name="videoStreaming" type="Boolean" mandatory="false">
        <description>Availability of video streaming. </description>
    </param>
    <param name="audioStreaming" type="Boolean" mandatory="false">
        <description>Availability of audio streaming. </description>
    </param>
</struct>
```

#### `GetSystemCapability` RPC (New)

Each `GetSystemCapability` request/response pair will only include a single capability. This is the only new RPC we have to add. All other pieces are structs and enums. 


`<element name="GetSystemCapability" value="48" hexvalue="30"/>`

###### Request

```xml
<function name="GetSystemCapability" functionID="GetSystemCapabilityID" messagetype="request">
<param name="systemCapabilityType" type="SystemCapabilityType" mandatory="true">
  	<description>The type of system capability to get more information on</description>
  </param>
</struct>
```

###### Response

```xml

<function name="GetSystemCapability" functionID="GetSystemCapabilityID" messagetype="response">
    <param name="systemCapability" type="SystemCapability" mandatory="true">    
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
        <element name="IGNORED"/>
        <element name="DISALLOWED"/>
        <element name="USER_DISALLOWED"/>
        <element name="UNSUPPORTED_RESOURCE"/>
        <element name="DATA_NOT_AVAILABLE">
  </param>
  <param name="info" type="String" maxlength="1000" mandatory="false">
  </param>
  <param name="success" type="Boolean" platform="documentation" mandatory="true">
      <description> true if successful; false, if failed </description>
  </param>

</struct>

```

    
#### `SystemCapability ` Struct (New)

The `systemCapabilityType` param is the only mandatory parameter. This parameter describes which other parameter is also included. Only the capability parameter that aligns with the provided `SystemCapabilityType` will be included; all other capability params will not be included

```xml
 <struct name="SystemCapability">
    <description>The systemCapabilityType indicates which type of data should be changed and identifies which data object exists in this struct. For example, if the SystemCapability Type is NAVIGATION then a "navigationCapability" should exist</description>
    <param name="systemCapabilityType" type="SystemCapabilityType" mandatory="true">
    </param>
    <param name="navigationCapability" type="NavigationCapability" mandatory="false">
    </param>
    <param name="phoneCapability" type="PhoneCapability" mandatory="false">
    </param>
    <param name="videoStreamingCapability" type="VideoStreamingCapability" mandatory="false">
    </param>
    <param name="audioStreamingCapability" type="audioStreamingCapability" mandatory="false">
    </param>
</struct>
```


#### `SystemCapabilityType ` Enum (New)

```xml
  <enum name="SystemCapabilityType">
    <element name="NAVIGATION"/>
    <element name="PHONE_CALL"/>
    <element name="VIDEO_STREAMING"/>
    <element name="AUDIO_STREAMING"/>
  </enum>
```

### Effort to add new capabilities
 1. Add to HMI_capabilities in RAI response
 2. Add new enum to SystemCapabilityType.
 3. Define a matching Capability struct
 4. Add previous capability struct to the high level `SystemCapability`
 
## Potential downsides

- There are currently a lot of capabilities already implemented in the RAI response as params. We would have to either deprecate those, or duplicate functionality.

## Impact on existing code
Each of the projects would need to have RPCs, Structs, Enums, etc added. Helper methods would also be nice for the mobile proxies. 


## Alternatives considered

- Continue to add things to the RegisterAppInterfaceResponse
- Deprecate RAI fields and move all possible capabilities to new structure.
- Replace `HMICapabilities` fields with array of `SystemCapabilityType` entries for capabilities supported by that system.