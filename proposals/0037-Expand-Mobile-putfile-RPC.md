

# Expand Mobile `putFile` RPC

* Proposal: [SDL-0037](0037-Expand-Mobile-putFile-RPC.md)
* Author: [Martin(Lingxiu) Chen]( https://github.com/lchen139) & [Timur Pulathaneli](https://github.com/tpulatha)
* Status: **In Review**
* Impacted Platforms: RPC, Core, iOS, Android

## Introduction

This proposal is to expand `putFile` RPC to incorporate it with unreliable medium.
This proposal seeks to enhance the reliability of large data transfers to the head unit by introducing a field for CRC in the `putFile` RPC.

## Motivation

Current SDL design assumes that the transport medium is 100% reliable and all data will be correctly retrieved by the receiver. In reality, no transport is guaranteed to be 100% error free. Errors might be caused by hardware design failure, software driver issues, or environmental noise interference.

The current implementation of SmartDeviceLink does give an Error feedback if a dropped frame impacts the JSON structure of a message. But if a frame is dropped during the binary part of a `putFile` sdl_core writes the file to the memory without noticing the dropped frame and responds to the mobile side with `SUCCESS`

This paired with the ability to upload very large files as chunks using the `offset` and `length` parameters of `putFile` results in the problem that an App might upload a very large file (say 1GB) and gets a `SUCCESS` for each small putFile. But when the complete file gets CRC checked on the head unit, this check fails because one `putFile` had a missing frame that went unnoticed.

## Proposed solution

The proposed solution introduces an optional new parameter to the `putFile` request that includes a 4-byte CRC checksum. 32 bit CRC (CRC32) can check data integrity up to 512 Mbit. If the CRC check fails, SDL core will send the `putFile` response with these values:
```
resultCode: CORRUPTED_DATA
info: "CRC Check on file failed. File upload has been cancelled, please retry."
success: false
```

## Detailed design

Addition to MOBILE API:
```
<enum name="Result" internal_scope="base">
  <element name="CORRUPTED_DATA">
    <description>The data sent failed to pass CRC check in receiver end</description>
  </element>
</enum>


<function name="putFile" functionID="putFileID" messagetype="request">
  [...]
  <param name="crc" type="Integer" minvalue="0" maxvalue="4294967295" mandatory="false">
    <description> Additional CRC32 checksum to protect data integrity up to 512 Mbits . </description>
  </param>
  [...]
</function>


<function name="putFile" functionID="putFileID" messagetype="response">
  [...]
  <param name="resultCode" type="Result" platform="documentation">
      <description>See Result</description>
      <element name=" CORRUPTED_DATA "/>
  </param>
  [...]
</function>
```

## Impact on existing code
- New parameters to `putFile` request and response (RPC change)
- SDL core generates CRC32 checksum based on received `putFile` data if CRC checksum parameter is included in request. (sdl_core only change)
- If the created CRC does not match the transmitted information, sdl_core response with `CORRUPTED_DATA`  (sdl_core, sdl_ios, sdl_android)

## Alternatives considered

Similar to the TCP design, the CRC checksum is placed at frame header ([SmartDeviceLink Protocol level](https://github.com/smartdevicelink/protocol_spec#22-version-2-frame-header)). The CRC checksum calculation is based on both the frame header and frame payload.

### Pros:
- Covers both headers and payloads for all SDL communication
- Research paper ["When The CRC and TCP Checksum Disagree"](conferences.sigcomm.org/sigcomm/2000/conf/paper/sigcomm2000-9-1.pdf) suggests variety error sources in internet will increase error rate from one packets out of few millions to one packets out of few thousand in TCP/IP level.  This approach provides additional robustness for overall system.

### Cons:
- Great impact for SDL protocol. Major revision for SDL protocol is required.

## Q&A about Downside
Q: How this CRC32 affects `putFile` performance?
A: CRC32 checksum calculation uses table look-up method. Lib will store pre-calculate CRC32 value and directly assign to request. It should not consume too much time. (Implementation example: https://opensource.apple.com/source/xnu/xnu-1456.1.26/bsd/libkern/crc32.c)
Q: How this proposal affects current framework?
A: This proposal introduces optional parameters. If old framework does not support this parameter, it will ignore this parameter.
