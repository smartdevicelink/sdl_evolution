# SDL Server 3.0.0 (refactor)

* Proposal: [SDL-NNNN](NNNN-sdl-server-3.md)
* Author:  [Russ Johnson](https://github.com/russjohnson09), [Nick Schwab](https://github.com/nickschwab), [Chris Rokita](https://github.com/crokita)
* Status: **Awaiting review**
* Impacted Platforms: [SDL Server]

## Introduction

This proposal is to refactor the sdl server project and release it as version 3.0.0 to improve maintainability, code readability, and reduce the level of effort for future enhancements.


## Motivation

The refactor will improve maintainability and make future enhancements easier to implement.

## Proposed solution

The proposed solution is to refactor the existing codebase to introduce the following
improvements and fixes.

1. Standardized input validation
2. Remove deprecated methods and start-up scripts
3. Require Postgres (power features, performance, maintainability, no demand thus far for other DBMS support)
4. Making default Functional Groups non-colliding with custom Functional Groups
5. Object-oriented data schemas with de/serialization and transformation methods for improved compatibility throughout code
6. Reducing/removing context binding between functions for easier-to-follow code
7. Use of async/await instead of callbacks and promises to reduce/remove dependencies on external libraries
8. Clean up SQL queries for improved use across code


## Potential downsides

With refactoring there is a time investment without having the benefit
of new features or bug fixes. The time investment on making these improvements now rather than later is worth it
because the technical debt of having difficult to maintain code will end up being a much
larger time investment in the future.

## Impact on existing code
This is a very board refactor change and will impact most all existing code. Integrations with the sdl_server REST API
should not be affected especially in the case of sdl_core's integration. Server setup instructions for local
development may need to be updated to remove references to obsolete start-up scripts.

## Alternatives considered

The list of changes in this issue will need to be made at some point to be able to maintain the sdl
server. Alternatives would be to wait until other requests come in and refactor code that is impacted
by these requests as they come in. This process of refactoring piece by piece would most likely take much longer 
than doing a single refactor. Doing it all at once will likely take less overall time and result in more consistent
code which is one of the main aspects of maintainable code.
