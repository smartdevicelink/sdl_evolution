# DTLS encryption

* Proposal: [0024-DTLS-encryption.md]
* Author: Luxoft/FORD
* Status: Open
* Impacted Platforms: protocol
[0024-DTLS-encryption.md]: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0024-DTLS-encryption.md

## Introduction

This is proposal is to use DTLS (Datagram Transport Layer Security) instead of TLS for protected service handshake, encryption and decryption.

## Motivation

It makes sense for services to be protected. The DTLS protocol provides communications privacy for datagram protocols. The protocol allows client/server applications to communicate in a way that is designed to prevent eavesdropping, tampering, or message forgery. The DTLS protocol is based on the Transport Layer Security (TLS) protocol and provides equivalent security guarantees. Datagram semantics of the underlying transport are preserved by the DTLS protocol.

## Proposed solution

SDL must ignore malformed packet during processing of encrypted payloads using DTLS protocol.   
In case the value of "Protocol" param is DTLSv1.0 at [Security Manager] section of .ini file
and mobile app successfully opens encrypted service (TLS handshake was succesfull)
and at least one of encrypted packet is malformed due to any reason (per)
SDL must:   
ignore this malformed packet
search for the next valid header   
continue processing of the next valid encrypted packet   

SDL must support DTLS encryption for protected services.
In case the value of "Protocol" param is DTLSv1.0 at [Security Manager] section of .ini file.   
SDL must: perform protected service handshake, encryption and decryption using DTLSv1.0 protocol.   
All related to Security feature requirements must be applicable for DTLSv1.0 protocol as well as for TLSv1.2.   

The "Protocol" parameter at .ini file of [Security Manager] section defines the version of encryption protocol and must be used for:   
a) protected service handshake,   
b) encryption   
c) decryption by SDL.   

## Detailed design
TBD

## Impact on existing code
TBD

## Alternatives considered
TBD
