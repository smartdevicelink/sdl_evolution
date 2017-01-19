# Respond to backslash symbol at "fileName" parameter

* Proposal: [SDL-NNNN]
* Author: [Melnyk Tetiana](https://github.com/TMelnyk)
* Status: Awaiting review
* Impacted Platforms: Core
[SDL-NNNN]: https://github.com/smartdevicelink/sdl_evolution/new/master/proposals/NNNN-respond-to-backslash-symbol.md

## Introduction
SDL must respond with INVALID_DATA to app due to "/" symbol. 

## Motivation  
**Required for FORD**  
**Required additional clarification from FORD.**  
Currently Linux SDL has NO restrictions related to "\" (backslash) symbol at `<syncFileName>` parameter.

## Proposed solution
SDL must respond with 'INVALID_DATA, success:false' resultCode in case the name of the file that app requests to upload on the system contains "\" (backslash).  

The following use case possible:  
app -> SDL: PutFile (""\" 123.jpg") -> "syncFileName" with backslash  
As result in this case SDL must return INVALID_DATA to mobile app.

## Detailed design
TBD

## Impact on existing code
TBD

## Alternatives considered
TBD
