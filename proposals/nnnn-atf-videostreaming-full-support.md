# ATF Video streaming support

* Proposal: [SDL-NNNN](nnnn-atf-videostreaming-full-support.md)
* Author: [Alexander Kutsan](https://github.com/LuxoftAKutsan)
* Status: **Awaiting review**
* Impacted Platforms: [ATF]

## Introduction

Video streaming is a major feature of SDL. 
Currently it should be tested manually for each release. 
Testing of video streaming is rather complicated and expensive, and there is big probability of human mistakes during testing.

Currently ATF is able to stream data from mobile side, but not able to handle streaming from HMI side, and to check data is received and not corrupted.

ATF should provide ability to cover mentioned use cases related to video streaming. 

## Motivation

Full video streaming feature support will provide ability to cover mentioned streaming use cases with automated tests and reduce efforts for manual testing.

Tests related to video streaming will be included into smoke SDL test cases and could be performed on each pull request.

Automatization of testing of video streaming use cases could reduce time consumption for testing video streaming.

In addition ATF will provide ability to create tests for complicated use cases like send requests, notifications, etc during streaming. 

## Proposed solution

ATF should support reading data from pipe/socket and save it to file system.
List of provided APIs to test script:

#### ListenStreaming

**Parameters** : 
 - Streaming source (pipe or socket)
 - Count of bytes for event call : event with custom callback will be called after streaming some amount of bytes

**Return value** :
 - Event that will be triggered on each "*count of bytes*" received or on closing port\pipe. 
   Event callback should provide access to file with received data, count of received bytes and root cause of event. 


## Potential downsides

N/A

## Impact on existing code

Should impact only ATF code.

## Alternatives considered

Do not test video streaming with automated test framework.
