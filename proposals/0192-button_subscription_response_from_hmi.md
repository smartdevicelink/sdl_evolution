# Button Subscription response from HMI

* Proposal: [SDL-0192](0192-button_subscription_response_from_hmi.md)
* Author: [Alexander Kutsan](https://github.com/LuxoftAKutsan)
* Status: **Accepted with Revisions**
* Impacted Platforms: [Core, HMI]

## Introduction
This proposal is to replace `OnButtonSubscription` notification
with `SubscribeButton` request/response,`UnsubscribeButton` request/response to HMI. 

## Motivation


In the current design when an app wants to subscribe to particular button, the app sends a SubscribeButton request to SDL Core. SDL Core then immediately provides a response of 'SUCCESS' to the app and sends the OnButtonSubscription notification to HMI. The problem with this design is that if for any reason HMI does not accept or fails to accept this subscription then HMI has no way to notify the app that the button has not been successfully subscribed. This results in the app assuming that it has successfully subscribed to a button when it has not.
Through this proposal we propose a design for fixing this problem.
The proposed design is similar to how other subscriptions such as VehicleData, InteriorVehicleData work on the system.


## Proposed solution

### API changes

Remove `<function name="OnButtonSubscription" messagetype="notification">`. 

Add new RPCs to HMI_API:
```xml
<function name="SubscribeButton" messagetype="request">
        <description>
            Subscribes to buttons.            
        </description>
		
	    <param name="appID" type="Integer" mandatory="true">
			<description>The ID of the application requesting this button usubscription. </description>
        </param>
		
        <param name="buttonName" type="ButtonName" mandatory="true">
            <description>Name of the button to subscribe.</description>
        </param>
</function>

<function name="SubscribeButton" messagetype="response"> </function>

<function name="UnsubscribeButton" messagetype="request">
        <description>
            Unsubscribes from buttons.            
        </description>
        
        <param name="appID" type="Integer" mandatory="true">
            <description>The ID of the application requesting this button unsubscription. </description>
        </param>
        
        <param name="buttonName" type="ButtonName" mandatory="true">
            <description>Name of the button to unsubscribe.</description>
        </param>
    </function>

<function name="UnsubscribeButton" messagetype="response"></function>
```

 - After sending a SubscribeButton request, if the HMI does not respond within DefaultTimeout period, then SDL Core shall provide a response of `TIMED_OUT` to the requesting application.
 - If after SDL Core sends a `TIMED_OUT` response to the application, HMI sends the response to Core notifying that the button has been successfully subscribed, then SDL Core shall send a request to HMI to unsubscribe the button. This is done to ensure the application and HMI are in sync.
 - Similarly, if after SDL Core sends a `TIMED_OUT` response to the application, HMI sends the response to Core notifying that the button has been successfully unsubscribed, then SDL Core shall send a request to HMI to subscribe the button.

### Resumption 

During Resumption SDL should restore all button subscriptions for application and send required SubscribeButton requests to HMI.

## Potential downsides

Removing OnButtonSubscription will require a major version change

## Impact on existing code

Impacts SDL Core and HMI. 

## Alternatives considered
N/A
