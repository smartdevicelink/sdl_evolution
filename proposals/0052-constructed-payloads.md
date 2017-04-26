# Constructed Payloads

* Proposal: [SDL-0052](0052-constructed-payloads.md)
* Author: [Joey Grover](https://github.com/joeygrover)
* Status: **Awaiting Review**
* Impacted Platforms: Android, iOS, Core, Protocol

## Introduction

This proposal is for the addition of constructed payloads for non-RPC type packets. It will allow for clearer definition of payloads and allow for better parsing between versions. Constructed payloads reduce overhead by avoiding having to send an RPC message as well not mixing different services in the process. 


## Motivation

Currently there are a few control packets that have payloads attached that mean very specific things. They also have to be just taken at the byte level and parsed at some arbitrary length based on the specific control packet type (eg. StartServiceACK). 

This also reduces the overhead on creating new RPC messages to send very simple values along with control packets. 

There are many use cases for adding structure payloads to packets, a few are:

- `StartServiceACK` (RPC)
    - HashId
    - MTU
- `StartService` (video streaming)
    - Desired Height
    - Desired Width
    - Desired Frame Rate
- `StartServiceACK` (video streaming)
    - Accepted Height
    - Accepted Width
    - Accepted Frame Rate
    - Accepted MTU for this service

There are more potential uses cases, but this proposal is only for the addition of the structured payload paradigm so each of those uses cases will need their own proposals. 



## Proposed solution

The solution is to use BSON tags in control packets. It is not a proposal to refactor the RPC service.

##### Example

|   Payload  | Raw      					| Description |
| ---------- |:-----------------------:|------------------|
| `{MTU:1024}`|`\x0E\x00\x00\x00`   		| total document size
| 				 |`\x10 `               	|  0x10 = type int32 |
| 				 | `MTU\x00 `  				| field name + null terminator|
| 				 | `\x04\x00\x00\x00\x00\x04\x00\x00`|  field value (size of value, value)
| 				 |`\x00` 						|  `0x00` = type EOO ('end of object')
  


<br>
More information  on BSON can be found [here](http://bsonspec.org/).

## Potential downsides

- Have to either find a library for each platform that conforms to license requirements or code an implementation from scratch
- The spec for the payload tags will have to be defined in the protocol spec (as of right now)
- The protocol version will need to be bumped up

## Impact on existing code
Each of the projects would need to have a BSON parser put into place. There would need to be a check for protocol versions to know when structured payloads were implemented and in place. 


## Alternatives considered

Besides not doing this, no alternatives were considered.
