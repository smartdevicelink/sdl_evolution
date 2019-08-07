# Add App Services to HMICapabilities

* Proposal: [SDL-0246](0246-app-services-hmi_capabilities.md)
* Author: [Joey Grover](https://github.com/joeygrover)
* Status: **In Review**
* Impacted Platforms: [iOS / Java Suite / JavaScript Suite /Core / RPC]



## Introduction
[SDL-0167](0167-app-services.md) introduced the App Services functionality. It included a new capability, however that capability was not included into the `HMICapabilities` struct as all other system capabilities have been.


## Motivation

All system capabilities have been added to the `HMICapabilities` as a way for the developer to quickly find if a capability was supported or not. It's important to keep consistency with all system capabilities that are added that use the new capability retrieval feature.


## Proposed solution

### Add param to HMICapabilities

```
<struct name="HMICapabilities" since="3.0">
    <param name="appServices" type="Boolean" mandatory="false" since="x.x">
       <description>Availability of App Services functionality. True: Available, False: Not Available</description>
    </param>
</struct>
```

### Handle corner case with RPC Spec Version 5.1

Since the param was not available in the RPC Spec Version 5.1.0, the System capability managers will need to return true for that case. Otherwise, use the provided method from the `hmiCapabilities` struct. The iOS library hasn't implemented this method yet, but it is planned so  it will follow a similar flow.

```java
	public boolean isCapabilitySupported(SystemCapabilityType type){
		if(cachedSystemCapabilities.get(type) != null){
			//The capability exists in the map and is not null
			return true;
		}else if(cachedSystemCapabilities.containsKey(SystemCapabilityType.HMI)){
			HMICapabilities hmiCapabilities = ((HMICapabilities)cachedSystemCapabilities.get(SystemCapabilityType.HMI));
			switch (type) {
				case NAVIGATION:
					return hmiCapabilities.isNavigationAvailable();
				
				...
				
				case APP_SERVICES:
					SdlMsgVersion rpcVersion = callback.getSdlMsgVersion();
					if(rpcVersion != null){
						if(rpcVersion.getMajorVersion() == 5 && rpcVersion.getMinorVersion() == 1){
							return true;
						}
					}
					//Otherwise, defaults to false if not included
					return hmiCapabilities.isAppServicesAvailable();
				default:
					return false;
			}
		} else {
			return false;
		}
	}
```

## Potential downsides

There could be a chance that a module using RPC Spec version 5.1.0 does not support App Services. However, this would be quickly realized after the `GetSystemCapability` request was sent and a response received with `success = false`.


## Impact on existing code

- The param will have to be added to the HMICapabilities struct in all platforms
- SystemCapabilityManager will have to be updated to handle corner case for RPC spec version 5.1.0 in all app libraries


## Alternatives considered

- Handling the corner case in the `HMICapabilities` struct, but it does not have direct access to RPC spec version in all platforms. The JavaSuite platforms could use the `format` method call to auto-populate the param `appServicesAvailable` with a true value for RPC Spec Version 5.1.0. If iOS had this ability I would have chosen this approach to avoid RPC corner cases outside of the RPC layer.
