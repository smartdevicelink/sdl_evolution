# Configurable time before shutdown

* Proposal: [SDL-NNNN](nnnn-configurable-time-before-shutdown.md)
* Author: [Alexander Kutsan](https://github.com/LuxoftAKutsan)
* Status: **Awaiting review**
* Impacted Platforms: [Core]

## Introduction

To prevent missing logs in SDL shutdown add Additional ini file options:
 - Write all logs to file system before shutdown 
 - Maximum time of sdl shutting down
 
## Motivation

In debug mode SDL produce a lot of logs in is asynchronous mode. 
In some use cases (like video streaming or big Put file) SDL produce a lot of logs.
SDL collect this logs in queue and write to file system in separate thread.
Writing to file system may requir big amount of time.

In current implementation after receiving IGNITION_OFF signal SDL drop all logs that was not written yet.
Such behavior sometimes prevents analyzing of SDL issues that found by ATF script, and requires adding additional timeouts in test scripts before SDL shutdown.

This is example of sequence in script:

```
StartSDL()
RegisterApplication()
ActivateApplication
PutFile(some_big_file)
StopSDL()
```

Logs of Put file request won't be written to file system, likey.
To avoid such behavior script should be modified :
```
StartSDL()
RegisterApplication()
ActivateApplication
PutFile(some_big_file)
Sleep(SomeMagicTime)
StopSDL()
```

But `SomeMagicTime` will be different for different workstations and depend from operation system load.
So this problem can be solved only with modifications on SDL side. 

## Proposed solution

 - Add option to flush log messages before shutdown.
 - Add option that specifies time maximum before shutdown.

```
// Write all logs in queue to file system before shutdown 
FushLogMessagesBeforeShutdown = false

// Maximum time to wait for writing all data before exit sdl in seconds
MaxTimeBeforeShutdown = 30
```

By default `FushLogMessagesBeforeShutdown` should be false. In that case SDL should not wait for writing all data to file system ans stop process after receiving `OnExitAllApplications` notification. 

`MaxTimeBeforeShutdown` doe used in case if `FushLogMessagesBeforeShutdown` is `true`. It should measure timer from `OnExitAllApplications` notification received. In case if writing logs to file system takes more than specified, SDL should terminate writing and finish process. 


## Potential downsides

N/A

## Impact on existing code

Impacts ignition off process of SDL core.

## Alternatives considered
 1. Do not write all logs to SDL before shutdown ( some logs may  be missed)
 2. Write all logs before shutdown ( shutdown may take a log time)
 

