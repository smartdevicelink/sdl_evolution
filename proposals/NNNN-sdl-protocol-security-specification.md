# SDL Protocol Security Specification

* Proposal: [SDL-NNNN](NNNN-sdl-protocol-security-specification.md)
* Author: [Kujtim Shala](https://github.com/smartdevicelink/kshala-ford)
* Status: **Awaiting review**
* Impacted Platforms: [Core / iOS / Java Suite / JavaScript Suite / Protocol]

## Introduction

This proposal adds the documentation and specification around protected communication, encryption and handshake to the SDL protocol specification. It is a collaborated effort with Ford and Luxoft to protect the implemented SDL security from unexpected changes and to allow SDL Evolution proposals to improve it.

## Motivation

SDL has used protected services since the start of mobile navigation apps. Unfortunately the protocol specification doesn't contain a section around establishing a protected service with handshake and encryption. This leads to contradictory implementations in SDL Core and the app libraries. Recently we have identified a number of bugs in SDL Core and the app libraries which break with protected communication. These issues are difficult to address with the SDLC as there is no specification around protected communication that Core and the app libraries should follow. In order to resolve the issues there must be a proper specification within SDLC around protected communication.

## Proposed solution

The solution is to provide a new section into the protocol spec around security and protection. The baseline for this section is reverse engineered from SDL Core and the currently implemented behavior of the security manager but also existing documentation from SDL Core and the app libraries.

### Change 1: Update Frame Info Fields

Because TLS handshake uses a Frame Info field for Single frames the spec must be changed accordingly:

<table width="100%">
  <tr>
    <th>Field</th>
    <th>Size</th>
    <th>Description</th>
  </tr>
  <tr>
    <td>Frame Info</td>
    <td>8 bit</td>
    <td>
      ...<br>
      <b>Frame Type = 0x01 (Single Frame)</b><br>
      <s>0x00 - 0xFF Reserved</s><br>
      0x00 Single Frame<br>
      0x01 - 0xFF Reserved<br>
      ...
    </td>
<table>

### Change 2: Add New Section

The following section should be added to the protocol spec:

## 4.7 Secured Communication

It is possible to establish a secured and encrypted communication with the system by setting the frame header encryption flag to `1` when starting a new service. If the authentication was successful, the system will reply with a `StartService ACK` frame with the encryption flag also set to `1` indicating that encrypted data is now accepted. If the authentication fails for some reason the system will reset the TLS connection and return a `StartService NAK` frame.

### 4.7.1 Authentication

The below diagram shows the sequence of how the TLS handshake exchanges certificates to compute the master secret.

![TLS Handshake activity diagram](../assets/proposals/NNNN-sdl-protocol-security-specification/tls-handshake.png)

The authentication is done using TLS handshake. The TLS handshake process is defined by TLS and is not part of the SDL protocol. The handshake is designed as a client server communication which is configurable in the system settings. An application can take the role of a server where the system is the client or vice versa. This setting is not dynamic which means an SDL integrator must agree on one setup and avoid Client/Client or Server/Server connections. The client entity will initiate a TLS handshake with the corresponding security manager of the server. The client will do this only if the server was not authenticated before in the current transport connection. According to the TLS handshake process the peer certificate can be omitted for the server but it's required for the client.

The system can be configured to support one encryption method. The following methods are supported:

- SSLv3
- TLSv1
- TLSv1.1
- TLSv1.2
- DTLSv1

Dependent of the role the system has to initiate with the corresponding server method or client method.

### 4.7.1 Security Query

The TLS Payload is sent in a binary header. The size is 12 bytes which matches the size of the RPC Payload Binary Header.

#### 4.7.1.1 Binary Query Header

<table width="100%">
  <tr>
    <th width="25%">Byte 1</th>
    <th width="25%">Byte 2</th>
    <th width="25%">Byte 3</th>
    <th width="25%">Byte 4</th>
  </tr>
  <tr>
    <td>Query Type</td>
    <td colspan="3" align="center">Query ID</td>
  </tr>
  <tr>
    <td colspan="4" align="center">Sequential Number</td>
  </tr>
  <tr>
    <td colspan="4" align="center">JSON Size</td>
  </tr>
</table>

#### 4.7.1.2 Binary Header Fields

<table width="100%">
  <tr>
    <th>Field</th>
    <th>Size</th>
    <th>Description</th>
  </tr>
  <tr>
    <td>Query Type</td>
    <td>8 bit</td>
    <td>
      0x00 Request <br>
      0x01 - 0x0F Reserved<br>
      0x10 Response<br>
      0x11 - 0x1F Reserved<br>
      0x20 Notification<br>
      0x21 - 0xFE Reserved<br>
      0xFF Invalid Query Type
    </td>
  </tr>
  <tr>
    <td>Query ID</td>
    <td>24 bit</td>
    <td>
      0x000001 Send Handshake Data<br>
      0x000002 Send Internal Error<br>
      0x000003 - 0xFFFFFE Reserved<br>
      0xFFFFFF Invalid Query ID
    </td>
  </tr>
  <tr>
    <td>Sequential Number</td>
    <td>32 bit</td>
    <td>
      Message ID can be set by the Mobile libraries to track security messages.
      The system uses the same Message ID when replying to the query allowing the mobile to correlate messages.
    </td>
  </tr>
  <tr>
    <td>JSON Size</td>
    <td>32 bit</td>
    <td>The size of the JSON data following the binary query header.</td>
  </tr>
</table>

#### 4.7.1.3 Hybrid Query Payload

The security query is able to contain JSON data as well as binary data. During the handshake the TLS handshake data is sent as binary data. In case of an error, a notification is sent with an error code and error message as JSON data. See "Error handling" section for details.

<table width="100%">
  <tr><td align="center">Binary Query Header</td></tr>
  <tr><td align="center">JSON Data</td></tr>
  <tr><td align="center">Binary Data</td></tr>
</table>

### 4.7.2 Start Service 

The issuer sends a control frame as already described in Section 3 with encryption flag set to `1`.

### 4.7.3 Handshake frames

The system will initiate a TLS handshake to authenticate the application where the system's role will be the client while the application's role will be the server. The system will do this only once if the application was not authenticated before in the current transport connection. The TLS handshake data is always sent in single frames. The service type for TLS handshake is the control service. 

#### 4.7.3.1 SDL Protocol Frame Header

The following SDL frame header is used for every frame related to TLS handshake.

<table width="100%">
  <tr>
    <th colspan="8">SDL Protocol Frame Header</th>
  <tr>
  <tr>
    <th>Version</th>
    <th>E</th>
    <th>Frame Type</th>
    <th>Service Type</th>
    <th>Frame Info</th>
    <th>Session ID</th>
    <th>Data Size</th>
    <th>Message ID</th>
  </tr>
  <tr>
    <td>Max major version supported<br>by module and application</td>
    <td>no</td>
    <td>Single Frame</td>
    <td>Control Service</td>
    <td>Single Frame Info</td>
    <td>Assigned Session ID</td>
    <td>
      Binary Query Header +<br>
      JSON Data size + <br>
      Binary Handshake Data size
    </td>
    <td>Enumerated number</td>
  </tr>
  <tr>
    <td>0xN</td>
    <td>0b0</td>
    <td>0b001</td>
    <td>0x00</td>
    <td>0x00</td>
    <td>0xNN</td>
    <td>0xC + 0xNNNNNNNN + 0xNNNNNNNN</td>
    <td>0xNNNNNNNN</td>
  </tr>
</table>

#### 4.7.3.2 Query Header

The following query header is used by the system and the application to send TLS handshake data.

<table width="100%">
  <tr>
    <th colspan="4">Binary Query Header</th>
  <tr>
  <tr>
    <th>Query Type</th>
    <th>TLS Message Type</th>
    <th>Sequential Number</th>
    <th>JSON Size</th>
  </tr>
  <tr>
    <td>Request</td>
    <td>Send Handshake Data</td>
    <td>Any number to be used to correlate query messages</td>
    <td>Zero</td>
  </tr>
  <tr>
    <td>0x00</td>
    <td>0x000001</td>
    <td>0xNNNNNNNN</td>
    <td>0x00000000</td>
  </tr>
  <tr>
    <th colspan="4">Binary TLS Handshake Data</th>
  </tr>
</table>

### 4.7.4 Start Service ACK

Once the handshake is completed and the system has verified the application, the system returns a `StartService ACK` frame with the encryption flag set to `1`.

### 4.7.5 Error handling

If an error occurs during the TLS handshake a notification is sent with an error code and error text as JSON data. Additionally the error code is added as a single byte binary data.

#### 4.7.5.1 Query Header

The following query header is used by the system and the application to send error messages.

<table width="100%">
  <tr>
    <th colspan="4">Binary Query Header</th>
  <tr>
  <tr>
    <th>Query Type</th>
    <th>TLS Message Type</th>
    <th>Sequential Number</th>
    <th>JSON Size</th>
  </tr>
  <tr>
    <td>Notification</td>
    <td>Send Internal Error</td>
    <td>Any number to be used to correlate query messages</td>
    <td>Size of the JSON data</td>
  </tr>
  <tr>
    <td>0x20</td>
    <td>0x000002</td>
    <td>0xNNNNNNNN</td>
    <td>0xNNNNNNNN</td>
  </tr>
  <tr>
    <th colspan=4">JSON Data</th>
  </tr>
  <tr>
    <th colspan=4">Binary Data: Single Byte Error Code</th>
  </tr>
</table>

#### 4.7.5.2 JSON Data structure

<table width="100%">
  <tr>
    <th>Key</th>
    <th>Description</th>
  </tr>
  <tr>
    <td>id</td>
    <td>A decimal value representing an Error code.</td>
  </tr>
  <tr>
    <td>text</td>
    <td>A string describing the error.</td>
  </tr>
</table>

#### 4.7.5.3 Error codes

<table width="100%">
  <tr>
    <th>Error code</th>
    <th>Byte</th>
    <th>Value</th>
    <th>Description</th>
  </tr>
  <tr>
    <td>ERROR_SUCCESS</td>
    <td>0x00</td><td>0</td>
    <td>Internal Security Manager value</td>
  </tr>
  <tr>
    <td>ERROR_INVALID_QUERY_SIZE</td>
    <td>0x01</td><td>1</td>
    <td>Wrong size of query data</td>
  </tr>
  <tr>
    <td>ERROR_INVALID_QUERY_ID</td>
    <td>0x02</td><td>2</td>
    <td>Unknown Query ID</td>
  </tr>
  <tr>
    <td>ERROR_NOT_SUPPORTED</td>
    <td>0x03</td><td>3</td>
    <td>SDL does not support encryption</td>
  </tr>
  <tr>
    <td>ERROR_SERVICE_ALREADY_PROTECTED</td>
    <td>0x04</td><td>4</td>
    <td>Received request to protect a service that was protected before</td>
  </tr>
  <tr>
    <td>ERROR_SERVICE_NOT_PROTECTED</td>
    <td>0x05</td><td>5</td>
    <td>Received handshake or encrypted data for not protected service</td>
  </tr>
  <tr>
    <td>ERROR_DECRYPTION_FAILED</td>
    <td>0x06</td><td>6</td>
    <td>Decryption failed</td>
  </tr>
  <tr>
    <td>ERROR_ENCRYPTION_FAILED</td>
    <td>0x07</td><td>7</td>
    <td>Encryption failed</td>
  </tr>
  <tr>
    <td>ERROR_SSL_INVALID_DATA</td>
    <td>0x08</td><td>8</td>
    <td>SSL invalid data</td>
  </tr>
  <tr>
    <td>ERROR_HANDSHAKE_FAILED</td>
    <td>0x09</td><td>9</td>
    <td>In case of all other handshake errors</td>
  </tr>
  <tr>
    <td>INVALID_CERT</td>
    <td>0x0A</td><td>10</td>
    <td>Handshake failed because certificate is invalid</td>
  </tr>
  <tr>
    <td>EXPIRED_CERT</td>
    <td>0x0B</td><td>11</td>
    <td>Handshake failed because certificate is expired</td>
  </tr>
  <tr>
    <td>ERROR_INTERNAL</td>
    <td>0xFF</td><td>255</td>
    <td>Internal error</td>
  </tr>
  <tr>
    <td>ERROR_UNKNOWN_INTERNAL_ERROR</td>
    <td>0xFE</td><td>254</td>
    <td>Error value for testing</td>
  </tr>
</table>

#### 4.7.5.4 Actions in case of an error

In case of an error, the system and the application should reset the active SSL connection of the current transport connection. This impacts already established secured service sessions as all of them will be closed. The application will need to restart all services which require protection.

## Potential downsides

Identifying potential downsides is difficult as this proposal adds specifications and documentation to the existing implementation. The downside of accepting this proposal is the effort that's required to review and audit the implementations of every SDL platform.

## Impact on existing code

SDL Core impact is very low as most of the specification is reverse engineered from it. Still the following items impact SDL Core:
1. A further review is required to improve error handling.
2. Error codes around handshake failed or invalid/expired cert are new and should be used by SDL Core if these errors occur.
3. A known issue should be resolved in that SDL Core doesn't respond with NAK if the application sends an error frame.

Compared to Core, more effort is required on the SDL app libraries. Their implementation is incomplete and contradicting to SDL Core and the protocol. For instance the sdl_ios library uses the RPC Payload header instead of a Query Header to send TLS handshake data. The structure of these headers don't align in the first byte (RPC Payload 4 bit, Query Header 8 bit).

The mobile libraries need to add the Security Query and the Binary Query Header and serialize SDL protocol frames using this query. It is recommended to add a new class called `SDLProtocolSecurity` to all libraries which implement this security specification. This is only a recommendation and decisions to implementation details are to be made by the code donator and the SDLC Project Maintainer.

## Alternatives considered

The author couldn't think of other alternatives to add a security specification to SDL. There are security enabled vehicles on the road which limit the abilities to design a new specification. However with the protocol specification version and this security section it is possible to improve the security with a future version.
