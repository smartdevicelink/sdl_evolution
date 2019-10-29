# Deprecate HMI RPC OnFindApplications

* Proposal: [SDL-NNNN](NNNN-Deprecate-HMI-RPC-OnFindApplications.md)
* Author: [JackLivio](hhttps://github.com/JackLivio)
* Status: **Awaiting review**
* Impacted Platforms: [Core]

## Introduction

This proposal is for deprecating and removing an unusable HMI RPC `OnFindApplications`.

## Motivation

There is an HMI RPC `OnFindApplications` which has no implemented logic and sending the notification to Core will cause no action.

The Run function for the RPC only has a comment "TODO"

```
void OnFindApplications::Run() {
  LOG4CXX_AUTO_TRACE(logger_);

  // TODO(PV): add UpdateAppsOnDevice to ApplicationManager
}
```

The author has failed to find possible ways to implement this RPC to make it useful without creating redundancies. 

HMI RPC `UpdateAppList` already communicates app information to the HMI automatically when apps are registered.

HMI RPC `OnStartDeviceDiscovery` will tell Core's transport adapters (ie Bluetooth) to search paired devices and discover SDL Apps.

## Proposed solution

The author proposes to mark the RPC `OnFindApplications` as deprecated in the HMI API in the next release, and then remove the RPC from the HMI API and Core in the following release.

```
    <function name="OnFindApplications" messagetype="notification">
-     <description>This method must be invoked by HMI to get list of registered apps.</description>
+     <description>DEPRECATED - This RPC is not implemented</description>
      <param name="deviceInfo" type="Common.DeviceInfo" mandatory="false">
        <description>The name and ID of the device the list of registered applications is required for.</description>
      </param>
    </function>
```

## Potential downsides

An OEM could have implemented this RPC on their own in which case the Author requests that OEMs reviewing this proposal note if they are using this RPC.

## Impact on existing code

Only impacts SDL Core. OnFindApplications should be removed from the HMI API and the OnFindApplications supporting command files should be removed from the repository.

## Alternatives considered

Find a possible implementation for this RPC.

```
