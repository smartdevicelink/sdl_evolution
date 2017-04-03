# DTLS encryption

* Proposal: [SDL-NNNN](nnnn-dtls-encryption.md)
* Author: [Markos Rapitis](https://github.com/mrapitis)
* Status: **Awaiting review**
* Impacted Platforms: Core


## Introduction

This proposal is to add DTLS (Datagram Transport Layer Security) to SDL core.   SDL core will utilize the DTLS communications protocol as a preferred solution when sending encrypted data over protected services (such audio 0x0a  and video 0x0b ) including the handshake, encryption and decryption processes.

## Motivation

Currently SDL core offers the capability to utilize the TLS v1.2 communications protocol to establish protected services for activities like video and audio streaming.  While TLS v1.2 is an exceptional security protocol, it unfortunately has dependence on packet ordering and lacks the ability to recover from lost packets.  Since many OEM hardware implementations cannot 100% guarantee packet delivery and ordering, TLS v1.2 does not provide a sufficient capabilities for the utilization of protected services. 
DTLS is an implementation of TLS over a datagram protocol.  DTLS is similar to TLS intentionally except that DTLS has to solve two large problems that OEM headunits may face -- packet loss and packet reordering. DTLS implements three important features to solve these problems:

 - A packet retransmission strategy 
 - Assigning sequence number within the handshake process
 - Replay detection for added security


## Proposed solution

 Add capability to SDL core to utilize the DTLS v1.0 communications protocol. 

 - Add a ‘DTLSv1.0’ parameter to the ‘[Security Manager]’ section of the SmartDeviceLink.ini file. 
 
 - If the ‘DTLSv1.0’ has been specified in the .ini file, SDL core will open protected services using the DTLS v1.0 protocol including the following:
	 - Perform DTLS v1.0 handshake 
	 - Encryption
	 - Decryption

 - Fortunately from an implementation standpoint, since SDL core is currently utilizing the OpenSSL library all necessary supporting API’s for DTLS v1.0 already exists to leverage the communications protocol. 
 - From a SDL core code perspective, the existing SDL core security initialization process will make use of the following additional OpenSSL API: 
 
	 - DTLSv1_server_method()
	 - DTLSv1_client_method()


##Potential downsides
None

## Impact on existing code
Impact on existing code will be minimal as SDL core already makes use of the OpenSSL library and already offers some existing security protocols inside of the library.

## Alternatives considered
TLS v1.2, however given the downsides previously mentioned with this protocol, DTLS v1.0 suits SDL's needs best.
