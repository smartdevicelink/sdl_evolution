# OnAppInterfaceUnregistered 

* Proposal: [SDL-NNNN]
* Author: [Melnyk Tetiana](https://github.com/TMelnyk)
* Status: Awaiting review
* Impacted Platforms: Core
[SDL-NNNN]: https://github.com/smartdevicelink/sdl_evolution/new/master/proposals/NNNN-OnAppInterfaceUnregistered.md

## Introduction
SDL marks mobile app message as malformed in case this message does not match one or more of verification criteria:  
1. Protocol version shall be from 1 to 3;  
2. ServiceType shall be equal 0x0 (Control), 0x07 (RPC), 0x0A (PCM), 0x0B (Video), 0x0F (Bulk);  
3. Frame type shall be 0x00 (Control), 0x01 (Single), 0x02 (First), 0x03 (Consecutive);  
4. For Control frames Frame info value shall be from 0x00 to 0x06 or 0xFE(Data Ack), 0xFF(HB Ack);  
5. For Single and First frames Frame info value shall be equal 0x00;  
6. For Control frames Data Size value shall be less than MTU header;  
7. For Single and Consecutive Data Size value shall be greater than 0x00 and shall be less than N (this value will be defined in .ini file);  
8. Message ID be equal or greater than 0x01 for non-Control Frames;  
9. Data size of First Frame shall be equal 0x08 (payload of this packet will be 8 bytes).  

SDL must respond OnAppInterfaceUnregistered (PROTOCOL_VIOLATION) in case mobile app sends malformed messages.

## Motivation
**Required for FORD**  
SDL must count the number of malformed messages in case SDL can define the session.  
SDL must unregister app in case this app sends malformed messages more than allowed. 
SDL must close the whole connection in case SDL cannot define the session with malformed messages.  
SDL must terminate the whole connection with app in case this app sends the very first malformed message.  
SDL must close the whole connection in case NOT registered app sends the very first malformed message.
SDL must respond (PROTOCOL_VIOLATION) in case mobile app sends malformed messages. 

## Proposed solution 
SDL will close connection with mobile app in case app sends first malformed message, no matter:  
1. app registered:  
a. "MalformedMessageFiltering" = false  
b. "MalformedMessageFiltering" = true but SDL cannot define session of malformed messages  
2. app is NOT registered  
a. app tries to connect over protocol version more than 3 

* In case the "MalformedMessageFiltering" = true at .ini file  
and registered mobile app sends malformed messages  
and SDL does NOT define the session of these malformed messages  
SDL must terminate the whole connection (independently from app registestered or not).

* In case the limit of "MalformedFrequencyCount" and "MalformedFrequencyTime" params exceeds  
SDL must:  
send OnAppInterfaceUnregistered (PROTOCOL_VIOLATION) to mobile app  
allow mobile app to re-register within the same session.
SDL must NOT terminate session with this mobile app.

* In case the "MalformedMessageFiltering" = false at .ini file   
and registered mobile app sends the very first malformed message  
SDL must terminate the whole connection (no matter can or cannot SDL define the session).

* In case the "MalformedMessageFiltering" = false or true at .ini file 
and NOT registered mobile app sends the very first malformed message (app tries to connect over noе supported protocol version)  
SDL must terminate the whole connection.

* In case the "MalformedMessageFiltering" = true at .ini file  
and registered mobile app sends malformed messages  
and SDL defines the session of these malformed messages  
SDL must count number of malformed messages from mobile app according to params at .ini file 

## Detailed design
TBD

## Impact on existing code
TBD

## Alternatives considered
TBD
