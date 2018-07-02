# Button Subscription response from HMI

* Proposal: [SDL-NNNN](nnnn-button_subscription_response_from_hmi.md)
* Author: [LuxoftAKutsan](https://github.com/LuxoftAKutsan)
* Status: **Awaiting review**
* Impacted Platforms: [Core]

## Introduction
This proposal is to replace `OnButtonSubscription` notification
with `SubscribeButton` request/response,`UnsubscribeButton` request/response to HMI. 


## Motivation

All SDL subscriptions (VehicleData, InteriorVehicleData) have very similar flow. 
SDL sends request to HMI and waits for successful response. 

ButtonSubscription is the only one subscription type that has a different flow.  

To keep consistency and be able to check HMI errors ButtonSubscription should else be done by request/response scheme. 

Before sending response to mobile application, SDL should be sure that HMI processed this subscription.
`OnButtonSubscription` notification has no mechanism to check whether the subscription was processed successfully.  
It could be done with new request/response sent to HMI.


## Proposed solution

### API changes

Remove `<function name="OnButtonSubscription" messagetype="notification">`. 

Add new RPCs to HM_API:
```xml
  <function name="SubscribeButton" messagetype="request">
        <description>
            Subscribes to built-in HMI buttons.
            The application will be notified by the OnButtonEvent and OnButtonPress.
            To unsubscribe the notifications, use unsubscribeButton.
        </description>
        
        <param name="buttonName" type="ButtonName" mandatory="true">
            <description>Name of the button to subscribe.</description>
        </param>
    </function>
    
    <function name="SubscribeButton" messagetype="response">
        <param name="success" type="Boolean" platform="documentation" mandatory="true">
            <description> true if successful; false, if failed </description>
        </param>
        
        <param name="resultCode" type="Result" platform="documentation" mandatory="true">
            <description>See Result</description>
            <element name="SUCCESS"/>
            <element name="INVALID_DATA"/>
            <element name="OUT_OF_MEMORY"/>
            <element name="TOO_MANY_PENDING_REQUESTS"/>
            <element name="APPLICATION_NOT_REGISTERED"/>
            <element name="GENERIC_ERROR"/>
            <element name="UNSUPPORTED_RESOURCE" />
            <element name="IGNORED" />
            <element name="REJECTED"/>
        </param>
        
        <param name="info" type="String" maxlength="1000" mandatory="false" platform="documentation">
            <description>Provides additional human readable info regarding the result.</description>
        </param>
    </function>
    
    <function name="UnsubscribeButton" messagetype="request">
        <description>Unsubscribes from built-in HMI buttons.</description>
        
        <param name="buttonName" type="ButtonName" mandatory="true">
            <description>Name of the button to unsubscribe.</description>
        </param>
    </function>
    
    <function name="UnsubscribeButton" messagetype="response">
        <param name="success" type="Boolean" platform="documentation" mandatory="true">
            <description> true if successful; false, if failed </description>
        </param>
        
        <param name="resultCode" type="Result" platform="documentation" mandatory="true">
            <description>See Result</description>
            <element name="SUCCESS"/>
            <element name="INVALID_DATA"/>
            <element name="OUT_OF_MEMORY"/>
            <element name="TOO_MANY_PENDING_REQUESTS"/>
            <element name="APPLICATION_NOT_REGISTERED"/>
            <element name="GENERIC_ERROR"/>
            <element name="UNSUPPORTED_RESOURCE" />
            <element name="IGNORED" />
            <element name="REJECTED"/>
        </param>
        
        <param name="info" type="String" maxlength="1000" mandatory="false" platform="documentation">
            <description>Provides additional human readable info regarding the result.</description>
        </param>
    </function>

```

### Storing subscriptions

SDL should store the list of applications that are subscribed to a certain button. 
According to existing API, HMI does not know anything about applications that are subscribed to a button.

When application1 subscribes to a new button, SDL should send `SubscribeButton` request to HMI. 

When application2 subscribes to **the same** button, SDL should **not** send anything to HMI, and store subscription internally.

When any application subscribes to a **new** button, SDL should send `SubscribeButton` request to HMI. 

When the last application subscribed to certain button unsubscribes SDL should send `UnsubscribeButton` request to HMI. 

When the last application subscribed to certain button unregiteres SDL should send `UnsubscribeButton` request to HMI. 

When HMI send OnButtonPress notification, SDL should initiale sending onButtonPress notification to all subscribed applications.

### Resumption 

During Resumption SDL should restore all button subscriptions for application and send required `SubscribeButton` requests.
In case any existing application already subscribed to a certain button,
SDL should not send any requests to HMI and store subscription internally.

## Potential downsides

No

## Impact on existing code

Impacts SDL core and HMI. 

## Alternatives considered
 1. Keep `OnButtonSubscription` notification. But in that case SDL has no ability to check if application was successfully subscribed to a button on HMI.
 
 2. Do not store subscriptions internally and just transfer mobile subscriptions with app_id to HMI. 
In that case additional logic of storing subscriptions should be implemented on HMI and it will lead to many redundant subscription and notification requests. 
