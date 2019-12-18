# Remove duplicate parameter FileName from HMI RPC BasicCommunication.OnPutFile

* Proposal: [SDL-0265](0265-Remove-Duplicate-Parameter-HMI-RPC-OnPutFile.md)
* Author: [Shobhit Adlakha](https://github.com/ShobhitAd)
* Status: **Accepted**
* Impacted Platforms: [Core]

## Introduction

This proposal is for removing the duplicate parameter `FileName` from the HMI RPC `BasicCommunication.OnPutFile`.

## Motivation

Currently, there are two file name parameters in the HMI API for the `BasicCommunication.OnPutFile` notification:

```xml
      <param name="FileName" type="String" maxlength="255" mandatory="true">
        <description>File reference name.</description>
      </param>
```

and 

```xml
      <param name="syncFileName" type="String" maxlength="255" mandatory="true">
        <description>File reference name.</description>
      </param>
```

SDL Core, ATF and the HMI only use the `syncFileName` parameter for the implementation/testing of `BasicCommunication.OnPutFile`. The `FileName` parameter is not used.

## Proposed solution

The author proposes removing the `FileName` parameter for the RPC `BasicCommunication.OnPutFile` from the [HMI_API.xml](https://github.com/smartdevicelink/sdl_core/blob/master/src/components/interfaces/HMI_API.xml) file in SDL Core.

```xml
<function name="OnPutFile" messagetype="notification" >
    ...
-   <param name="FileName" type="String" maxlength="255" mandatory="true">
-       <description>File reference name.</description>
-   </param>

    <param name="syncFileName" type="String" maxlength="255" mandatory="true">
        <description>File reference name.</description>
    </param>
    ...
</function>
```

Since the parameter is unused, it can be removed from the API without any implementation changes in Core, ATF or the HMI.

## Potential downsides

An OEM may have implemented the `FileName` parameter for `BasicCommunication.OnPutFile` on their own. If that is the case, the author requests that OEMs reviewing this proposal note that they are using this parameter.

## Impact on existing code

This proposal only impacts SDL Core. The `FileName` parameter for `BasicCommunication.OnPutFile` should be removed from the HMI API in SDL Core.

## Alternatives considered

Find a possible use for the extra filename parameter in the notification. For example, have the `syncFileName` be the actual file name and the `FileName` be a string used by the HMI to map to the actual file name.
