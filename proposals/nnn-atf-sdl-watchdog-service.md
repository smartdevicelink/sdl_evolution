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
 - Monitor S DL lifecycle
 - Catch SDL crash and provide core file
 - Provide SDL logs
 
In ATF will be created component that will communicate with SDL Watchog via API :

Request name :
  *StartSDL*
Decription : 
  Start SDL instance
Options:
 - SDL build configuration
 - configuraiton files (preloaded_pt, ini, etc ...)
 Return value : 
   - Ip adress and port of mobile connection
   - Ip adress and port of HMI connection
   - Ip adress and port of logs accessing
   - Ip adress and port of SDL telemetry information   
   - Some transport specific connection information (BT or USB ...) 

## Potential downsides

Describe any potential downsides or known objections to the course of action presented in this proposal, then provide counter-arguments to these objections. You should anticipate possible objections that may come up in review and provide an initial response here. Explain why the positives of the proposal outweigh the downsides, or why the downside under discussion is not a large enough issue to prevent the proposal from being accepted.

## Impact on existing code

Describe the impact that this change will have on existing code. Will some SDL integrations stop compiling due to this change? Will applications still compile but produce different behavior than they used to? Is it possible to migrate existing SDL code to use a new feature or API automatically?

## Alternatives considered

Describe alternative approaches to addressing the same problem, and why you chose this approach instead.
