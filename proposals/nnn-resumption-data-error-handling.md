# Feature name 

* Proposal: [SDL-NNNN](nnn-resumption-data-error-handling.md)
* Author: [LuxoftAKutsan](https://github.com/LuxoftAKutsan)
* Status: **Awaiting review**
* Impacted Platforms: [Core]

## Introduction

Handle HMI error responses during restoring data during resumption. Add new result code to mobile PARTIALLY_RESUMED. 

## Motivation

During resumption data some data may be not restored due to some reasons HMI error response on any persistent data add request . 

SDL should take care about this possible problems and fail resumption of data may not be restored. 

## Proposed solution

During registration with hash ID available SDL should send all required requests/notification for restoring persistent data.

List of persistent data to restore : 

 - AddCommand (Menu +VR)
 - AddSubMenu
 - CreateInteractionChoiceSet
 - SetGlobalProperties
 - SubscribeButton
 - SubscribeVehicleData
 - SubscribeWayPoints

After success response received for all of persistent data requests to HMI SDL should response to to mobile `RegisterAppInterfaceResponse(success=true,result_code=SUCCESS)` 
and OnHashChangeNotification.

If any of sent' during resumption requests to HMI respond with any kind of error or didn't respond, SDL should revert already restored data with appropriate RPC's :
 - DeleteCommand,
 - DeleteSubMenu,
 - DeleteInteractionChoiceSet,
 - ResetGlobalProperties,
 - UnsubscribeButton,
 - UnsubscribeVehicleData
 - UnsubscribeWayPoints
 
After reverting persistent data SDL should response to to mobile `RegisterAppInterfaceResponse(success=true,result_code=RESUME_FAILED)`.


## Potential downsides
This approach may slow down app registration, in cases when there are a lot of resumption data. 

## Impact on existing code

Impacts resumption component of SDL and application registration process.

## Alternatives considered


#### Do not check response from HMI.
If application was able to send any persistent data during previous connect, there should be no reason not to restore this data.  
So this proposal is more about unexpected or not correct behavior of HMI. 


#### Create special result code "partial resumption"

Prevent failing resumption in case if part of data was rejected by HMI, and send in RegisterAppInterfaceResponse information what data was not restored. 

Options :
 1. Provide information about data that was not restored in info field.
 2. Extend RegisterAppInterfaceResponse API with special field that will contain data that was not restored.

This solution is over engineering because, if application was able to send any persistent data during previous connect, there should be no reason not to restore this data.
