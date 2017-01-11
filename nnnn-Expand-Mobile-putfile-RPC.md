
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

Core should not delete file when one chunk was corrupted and it will response "Corrupted_DATA" to app, Instead of "Invalid_DATA". So that the app has a chance to correct that chunk instead of resending entire file.
App will know it is corrupted chunk of data, and it will start retransmission for that chunk.

Major change:
		1. New parameters to putfile request and response 
		2. Send "Corrupted_DATA" instead of "Invalid_DATA" to app.(SDL core only change)
  
## Impact on existing code


## Alternatives considered

