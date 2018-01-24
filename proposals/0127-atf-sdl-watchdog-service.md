# SDL watchdog

* Proposal: [SDL-0127](0127-atf-sdl-watchdog-service.md)
* Author: [Alexander Kutsan](https://github.com/LuxoftAKutsan)
* Status: **Accepted**
* Impacted Platforms: [Core]

## Introduction
Create service responsible for running and monitoring multiple SDL processes and handling SDL configurations.
Service will provide API to test scripts, and script will be able to run SDL with certain configuration. 
Also this service should provide possibility to run multiple SDL instances (for parallel testing), monitor and control their life cycle. 

## Motivation

Major problem of current automated testing approach is that it is impossible to test multiple instances of SDL simultaneously.
Currently SDL and ATF should be located on the same workstation because ATF actually runs SDL via bash scripts. 
Implementation of SDL watchdog gives possibility to locate ATF and SDL independently (on one or on separate workstations).
Also ATF is not able to control SDL configuration, it just uses SDL that is located in a predefined place. 
If script is able to get SDL with certain build flags, or certain version of SDL, that will reduce a lot of testing efforts.
Separating of script run logic and SDL control logic will provide possibility to test SDL with automated scripts on head unit.

## Proposed solution

Create SDL Watchdog service.
Responsibilities of SDL Watchdog:
 - Run SDL with custom configuration and resource files
 - Run multiple instances of SDL simultaneously
 - Stop certain SDL instance
 - Monitor SDL life cycle
 - Catch SDL crash and provide core file
 - Provide SDL logs
 
SDL Watchdog should provide following API

#### SDL Watchdog API

**StartSDL**
``` 
Description: 
 - Start SDL instance
Options:
 - SDL build configuration
 - resource files (preloaded_pt, ini, etc ...)
Return value: 
 - ID of SDL process
 - IP address and port of mobile connection
 - IP address and port of HMI connection
 - IP address and port of logs accessing
 - IP address and port of SDL telemetry information   
 - Some transport specific connection information (BT, USB, etc) 
```

**StopSDL**
``` 
Description: 
 - Stop SDL process
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
 - Path to artifact file
Return value : 
 - Requested artifact file data
```

**OnSDLStopped**
``` 
Description : 
 - Callback triggered by watchdog service when SDL stops
Options:
 - ID of SDL process
 - Stop reason (crash, regular shutdown, kill, etc) 
 - Payload (core file in case if SDL crashed) 
```

#### ATF internal implementation

On ATF side, should create a component (for example: `SDL`) that is able to communicate with SDL Watchdog via API.
Also on ATF side SDL watchdog component should be able to fetch SDL logs by telnet, monitor SDL core crash and download stack trace.

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

Impacts atf component named SDL, also impacts Fasade of ATF. 
Impacts all scripts related to multiple ignition cycles.

## Alternatives considered
Run SDL via command prompt, but it requires ATF to be located on the same workstation with SDL and does not support automated testing on Head unit. 
