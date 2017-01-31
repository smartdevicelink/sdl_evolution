

# Expand Mobile putfile RPC

* Proposal: [SDL-NNNN](NNNN-filename.md)
* Author: [Martin(Lingxiu) Chen]( https://github.com/lchen139)
* Status: **Awaiting review**
* Impacted Platforms: RPC, Core, iOS, Android

## Introduction

This proposal is to expand putfile RPC to incorporate with unreliable wireless medium.
This proposal seeks to enhance the reliability of large data transfers to the Head Unit by introducing a field for CRC in the putFile RPC. 

## Motivation

Current SDL design assumes that the transport medium is 100% reliable and all data will be correctly retrieved by the receiver. 
However, not every wireless medium is guaranteed to be 100% error free. This error might be introduced by hardware design failure, hardware driver issue and environmental noise interference. Theoretically, transport layer will have retransmission mechanism to handle all this kinds of errors. But wireless mediums like bluetooth can’t have this protection due to compability issue with major phone manufacturers (Samsung, HTC, Huawei, .etc).  

The primary motivation of this proposal is to allow developer use CRC checksum to guarantee data integrity in error sensitive scenario (Transfer large binary file).



## Proposed solution

Proposed solution introduces an optional 4-byte CRC checksum in putfile RPC. 32 bit CRC(CRC32) can check data integrity up to 512 Mbit. If the CRC check fails, SDL core will request retry for the same putfile operation by sending back  “CORRUPTED_DATA” result code. CRC calculation and retransmission should be handled by file manager inside mobile library. This file manager should be modified to accept a CRC flag passed by application logic.

## Detailed design

Addition to MOBILE API:
```
<enum name="Result" internal_scope="base">
    <element name="CORRUPTED_DATA">
      <description>The data sent continuously failed to pass CRC check in receiver end</description>
    </element>
</enum>


  <function name="PutFile" functionID="PutFileID" messagetype="request">

    
<param name="CRC" type="Long" minvalue="0" maxvalue="4,294,967,295" mandatory="false">
<param name="CRC" type="Boolean" mandatory="false">
      <description> This parameter enables Aadditional CRC32 checksum to protect data integrity up to 512 Mbits . If this parameter is not specified, the value of this parameter should be treated as false </description>
    </param>

  </function>
  
 
  <function name="PutFile" functionID="PutFileID" messagetype="response">

    <param name="resultCode" type="Result" platform="documentation">
      <description>See Result</description>
      <element name=" CORRUPTED_DATA "/>
    </param>

  </function> 
```
Background for current framework:
When a large binary file needs to be transferred, the app breaks the file into smaller chunks and sends these chunks to the Head Unit via putFile. If the SDL core on the Head Unit receives the chunk successfully, it will respond with a result code of SUCCESS and append that chunk to the binary cache file. Otherwise, SDL core will responds with a result code of “INVALID_DATA" and that chunk will not be appended to the binary file cache. 

Change:
Mobile library should have a file manager included to support CRC calculation and data retransmission. This file manager should be modified to allow CRC flag passed by application logic. If CRC flag is enabled, file manager will calculate CRC checksum automatically and send putfile request with CRC checksum. Once SDL core receives putfile request with CRC checksum, SDL core will have to calculate the CRC checksum and compare it with the CRC checksum provided in the putFile request. If the two checksums do not match then SDL core will know that the received data has been corrupted and will provide a response of “CORRUPTED_DATA” to the application file manager. When the application file manager receives “CORRUPTED_DATA” response, it should resend the same packet of data. File manager should give up retransmission and log an error after certain number of retries (e.g. 5).Once CRC checksum is enabled, Mobile Library generates CRC32 checksum for data chunk provided by App. Then, mobile library sends this data chunk along with CRC32 checksum to SDL core.  In receiver end, SDL core will have to calculate the CRC checksum and compare it with the CRC checksum provided by mobile library. If the two checksums do not match then SDL core will know that the received data has been corrupted and will request mobile library to resend data along with checksum. SDL core will have a number limit for same data packet retransmission. If retry limit is reached, SDL core will provide a response of “CORRUPTED_DATA” to the application. The app may have a logic resending same chunk of data or logging an error and giving up.


## Impact on existing code
		1. New parameters to putfile request and response (RPC change) 
		2. Send "CORRUPTED_DATA" instead of "INVALID_DATA" to app.(SDL core only change)
		3. File Manager inside mMobile Library generates CRC32 checksum and handles file retransmission based on putfile payload data (IOS, Android change). 
		4. SDL core generates CRC32 checksum based on received putfile data if CRC checksum option is enabled. (SDL core only change)
		5. Mobile Library and SDL core should have retransmission mechanism for CRC check failure case. (SDL core, IOS and Android change)
  


## Alternatives considered

NO

