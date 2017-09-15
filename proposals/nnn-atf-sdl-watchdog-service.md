# SDL watchdog

* Proposal: [SDL-NNNN](nnn-atf-sdl-watchdog-service.md)
* Author: [Alexander Kutsan](https://github.com/LuxoftAKutsan)
* Status: **Awaiting review**
* Impacted Platforms: [ATF]

## Introduction
Create service that is responsible for running and monitoring multiple SDL processes and handling SDL configurations.
Service will provide API to test scripts, and script will be able to run SDL with certain configuration. 
Also this service should provide possibility to run multiple SDL instances (for parallel testing), monitor and control their life cycle. 

## Motivation

Major problem if current automated testing is that it is impossible to test multiple instances of SDL simultaneously.
Currently SDL and ATF should be separated on the same workstation, because ATF actually runs SDL via bash scripts. 
Also ATF is not able to control SDL configuration, it just uses SDL that located in predefined place. 
It will reduce a lot of testing efforts, if script will be able to get SDL with certain build flags, or certain version of SDL. 
Also separating logic of script running and controlling of SDL will provide possibility of automated testing SDL on head unit.

## Proposed solution

Create SDL Watchdog service.
Responsibilities of SDL Watchdog:
 - Run SDL with custom configuration and resource files
 - Run multiple instances of SDL simultaneously.
 - Kill certain SDL process
 - Monitor SDL life cycle
 - Catch SDL crash and provide core file
 - Provide SDL logs
 
SDL Watchdog should provide API

#### SDL Watchdog API

**StartSDL**
``` 
Description: 
 - Start SDL instance
Options:
 - SDL build configuration
 - configuration files (preloaded_pt, ini, etc ...)
Return value: 
 - ID of SDL process
 - Ip address and port of mobile connection
 - Ip address and port of HMI connection
 - Ip address and port of logs accessing
 - Ip address and port of SDL telemetry information   
 - Some transport specific connection information (BT or USB ...) 
```

**StopSDL**
``` 
Description: 
 - Kill SDL Process
Options:
 - ID of SDL process
Return value: 
 - Result code
```

**GetSDLArtifact**
``` 
Description: 
 - Download particular artifact file from defined SDL process  
Options:
 - ID of SDL process (may be already not active)
 - Path to file
Return value : 
 - file to download
```

**OnSDLStopped**
``` 
Description : 
 - Callback service send if SDL is stopped
Options:
 - ID of SDL process
 - Stop reason (Crash, regular shutdown, kill ...) 
 - Payload (core file in case if SDL crashed) 
```

#### ATF internal implementation

On ATF side should be created SDL component that is able to communicate with SDL Watchdog via API.
Also on ATF side SDL component should be able to fetch SDL logs by telnet, monitor SDL core crash and download stack trace.

ATF should provide following API for script:

- StartSDL : start SDL with custom configuration
- StopSDL : stop SDL by defined identifier
- GetArtifactoryFile : download from SDL workstation arbitrary file
- GetOnSDLStoppedEvent : return SDL stop event, may be used for expectations or delayed execution

#### Diagrams 
![SDL watch dog and ATF communication](/assets/proposals/nnnn-Atf-Sdl-Watchdog-Service/sdl-watchdog.png)

## Potential downsides

N/A

## Impact on existing code

Impacts ATF code, some scripts, and required implementation of Watchdog service.

## Alternatives considered
Run SDL via command prompt, but it requires ATF to be separated on the same workstation with SDL and do not support automated testing on Head unit. 
