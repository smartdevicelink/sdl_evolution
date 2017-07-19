# System Capability Manager
* Proposal: [SDL-0079](0079-system_capability_manager.md)
* Author: [Austin Kirk](https://github.com/askirk), [Joey Grover](https://github.com/joeygrover)
* Status: **In Review**
* Impacted Platforms: Android

## Introduction
This proposal is to introduce a universal method for developers to request a capability for a given subject (e.g. NAVIGATION, PHONE_CALL, VIDEO\_STREAMING). This method will also retrieve capabilities that are returned in a RegisterAppInterfaceResponse (HMICapabilities, DisplayCapabilities). This will be made possible via an internal `SystemCapabilityManager` stored within the `SdlProxyBase` class.

## Motivation
The introduction of the [System Capability Query](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0055-system_capabilities_query.md) has created a need for an  intuitive and platform native way for developers to retrieve capabilities. The new RPC's can be a burden on developers to learn and continually copy and paste boiler plate code to repeat a very similar task. It also introduces a problem of the app either having to cache the results or request them each time they are needed, both of which are not developer friendly.
 
Also, there are currently a multitude of methods that exist in `SdlProxyBase` for each of the capabilities returned in a `RegisterAppInterfaceResponse`, including but not limited to:

```
getDisplayCapabilities()
getHmiCapabilities()
getSoftButtonCapabilities()
```

This approach could be simplified to a single method that retrieves the correct capability given a key, or in this case, a `SystemCapabilityType`.


We need a single, streamlined approach that accounts for both these situations: requesting a capability that is flagged as enabled in the `RegisterAppInterfaceResponse` using a `GetSystemCapability` request and getting a capability included in the `RegisterAppInterfaceResponse`.

## Proposed solution
The proposed solution involves the addition/modification of the following classes:

#### SystemCapabilityManager
A new manager class, `SystemCapabilityManager`, will be added with the following members, methods, and interfaces:

```java
interface ISystemCapabilityManager{
	onSendPacketRequest(RPCMessage message);
}
```
A locally defined interface for the manager. The interface will contain a callback that will allow the manager to request RPCs be sent.

```java
public SystemCapabilityManager(ISystemCapabilityManager interface){...}
```
A constructor that takes in an instance of the `ISystemCapabilityManager` interface. 
 

```java
HashMap<SystemCapabilityType, Object> cachedSystemCapabilities = new HashMap<>();
```

A map to hold any Capabilities that were previously retrieved via `GetSystemCapability` request as well as the parsed `RegisterAppInterfaceResponse` for all of its capabilities.

```java
public void parseRAIResponse(RegisterAppInterfaceResponse response){...}
```

A method to handle the `RegisterAppInterfaceResponse` and parse its values to be stored in the capabilities hash map.

```java
public Object getSystemCapability( final SystemCapabilityType systemCapabilityType, final SystemCapabilityListener scListener){}
```

Method that will send the requested capability object to the `SystemCapabilityListener` callback after it is found in the cached map or is requested for via `GetSystemCapability`.

If `null` is passed in for the `SystemCapabilityListener` the manager will not attempt to retrieve a value, but rather only return the capability if it is currently cached.

```java
public Object getSystemCapability( final SystemCapabilityType systemCapabilityType){}
```
Synchronous method that will return the requested system capability. If it is not cached, it will perform a query using the `GetSystemCapability` and wait until a value is retrieved to then return. 

#### SdlProxy Base Changes

```java
protected SystemCapabilityManager _systemCapabilityManager;
```

Local `SystemCapabilityManager` initialized when a `RegisterAppInterfaceResponse` is received.

```
public Object getSystemCapability(SystemCapabilityType systemCapabilityType, SystemCapabilityListener scListener)
```

Method that allows a developer to receive a Capability object for a given `SystemCapabilityType` by implementing a `SystemCapabilityListener` callback. In `SdlProxyBase` this method would simply pass its arguments to `_systemCapabilityManager. getSystemCapability(...)`.


Previous methods for getting capabilities (`getDisplayCapabilities`, `getHmiCapabilities`, etc)  will also be deprecated to encourage developers to move toward the new manager as well as being able to remove the methods in the future.

 
#### SystemCapabilityListener (New)

```
public interface OnSystemCapabilityListener {
    public void onCapabilityRetrieved(Object capability);
    public void onError(String info);
}
```
Developers must implement this callback when requesting a capability through `proxy. getSystemCapability(...)`.

#### Common Usage

```java
proxy.getSystemCapability(SystemCapabilityType.DISPLAY, new OnSystemCapabilityListener(){

	@Override
	public void onCapabilityRetrieved(Object capability){
		DisplayCapabilities displayCap = (DisplayCapabilities)capability;
		//Can then perform operations on the displayCap
	}
	
	@Override
	public void onError(String info){
	
	}
});
```


## Potential downsides

Previous methods of retrieving Capabilities through individual method calls could be considered deprecated and developers would need to update to this new consolidated approach. However, with the addition of the `GetSystemCapability` RPC, it makes sense to make a single, straightforward means to retrieve any conceivable Capability object.


## Impact on existing code

This is meant to add new functionality to the proxy for developers, and may deprecate prior methods of retrieving capabilities, as previously mentioned.

## Alternatives considered

An alternative is to use the multitude of individual methods to retrieve capability objects included in the `RegisterAppInterfaceResponse` and send individual and perhaps repetitive `GetSystemCapability` requests to retrieve capability objects that are not included. While this alternative would work fine, this solution provides a single method is easier for developers to use.
