# Configurable time before shutdown

* Proposal: [SDL-NNNN](nnnn-configurable-time-before-shutdown.md)
* Author: [Alexander Kutsan](https://github.com/LuxoftAKutsan)
* Status: **Awaiting review**
* Impacted Platforms: [Core]

## Introduction

To prevent missing logs after SDL shutdown, additional ini file options should be added : 
 - Write all logs to file system before shutdown 
 - Maximum time of SDL shutting down
 
## Motivation

SDL produces a tone of logs in the asynchronous mode in some use cases (like video streaming or big put file),
In som use cases (like video streaming or big put file) SDL can procude tone (up to gigabyte) of logs in asynchronous mode. 
SDL collects these logs in queue and and writes them to a file system in a separate thread.
Writing to the file system may require big amount of time (sometimes up to 5 - 10 minutes).

In the current implementation, after receiving IGNITION_OFF signal, SDL drops all logs that have not yet been written.
Such behavior sometimes prevents analyzing of SDL issues that are found by the ATF script, and requires adding extra timeouts in test scripts before SDL shutdown.

This is an example of sequence in script:

```
StartSDL()
RegisterApplication()
ActivateApplication
PutFile(some_big_file)
StopSDL()
```

Logs of Put file request won't be written to file system, likely.
To avoid such behavior script should be modified :
```
StartSDL()
RegisterApplication()
ActivateApplication
PutFile(some_big_file)
Sleep(SomeUndefinedTime)
StopSDL()
```

But `SomeUndefinedTime` will be different for different workstations and depend on operation system load.
So this problem can be solved only with modifications on SDL side. 

## Proposed solution

 - Add option to flush log messages before shutdown.
 - Add option that specifies maximum time before shutdown.

```
// Write all logs in queue to file system before shutdown 
FlushLogMessagesBeforeShutdown = false

// Maximum time to wait for writing all data before exit SDL in seconds
MaxTimeBeforeShutdown = 30
```

By default `FlushLogMessagesBeforeShutdown` should be false. In that case, SDL should not wait for all data to be written to the file system and stop process after receiving `OnExitAllApplications` notification. 

`MaxTimeBeforeShutdown` would be used in case if `FlushLogMessagesBeforeShutdown` is `true`. It should measure time from `OnExitAllApplications` notification received. In case if writing logs to file system takes more time than specified, SDL should terminate writing and finish process. 


## Potential downsides

N/A

## Impact on existing code

Impacts ignition off process of SDL core.

## Alternatives considered
 1. Do not write all logs to SDL before shutdown ( some logs may  be missed)
 2. Write all logs before shutdown ( shutdown may take a long time)
 

