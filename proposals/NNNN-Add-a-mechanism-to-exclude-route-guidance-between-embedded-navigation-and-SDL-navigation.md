# Add a mechanism to exclude route guidance between embedded navigation and SDL navigation

* Proposal: [SDL-NNNN](NNNN-Add-a-mechanism-to-exclude-route-guidance-between-embedded-navigation-and-SDL-navigation.md)
* Author: [Shohei Kawano](https://github.com/Shohei-Kawano)
* Status: **Awaiting review** 
* Impacted Platforms: [Core / HMI / iOS / Java Suite / RPC]

## Introduction

This proposal is to add an exclusive control mechanism to prevent conflict of route guidance between embedded navigation and SDL navigation.  

## Motivation

Currently, there is a rule that sends `OnEventChanged(EMBEDDED_NAVI, true / false)` to SDL when embedded navigation becomes activate / deactivate.  
However, the activate / deactivate state of the embedded navigation is not specifically defined.  

**Table 1** Action definition for `OnEventChanged(EMBEDDED_NAVI, true / false)`  

| | `OnEventChanged(EMBEDDED_NAVI, true)` | `OnEventChanged(EMBEDDED_NAVI, false)` |
|----|----|----|
|Embedded Navigation|Video : No definition <br> Audio : No definition <br> Route Guidance : No definition <br> * The document does not describe the activation status or operation of embedded navigation.|Video : No definition <br> Audio : No definition <br> Route Guidance : No definition <br> * The document does not describe the deactivation status or operation of embedded navigation.|
|SDL Navigation|HMI Level : BACKGROUND<br>Audio : NOT_AUDIBLE<br>Route Guidance : No definition|HMI Level : FULL<br>Audio : AUDIBLE<br>Route Guidance : No definition|

Therefore, depending on the inactive operation of the built-in navigation (the handling of the route), the problem shown in the following table "Problems caused by the deactivate navigation operation" may occur.  

**Table 2** Problems caused by the inactive navigation operation

| |Embedded Navigation -> SDL Navigation|SDL Navigation -> Embedded Navigation|
|----|----|----|
|Delete Route|The route of embedded navigation disappears just by starting it for the purpose of viewing instead of using it.|The route of SDL navigation disappears just by starting it for the purpose of viewing instead of using it.|
|Keep Route|Native navigation route guidance overlaps when using SDL navigation.|No problem.|

Simply adding route deletion to the `OnEventChanged` behavior rule will result in behavior that does not meet the user's intention.  
Prevents unintended route deletion and conflicting route guidance by adding a mechanism to exclude route guidance.  


## Proposed solution

Add RPC `CancelGuideNaviApp` which requests cancellation of route guidance of SDL navigation from embedded navigation to enable exclusion of route guidance.  
Also, add RPC `CancelGuideEmbeddedNavi` requesting cancellation of route guidance of embedde navigation from the SDL navigation.  

HMI_API.xml
```xml
    <function name="CancelGuideNaviApp" messagetype="request">
      <description>Request route guidance cancellation of SDL navigation</description>
      <param name="appID" type="Integer" mandatory="true">
        <description>ID of application related to this RPC.</description>
      </param>
    </function>

    <function name="CancelGuideNaviApp" messagetype="response">
    </function>

    <function name="CancelGuideEmbeddedNavi" messagetype="request">
      <description>Request route guidance cancellation of embedded navigation</description>
      <param name="appID" type="Integer" mandatory="true">
        <description>ID of application related to this RPC.</description>
      </param>
    </function>

    <function name="CancelGuideEmbeddedNavi" messagetype="response">
    </function>
```

MOBILE_API.xml
```xml
    <function name="CancelGuideNaviApp" messagetype="request">
      <description>Request route guidance cancellation of SDL navigation</description>
    </function>

    <function name="CancelGuideNaviApp" functionID="CancelGuideNaviAppID" messagetype="response">
        
        <param name="success" type="Boolean" platform="documentation" mandatory="true">
            <description> true if successful; false, if failed </description>
        </param>
        
        <param name="resultCode" type="Result" platform="documentation" mandatory="true">
            <description>See Result</description>
            <element name="SUCCESS"/>
            <element name="DISALLOWED"/>
            <element name="REJECTED"/>
            <element name="ABORTED"/>
            <element name="IGNORED"/>
            <element name="INVALID_DATA"/>
            <element name="OUT_OF_MEMORY"/>
            <element name="TOO_MANY_PENDING_REQUESTS"/>
            <element name="GENERIC_ERROR"/>
            <element name="USER_DISALLOWED"/>
        </param>
        
    </function>

    <function name="CancelGuideEmbeddedNavi" messagetype="request">
      <description>Request route guidance cancellation of embedded navigation</description>
    </function>

    <function name="CancelGuideEmbeddedNavi" functionID="CancelGuideEmbeddedNaviID" messagetype="response">
        
        <param name="success" type="Boolean" platform="documentation" mandatory="true">
            <description> true if successful; false, if failed </description>
        </param>
        
        <param name="resultCode" type="Result" platform="documentation" mandatory="true">
            <description>See Result</description>
            <element name="SUCCESS"/>
            <element name="UNSUPPORTED_REQUEST"/>
            <element name="DISALLOWED"/>
            <element name="REJECTED"/>
            <element name="ABORTED"/>
            <element name="IGNORED"/>
            <element name="INVALID_DATA"/>
            <element name="APPLICATION_NOT_REGISTERED"/>
            <element name="OUT_OF_MEMORY"/>
            <element name="TOO_MANY_PENDING_REQUESTS"/>
            <element name="GENERIC_ERROR"/>
            <element name="USER_DISALLOWED"/>
        </param>
        
    </function>
```

## Potential downsides

No potential downsides  

## Impact on existing code

The addition of a new RPC has the following effects:  
- Core
- HMI
- iOS
- Java Suite
- RPC

## Alternatives considered

Delete route in conjunction with `OnEventChanged(EMBEDDED_NAVI, true)`.  
However, it is not recommended because unintended route deletion may occur.  
