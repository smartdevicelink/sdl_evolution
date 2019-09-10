# SDL Server 3.0.0 (refactor)

* Proposal: [SDL-0247](0247-sdl-server-3.md)
* Author:  [Russ Johnson](https://github.com/russjohnson09), [Nick Schwab](https://github.com/nickschwab), [Chris Rokita](https://github.com/crokita)
* Status: **Returned for Revisions**
* Impacted Platforms: [SDL Server]

## Introduction

This proposal is to refactor the sdl server project and release it as version 3.0.0 to improve maintainability, code readability, and reduce the level of effort for future enhancements.


## Motivation

The refactor will improve maintainability and make future enhancements easier to implement.

## Proposed solution

The proposed solution is to refactor the existing codebase to introduce the following improvements and fixes.

1. Standardized input validation
2. Remove deprecated methods and start-up scripts
3. Require Postgres (power features, performance, maintainability, no demand thus far for other DBMS support)
4. Making default Functional Groups non-colliding with custom Functional Groups
5. Object-oriented data schemas with de/serialization and transformation methods for improved compatibility throughout code
6. Reducing/removing context binding between functions for easier-to-follow code
7. Use of async/await instead of callbacks and promises to reduce/remove dependencies on external libraries
8. Clean up SQL queries for improved use across code


## Potential downsides

This refactor will be a significant time investment that will put a hold on other features until it is completed.  This problem can be addressed by implementing the refactor at a time when few other changes are required.


## Impact on existing code

This is a very broad refactor change and will touch most of the existing sdl server code. The input and output of SDL Server’s policy table update API endpoints will not be changed in order to preserve backward compatibility with existing SDL Core integrations. Server setup instructions for local development may need to be updated to remove references to obsolete start-up scripts.

## Alternatives considered

The changes listed here are ones that will need to be made at some point. As features are added complexity will grow, but by following the changes outlined in this refactor this added complexity can be made more manageable. Alternatives considered revolve around the timing and scope of changes made. Some of these changes could be made in smaller chunks and spread out over multiple issues. For example, cleaning up the SQL queries could be done to the module-config and policy endpoints separately. Individually this might take less time than doing them together, but overall it would be a larger effort than doing a single refactor across the entire sdl server.

