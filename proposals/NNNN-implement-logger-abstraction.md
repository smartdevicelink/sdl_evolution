# Implement logger abstraction

* Proposal: [SDL-NNNN](NNNN-implement-abstract-wrapper-for-logger.md)
* Author: [Alexandr Galiuzov](https://github.com/AGaliuzov)
* Status: **Awaiting review**
* Impacted Platforms: [Core]

## Introduction
The good abstraction for the logger allows to easily substitute the logger library from one to another in case of neccesity.
Different system has different logging mechanizm and SDL has to be easily adopted to use any logger library as a background sink.
## Motivation
Currently SDL has strong dependency from its loggin library called `log4cxx`. It is reflected in macro name SDL uses to log some event i.e. `LOG4CXX_DEBUG`.
Such approach not flexible enough. Systems as QNX have own logging system called `slog`, Windows OS also have own native logger.
But in case one want to use some system native logger it would be quite hard to rework SDL logging system. The proposal is geared to simplify the SDL logger
adoption process by making it abstract.
## Proposed solution
* Change the logger naming by removing `LOG4CXX` prefix. Proposed variant is to use `SDL_LOG` prefix.
  Example: `SDL_LOG_DEBUG()`, `SDL_LOG_AUTO_TRACE()` etc.
* Write abstract logger class which defines the common for eny logger methods: `Enable`, `Disable`, `Init`, `Deinit`, `Flush`, `PushMessage`.
  So the class easily could be adopted to any kind of logger by simply subclassing and overriding neccessary methods.
* Write set of macro definitions which allows to easily use the logger without any knowledge about its background sink.
* Remove the explicit logger name usage from the logging macro. The currently existing code `LOG4CXX_DEBUG(logger, "Message to log")` should be transformed into `SDL_LOG_DEBUG("Message to log")`.
So the user don't need to keep in mind the exact logger variable name.

## Potential downsides
There is no any downside as the proposal simply adds abstraction level to the currently existing functionality.
## Impact on existing code
Even though the whole SDL code will be impacted the impact itself quite low because the change itself is renaming.
The `logger.h` class will be changed to support described functionality.
## Alternatives considered
The only alternative is to keep using the same logger and the same macro names.
