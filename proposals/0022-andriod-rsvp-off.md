
# Feature name

* Proposal: [SDL-0022](0022-andriod-rsvp-off.md)
* Author: [Joey Grover](https://github.com/smartdevicelink)
* Status: **In Review**
* Impacted Platforms: [Android]

## Introduction

This proposal is to enable a tiered level of router service validation in the Android SDL library to help drive down traffic to the RSVP server when obtaining a list of trusted routers and prevent apps from not showing up when unable to obtain a refreshed list.


## Motivation

The multiplexing functionality uses a list of trusted router services that is obtained via a web call to the RSVP server. Since each app has to have their own list, traffic becomes pretty high and expensive to run the RSVP server. If the server bandwidth isn't increased to handle the high deamnd, apps will timeout in their requests. This cuases apps to potentially not trust router services that should be trusted and not register with modules. 
 

## Proposed solution

The multiplexing transport config can implement a flag of tiered security levels for the `RouterServiceValidator`. This would give app developers the choice if they wish to enable the security feature. The feature would then be turned off by default, but explicitly explained in the developer guides on [smartdevicelink.com](https://www.smartdevicelink.com).

## Detailed design

The `MultiplexTransportConfig` class would have a new int flag that developers could set via a new constructor or setter method. The constants for this flag would also reside in the class. The following explain what the tiers would look like. 

```java
	/**
	 * Multiplexing security will be turned off. All router services will be trusted.
	 */
	public static final int FLAG_MULTI_SECURITY_OFF 		= 0x00;
	/**
	 *  Multiplexing security will be minimal. Only trusted router services will be used. Trusted router list will be obtain from 
	 *  server. List will be refreshed every <b>30 days</b> or during next connection session if an SDL enabled app has been
	 *  installed or uninstalled. 
	 */
	public static final int FLAG_MULTI_SECURITY_LOW 		= 0x10;
	/**
	 *  Multiplexing security will be on at a normal level. Only trusted router services will be used. Trusted router list will be obtain from 
	 *  server. List will be refreshed every <b>7 days</b> or during next connection session if an SDL enabled app has been
	 *  installed or uninstalled. 
	 */
	public static final int FLAG_MULTI_SECURITY_MED 		= 0x20;
	/**
	 *  Multiplexing security will be very strict. Only trusted router services installed from trusted app stores will 
	 *  be used. Trusted router list will be obtain from server. List will be refreshed every <b>7 days</b> 
	 *  or during next connection session if an SDL enabled app has been installed or uninstalled. 
	 */
	public static final int FLAG_MULTI_SECURITY_HIGH 		= 0x30;
	
```

Developers would just have to set this flag when creating the `MultiplexTransportConfig`

```java
mtConfig.setSecurityLevel(MultiplexTransportConfig.FLAG_MULTI_SECURITY_MED);
```
\- OR - 

```java
MultiplexTransportConfig mtConfig = new MultiplexTransportConfig(context, APP_ID,MultiplexTransportConfig.FLAG_MULTI_SECURITY_MED);
```

The RouterServiceValidator already has a flag for certain levels of security measure checks and methods that can be levereged:

```java
	private boolean shouldOverrideInstalledFrom(){
		return (this.inDebugMode && ((this.flags & FLAG_DEBUG_INSTALLED_FROM_CHECK) != FLAG_DEBUG_INSTALLED_FROM_CHECK));
	}
```

When the flag is set and the method returns true, the RouterServiceValidator will just use that value as if it passed that checked, i.e. if the previous method returns true it will be assumed that the router service in question was installed from a trusted app store without actually checking.

## Impact on existing code

This is pretty scoped in terms of impact. The `MultiplexTransportConfig` would have a new flag, and the `RouterServiceValidator` already has methods to see if different checks are enabled, those statements would just need to look for the flags set from the config file.

## Alternatives considered

The two other alternatives are continuing the way it is and completely removing. The current implementation is secure, however, it has impacts on app's availability on modules. Completely removing the feature isn't recommeneded as if an app has reserverations on conecting to different router services they need to have the ability to ensure the amount of security they wished.

