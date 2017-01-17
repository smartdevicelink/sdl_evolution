
# Expand Mobile putfile RPC

* Proposal: [SDL-NNNN](NNNN-filename.md)
* Author: [Martin(Lingxiu) Chen]( https://github.com/lchen139)
* Status: **Awaiting review**
* Impacted Platforms: RPC, Core, iOS, Android

## Introduction

This proposal is to expand putfile RPC to incorporate with unreliable wireless medium.

## Motivation

Currently SDL design lies in assumption that transfer medium is 100% reliable and all data will be retrieved correctly in receiver end. However, not every wireless medium is guaranteed to be 100% error free. This error might be introduced by hardware design failure, hardware driver issue and environmental noise interference. Theoretically, transport layer will have retransmission mechanism to handle all this kinds of errors. But wireless mediums like bluetooth can’t have this protection due to comp ability issue with major phone manufacturers (Samsung, HTC, Huawei, .etc).  

The primary motivation of this proposal is to allow developer use CRC checksum to guarantee data integrity in error sensitive scenario (Transfer large binary file).


## Proposed solution

Proposed solution is introducing an optional 4-byte CRC checksum in putfile RPC. 32 bit CRC(CRC32) can check data integrity up to 512 Mbit. If SDL core failed to pass CRC check, SDL core will request retry for same putfile operation by feeding back "Corrupted_DATA" result code.

## Detailed design

Addition to MOBILE API:
```
<enum name="Result" internal_scope="base">
    <element name="Corrupted_DATA">
      <description>The data sent failed to pass CRC check in receiver end</description>
    </element>
</enum>


  <function name="PutFile" functionID="PutFileID" messagetype="request">

    <param name="CRC Checksum" type="Unsigned Long" minvalue="0" maxvalue="4,294,967,295" mandatory="false">
      <description>Additional CRC32 checksum to protect data integrity up to 512 Mbits</description>
    </param>

  </function>
  
 
  <function name="PutFile" functionID="PutFileID" messagetype="response">

    <param name="resultCode" type="Result" platform="documentation">
      <description>See Result</description>
      <element name="Corrupted_DATA"/>
    </param>

  </function> 
```
Background for current framework:
When dealing with large binary file, app breaks file into chunks and putfile chunks one by one to core. If core received the chunk successfully, it will response result code "success" and append that chunk to binary file cache. Otherwise, core will response result code "Invalid_DATA" and that chunk will not be appended to binary file cache. 

Change:
Once CRC checksum is enabled, Core will compare CRC checksum calculated by received data and CRC checksum provided by putfile request. If two checksum value doesn't agree to each other, Core will know received data is corrupted. Then, Core shall not delete binary file cache and it should response "Corrupted_DATA" to app, instead of "Invalid_DATA". This gives app a chance to directly correct that  chunk before transfering next chunk. With "Corrupted_DATA" response, app will know it is corrupted chunk of data, it will start retransmitting for that chunk. App will retry up to 5 times(defined by application) before it stop and record errors.

Major change:
		1. New parameters to putfile request and response 
		2. Send "Corrupted_DATA" instead of "Invalid_DATA" to app.(SDL core only change)
		3. SDL core generate CRC32 checksum based on received putfile data if CRC checksum option is enabled. ( SDL core only change)
  
## Impact on existing code


## Alternatives considered

NO
