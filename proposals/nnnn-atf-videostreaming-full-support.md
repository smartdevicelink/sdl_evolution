# ATF Video streaming support

* Proposal: [SDL-NNNN](nnnn-atf-videostreaming-full-support.md)
* Author: [Alexander Kutsan](https://github.com/LuxoftAKutsan)
* Status: **Awaiting review**
* Impacted Platforms: [ATF]

## Introduction

Video streaming is major feature of SDL. 
Currently it should be tested manually on each release. 
Testing video streaming is rather complicated and expensive, and there are big probability of human error during testing.

Currently ATF is able to stream data from mobile side, but not able to handle streaming from HMI side, and check that data received and not corrupted.

ATF should provide ability to cover all use cases related to video streaming. 

## Motivation

Full streaming feature support will provide ability to cover all streaming cases with automated tests and reduce efforts for manual testing. 

Streaming tests should be part of smoke SDL test cases and should be performed on each pull request. 

Automatizing of video streaming use cases should also reduce time consumption's for testing video streaming.  

Also ATF should provide ability to perform other testing activities (send requests, notifications , etc ... ) during streaming. 

## Proposed solution

ATF should support reading data from pipe/socket and save them to file on file system.
List of provided API to test script:

#### ListenStreaming

**Parameters** : 
 - Streaming source (pipe or socket)
 - Count of bytes for event call : event with custom callback will be called after streaming some amount of bytes

**Return value** :
 - Event that will be triggered each "*count of bytes*" received and on closing port\pipe. 
   In event callback should be access to file with received data and count of received bytes and root cause of event 


## Potential downsides

N/A

## Impact on existing code


Should impact only ATF code

## Alternatives considered

Do not test wide streaming with automated test framework.