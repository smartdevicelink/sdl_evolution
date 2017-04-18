# Implement logger abstraction

* Proposal: [SDL-0046](0046-implement-logger-abstraction.md)
* Author: [Alexandr Galiuzov](https://github.com/AGaliuzov)
* Status: **Accepted**
* Impacted Platforms: [Core]

## Introduction
The good abstraction for the logger allows to easily substitute the logger library from one to another in the case of necessity. The different system has different logging mechanism and SDL has to be easily integrated to use any logger library as a background sink.

## Motivation
SDL has the strong dependency on the specific logging library - `log4cxx`. Such approach has number of drawbacks
* This is old, not already supported the opensource library.
* It has to be separately compiled for any new system such as QNX. Which could lead to compatibility problem and additional efforts to bypass this problem.
* It has the own configuration which could be the critical issue on the production stage when the support team can't fix the issue because SDL logger has not been correctly configured.

 Every OEM is able to have own logger used to log events from the entire system. Obviously, as a part of the complex system, SDL has to use the same logger with the same configurations as the other components. The advantages of such approach are following:
 * Fast and easy integration of the SDL into the existing infrastructure.
 * Ability to configure SDL logging over centralized configuration. So the integrator doesn't need to remember about separate SDL logger config and separately support it.
 
## Proposed solution
* Use abstract logging prefix `SDL_LOG` instead of `LOG4CXX` i.e `SDL_LOG_DEBUG()`, `SDL_LOG_AUTO_TRACE()` etc.
* Write abstract logger class which defines the common for any logger methods: `Enable`, `Disable`, `Init`, `Deinit`, `Flush`, `PushMessage`. So the class easily could be integrated into any kind of logger by simply subclassing and overriding necessary methods.
* Write set of macro definitions which allow to easily use the logger without any knowledge about its background sink.
* Remove the explicit logger name usage from the logging macro. The currently existing code `LOG4CXX_DEBUG(logger, "Message to log")` should be transformed into `SDL_LOG_DEBUG("Message to log")`. So the user doesn't need to keep in mind the exact logger variable name.

## Potential downsides
There is no any downside as the proposal simply adds abstraction level to the currently existing functionality.

## Impact on existing code
Even though the whole SDL code will be modified the impact itself quite low because the change itself is renaming.
The `logger.h` class will be changed to support described functionality.

## Alternatives considered
The only alternative is to keep using the same logger and the same macro names.
