# Reject PROPRIETARY/HTTP SystemRequests when PTU is not in progress

* Proposal: [SDL-NNNN](nnnn-reject-proprietary-http-systemrequests-when-ptu-not-in-progress.md)
* Author: [ShobhitAd](https://github.com/ShobhitAd)
* Status: **Awaiting review**
* Impacted Platforms: [Core]

## Introduction

This proposal is to make modifications in sdl_core to reject incoming `PROPRIETARY`/`HTTP` SystemRequests if there is no policy table update (PTU) in progress.

## Motivation

As reported in the sdl_core issue [#3076](https://github.com/smartdevicelink/sdl_core/issues/3076), SDL is currently able to update the policy table when a PTU procedure is not in progress.

### PROPRIETARY requests

Currently, if an application sends a SystemRequest request requestType "PROPRIETARY", nonempty fileName and PTU contents in the bulkData. Core forwards the request to the HMI. The HMI then sends an `SDL.OnReceivedPolicyUpdate` notification to SDL core.

![PROPRIETARY request type](../assets/proposals/nnnn-reject-proprietary-http-systemrequests-when-ptu-not-in-progress/Proprietary_request_flow.png)
### HTTP requests

Currently, if an application sends a SystemRequest request requestType "HTTP" and PTU contents in the bulkData, core will attempt to validate and apply the PTU.

![HTTP request type](../assets/proposals/nnnn-reject-proprietary-http-systemrequests-when-ptu-not-in-progress/Http_request_flow.png)


This is a security concern because, if an OEM isn't using PTU encryption, any app could try to update the PT to get all permissions at any time.

## Proposed solution

<!-- Describe your solution to the problem. Provide examples and describe how they work. Show how your solution is better than current workarounds: is it cleaner, safer, or more efficient? Use subsections if necessary.

Describe the design of the solution in detail. Use subsections to describe various details. If it involves new protocol changes or RPC changes, show the full XML of all changes and how they changed. Show documentation comments detailing what it does. Show how it might be implemented on the App Library and Core. The detail in this section should be sufficient for someone who is *not* one of the authors to be able to reasonably implement the feature and future [smartdevicelink.com](https://www.smartdevicelink.com) guides. -->

The proposed solution is to add a check in the `system_request.cc` to check if:

1. The requestType is `PROPRIETARY` or `HTTP`
2. There is a PTU procedure in progress
3. The app that was sent the `OnSystemRequest` notification with the policy table snapshot is the one sending the `SystemRequest`.

If Condition 1. is met but 2. and/or 3. are not. The `SystemRequest` should be rejected.

## Potential downsides

The proposed solution does not completely fix the issue. Since the app used to carry out the PTU is selected randomly(using `PolicyHandler::ChooseRandomAppForPolicyUpdate`), it is possible for the PTU OnSystemRequest to be received by a bad actor. This will allow the bad actor to send `PROPRIETARY`/`HTTP` SystemRequests during the PTU procedure to modify SDL's local policy table. Limiting this behavior might also have unintended consequences to other OEMs policy flow.

## Impact on existing code

The proposed solution would only make changes to the `PolicyHandler` class and `system_request.cc`. No changes would be required to the MOBILE and HMI API.

## Alternatives considered

An alternative to the proposed solution would be to force all PTUs to be encrypted. This would prevent bad actors from tampering with or creating new PTU.