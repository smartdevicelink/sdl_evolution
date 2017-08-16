# Expandable Design for Proprietary Data Exchange

* Proposal: [SDL-0082](0082-Expandable-design-for-proprietary-data-exchange.md)
* Author: [Robin Kurian](https://github.com/robinmk)
* Status: **In Review**
* Impacted Platforms: [Core/iOS/Android/RPC]

## Introduction

The SystemRequest/OnSystemRequest RPCs provide a mechanism for various components within the head unit to exchange data with app(s) written specifically to communicate with those components. With the growing popularity of SDL as a means of data exchange between head units and the outside world, there is a need to provide service to more such components. Today, the list of such components is limited to the 'RequestType' enum. Expanding this list everytime would not be an ideal solution.
This document proposes a new mechanism for an expandable design in such scenarios by introducing a new string field called 'RequestSubType' to be used along with a new 'RequestType' enum called 'OEM_SPECIFIC'.

## Motivation

With the growing popularity of SDL, more components within the SYNC head unit would like to exchange their data in a component specific proprietary way with the owner applications. Right now, there is not a good mechanism to identify each component without adding a new enum to identify each new component.

## Proposed solution

### Head Unit
#### Mobile API & HMI API
The 'RequestType' enum would need to be expanded with a new type called 'OEM_SPECIFIC'.
```xml
<enum name="RequestType">
    <description>Enumeration listing possible asynchronous requests.</description>
    :
    <element name="OEM_SPECIFIC" />    
  </enum>
  ```
A new parameter called 'RequestSubType' of type string will need to be added to the `SystemRequest` and `OnSystemRequest` RPCs at both the Mobile API and HMI API level.
An OEM can define the 'RequestSubType' to ensure data exchange with OEM specific owner applications.
```xml
 <function name="SystemRequest" functionID="SystemRequestID" messagetype="request" >
    <description>An asynchronous request from the device; binary data can be included in hybrid part of message for some requests (such as HTTP, Proprietary, or Authentication requests)</description>
    <param name="requestType" type="RequestType" mandatory="true">
      <description>
        The type of system request.
        Note that Proprietary requests should forward the binary data to the known proprietary module on the system.
      </description>
    </param>
    <param name="requestSubType" type="String" maxlength="255" mandatory="false">
      <description>
        This parameter is filled for supporting OEM proprietary data exchanges.
      </description>
    </param>
    <param name="fileName" type="String" maxlength="255" mandatory="false">
      <description>
        Filename of HTTP data to store in predefined system staging area.
        Mandatory if requestType is HTTP.
        PROPRIETARY requestType should ignore this parameter. 
      </description>
    </param>
  </function>
  
  <function name="OnSystemRequest" functionID="OnSystemRequestID" messagetype="notification" >
    <description>
      An asynchronous request from the system for specific data from the device or the cloud or response to a request from the device or cloud
      Binary data can be included in hybrid part of message for some requests (such as Authentication request responses)
    </description>
    <param name="requestType" type="RequestType" mandatory="true">
      <description>The type of system request.</description>
    </param>
    <param name="requestSubType" type="String" maxlength="255" mandatory="false">
      <description>
        This parameter is filled for supporting OEM proprietary data exchanges.
      </description>
    </param>	
    <param name="url" type="String" maxlength="1000" minsize="1" maxsize="100" mandatory="false">
      <description>
        Optional URL for HTTP requests.
        If blank, the binary data shall be forwarded to the app.
        If not blank, the binary data shall be forwarded to the url with a provided timeout in seconds.
      </description>
    </param>
    <param name="timeout" type="Integer" minvalue="0" maxvalue="2000000000" mandatory="false">
      <description>
      	Optional timeout for HTTP requests
      	Required if a URL is provided
      </description>
    </param>
    <param name="fileType" type="FileType" mandatory="false">
       <description>Optional file type (meant for HTTP file requests).</description>
    </param>
    <param name="offset" type="Long" minvalue="0" maxvalue="100000000000" mandatory="false">
      <description>Optional offset in bytes for resuming partial data chunks</description>
    </param>
    <param name="length" type="Long" minvalue="0" maxvalue="100000000000" mandatory="false">
      <description>Optional length in bytes for resuming partial data chunks</description>
    </param>    
  </function>	
```
#### HMI API
```xml
 <struct name="HMIApplication">
  :
  <param name="requestSubType" type="String" maxlength="100" minsize="0" maxsize="100" array="true" mandatory="false">
   <description>
	The list of SystemRequest's requestSubTypes allowed by policies for the named application.
	If the app sends a requestSubType which is not specified in this list, then that request should be rejected.
	An empty array signifies that any value of requestSubType is allowed for this app.
	If this parameter is omitted, then a request with any value of requestSubType is now allowed for this app
   </description>
  </param>
</struct>

<function name="OnAppPermissionChanged" messagetype="notification">
 :
 <param name="requestSubType" type="String" maxlength="100" minsize="0" maxsize="100" array="true" mandatory="false">
  <description>
   The list of SystemRequest's requestSubTypes allowed by policies for the named application.
   If the app sends a requestSubType which is not specified in this list, then that request should be rejected.
   An empty array signifies that any value of requestSubType is allowed for this app.
   If this parameter is omitted, then a request with any value of requestSubType is now allowed for this app
  </description>
 </param>
</function>
```
### iOS / Android Proxy

When the proxy layer receives an `OnSystemRequest` with the "requestSubType" parameter defined, the proxy layer should forward such requests to the application layer for further processing.
Any request by the application layer with "requestSubType" defined, should be forwarded by the proxy to SDL Core via the `SystemRequest` RPC.

## Potential downsides

NA

## Impact on existing code

It is to be noted that, today, an `OnSystemRequest` with 'RequestType' of 'PROPRIETARY' && 'fileType' of 'JSON' or a 'RequestType' of 'HTTP' and 'fileType' of 'BINARY' is considered as a policy table update which would cause the proxy layer to do further processing instead of passing the data to the application layer.
So, while the 'requestSubType' parameter can be used with any value of 'RequestType' and 'fileType', it should not be used with the above specified combination in an 'OnSystemRequest' notification.
If a newer proxy sends a `SystemRequest` RPC with the new "requestSubType" parameter to an older system, that RPC would be rejected by the system with a response of INVALID_DATA. 
If a newer system sends an `OnSystemRequest` notification with the new "requestSubType" parameter (and not in the above specified combination) to an older proxy, that notification would be forwarded to the application layer.
Today, mechanism exists for the policy manager to authorize requests based on the `requestType` parameter. The same mechanism will need to be extended for the `requestSubType` parameter.

## Alternatives considered

1. The desired results could be achieved by adding new request types every time a new module wants to send data to the app. However this would require constant updates to the specifications and design and would not be ideal.
2. Initially, using only the new 'requestSubType' parameter without expaning the 'requestType' enum was considered. However, in such a scenario the most appropriate 'requestType' would have been 'PROPRIETARY' which would have caused the proxy to attempt a policy table update.
