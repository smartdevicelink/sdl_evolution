# GetSystemTime RPC

* Proposal: [SDL-NNNN](NNNN-filename.md)
* Author: [Aleksandr Stasiuk](https://github.com/AStasiuk)
* Status: **Awaiting review**
* Impacted Platforms: [Core / RPC ]

## Introduction

This proposal is about adding a new RPC GetSystemTime to SDL Core for correct receiving of system time.


## Motivation

Allow SDL Core obtaine time from the system in UTC format. Exclude possibility of UTC time distortion in case using system time from other components of the system.


## Proposed solution


The solution proposes adding new RPC between SDL and HMI.  GetSystemTime gives possibility to get the System Time status by making the following additions to the HMI API.

SDL Core must send this GetSystemTime RPC to HMI in case of Policy Table Update procedure and before Security TLS Handshake.

Expected that HMI will request system time from the system and provide to SDL Core via GetSystemTime_response

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

Would require a major version change.

## Alternatives considered

Using mqueue signals mechanism.
