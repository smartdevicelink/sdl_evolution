# GetSystemTime RPC

* Proposal: [SDL-0120](0120-GetSystemTime.md)
* Author: [Aleksandr Stasiuk](https://github.com/AStasiuk)
* Status: **Accepted**
* Impacted Platforms: [Core / RPC]

## Introduction

This proposal is about adding a new RPC GetSystemTime in order for SDL Core to get accurate system time information which is utilized by the TLS handshake mechanism.


## Motivation

Head units can make use of TLS handshake mechanism for security reasons to ensure the connected applications are authentic. This becomes necessary for projection experiences (such as Mobile Navigation) where the app has complete control over the content it displays. To facilitate such security mechanisms SDL Core will need to be provided with accurate time information. Today, SDL Core can get the time information by querying the platform OS which may or may not be accurate.
This proposal provides a solution to this problem by having SDL Core request the system for time information. The system would then be responsible for providing accurate time related information.


## Proposed solution


The solution proposes adding a new RPC between SDL and HMI called `GetSystemTime`. This RPC allows SDL Core to query the HMI for the accurate system time.

SDL Core must send the  `GetSystemTime` RPC to HMI for obtaining the system time during the Security TLS Handshake.

The expectation is that HMI will provide the accurate system time with the GetSystemTime response.

## Additions to HMI_API

GetSystemTime request\response

```xml
<interface name="BasicCommunication" version="< >" date="< >">
<function name="GetSystemTime" messagetype="request">
    <description>Request from SDL to HMI to obtain current UTC time.</description>
</function>
<function name="GetSystemTime" messagetype="response">
    <param name="systemTime" type="Common.DateTime" mandatory="true">
      <description>Current UTC system time</description>
    </param>
  </function>
```
OnSystemTimeReady notification

```xml
<interface name="BasicCommunication" version="< >" date="< >">
<function name="OnSystemTimeReady" messagetype="notification">
    <description>HMI must notify SDL about readiness to provide system time.</description>
</function>
```

## Potential downsides

N/A

## Impact on existing code

Requires changes on SDL core,  and HMI_API.

Would require a minor version change.

## Alternatives considered

The alternative would be to use the platform provided time which is the existing solution.
