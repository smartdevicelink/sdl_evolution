

# Expand Mobile putfile RPC

* Proposal: [SDL-NNNN](NNNN-filename.md)
* Author: [Martin(Lingxiu) Chen]( https://github.com/lchen139)
* Status: **Awaiting review**
* Impacted Platforms: RPC, Core, iOS, Android

## Introduction

This proposal is to expand putfile RPC to incorporate it with unreliable wireless medium.
This proposal seeks to enhance the reliability of large data transfers to the Head Unit by introducing a field for CRC in the putfile RPC.

## Motivation

Current SDL design assumes that the transport medium is 100% reliable and all data will be correctly retrieved by the receiver. In reality, however, not every wireless medium is guaranteed to be 100% error free. Errors might be caused by hardware design failure, hardware driver issues, or environmental noise interference. Theoretically, transport layers will have retransmission mechanisms to handle all types of errors, but wireless mediums like bluetooth can’t have the same protection, due to compatibility issues with major phone manufacturers (Samsung, HTC, Huawei, .etc).  

The primary motivation of this proposal is to allow developers to use CRC checksum to guarantee data integrity in error sensitive scenarios (such as the transfer of a large binary file).


## Proposed solution

The proposed solution introduces an optional 4-byte CRC checksum in putfile RPC. 32 bit CRC (CRC32) can check data integrity up to 512 Mbit. If the CRC check fails, SDL core will request to retry for the same putfile operation by sending back the result code “CORRUPTED_DATA”. CRC calculations and retransmissions should be handled by the file manager inside the mobile library. This file manager should be modified to accept a CRC flag passed by application logic.

## Detailed design

Addition to MOBILE API:
```
<enum name="Result" internal_scope="base">
    <element name="CORRUPTED_DATA">
      <description>The data sent failed to pass CRC check in receiver end</description>
    </element>
</enum>


  <function name="PutFile" functionID="PutFileID" messagetype="request">

    
<param name="CRC" type="Long" minvalue="0" maxvalue="4,294,967,295" mandatory="false">
      <description> Additional CRC32 checksum to protect data integrity up to 512 Mbits . </description>
    </param>

  </function>
  
 
  <function name="PutFile" functionID="PutFileID" messagetype="response">

    <param name="resultCode" type="Result" platform="documentation">
      <description>See Result</description>
      <element name=" CORRUPTED_DATA "/>
    </param>

  </function> 
```
### Background for current framework:
When a large binary file needs to be transferred, the app breaks the file into smaller chunks and sends these chunks to the Head Unit via putfile. If the SDL core on the Head Unit receives the chunk successfully, it will respond with a result code of SUCCESS and append that chunk to the binary cache file. Otherwise, the SDL core will respond with a result code of “INVALID_DATA" and that chunk will not be appended to the binary file cache. 

### Change:
Mobile libraries should have a file manager included to support CRC calculation and data retransmission. This file manager should be modified to allow the CRC flag passed by application logic. If the CRC flag is enabled, the file manager will calculate the CRC checksum automatically and send a putfile request with the CRC checksum. Once the SDL core receives the putfile request with the CRC checksum, the SDL core will have to calculate the CRC checksum and compare it with the CRC checksum provided in the putfile request. If the two checksums do not match, then the SDL core will know that the received data has been corrupted and will provide a response of “CORRUPTED_DATA” to the application file manager. When the application file manager receives a “CORRUPTED_DATA” response, it should resend the same packet of data. The file manager should give up retransmission and log an error after a certain number of retries (e.g. 5). Once the CRC checksum is enabled, the Mobile Library generates a CRC32 checksum for the data chunk provided by the App. Then, the mobile library sends this data chunk along with the CRC32 checksum to the SDL core.  On the receiving end, the SDL core will have to calculate the CRC checksum and compare it with the CRC checksum provided by mobile library. If the two checksums do not match, then the SDL core will know that the received data has been corrupted and will request the mobile library to resend the data along with the checksum. The SDL core will have a number limit for the same data packet retransmission. If the retry limit is reached, the SDL core will provide a response of “CORRUPTED_DATA” to the application. The app may have a logic resending same chunk of data or logging an error and giving up.

### Impact on existing code
- New parameters to putfile request and response (RPC change) 
- Send "CORRUPTED_DATA" instead of "INVALID_DATA" to app.(SDL core only change)
- File Manager inside mobile Library generates CRC32 checksum and handles file retransmission (IOS, Android change). 
- SDL core generates CRC32 checksum based on received putfile data if CRC checksum option is enabled. (SDL core only change)
	
  


## Alternatives considered

Similar to the TCP design, the CRC checksum is placed at frame header ([SmartDeviceLink Protocol level](https://github.com/smartdevicelink/protocol_spec#22-version-2-frame-header)). The CRC checksum calculation is based on both the frame header and frame payload.

### Pros:
- Covers both headers and payloads for all SDL communication
- Research paper ["When The CRC and TCP Checksum Disagree"](conferences.sigcomm.org/sigcomm/2000/conf/paper/sigcomm2000-9-1.pdf) suggests variety error sources in internet will increase error rate from one packets out of few millions to one packets out of few thousand in TCP/IP level.  This approach provides additional robustness for overall system. 


### Cons:
- Great impact for SDL protocol. Major revision for SDL protocol is required.



##Q&A about Downside
Q: How this CRC32 affects putfile performance?
A: CRC32 checksum calculation uses table look-up method. Lib will store pre-calculate CRC32 value and directly assign to request. It should not consume too much time. (Implementation example: https://opensource.apple.com/source/xnu/xnu-1456.1.26/bsd/libkern/crc32.c) 
Q: How this proposal affects current framework?
A: This proposal introduces optional parameters. If old framework does not support this parameter, it will ignore this parameter.

