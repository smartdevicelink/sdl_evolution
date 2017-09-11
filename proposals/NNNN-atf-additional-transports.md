# ATF support of additional transports(BT and USB)

* Proposal: [SDL-NNNN](NNNN-atf-additional-transports.md)
* Author: [SDL Developer](https://github.com/smartdevicelink)
* Status: **Awaiting review**
* Impacted Platforms: [Core / iOS / Android / Web / RPC / Protocol]

## Introduction

Currently some number of test sets requires manual checking on real transport. 
This part of manual work should be also automated via Automated test framework.

Automated test framework should support communication with SDL via :
 - TCP (alredy supported)
 - Bluetooth
 - USB
 
Full Bluetooth and USB testing of ATF should use real device for communicaiton with SDL.
In future this approach also will allow test SDL on custom OEM headunits.

## Motivation

Some features of SDL assumes usage of certain transport : USB or Bluetooth.
Some features even decribe SDL behavior in case of transport switch or multiple device connection.
Also main usage of SDL on headunits is Bluetooth or USB. 
ATF should support custom transports. 

Main reasons :
 - Automated testing transport specific use cases
 - Automated smoke and full regression testing of SDL via Bluetooth and USB
 - Automated testing SDL on real hardware
 
## Proposed solution

Use real mobile device as transport adapter.
Create Mobile application as part of ATF infrastrucure. 
Mobile application may use [sdl android liibrary](https://github.com/smartdevicelink/sdl_android)
for communicating with SDL and TCP connection for communication with ATF.

Mobile application(Mobile transport adapter) should povide ATF side such RPCs:
 - ConnectToSDL(transport)
 - RemoveConnection(connection_id)
 - GetListOfAvailableTransports()
 - SendData(connection_id, data)
 
ATF shoud be able to connect to multiple Mobile transport adapters and provide to test engeneer ability to use any of them. 

ATF should provide such API to test engeneer: 
 - ConnectToSDL(device, connection type)
 - RemoveConnection(connection)
 - SendRawData(connection)
 - GetListOfAvailableDevices()
 - GetDeviceInfo(device)
 
_СonnectToSDL_ should return connection object.
Connction object should provide ability to create sessions on it. Session interface should not be changed.  

In case if mobile device is absent, ATF should be able to test SDL via TCP connection (as it does now).

Hight Level relationship diagram: 
[!Hight Level relationship diagram](/assets/nnnn-atf-additional-transports/atf-additional-transports.png)

## Potential downsides

This solution is not scalable. 
To run multiple scripts that test transport sumutaniously required adding fisical mobile device. 

## Impact on existing code

Impact on ATF internal structure.
May impact some scripts that test multiple connection.  

## Alternatives considered

#### Avoid automatic transport testing

 In SDL transport implemented throw adapters,
 so porting SDL on customer harware requires rewriting transport adapters from scratch.
 And any transport testing that is done on Ubuntu Linux x86 becomes not actual.
 But missing autmatic transport testing make not possible to test buisness logic that is related to transport switch. 
 And this approach provide possibility event testing SDL on custom transports.
 
 #### Emulate transports
 
 Emulating USB\Bluetooth transports is probably possible, but it requires some research and development and PoC project. 
 Also emulating transport won't allow performing automatic testing of SDL on custom headnits,
 so any testing that will be done on Ubuntu Linux x86 becomes not actual. 
 
 
