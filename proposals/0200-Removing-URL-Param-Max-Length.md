# Removing URL Parameter Max Length
* Proposal: [SDL-0200](0200-Removing-URL-Param-Max-Length.md)
* Author: [Harshavardhan Patankar](https://github.com/hypatankar)
* Status: **In Review**
* Impacted Platforms: [Core, HMI, Android, iOS,RPC]

## Introduction

This proposal is to remove maximum length attribute for URL strings provided to OnSystemRequest, StartStream and StartAudioStream and let the URL strings be of any length permissible by the system architecture. Some strings such as the URL in ServiceInfo in HMI API do not have a limit so this would not be too unusual. URLs which are deprecated are not considered in this proposal.

## Motivation

Sometimes, it is necessary to provide a URL which is very large and thus cannot fit in the current 1,000 or 500 character limit. However, under the current implementation we cannot provide a URL which is over 1,000 characters in length.

## Proposed solution

We should remove the max length of the URLs in OnSystemRequest, StartStream and StartAudioStream and let the max size of the string be constrained by the system architecture in both the Mobile API and HMI API.

## Mobile API

We should remove the max length attribute of the following URL for OnSystemRequest. 

```xml
   <function name="OnSystemRequest" functionID="OnSystemRequestID" messagetype="notification" >
        <description>
            An asynchronous request from the system for specific data from the device or the cloud or response to a request from the device        or cloud
            Binary data can be included in hybrid part of message for some requests (such as Authentication request responses)
        </description>
        <param name="requestType" type="RequestType" mandatory="true">
            <description>The type of system request.</description>
        </param>
        <param name="url" type="String" mandatory="false">
            <description>
                Optional URL for HTTP requests.
                If blank, the binary data shall be forwarded to the app.
                If not blank, the binary data shall be forwarded to the url with a provided timeout in seconds.
            </description>
        </param>
        ...
```   

## HMI API

We should remove the max length attribute of the following URL for OnSystemRequest in HMI API. 

```xml
   <function name="OnSystemRequest" messagetype="notification" >
      <description>
        An asynchronous request from the system for specific data from the device or the cloud or response to a request from the device or cloud
        Binary data can be included in hybrid part of message for some requests (such as Authentication request responses)
      </description>
      <param name="requestType" type="Common.RequestType" mandatory="true">
        <description>The type of system request.</description>
      </param>
      <param name="url" type="String" minlength="1" mandatory="false">
        <description>Optional array of URL(s) for HTTP requests.</description>
      </param>
      ...
```   

The URL parameters in StartStream and StartAudioStream in HMI API should also have max length removed.

```xml
  <function name="StartStream" messagetype="request">
    <description>Request from SmartDeviceLinkCore to HMI to start playing video streaming.</description>
    <param name="url" type="String" minlength="21" mandatory="true">
      <description>URL that HMI start playing.</description>
    </param>
    ...
  <function name="StartAudioStream" messagetype="request">
   <description>Request from SmartDeviceLinkCore to HMI to start playing audio streaming.</description>
   <param name="url" type="String" minlength="21" mandatory="true">
     <description>URL that HMI start playing.</description>
   </param>
   ...
```

## Potential downsides

Increasing the size of the URL may provide a minimal performance impact since the system needs to process a larger string for the URL parameter. The increased string length may also be considered a breaking change.

## Impact on existing code

There should be a minimal impact on existing code because we are simply removing the max length size limitation from the URL parameter. Generally, when a string is declared in our mobile platforms, in Android and iOS, a size is not set for the string. Impact should be very minimal. 

## Alternatives considered

Many strings in both Mobile API and HMI API have max lengths so removing max lengths for the specified URL strings could be considered breaking trend. A possible alternative is to specify a very high max length for the URL strings discussed in this proposal. The max length for the URL strings could be 64,000 or larger because most upper limits for URLs are larger than 64,000 in length.
