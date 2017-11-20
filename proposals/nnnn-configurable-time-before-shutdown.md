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

 - Add option to flush log messages before shutdown.
 - Add option that specifies time maximum before shutdown.

```
// Write all logs un queue to filesystem before shutdown 
FushLogMessagesBeforeShutdown = false

// Maximum time to wait for writing all data before exit sdl in seconds
MaxTimeBeforeShutdown = 30
```

By default `FushLogMessagesBeforeShutdown` should be false. In that case SDL should not wait for writing all data to file system ans stop process after receiving `OnExitAllApplications` notification. 

`MaxTimeBeforeShutdown` doe used in case if `FushLogMessagesBeforeShutdown` is `true`. It should measure timer from `OnExitAllApplications` notification received. In case if writing logs to file system takes moer than specified, SDL should terminate writing and finish process. 


## Potential downsides

N/A

## Impact on existing code

Impact ignition off process of SDL core.

## Alternatives considered
 1. Do not write all logs to SDL before shutdown ( some logs may  be missed)
 2. Write all logs before shutdown ( shutdown may take a log time)
 
