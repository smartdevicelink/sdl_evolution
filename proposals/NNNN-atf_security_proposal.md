# Security ATF feature

* Proposal: [SDL-NNNN](NNNN-atf_security_proposal.md)
* Author: [Alexander Kutsan](https://github.com/LuxoftAKutsan)
* Status: **Awaiting review**
* Impacted Platforms: [ATF]

## Introduction

This proposal describes support of security sessions in ATF (Automated Test Framework).
ATF should be able to test SDL security feature.

Main ATF features for checking SDL security are:
 - Support of secure SDL sessions;
 - Support of testing broken handshake;
 - Support of sending raw data in secure channel;
 - Support of expected secure requests\responses\notifications;
 - Support Transport Layer Security (TLS) and Datagram Transport Layer Security (DTLS). 

## Motivation

Motivation of this proposal is to create ability of coverage the secure sessions. Which is the most important not covered part of SDL functionality.

Manual testing of security SDL feature is slow and expensive. Also there is a big probability of error during manual testing.
Testing automatization of all SDL use cases is the best option to be sure that new code does not break SDL functionality.

ATF has possibility to cover almost all SDL use cases with automatic testing. But there is still some functionality that remains uncovered my ATF:
 - Bluetooth transport;
 - USB transport;
 - Security feature;
 - Audio\Videostreaming (partially supported).
 
## Proposed solution

Add new APIs in ATF:
 - connection.StartSecureSession;
 - session.SendEncryptedRPC;
 - session.ExpectEncryptedResponse;
 - session.ExpectEncryptedNotification;
 - session.SendPacket; 
 - session.ExpectPacket;
 
[mobile_session.lua](https://github.com/smartdevicelink/sdl_atf/blob/master/modules/mobile_session.lua) and 
[mobile_session_impl.lua](https://github.com/smartdevicelink/sdl_atf/blob/master/modules/mobile_session_impl.lua) should be extended with secure session interfaces. 

Should be added new ini file option: `SecurityProtocol`\
Should be added new command line option: `security_protocol`\
In case if this option is missed, use TLS security by default.

### Detailed design

#### New component: 
Will be added new component : *SecurityManager* 

Responsibility of SecurityManager :
 - Manage digital certificates;
 - Manage TLS or DTLS protocols; 
 - Handle Secure Sockets Layer (SSL) context;
 - Provide interface for encryption\decryption;
 - Be able to perform a handshake.

#### New APIs: 

##### connection.StartSecureSession:
###### Description
 Start secure session :
  1. Send StartSession with `encrypted flag = true`;
  2. Perform TLS/DTLS handshake; 
  3. Expect StartSessionAck.
  
  This is a blocking call. Will block current execution until session won't be established or failed.
###### Arguments:
  - protocol (if missed, used one from console or ini file options).
###### Return value:
  - session object.
  
##### session.SendEncryptedRPC:
###### Description
 Send encrypted RPC:
  1. Encrypts payload and binary data;
  2. Send RPC to SDL;
###### Arguments:
  - function name - stringified RPC name;  
  - arguments  - lua table with arguments of RPC (payload);
  - file name - path to file with binary data.
###### Return value:
  - correlation ID of sent request.

##### session.ExpectEncryptedResponse:
###### Description
 Add expectation to encrypted response with specific correlation_id.
###### Arguments :
  - correlation_id - correlation ID;
  - data  - expected payload (decrypted).
###### Return value :
  - expectation.
  
##### session.ExpectEncryptedNotification:
###### Description
 Add expectation to encrypted notification.
###### Arguments:
  - function_name - expected notificaiton name
  - data - expected payload (decrypted).
###### Return value:
  - expectation.
  
##### session.SendPacket:
###### Description
Send Raw Packet for testing wrong TLS handshake.
###### Arguments:
  - data - bytes to send.
###### Return value :
  N\A
  
##### session.ExpectPacket :
###### Description
Expect custom packet for checking TLS Handshake.
###### Arguments :
  - data - bytes that ATF expects.
###### Return value :
  - expectation.

## Potential downsides

- session.ExpectPacket - very common interface, it might need more deep analysis of input data. Also present possibility to reduce efficiency of the whole ATF system. This interface also allows tester to check any incoming data from SDL.

- session.SendPacket - very low level interface, it might require a lot of additional complicated logic for constructing bytes to send in script. This interface also allows tester to send any data.

## Impact on existing code

Should be impacted only ATF code.
If during implementation will be found some blocker issues in SDL, they should be fixed.

## Alternatives considered
Manual testing with using mobile application and Web HMI. 
