# Malformed packet: length of search for the next valid header must be limited by .ini file settings

* Proposal: [SDL-NNNN]
* Author: [Melnyk Tetiana](https://github.com/TMelnyk)
* Status: Awaiting review
* Impacted Platforms: Core
[SDL-NNNN]: https://github.com/smartdevicelink/sdl_evolution/new/master/proposals/NNNN-Malformed-packet.md
## Introduction
SDL allows special mechanism in packets validation (validator moves by one byte and tries to find first valid packet).
It causes big performance decreasing in case big packet with invalid header has come.

## Motivation  
We propose to validate only N first bytes of incoming data and stop validation procedure in case no valid header was found (meaning: SDL will terminate connection). 
It would prevent time delays during packets validation, especially in case big data packets have come. 
Size of data to be validated will be described as new parameter in ini file.

## Proposed solution
Adding new "NumberOfShiftedBytes" param at .ini file to avoid SDL's "hanging" while searching for the next valid header in the big packet (since 128k payload is now supported).  
SDL must start searching for the next valid header in case of first malformed <NumberOfShiftedBytes> times  
SDL must search valid header unlimited times in case "NumberOfShiftedBytes" is zero  
SDL must use the default value in case "NumberOfShiftedBytes" is empty.

 "MalformedMessageFiltering" should be designed for SDL to start the process of searching for the next valid header in the malformed packet (after the first invalid header is detected) with the purpose to count the malformed messages from the app. 
 If disabled (set to "false"), SDL will drop the connection upon the very first malformed message detection. 


## Detailed design
TBD

## Impact on existing code
TBD

## Alternatives considered
TBD
