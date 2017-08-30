# Feature name

* Proposal: [SDL-NNNN](NNNN-atf_security_proposal.md)
* Author: [Alexander Kutsan](https://github.com/LuxoftAKutsan)
* Status: **Awaiting review**
* Impacted Platforms: [ATF]

## Introduction

This proposal describes support of security sessions in ATF(Automated test framework).
ATF should be able to test security SDL feature.

Main ATF features for checking security feature:
 - Support of secure sessions
 - Support of testing broken handshake
 - Support of sendng raw data in secure chanel
 - Support expecting secure requests\responses\notifiations
 - Support TLS, DTLS

## Motivation
Manual testing is slow, and expensive. Also there are big probability of error during manual testing.\
Testing automatisation of all SDL use cases is best option to be sure that new code does not brerakes SDL functionality.

ATF is able to cover almoust all SDL use cases with automatic testing. 
The only things that is not supported by ATF :
 - Bluetooth transport
 - USB transport
 - Security feature
 - Audio\Videostreaming (partialy supported) 
 
Motivation of this proposal is to crete ability to cover most important not covered part of SDL functionality - secure sessions

## Proposed solution

Add new APIs in ATF:
 - connection.StartSecureSession
 - session.SendEncryptedRPC
 - session.ExpectEncryptedResponse
 - session.ExpectEncryptedNotification
 - session.SendPacket 
 - session.ExpectPacket
 
[mobile_session.lua](https://github.com/smartdevicelink/sdl_atf/blob/master/modules/mobile_session.lua) and 
[mobile_session_impl.lua](https://github.com/smartdevicelink/sdl_atf/blob/master/modules/mobile_session_impl.lua) should be extended with secure session interfaces. 

Should be added new ini file option : `SecurityProtocol`
Should be added new command line option : `secutity_protocol`
In case if this option missed, use TLS by default.

### Detailed design

#### New components : 
Will be added new component : *SecurityManager* 

Responsibility of SecurityManager :
 - Manage certificates
 - Manage TLS or DTLS
 - Handle ssl context
 - provide interface for crypting\decrypting
 - Be able to perform a handshake

#### New APIs: 

##### connection.StartSecureSession :
###### Description
 Start secure session :
  1. Send StartSession with `encrypted flag = true`
  2. perform TLS handshake 
  3. Expect StartSessionAck 
  
  This is blocking call. and will block execution until session won't be established or failed.
###### Arguments :
  - protocol ( if missed, used one from console or ini file options)
###### Return value :
  - session object
  
##### session.SendEncryptedRPC :
###### Description
 Send encrypted RPC:
  1. Encrypts payload and binary data
  3. Send RPC to SDL
###### Arguments :
  - function name - stringified RPC name  
  - arguments  - lua table with arguments of RPC (payload)
  - file name - pth to file with binary data
###### Return value :
  - correlation id of sent request

##### session.ExpectEncryptedResponse :
###### Description
 Add expectation to encrypted response with specific correlation_id
###### Arguments :
  - correlation_id - correlation id
  - data  - expected payload (decrypted)
###### Return value :
  - expectation
  
##### session.ExpectEncryptedNotification :
###### Description
 Add expectation to encrypted notification
###### Arguments :
  - data - expected payload (decrypted)
###### Return value :
  - expectation
  
##### session.SendPacket :
###### Description
Send Raw Packet for testing wrong TLS handshake
###### Arguments :
  - data -  bytes to send
###### Return value :
  N\A
  
##### session.ExpectPacket :
###### Description
Expect custom packet for checking TLS Handshake 
###### Arguments :
  - data -  bytes that ATF expects
###### Return value :
  expectation

## Potential downsides

- session.ExpectPacket - very common interface it may need deep analysing of input data and reduce efficience, also allows tester to send ant data.

- session.SendPacket - very low level interface, may require a lot of additional complicated logic of constructing bytes to send in scrypt

## Impact on existing code

Should be imcacted only ATF code.
If during implementation will be founded blocker issues in SDL, it should be fixed.

## Alternatives considered
Using mobile application and manual testing. 
