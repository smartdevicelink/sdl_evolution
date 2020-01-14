# Extend SystemRequest With Optional Data For Proprietary Data Exchange

* Proposal: [SDL-0263](0263-System-Request.md)
* Author: [Zhimin Yang](https://github.com/smartdevicelink/yang1070)
* Status: **Returned for Revisions**
* Impacted Platforms: [Core / iOS / Java Suite / RPC]

## Introduction

RPC `SystemRequest` and `OnSystemRequest` can send bulk binary data between a mobile app and SDL Core using hybrid message. However, these binary data are not defined in HMI API. Instead, SDL Core/HMI saves the data to a binary file and passes the filename to HMI/SDL Core. 

## Motivation

With the growing popularity of SDL, more components within the head unit would like to exchange their data in a component specific proprietary way with the owner applications. Most of the time, the size of the information is less than a kilobyte. Currently mobile apps can send/receive binary data in `SystemRequest` and `OnSystemRequest` RPC messages using hybrid message, and a file needs to be passed between SDL Core and HMI to exchange the data. File operations (create, read, write, delete) are slow. It is better to send data (especially a small amount of data) using message directly.

Furthermore, currently a mobile app can send a `SystemRequest` to the head unit, only getting a result code back. The resulting vehicle data is not available in the response. We propose to provide a mobile app with a way to request OEM specific data from the head unit depending on the `requestType` and `subRequestType` in the `OnSystemRequest` response.

## Proposed solution

This proposal adds a new optional parameter to the existing `SystemRequest` request and `OnSystemRequest` notification in HMI API.
This proposal also adds a new optional parameter to the `SystemRequest` response in the HMI API. The data shall be transmitted via hybrid message to mobile.

Mobile API changes

There is no parameter added to mobile API. However, the text description of `SystemRequest` response shall say that binary data can be included in the hybrid part of the message in the response of a system request.
 
HMI API changes

```xml
<function name="OnSystemRequest" messagetype="notification" >
    ...
+   <param name="data" type="String" maxlength="65535" mandatory="false">
+       <description> 
+           Base64 encoded data sending from HMI to SDL Core. If it exists, "fileName" shall be ignored; 
+           SDL Core shall decode the string and treat the resulting data like it comes from a binary file.
+           SDL Core shall send decoded data to the mobile app in hybrid part of message.
+        </description>
+   </param>
</function>


<function name="SystemRequest" messagetype="request">
    ...
+   <param name="requestData" type="String" maxlength="65535" mandatory="false">
+       <description>
+         If it exists, "fileName" shall be ignored;
+         If the length of incoming binary data from hybrid message is less than configured bytes, instead of saving it to a binary file, SDL Core base64 encodes the data.  
+       </description>
+   </param>
</function>


<function name="SystemRequest" messagetype="response">
    ...
+   <param name="resultData" type="String" maxlength="65535" mandatory="false">
+       <description> Base64 encoded result data from the system to SDL Core. SDL Core shall send decoded data to the mobile app in hybrid part of message. </description>
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

- When SDL Core receives a `SystemRequest` request from mobile, if the incoming binary data is less than a certain size specified by smartdevicelink.ini, instead of saving the data to a temporary file, SDL Core shall encode the data using base64 format, and send the encoded string as `requestData` directly within a SystemRequest HMI message. If the size of the data is large, SDL Core saves the data to a file and passes the file name to HMI as before.

- When SDL Core receives an `OnSystemRequest` notification from the HMI, if the optional `data` parameter exists, SDL Core shall ignore the `fileName` parameter. Instead of reading data from the file, SDL Core shall base64 decode the string, and send the resulting data in the hybrid part of the message to mobile. If the optional `data` parameter does not exist, SDL Core reads data from the file as before.

- When SDL Core receives a `SystemRequest` response from the HMI, if the optional `resultData` parameter exists, SDL Core shall base64 decode the string, and send the resulting data in the hybrid part of the message to mobile. 

Potential changes to HMI

- When HMI receives a `SystemRequest` request, if optional parameter `requestData` exists, it shall ignore the `fileName` parameter. It shall base64 decode the string and use the data as if it comes from a file.

- When HMI sends an `OnSystemRequest` notification, it is free to choose either the file transfer (as before) or string transfer (new) regardless of the configurable parameter in smartdevicelink.ini.

- When HMI sends a `SystemRequest` response with `resultData`, it shall choose string transfer.

Since `fileName` is mandatory in the HMI API for SystemRequest request and OnSystemRequest and it will be ignored when `requestData`/`data` exists, `fileName` can be hard coded to any string. This is true for both SDL core and HMI.



### Potential code changes to Java Proxy

Since java suite already has the code to extract hybrid part of the protocl message and set the bulk data when create a RPC message (response), the only change is to expose a method for developer to get the result data.

```java
public class SystemRequestResponse extends RPCResponse {
    public SystemRequestResponse() {
        super(FunctionID.SYSTEM_REQUEST.toString());
    }

    public SystemRequestResponse(Hashtable<String, Object> hash) {
        super(hash);
    }

    public SystemRequestResponse(Hashtable<String, Object> hash, byte[] bulkData){
        super(hash);
        setBulkData(bulkData);
    }
	
	/**
	 * Constructs a new SystemRequestResponse object
	 * @param success whether the request is successfully processed
	 * @param resultCode whether the request is successfully processed
	 */
	public SystemRequestResponse(@NonNull Boolean success, @NonNull Result resultCode) {
		this();
		setSuccess(success);
		setResultCode(resultCode);
	}
	
	public void setResultData(byte[] resultData) {
        setBulkData(aptData);
    }
	
	public byte[] getResultData() {
        return getBulkData();
    }
}
```
Potential code changes to iOS Proxy

Similar to Java Suite, the required function would be parsing the `SystemRequestResponse` message, extracting bulk data in protocol level message, and exposing a get method for it. 
After looking at the code, `bulkData` is already a public property of `SDLRPCMessage`. `SDLSystemRequestResponse`, `SDLOnSystemRequest`, and `SDLSystemRequest` all inherit from `SDLRPCMessage`. `bulkData` is already exposed (can be set/get and is nullable) and `SDLRPCMessage` handles the parsing from SDL Core too, therefore, there is no code change need. Developers can use something like the following to access `bulkData`:

```
SDLSystemRequestResponse *respsonse = …
NSLog(response.bulkData)
```

## Potential downsides

Instead of writing/reading from a file, SDL Core needs to do base64 encoding/decoding. The length ratio of base64 encoded bytes to input bytes is about 4:3 (33% overhead). 

## Impact on existing code

- Mobile and HMI_API need to be updated.
- SDL Core needs to be updated.
- SDL proxy libs need updates.

## Alternatives considered

Adding the new optional parameters to the corresponding RPCs in the mobile API. Thus, for small amount of data, it can be sent using regular RPC messages without hybrid part.
