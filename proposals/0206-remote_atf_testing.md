# Remote Automated Testing

* Proposal: [SDL-0206](0206-remote_atf_testing.md)
* Author: [Alexander Kutsan](https://github.com/LuxoftAKutsan)
* Status: **In Review**
* Impacted Platforms: [ATF]

## Introduction

This proposal is about modification of Automated Test Framework (ATF) for providing ability to test SDL on remote workstations using automated test scripts.   

## Motivation

Automated testing of SDL on the real OEM hardware would significantly reduce efforts during the integration stage.  
This also can ensure that during the integration stage the business logic SDL will be ported successfully and will not be corrupted. 

On various OEM platforms communication between HMI and SDL is performed through different transports, that may not be retrieved from the target (e.g. mqueue). So for ATF it's not possible to connect to SDL from HMI side and emulate HMI behavior.  
This proposal suggests adding the optional proxy (relay) layer. This layer will connect to SDL, which is located on the OEM's target and expose API to ATF, which is located on other workstation via Transmission Control Protocol (TCP).

## Proposed solution

It is proposed to create Remote ATF Adapter as a separate application. This application will be executed on the same hardware with SDL and will provide an API for communication with SDL and will control the SDL life cycle.

### Remote ATF Adapter

ATF will use the Remote ATF Adapter as a relay for sending data to SDL via the HMI connection.  
Remote ATF Adapter may utilize any local transport that is used for connection between SDL and HMI on specific OEM hardware, but it will provide TCP for ATF and Open Source ATF will be used. 

![Remote ATF Adapter](/assets/proposals/nnnn-hmi-relay/ATFRemoteAdapter.png)

Remote ATF Adapter should provide the following functionality:

#### Connection management:
For sending and receiving data. In some cases more than one connection (with different connection types) should be opened, so interface should be rather general.

The following RPCs are required: 
 - Open Connection (connection parameters)
 - Send (connection, data) -> status
 - Receive (connection) -> data 
 - Close Connection(connection) -> status

#### RPCs for SDL life cycle management:
Testing of some SDL functionality (e.g. Resumption flow) requires performing of ignition cycles. For SDL, the new ignition cycle means it will be stopped and started again (with additional notifications before stopping). So ATF will need to control the SDL life cycle.
This can only be done with a Remote ATF Adapter on a remote workstation. 

The following RPCs are required: 
 - Start SDL 
 - Stop SDL
 - CheckSDL state
 
#### File management:
Some automated use cases are required as special preconditions for the modifications in smartDeviceLink.ini file, capabilities, preloaded policy table, etc.  
Because of this Remote ATF Adapter, it should provide functionality for file and folder management, such as: 
 - Upload file
 - Download file
 - Update file
 - Delete file
 - Check if file exists
 - Create a directory
 - Delete a directory
 - Check if directory exist 

#### Low level OS management: 
 - Command execute
 
For communication with SDL, the OEM adapter will need to implement this API. 
In case OEM requires additional functionality, relay server API may be extended.

ATF should use this API for sending/receiving data as a simulation of the HMI side.

Remote connection as a simulation of Mobile side may be done in scope of the following proposal: [ATF support of additional transports (BT and USB)](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0126-atf-additional-transports.md). Or by using of Wi-Fi (TCP) transport, in this case additional implementation is not required. 


### Open source implementation of Remote ATF Adapter

Open source implementation of Remote Adapter Server will support appropriate transports to test open source SDL : 
- TCP for mobile connections (additional transports for automated testing provided in separate proposal)
- Web socket for HMI connection. 

Remote Adapter Server is a component with listed transport agnostic interfaces, so  an OEM can implement for another transport. The API of the Remote Adapter Server can be extended in case the OEM implementation of SDL requires any additional functionality.

The open source implementation of the Remote adapter server is part of this proposal.
The Remote adapter server should be done using the C++ programming language to provide minimal latency, and to support a long list of supported platforms.
The Remote adapter server runs on the target, it communicates with SDL as HMI (using web socket for open source) and as mobile (using TCP for open source).
The Remote adapter server is controlled via ATF(from host) via TCP.

The Remote Client should be maintained in [sdl_atf](https://github.com/smartdevicelink/sdl_atf) repository as part of ATF.
The OEM may reimplement the Remote adapter server in case it uses another HMI communication transport, or has any additional transports for communication with SDL. 

## Potential downsides

N/A

## Impact on existing code

Impacts only Automated Test Framework code. 

## Alternatives considered

Investigated using TCP and web-sockets for HMI communication by OEM.
