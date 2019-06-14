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
of new features or bug fixes. The authors believe that it is worth
the time investment because

The time investment on making the changes now rather than later is worth it
because the technical debt of having hard to maintain code will be a much
larger time investment in the future.

Describe any potential downsides or known objections to the course of action presented in this proposal, 
then provide counter-arguments to these objections. 
You should anticipate possible objections that may come up in review and provide an initial response here. 
Explain why the positives of the proposal outweigh the downsides, 
or why the downside under discussion is not a large enough issue to prevent the proposal from being accepted.

## Impact on existing code


Describe the impact that this change will have on existing code. 
Will some SDL integrations stop compiling due to this change? 
Will applications still compile but produce different behavior than they used to? 
Is it possible to migrate existing SDL code to use a new feature or API automatically?

## Alternatives considered

Postponing until we have the need for new features or when bugs come up.
This is not a good appro

