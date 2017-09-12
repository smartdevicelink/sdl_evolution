# SDL watchdog

* Proposal: [SDL-NNNN](nnn-atf-sdl-watchdog-service.md)
* Author: [Alexander Kutsan](https://github.com/LuxoftAKutsan)
* Status: **Awaiting review**
* Impacted Platforms: [ATF]

## Introduction
Create service that is responcible for running and monitoring multiple SDL processes and handling SDL configurations.
Service will provide API to test scripts, ans script will be able to run SDL with certain configuration. 
Also this service should provide possibility to run multiple SDL instanses(for parralel testing), monitor and controll their lifecycle. 

## Motivation

Major problem if cyrrent autmated testing is that it is impossible to test multiple instances of SDL simutaniouusly.
Currently SDL and ATF should be separated on the same workstation, because ATF actualy runs SDL via bash scripts. 
Also ATF is not able to controll SDL configuration it just use SDL that separated in predefined place. 
It will reduce a lot of testing efforts, if script will be able to get SDL with certain build flags, or certan version of SDL. 
Also separating logic of script running and controlling of SDL will provide possibility of automated testin SDL on headunit.

## Proposed solution

Creating service SDL Watchdog.
Responcibilities SDL Watchdog:
 - Run SDL with custom configuration and resource files
 - Run multiple instances of SDL sumutaniously.
 - Kill certain SDL process
 - Monitor SDL lifecycle
 - Catch SDL crash and provide core file
 - Provide SDL logs
 
SDL Watchdog should provide API

#### SDL Watchdog API :

**StartSDL**
``` 
Decription : 
 - Start SDL instance
Options:
 - SDL build configuration
 - configuraiton files (preloaded_pt, ini, etc ...)
Return value : 
 - ID of SDL process
 - Ip adress and port of mobile connection
 - Ip adress and port of HMI connection
 - Ip adress and port of logs accessing
 - Ip adress and port of SDL telemetry information   
 - Some transport specific connection information (BT or USB ...) 
```

**StopSDL**
``` 
Decription : 
 - Kill SDL Process
Options:
 - ID of SDL process
Return value : 
 - Result code
```

**GetSDLArtifact**
``` 
Decription : 
 - Download some artifact file from some SDL process  
Options:
 - ID of SDL process (may be already not active)
 - Path to file
Return value : 
 - file to download
```

**OnSDLStopped**
``` 
Decription : 
 - Callback service send if SDL is stopped
Options:
 - ID of SDL process
 - Stop reason (Crash, regular shutdown, kill ...) 
 - Payload (core file in case if sdl was crashed) 
```

#### ATF internal implementation.

On ATF silde should be created SDL component that is able to communicate with SDL Watchdog via API.
Also on ATF side SDL component should be able to fetsh SDL logs by telnet, monitor SDL core crash and download stacktrace.

ATF should provide folowing API for script:

- StartSDL : start sdl with custom configuration
- StopSDL : stop sdl by identifier
- GetArtifactoryFile : download from sdl workstation arbitary file
- GetOnSDLStoppedEvent : return sdl stop event, may be used for expectations or delayed execution

#### Diagrams 
![SDL watch dog and ATF communication](/assets/proposals/nnnn-Atf-Sdl-Watchdog-Service/SDL watchdog.png)

## Potential downsides

Describe any potential downsides or known objections to the course of action presented in this proposal, then provide counter-arguments to these objections. You should anticipate possible objections that may come up in review and provide an initial response here. Explain why the positives of the proposal outweigh the downsides, or why the downside under discussion is not a large enough issue to prevent the proposal from being accepted.

## Impact on existing code

Describe the impact that this change will have on existing code. Will some SDL integrations stop compiling due to this change? Will applications still compile but produce different behavior than they used to? Is it possible to migrate existing SDL code to use a new feature or API automatically?

## Alternatives considered

Describe alternative approaches to addressing the same problem, and why you chose this approach instead.
