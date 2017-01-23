# RegisterAppInterface: providing the value of _steeringWheelLocation_ parameter at response.

* Proposal: [SDL-NNNN](NNNN-RegisterAppInterface_steeringWheelLocation_parameter.md)
* Author: [Melnyk Tetiana](https://github.com/TMelnyk)
* Status: **Awaiting review**
* Impacted Platforms: Core / RPC

## Introduction

The proposal is to give a permission to provide the vehicle driver location as part of the response to a registration request.

## Motivation

**Required for FORD.**   
In order to expand the range of provided services, the system shall provide the vehicle driver location as part of the response to a registration request.

## Proposed solution

SDL returns the value of _steeringWheelLocation_ received from HMI or retrieved from 'HMI_capabilities.json' file.   
a. The system shall provide a value of:   
     0 - for Left Hand Drive   
     1 - for Right Hand Drive   
b. The system shall source the vehicle driver location information from DID 0xDE00, Byte 4, Bit 6.   
c. For Vehicle Driver Location information, a value of:   
     0 - means the vehicle is Left Hand Drive   
     1 - means the vehicle is Right Hand Drive

1) In case SDL does NOT receive value of "steeringWeelLocation" parameter via UI.GetCapabilities_response from HMI OR receive invalid value of "steeringWeelLocation" parameter from HMI and any SDL-enabled app sends RegisterAppInterface_request to SDL, _SDL must_:   
   - retrieve the value of "steeringWeelLocation" parameter from "HMI_capabilities.json" file;
   - provide the value of "steeringWeelLocation" via RegisterAppInterface_response to mobile app.

2) In case any SDL-enabled app sends RegisterAppInterface_request to SDL and SDL has the value of "steeringWheelLocation" stored internally _SDL must_: 
   - provide this value of "steeringWeelLocation" via RegisterAppInterface_response to mobile app.

3) In case SDL receives valid value of "steeringWeelLocation" parameter via UI.GetCapabilities_response from HMI, _SDL must_:   
   - store the value of "steeringWheelLocation" received from HMI internally (keep value during one ignition cycle).

4) In case SDL cuts off fake parameters from response (request ) that SDL should transfer to mobile app AND this response (request) is invalid, _SDL must_:   
   - respond GENERIC_ERROR (success:false, \<info>) to mobile app.

5) In case HMI sends request (response, notification) with fake parameters that SDL should transfer to mobile app, _SDL must_:   
   - validate received response; 
   - cut off fake parameters; 
   - transfer this request (response or notification) to mobile app.

## Detailed design

TBD

## Impact on existing code

TBD

## Alternatives considered

TBD
