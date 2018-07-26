# Restructuring OnResetTimeout

* Proposal: [SDL-0189](0189-Restructuring-OnResetTimeout.md)
* Author: [Ankur Tiwari](https://github.com/ATIWARI9)
* Status: **Accepted with Revisions**
* Impacted Platforms: [Core / RPC]

## Introduction

This proposal is to use OnResetTimeout for applicable interfaces so as to update the function and expand it to be used by a broader set of RPCs than just in _UI_ and _TTS_ interfaces.

## Motivation

There is a need for an API to reset SDL timeout for many methods. Some of the examples are as below:
1. CreateInteractionChoiceSet/AddCommand
    1. Time taken to add VR grammar varies by underlying voice module and number of VR commands. We have seen the request getting timeout before the entire batch of VR commands can be processed.
2. SendLocation
    1. SendLocation popup remains on HMI to wait for user's selection. 
3. SetInteriorVehicleData
    1. Time for completion of a set action varies by target module. This can potentially be significantly more than SDL predefined timeout
4. GetInteriorVehicleDataConsent
    1. This is a user side HMI dialogue which needs input from user.
5. Alert
    1. This is a user side HMI dialogue which needs input from user.
6. Slider
    1. This is a user side HMI dialogue which needs input from user.
7. PerformInteraction
    1. This is a user side HMI dialogue which needs input from user.
8. ScrollableMessage
    1. This is a user side HMI dialogue which needs input from user.
9. DialNumber
    1. This is a user side HMI dialogue which needs input from user.
10. Any other request which can potentially take more time than predefined SDL timeout


## Proposed solution

We can add a common _OnResetTimeout_ function which can be used by **functions in all interfaces**. This new _OnResetTimeout_ function can be added to _BasicCommunication_ interface. To maintain consistency, we need to deprecate _OnResetTimeout_ functions in UI and TTS interfaces since the common function is more efficient to implement and utilize.

  
_OnResetTimeout_ function definition would be as follows for the _BasicCommunication_:

### BasicCommunication: _OnResetTimeout would be added:_

```
<function name="OnResetTimeout" messagetype="notification" since="X.Y">
    <description>
		HMI must send this notification to SDL for method instance for which timeout needs to be reset
    </description>	
    <param name="requestID" type="Integer" minvalue="0" maxvalue="65535" mandatory="true">	
		<description>
			Id between HMI and SDL which SDL used to send the request for method in question, for which timeout needs to be reset.
		</description>
    </param>
    <param name="methodName" type="String" mandatory="true">
		<description>
			Name of the function for which timeout needs to be reset
		</description>
    </param>
    <param name="resetPeriod" type="Integer" minvalue="0" maxvalue="1000000" mandatory="false">
		<description>
			Timeout period in milliseconds, for the method for which timeout needs to be reset.
			If omitted, timeout would be reset by defaultTimeout specified in smartDeviceLink.ini
		</description>
    </param>
</function>
```

**Note**: Though type needs to be Long for _resetPeriod_, I have kept it as Integer to maintain consistency in API as no other param uses Long irrespective of _maxvalue_

**Note**: HMI Integration Guidelines will need to be updated to reflect that currently there is no version negotiation between HMI and Core, so older HMI implementations will not work with this new version of Core.

* SDL can uniquely identify the request instance for which OnResetTimeout is being requested by HMI by using the ID between SDL<->HMI (_requestID_) and _methodName_
    * SDL uses unique ID across interfaces and apps, so we do not need appID to uniquely identify the function instance	
* HMI would be responsible to fine tune the wait time per method call as needed. It is up to HMI to control number of reset timeouts and duration of each reset timeout for endless or finite method timeout.
* This _OnResetTimeout_ function can be used across all the interfaces and for all the request functions.

### UI: _OnResetTimeout would be deprecated:_

```
<function name="OnResetTimeout" messagetype="notification" deprecated="true" since="X.Y">
	<description>
		HMI must provide SDL with notifications specific to the current Turn-By-Turn client status on the module
	</description>
	<param name="appID" type="Integer" mandatory="true">
		<description>Id of application that invoked notifcation.</description>
	</param>
	<param name="methodName" type="String" mandatory="true">
		<description>Currently used method name on which was triggered action</description>
	</param>
</function>
```

### TTS: _OnResetTimeout would be deprecated:_

```
<function name="OnResetTimeout" messagetype="notification" deprecated="true" since="X.Y">
	<description>
		Sender: HMI->SDL. HMI must send this notification every 10 sec. in case the 'methodName' results long processing on HMI
	</description>
	<param name="appID" type="Integer" mandatory="true">
		<description>Id of application that concerns the 'methodName'.</description>
	</param>
	<param name="methodName" type="String" mandatory="true">
		<description>The name of the method, the renew of timeout is required for</description>
	</param>
</function>
```




## Potential downsides
  * These changes would deprecate OnResetTimeout from _UI_ and _TTS_ interfaces.

## Impact on existing code
* HMI API needs to be updated
* SDL core needs to be updated

## Alternatives considered

* To increase SDL overall timeout
  * This is NOT a good solution as it increases timeout for all the RPCs. So failure cases which need to be reported would take longer time. e.g. the ReadDID requests for unavailable ECUs.
  
