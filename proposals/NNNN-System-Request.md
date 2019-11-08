# Extend SystemRequest With Optional Data For Proprietary Data Exchange

* Proposal: [SDL-NNNN](NNNN-System-Request.md)
* Author: [Zhimin Yang](https://github.com/smartdevicelink/yang1070)
* Status: **Waiting for review**
* Impacted Platforms: [Core / iOS / Java Suite / RPC]

## Introduction

RPC `SystemRequest` and `OnSystemRequest` can send bulk binary data between a mobile app and SDL Core using hybrid message. However, these binary data are not defined in HMI API. Instead, SDL Core/HMI saves the data to a binary file and passes the filename to HMI/SDL Core. 

## Motivation

With the growing popularity of SDL, more components within the head unit would like to exchange their data in a component specific proprietary way with the owner applications. Most of the time, the size of the information is less than a kilobyte. Currently mobile apps can send/receive binary data in SystemRequest and OnSystemRequest RPC messages using hybrid message, a file needs to be passed between SDL Core and HMI to exchange the data. File operations (create, read, write, delete) are slow. It is better to send data (especially a small amount of data) using message directly.


## Proposed solution

There is no change to the mobile API. This proposal adds a new optional parameter to the existing `SystemRequest` request/response and `OnSystemRequest` notification.

 
HMI API changes

```xml
<function name="OnSystemRequest" messagetype="notification" >
    ...
+   <param name="data" type="String" maxlength="65535" mandatory="false">
+       <description> 
+           Base64 encoded data sending from HMI to SDL. If it exists, "fileName" shall be ignored; 
+           SDL Core shall decode the string and treat the resulting data like it comes from a binary file.
+           SDL Core shall send decoded data to the mobile app in hybrid part of message
+        </description>
+   </param>
</function>


<function name="SystemRequest" messagetype="request">
    ...
+   <param name="requestData" type="String" maxlength="65535" mandatory="false">
+       <description>
+         If it exists, "fileName" shall be ignored;
+         If the length of incoming binary data from hybrid message is less than configured bytes, instead of saving it to a binary file, SDL base64 encoded the data.  
+       </description>
+   </param>
</function>


<function name="SystemRequest" messagetype="response">
    ...
+   <param name="resultData" type="String" maxlength="65535" mandatory="false">
+       <description> Base64 encoded result data from the system to SDL. SDL shall send decoded data to the mobile app in hybrid part of message. </description>
+   </param>
</function>
```


Here are the changes needed by SDL Core.
- Add a new configurable parameter in smartdevicelink.ini

```
; The payload in SystemRequest/OnSystemRequest packet bigger than this value will be saved to a file when passing to HMI,
; payload smaller than this value will be based64 encoded and stored as a string parameter to HMI 
; if not specified, this value will default to 0
MaximumBinaryPayloadSizeToString = 11520
```

- When SDL Core receives a SystemRequest request from mobile, if the incoming binary data is less than a certain size specified by smartdevicelink.ini, instead of saving the data to a temporary file, SDL Core shall encode the data using base64 format, and send the encoded string directly within a SystemRequest HMI message. If the size of data is large, SDL Core saves the data to a file and pass the file name to HMI as before.

- When SDL core revives a SystemRequest response or OnSystemRequest notification from HMI, if the optional `data`/`resultData` parameter exists, SDL Core shall ignore the `fileName` parameter. Instead of reading data from the file, SDL Core shall base64 decode the string, and send the resulting data in hybrid part of the message to mobile. If the optional `data`/`resultData` parameter does not exist, SDL Core reads data from file as before.

Potential changes to HMI

- When HMI receives a SystemRequest request, if optional parameter `requestData` exists, it shall ignore the `fileName` parameter. 
- When HMI sends a SystemRequest response or a OnSystemRequest notification, it is free to choose either the file transfer (as before) or string transfer (new) regardless of the configurable parameter in smartdevicelink.ini.

Potential changes to the mobile proxy lib

- Extract hybrid part of the message from SystemRequest RPC response message, if the library did not do that before.



## Potential downsides

Instead of writing/reading from a file, SDL Core needs to do base64 encoding/decoding. The length ratio of base64 encoded bytes to input bytes is about 4:3 (33% overhead). 

## Impact on existing code

- HMI_API needs to be updated.
- SDL Core needs to be updated.
- SDL proxy lib might need updates.

## Alternatives considered

Adding the new optional parameters to the corresponding RPCs in the mobile API. Thus, for small amount of data, it can be sent using regular RPC messages without hybrid part.
