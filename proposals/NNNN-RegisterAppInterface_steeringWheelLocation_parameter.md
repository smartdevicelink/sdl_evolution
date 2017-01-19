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
1. The system shall provide a value of:   
     0 - for Left Hand Drive   
     1 - for Right Hand Drive   
2. The system shall source the vehicle driver location information from DID 0xDE00, Byte 4, Bit 6.   
3. For Vehicle Driver Location information, a value of:   
     0 - means the vehicle is Left Hand Drive   
     1 - means the vehicle is Right Hand Drive

## Detailed design

TBD

## Impact on existing code

TBD

## Alternatives considered

TBD
