# Button Subscription response From HMI

* Proposal: [SDL-NNNN](nnnn-button_subscription_response_from_hmi.md)
* Author: [LuxoftAKutsan](https://github.com/LuxoftAKutsan)
* Status: **Awaiting review**
* Impacted Platforms: [Core]

## Introduction
Proposed to change `OnButtonSubscription` notification
to `SubscribeButton` request/response,`UnsubscribeButton` request/response to HMI. 


## Motivation

All SDL subscriptions (vehicleData, InteriorVehicleData) have very similar scheme of work. 
SDL send request to HMI and wait for successful response. 

ButtonSubscription is the only one subscription that has different scheme of work,
to keep consistency and be able to check HMI errors button subscription should else be done by request\response scheme. 

Before sending response to mobile SDL should be sure that HMI proceed this subscription.
Notification has no mechanism to check that subscription was proceed successfully, it should be done with request/response.


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

SDL should store list of applications that subscribed to certain button. 
According to proposed API HMI does not know anything about applications that subscribed to button.

When application1 subscribes to new button, SDL should send `SubscribeButton` request to HMI. 

When application2 subscribes to **the same** button, SDL should **not** send anything to HMI, and store subscription internally.

When any application subscribes to the **new** button, SDL should send `SubscribeButton` request to HMI. 

When the last application subscribed to certain button unsubscribed SDL should send `UnsubscribeButton` request to HMI. 

When the last application subscribed to certain button unregiteres SDL should send `UnsubscribeButton` request to HMI. 

When HMI send OnButtonPress notification, SDL should initiale sending onButtonPress notification to all subscribed applications.
### Resumption 

During Resumption SDL should restore all button subscriptions for application and send required SubscribeButton requests.
In case if any existing application already subscribed to certain button,
SDL should not send any requests to HMI and store subscription internally.

## Potential downsides

No

## Impact on existing code

Impacts SDL core and HMI. 

## Alternatives considered
 1. Keep OnButtonSubscription notification. But in that case SDL has no ability to check if HMI was successful subscribed to button,
 
 2. Do not store subscriptions internally and just transfer mobile subscriptions with app_id to HMI. 
In that case additional logic of storing subscriptions should be implemented on HMI and it will lead to many redundant subscription and notification requests. 
