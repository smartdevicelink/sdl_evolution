# Service Status Update to HMI

* Proposal: [SDL-0211](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0211-ServiceStatusUpdateToHMI.md)
* Author: [Robin Kurian](https://github.com/robinmk)
* Status: **Accepted with Revisions**
* Impacted Platforms: [Core / RPC]

## Introduction

This proposal is about adding a new RPC called 'OnServiceUpdate' which will be used by the HMI layer to know the status of certain services from SDL Core.


## Motivation

When a Mobile Navigation application is activated there is a series of steps taken; beginning with the app sending the StartService request for the Video Service and ending with the module acknowledging this request in a successful scenario. These steps include getting the current system time, performing a policy table update, decrypting certificates and ensuring validity of the certificates. Any of these steps could fail and since there is no mechanism for updating HMI with the status of the service, the HMI has no means of providing accurate feedback to the user on the status of the system or what steps to take in case of an error.
The motivation behind this proposal is to overcome this issue by introducing a new notification between SDL and HMI.


## Proposed solution


### Additions to HMI_API

The proposed solution is to introduce a new RPC for SDL Core to update HMI with the status of a particular service.

```xml
<function name="OnServiceUpdate" messagetype="notification">
  <description>
    Must be sent by SDL to HMI when there is an update on status of certain services.
    Services supported with current version: Video
  </description>
  <param name="serviceType" type="Common.ServiceType" mandatory="true">
    <description>Specifies the service which has been updated.</description>
  </param>
  <param name="serviceEvent" type="Common.ServiceEvent" mandatory="false">
    <description>Specifies service update event.</description>
  </param>
  <param name="reason" type="Common.ServiceUpdateReason" mandatory="false">
    <description>
      The reason for a service event. Certain events may not have a reason, such as when a service is ACCEPTED (which is the normal expected behavior).
    </description>
  </param>
   <param name="appID" type="Integer" mandatory="false">
       <description>ID of the application which triggered the update.</description>
   </param>	
</function>

<interface name="Common" version="2.0.0" date="2018-09-05">
:
:
  <enum name="ServiceType">
    <element name="VIDEO" >
      <description>Refers to the Video service.</description>
    </element>
    <element name="AUDIO" >
      <description>Refers to the Audio service.</description>
    </element>
    <element name="RPC" >
      <description>Refers to the RPC service.</description>
    </element>	  
  </enum>

  <enum name="ServiceEvent">
    <element name="REQUEST_RECEIVED" >
      <description>When a request for a Service is received.</description>
    </element>
    <element name="REQUEST_ACCEPTED" >
      <description>When a request for a Service is Accepted.</description>
    </element>			
    <element name="REQUEST_REJECTED" >
      <description>When a request for a Service is Rejected.</description>
    </element>			
  </enum>	

  <enum name="ServiceUpdateReason">
    <element name="PTU_FAILED" >
      <description>When a Service is rejected because the system was unable to get a required Policy Table Update.</description>
    </element>
    <element name="INVALID_CERT" >
      <description>When a Service is rejected because the security certificate is invalid/expired.</description>
    </element>			
    <element name="INVALID_TIME" >
      <description>When a Service is rejected because the system was unable to get a valid SystemTime from HMI, which is required for certificate authentication.</description>
    </element>			
  </enum>	
</interface>
```
 Note that the only time when SDL would not be able provide the appID would be during the first StartService request for the RPC service before RAI was sent.  
	
The details of the use cases are as follows:
(Note: Pop-ups on HMI side only serve as example.)

Use case 1:Successful scenario
![sunny day scenario][sunny-day-scenario]

Use case 2:Policy Table Update times out
![PTU Time Out][PTU-Time-Out]

Use case 3:PTU brings invlid cert/expired cert
![Invalid Cert][Invalid-Cert]

Use case 4: Invalid System Time
![Invalid System Time][Invalid-System-Time]

SDLCore should handle cases when HMI rejects a GetSystemTime request.

## Potential downsides

N/A

## Impact on existing code

Requires changes on SDL core and HMI_API.

Would require a minor version change.

## Alternatives considered

The author could not think of a better alternate solution.

[sunny-day-scenario]:../assets/proposals/0211-ServiceStatusUpdateToHMI/sunny-day-scenario.png
[PTU-Time-Out]: ../assets/proposals/0211-ServiceStatusUpdateToHMI/PTU-Time-Out.png
[Invalid-Cert]: ../assets/proposals/0211-ServiceStatusUpdateToHMI/Invalid-Cert.png
[Invalid-System-Time]: ../assets/proposals/0211-ServiceStatusUpdateToHMI/invalid-system-time.png
