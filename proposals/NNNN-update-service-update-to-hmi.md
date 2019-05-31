# Update to SDL0211 - Service Status Update to HMI

* Proposal: [NNNN](NNNN-update-service-update-to-hmi.md)
* Author: [Zhimin Yang](https://github.com/yang1070)
* Status: **Awaiting review**
* Impacted Platforms: [Core / RPC]

## Introduction

First, there is a name confliction on the enumeration of `ServiceUpdateReason` in approved proposals [App Services](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0167-app-services.md) and [ServiceStatusUpdateToHMI](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0211-ServiceStatusUpdateToHMI.md).

Second, in the [ServiceStatusUpdateToHMI](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0211-ServiceStatusUpdateToHMI.md) proposal, it defines 3 possible service update reasons (`PTU_FAILED`, `INVALID_CERT`, `INVALID_TIME`) when a `StartService` request is rejected. During the implementation, we identified more cases that need a reason:
- When a service is rejected because the system configuration ini file requires the enforcement of a protected service, but the app requests for an unprotected service.
- When a mobile app requests a protected service, but the system starts an unprotected service instead.


## Motivation

To resolve name conflict and add more update reasons.

## Proposed solution

Rename `ServiceUpdateReason` to `ServiceStatusUpdateReason` as App services also uses the same name `ServiceUpdateReason`.
Add two new reason codes to the enumeration of `ServiceStatusUpdateReason`.

The following are changes to the HMI_API.xml.

```xml

<function name="OnServiceUpdate" messagetype="notification">
    :
-   <param name="reason" type="Common.ServiceUpdateReason" mandatory="false">
+   <param name="reason" type="Common.ServiceStatusUpdateReason" mandatory="false">
    :
</function>

-<enum name="ServiceUpdateReason">
+<enum name="ServiceStatusUpdateReason">
    :
    :
    <element name="PROTECTION_ENFORCED" >
      <description>When a Service is rejected because the system configuration ini file requires the service must be protected, but the app asks for an unprotected service.</description>
    </element>
    <element name="PROTECTION_DISABLED" >
      <description>When a mobile app requests a protected service, but the system starts an unprotected service instead.</description>
    </element>
</enum>

```
## Potential downsides

N/A

## Impact on existing code

- Requires changes on SDL core and HMI_API.
- Does not require a version change as it is not a released feature.


## Alternatives considered
None


