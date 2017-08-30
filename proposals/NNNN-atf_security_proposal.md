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
 - session.SendEncryptedRequest
 - session.ExpectEncryptedResponse
 - session.ExpectEncryptedNotification
 - session.SendPacket 
 - ExpectPacket
 
## Potential downsides

N\A 

## Impact on existing code

Should be imcacted only ATF code.
If during implementation will be founded blocker issues in SDL, it should be fixed.

## Alternatives considered
Using Mobile application and manual testing. 
