# Handle response from HMI during resumption data

* Proposal: [SDL-NNNN](nnn-resumption-data-error-handling.md)
* Author: [LuxoftAKutsan](https://github.com/LuxoftAKutsan)
* Status: **Awaiting review**
* Impacted Platforms: [Core]

## Introduction

The aim of this feature is to handle HMI error responses while restoring the data during resumption process.

## Motivation

During resumption data some data may not be restored due to HMI error response to add persistent data request.

SDL should take care about this possible issues and fail resumption of data which might not be restored. 

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

After success response receiving for all of the persistent data requests to HMI, SDL should send to mobile application `RegisterAppInterfaceResponse(success=true,result_code=SUCCESS)` 
and OnHashChangeNotification.

If HMI responds with any kind of error or does not respond to any requests sent during resumption, SDL should revert already restored data with appropriate RPC's:
 - DeleteCommand
 - DeleteSubMenu
 - DeleteInteractionChoiceSet
 - ResetGlobalProperties
 - UnsubscribeButton
 - UnsubscribeVehicleData
 - UnsubscribeWayPoints
 
After reverting persistent data SDL should response `RegisterAppInterfaceResponse(success=true,result_code=RESUME_FAILED)` to mobile application.


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
