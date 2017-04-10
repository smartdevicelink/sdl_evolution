# Constructed Payloads

* Proposal: [SDL-NNNN](nnnn-constructed-payloads.md)
* Author: [Joey Grover](https://github.com/joeygrover)
* Status: **Awaiting Review**
* Impacted Platforms: Android, iOS, Core, Protocol

## Introduction

This proposal is for the addition of constructed payloads for non-RPC type packets. It will allow for clearer definition of payloads and allow for better parsing between versions. Constructed payloads reduce overhead by avoiding having to send an RPC message as well not mixing different services in the process. 

This proposal is a bit in depth but it is necessary. There are a few details that can be debated and a choice can be made. 

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

The solution is to create a common structure for non-RPC packet payloads. They will each have a tag, length, and data piece. 

| Tag        | Length      | Payload for Tag  |
| ---------- |:-----------:|------------------|
| 0x01,0x02  |0x01,0x08    |[0x05,0x46,0x15,0x01,0x00,0x66,0x24,0xD0]

A packet with multiple tags would look similar to:

| Payload|
| -------|
| **Tag**|
| Length |
| Data   |
| **Tag**|
| Length |
| Data   |

###Breakdown 

#### Tag
The tag section will be from length 2 to 128 bytes. Each tag will be defined for the specific packet type it is contained in. For example, tag `0x01` in a `StartServiceACK` for the RPC service will be the hash from the last session, but the `0x01` tag for the `StartServiceACK` for the video streaming service could be used for accepted height.

The definitions of the payloads will be defined by the protocol spec. However, all pieces of the payload will be considered optional. This allows us to add additional tags to the to the payloads without having to up the spec.

##### Length
The length section will be from length 2 to 129 bytes. The length section of the structured payload contains the total length of the data related to this tag.

This should never be 0. The tag would just not be included. 

##### Payload for tag
The payload for each tag will be of the length described in the previous length section. The payload itself would have to be specified as well. As a general guideline

|Type|Values|
|---|---|
|**Boolean**| 0x00 = False<br>0x01 = True|
|**Integer**| 0 -   2^128 (Either raw hex, or binary coded decimal)|
|**String** | Encoded byte data (ASCII,UTF8/16)|
|**Real Number**|Header byte followed by value|
|**Enums**| Custom dictionary of bytes per tag|

- **Integer** could be either raw value or use BCD 
- **String** encoding would be supplied via the register app interface
- **Real number** will have a header byte that describes the value. The MSB of the header byte will determine sign (positive = 0, negative = 1). The remaining 7 bits of the header byte indicate the location of the decimal point within the stored value. Thus, the min/max values rep- resented by this tag are ±∞, but the maximum precision available is 10−127.
- **Enums** can be defined by each tag to have a single value correspond to a specific value that has meaning for that tag/packet.

### Handling dynamic length sections
Both the tag and length sections of the structure can be of a dynamic length that can be expanded from 2 to 129 bytes. It will always contain at least 2 bytes.

||First byte| Second Byte|
|---|---|---|
|*Description*|Number of bytes of data for this section| Actual data for this section|
|*Length*|1 byte|1-128 bytes|
|*Values*| 1 - 127|0 - 2^128|
 
 So if we look at our original example for Tag:
 
| Tag        |
| ---------- |
| 0x01,0x02  |

The first byte, `0x01`, describes the length of the rest of this section, hence there is one byte that follows the first, `0x02`.

#### Sub-tags (Optional)
One of the benefits of the dynamic size of each section gives us the ability of give each tag their own sub-tags (and even sub-tags of sub-tags). 

| Tag        | Length      | Payload for Tag  |
| ---------- |:-----------:|------------------|
| 0x01,0x02  |0x01,0x08    |[0x01,0x03,0x01,0x04,0x00,0x66,0x24,0xD0]

The payload of this tag is actually another structured payload itself
`[0x01,0x03,0x01,0x04,0x00,0x66,0x24,0xD0]`

| Sub-tag        | Length      | Payload for Sub-tag  |
| ---------- |:-----------:|------------------|
| 0x01,0x03  |0x01,0x04    |[0x00,0x66,0x24,0xD0]



## Potential downsides

- This will require extra code that handles the parsings
- The spec for the payload tags will have to be defined in the protocol spec (as of right now)
- The protocol version will need to be bumped up

## Impact on existing code
Each of the projects would need to have a constructed payload parser put into place. There would need to be a check for protocol versions to know when structured payloads were implemented and in place. 


## Alternatives considered

Besides not doing this, no alternatives were considered.
