# Handle response from HMI during resumption data

* Proposal: [SDL-NNNN](nnn-resumption-data-error-handling.md)
* Author: [LuxoftAKutsan](https://github.com/LuxoftAKutsan)
* Status: **Awaiting review**
* Impacted Platforms: [Core]

## Introduction
The aim of this feature is to handle HMI error responses while restoring the data during resumption process.

## Motivation

During resumption some data may not be restored due to HMI error response to add persistent data request.

SDL should take care about theese possible issues and fail resume data that might not be restored. 

## Proposed solution

During registration with correct hash_ID SDL should send all required requests/notification for restoring persistent data.

List of persistent data to restore : 

 - AddCommand (Menu + VR)
 - AddSubMenu
 - CreateInteractionChoiceSet
 - SetGlobalProperties
 - SubscribeButton
 - SubscribeVehicleData
 - SubscribeWayPoints

After successful responses received for all HMI requests, SDL should send successful response to mobile application `RegisterAppInterfaceResponse(success=true,result_code=SUCCESS)` 
and OnHashChangeNotification.

If HMI respond with any kind of error or does not respond to any requests sent during resumption, SDL should revert already restored data with appropriate RPC's:
 - DeleteCommand
 - DeleteSubMenu
 - DeleteInteractionChoiceSet
 - ResetGlobalProperties
 - UnsubscribeButton
 - UnsubscribeVehicleData
 - UnsubscribeWayPoints

In case if some data like a subscription already used by other applications, it means that subscription is actual and SDL should not send unsubscribe requests to HMI. 


After reverting persistent data SDL should response `RegisterAppInterfaceResponse(success=true,result_code=RESUME_FAILED)` to mobile application.

If multiple applications trying to restore the same subscription SDL should send the only first subscription to HMI. 
If the first subscription was failed and application received `result_code=RESUME_FAILED` result code, for the second application SDL should also try to restore the subscription.

Folowing picture shows that SDL should make an attempt for subscribing second application even if first app received error for this subscription during resumption:

![Common data subscription error](../assets/proposals/nnnn-resumption-data-error-handling/multiple_app_error_handling_with_common_subscriptions.png "Common data subscription error")

Folowing picture is an example of error handling for subscriptions during parallel resumption of 2 applicaitons: 
![Error handling for 2 applicaitons](../assets/proposals/nnnn-resumption-data-error-handling/multiple_app_error_handling.png# "Multiple apps error handling")

## Potential downsides
This approach may slow down app registration, in cases when there is a lot of resumption data. 

## Impact on existing code

Impacts resumption component of SDL and application registration process.

## Alternatives considered


#### Do not check response from HMI
If application was able to send any persistent data during previous connection, there should be no reason not to restore this data.  
So this proposal is more about unexpected or incorrect HMI behavior. 


#### Create special result code "partial resumption"

Prevent failing resumption in case when part of the data was rejected by HMI, and send in RegisterAppInterfaceResponse information what data were not restored. 

Options :
 1. Provide information about data that was not restored in info field.
 2. Extend RegisterAppInterfaceResponse API with special field that will contain data that was not restored.

This solution is over engineering because, if application was able to send any persistent data during previous connection, there should be no reasons do not restore this data.
