# ATF support of additional transports(BT and USB)

* Proposal: [SDL-0126](0126-atf-additional-transports.md)
* Author: [Alexander Kutsan](https://github.com/LuxoftAKutsan)
* Status: **In Review**
* Impacted Platforms: [Core]

## Introduction

Currently some number of test scripts require manual checks using real transport. 
This part of manual work should be also automated with Automated test framework.

Automated test framework should support communication with SDL via :
 - TCP (already supported)
 - Bluetooth
 - USB
 
Full Bluetooth and USB testing of ATF should use real device for communication with SDL.
In future this approach also will allow to test SDL on custom OEM head units.

## Motivation

Some features of SDL assume usage of certain transport : USB or Bluetooth.
Some features describe SDL behavior in case of transport switch or multiple device connection.
Also generally SDL uses Bluetooth or USB as connection protocol on head unit. 
ATF should support custom transports. 

Main reasons :
 - Automated testing of transport specific use cases
 - Automated smoke and full regression testing of SDL via Bluetooth and USB
 - Automated testing of SDL on real hardware
 
## Proposed solution

Use real mobile device as a transport adapter.
Create Mobile application as a part of ATF infrastructure. 
Mobile application may use [SDL android library](https://github.com/smartdevicelink/sdl_android)
for communicating with SDL and TCP connection for communication with ATF.

Mobile application (Mobile transport adapter) should provide to ATF side such RPCs:
 - ConnectToSDL(transport)
 - RemoveConnection(connection_id)
 - GetListOfAvailableTransports()
 - SendData(connection_id, data)
 
ATF should be able to connect to multiple Mobile transport adapters and provide ability to use any of them to test engineer. 

ATF should provide such API to test engineer: 
 - ConnectToSDL(device, connection type)
 - RemoveConnection(connection)
 - SendRawData(connection)
 - GetListOfAvailableDevices()
 - GetDeviceInfo(device)
 
_СonnectToSDL_ should return connection object.
Connection object should provide ability to create sessions on it. Session interface should not be changed.  

In the case where a mobile device is absent, ATF should be able to test SDL via TCP connection (as it does now).

High Level relationship diagram: 
![High Level relationship diagram](/assets/proposals/nnnn-ATF-Additional-Transports/atf_transport_adapter.png)

## Potential downsides

This solution is not scalable. 
To run multiple scripts that test transport simultaneously, it will require adding a physical mobile device.

## Impact on existing code

Impact on ATF internal structure.
May impact some scripts that test multiple connections.
Also if this solution uses sdl_android, some changes may be required in sdl_android. 

## Alternatives considered

#### Avoid automatic transport testing

 SDL has implemented transport using adapters, so porting SDL on customer hardware requires rewriting transport adapters from scratch.
 And any transport testing that is done on Ubuntu Linux x86 becomes not actual.
 But not having automated testing of transport makes it impossible to check the business logic that is related to the transport switch.
 In addition proposed approach provides possibility of SDL testing on custom transports.
 
 #### Emulate transports
 
 Emulating of USB/Bluetooth transports probably is possible, but it requires some research, development and also PoC project. 
 Also emulating of transport won't allow performing of automated testing of SDL on custom head units, so any testing that will be performed on Ubuntu Linux x86 becomes not actual. 
