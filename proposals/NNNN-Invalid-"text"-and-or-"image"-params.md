# Invalid "text" or/and "image" parameters 

* Proposal: [SDL-NNNN] 
* Author: [Melnyk Tetiana](https://github.com/TMelnyk)
* Status: Awaiting review
* Impacted Platforms: Core
[SDL-NNNN]: https://github.com/smartdevicelink/sdl_evolution/new/master/proposals/NNNN-Invalid-"text"-and-or-"image"-params.md

## Introduction
SDL must respond with INVALID_DATA in case "text" and/or "image" parameters of requested SoftButton structure are invalid.

## Motivation  
**Required for FORD**  
**Required additional clarification from FORD.**  

In case "text" or/and "image" parameters are invalid in SoftButton struct of RPC SDL must respond INVALID_DATA to mobile app.

## Proposed solution  
1. In case mobile app sends any-relevant-RPC with SoftButtons with:  
Type=TEXT  
invalid value of 'image' parameter  
SDL must respond (INVALID_DATA, success:false) to mobile app.

2. In case  mobile app sends any-relevant-RPC with SoftButtons with:  
Type=IMAGE  
invalid value of 'text' parameter  
SDL must respond (INVALID_DATA, success:false) to mobile app.

## Detailed design
TBD

## Impact on existing code
TBD

## Alternatives considered
TBD
