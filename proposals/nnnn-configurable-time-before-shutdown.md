# Configurable time before shutdown

* Proposal: [SDL-NNNN](nnnn-configurable-time-before-shutdown.md)
* Author: [Alexander Kutsan](https://github.com/LuxoftAKutsan)
* Status: **Awaiting review**
* Impacted Platforms: [Core]

## Introduction

This proposal is about adding new parameters in ini file for configureing time to stopping SDL process after receiving Ignition off signal.
And configuring option if SDL should write all logs to the file system before shudown. 

## Motivation

In debug mode SDL produce a lot of logs.
Logging is asyncronious not to reduce eficiency of SDL business loginc. 
In some use cases (like videostreaming orbit Put file) SDL produce more logs than it can write to file system. 
SDL collect this logs in queue and write to file system in separate thread. 
After receiving IGNITION_OFF signal currently SDL drop all logs that was not written yet.
Such behaviour prevents analysing of SDL issues that found by ATF script by SDL logs, and requires adding additional timouts in test scripts before SDL shutdown.

This is example of sequence in script:

```
StartSDL()
RegisterApplication()
ActivateApplication
PutFile(some_big_file)
StopSDL()

```
After run of this script with bit probability Logs of Put file request wind be written to SDL. 
To avoid such behaviour script should be modified :
```
StartSDL()
RegisterApplication()
ActivateApplication
PutFile(some_big_file)
Sleep(SomeMagicTime)
StopSDL()

```
But SomeMagicTime will be different for different workstations and depend from operation system load.
So this problem can be solved only with modifications on SDL side. 

## Proposed solution

Add option to flush log messages before shutdown. 
Add option with time that  

## Potential downsides

Describe any potential downsides or known objections to the course of action presented in this proposal, then provide counter-arguments to these objections. You should anticipate possible objections that may come up in review and provide an initial response here. Explain why the positives of the proposal outweigh the downsides, or why the downside under discussion is not a large enough issue to prevent the proposal from being accepted.

## Impact on existing code

Describe the impact that this change will have on existing code. Will some SDL integrations stop compiling due to this change? Will applications still compile but produce different behavior than they used to? Is it possible to migrate existing SDL code to use a new feature or API automatically?

## Alternatives considered

Describe alternative approaches to addressing the same problem, and why you chose this approach instead.
