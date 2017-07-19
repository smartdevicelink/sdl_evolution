# Control Frame Payloads v1.0.0

* Proposal: [SDL-0078](0078-control_frame_payloads_v1_0_0.md)
* Author: [Joey Grover](https://github.com/joeygrover)
* Status: **Accepted with Revisions**
* Impacted Platforms: [Protocol/Android/iOS/Core]

## Introduction

With the acceptance of [Constructed Payloads](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0052-constructed-payloads.md) for Control Frames we need to ensure we spec out all the changes that will be needed for the first version of these payloads. This includes adding a new param to the `StartService` frame for RPC services that contains the max version supported for control frame payloads.
 
## Motivation
It is important to have proper specs when it comes to the protocol API within SDL. The new constructed payloads feature presents a challenge to keep track of all changes and how to version those changes. 

## Proposed solution
The proposed solution is to document all the payloads in the protocol spec. Because of the introduction of control frame payloads we will also have to bump the protocol version.

All changes are documented as followed:

#### Protocol Version 5.0.0 Header
We will keep track of all payloads via the protocol version. Because of this we need to change the protocol header to better support minor updates. We will use the original version byte as a flag, if the value is >=5 the next three bytes are version bytes now. We have added an extra byte to make an even 16 byte header. For now this byte will be defaulted to `0x00`, however in the future it can be used if needed for flags.

<table>
  <tr>
    <th colspan="3" width="25%">Byte 1</th>
    <th colspan="1" width="25%">Byte 2</th>
    <th width="25%">Byte 3</th>
    <th width="25%">Byte 4</th>
  </tr>
  <tr>
    <td width="12.5%" align="center">Version Flag</td>
    <td width="3.125%" align="center">E</td>
    <td width="9.375%" align="center">Frame Type</td>
    <td align="center">Version Major</td>
    <td align="center">Version Minor</td>
    <td align="center">Version Patch</td>
  </tr>
</table>

<table>
  <tr>
    <th width="300">Byte 5</th>
    <th width="25%">Byte 6</th>
    <th width="25%">Byte 7</th>
    <th width="25%">Byte 8</th>
  </tr>
  <tr>
    <td align="center">(TBD)</td>
    <td align="center">Service Type</td>
    <td align="center">Frame Info</td>
    <td align="center">Session ID</td>
  </tr>
</table>

<table >
  <tr>
    <th width="300">Byte 9</th>
    <th width="25%">Byte 10</th>
    <th width="25%">Byte 11</th>
    <th width="25%">Byte 12</th>
  </tr>
  <tr>
    <td colspan="4" align="center">Data Size</td>
  </tr>
</table>

<table>
  <tr>
    <th width="300">Byte 13</th>
    <th width="25%">Byte 14</th>
    <th width="25%">Byte 15</th>
    <th width="25%">Byte 16</th>
  </tr>
  <tr>
    <td colspan="4" align="center">Message ID</td>
  </tr>
</table>

#### Payloads
>Added: Protocol Version 5.0.0<br>
>*Note: All payloads are optional*<br>

Control frames use [BSON](http://bsonspec.org) to store payload data. All payload types are directly from the BSON spec. Each control frame info type will have a defined set of available data. Most types will also have differently available data based on their service type.

**Note:** Heartbeat, Heartbeat ACK, and Service Data ACK control frame types are not covered for any service as they were deprecated before payloads were introduced.

#####  Control Service
No defined payloads at this time.

##### RPC Service
###### Start Service
Nothing at this time. It will always be a version 1 packet so it should never have a structured payload.

###### Start Service ACK
| Tag Name| Type | Description |
|------------|------|-------------|
|hashId|int32| Hash ID to identify this service and used when sending an `EndService` control frame|
|MTU| int64 | Max transport unit to be used for this service|. If not included the client should use the protocol version default.|



###### Start Service NAK
| Tag Name| Type | Description |
|------------|------|-------------|
| rejectedParams |String Array| An array of rejected parameters|

###### End Service
| Tag Name| Type | Description |
|------------|------|-------------|
|hashId|int32| Hash ID supplied in the `StartServiceACK` for this service type|
###### End Service ACK

###### End Service NAK
| Tag Name| Type | Description |
|------------|------|-------------|
| rejectedParams |String Array| An array of rejected parameters such as: [`hashId`]


##### Audio Service
###### Start Service

###### Start Service ACK
| Tag Name| Type | Description |
|------------|------|-------------|
|hashId|int32| Hash ID to identify this service and used when sending an `EndService` control frame|
|MTU| int64 | Max transport unit to be used for this service. If not included the client should use the one set via the RPC service or protocol version default.|

###### Start Service NAK
| Tag Name| Type | Description |
|------------|------|-------------|
| rejectedParams |String Array| An array of rejected parameters such as: [`videoProtocol`, `videoProtocol`]

###### End Service
| Tag Name| Type | Description |
|------------|------|-------------|
|hashId|int32| Hash ID supplied in the `StartServiceACK` for this service type|
###### End Service ACK

###### End Service NAK
| Tag Name| Type | Description |
|------------|------|-------------|
| rejectedParams |String Array| An array of rejected parameters such as: [`hashId `]


##### Video Service
###### Start Service
| Tag Name| Type | Description |
|------------|------|-------------|
|height|int32| Desired height in pixels from the client requesting the video service to start|
|width|int32| Desired width in pixels from the client requesting the video service to start|
|videoProtocol|String| Desired video protocol to be used. See `VideoStreamingProtocol ` RPC|
|videoCodec|String|  Desired video codec to be used. See `VideoStreamingCodec` RPC|

###### Start Service ACK
| Tag Name| Type | Description |
|------------|------|-------------|
|hashId|int32| Hash ID to identify this service and used when sending an `EndService` control frame|
|MTU| int64 | Max transport unit to be used for this service. If not included the client should use the one set via the RPC service or protocol version default.|
|height|int32| Accepted height in pixels from the client requesting the video service to start|
|width|int32| Accepted width in pixels from the client requesting the video service to start|
|videoProtocol|String| Accepted video protocol to be used. See `VideoStreamingProtocol ` RPC|
|videoCodec|String|  Accepted video codec to be used. See `VideoStreamingCodec` RPC|


###### Start Service NAK
| Tag Name| Type | Description |
|------------|------|-------------|
| rejectedParams |String Array| An array of rejected parameters such as: [`videoProtocol`, `videoProtocol`]

###### End Service
| Tag Name| Type | Description |
|------------|------|-------------|
|hashId|int32| Hash ID supplied in the `StartServiceACK` for this service type|

###### End Service ACK

###### End Service NAK
| Tag Name| Type | Description |
|------------|------|-------------|
| rejectedParams |String Array| An array of rejected parameters such as: [`hashId`]



## Potential downsides
- Introduces a new version that will have to be kept track of. 
- Testing would have to be performed with legacy systems that do not support version 5 of the protocol to ensure adding the payload to the `StartService` frame doesn't break anything.


## Impact on existing code
Same impacts as the previously accepted [Constructed Payloads](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0052-constructed-payloads.md) with a few minor additions to keep track of control frame payload versions. 

## Alternatives considered
-Including `controlVersion` param into the RPC service `StartService` and ACK. This would be an added version to keep track of. It would also introduce risks in terms of adding a payload to a version 1 packet.  Overall a messier solution that served only a single purpose rather than multiple. 
- Not expanding the protocol header and not including `controlVersion` param into the RPC service `StartService` and ACK. This would force us to bump the protocol version every time we made a change. Unless we kept everything optional and agreed that param additions didn't require a bump, but that is messy. 





