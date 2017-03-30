# Improve Automated test framework

* Proposal: [SDL-NNNN](NNNN-atf-improvement-proposal.md)
* Author: [Alexander Kutsan](https://github.com/smartdevicelink)
* Status: **Awaiting review**
* Impacted Platforms: [Core / ATF]

## Introduction
Integration SDL to OEM environment consists of 2 main activities:
 - adjustments of sdl_core
 - integration ans verification
 
Mission of the Automated test framework (ATF) is:
 - Extend testing coverage (not all functionality could be tested manual)
 - Reduce efforts for testing SDL functionality.
 - And speed up covering with tests new functionality.
Integration requires checking SDL functionality on new platform within new infrastructure.
Also ATF gives ability to monitor regression during development cycle.

#### Current approach boundaries:

 - Unable to setup SDL deployment preconditions(SDL build flags and environment) for test script automatically.
 - Each SDL configuration requires preparation of specific test set.
 - Unable to Start/Stop of externally started SDL via test script, such as on OEM Head-Unit.
 - Format of current ATF reports does not match popular CI build reports standards (like JUnit od etc.).
 - Backward Compatibility is implemented in not full scope. Not all versions of the scripts can be executed on any version of ATF.
 - ATF does not limit script access to private ATF methods.
 - Existed ATF documentation is not enough to create test scripts from scratch.
 - ATF scripts structure is rather complicated it leads to additional efforts to debug and maintenance.
 - ATF contains part of business logic of work with SDL.


Proposal is to resolve these boundaries and make ATF more flexible, scalable.
Additional point is seamless integration with CI systems.

#### Proposed solution benefits:
 - Possibility to verify SDL integration on OEM platform automatically (with or without mobile or HMI).
 - Seamless integration ATF into CI system.
 - ATF facade will simplify creating and supporting test scripts and test sets (add backward compatibility between different versions of ATF and test scripts).
 - ATF will provide full doxygen documentation.
 - Unified approach for test script and test set creating.
 - Proposed architecture allows flexible integration of ATF into existing SDL verification infrastructure on OEM side.

As plus there are further possibilities to provide performance testing and scenario testing.
 
## Motivation

Current testing approach requires changes in ATF during testing some of SDL scenarios.
It also requires additional environment preparation/configuration and control during executing test sets and integrating ATF to popular CI systems.
It is necessary to make ATF easy to use and extend its scaling possibilities.

## Proposed solution

There are 3 different layers of using ATF:

1. Local executing and debugging specific scenario.
2. Local test set execution, logs, reports, traffic analyses. Test set can be executed on remote SDL and on local SDL build.
3. CI execution of test set, collection of logs, reports, traffic logs for further analysis.

ATF should be easy to use as for executing and debugging one concrete scenario on local workstation even with custom modified SDL.

ATF architecture should be modified to support all these 3 layers of execution. Also ATF should support testing SDL on remote workstation/target.

A lot of specific testing functionality may be moved from ATF to testing scripts.
Automatic creating of connection and mobile session with SDL, and HMI - SDL connection should be removed from ATF.
Many scripts do not need HMI or mobile connection, or app registration with specific parameters. This functionality should be a part of scripts, but not ATF.

ATF output artifacts should be improved.
ATF should provide test engineer ability to log custom messages.
Proposed output artifacts of ATF:
 * Transport logs with time stamps and test case marks
 * Collected SDL logs (via Telnet)
 * ATF JUnit (or other popular report format) report (if test set was executed)
 * ATF internal log with custom messages and expectations analyses
 * Test script artifacts (files, used in test script)
 
ATF should not fail script due to internal logic. In case if something unusual occurs (SDL is down or connection is terminated) ATF should provide callback to script, and user should decide if script should be failed in this case.

ATF should provide interface for pre- and post-conditions for scripts. Post-condition should be executed even if test was failed.

ATF should deploy clear SDL environment for each script run.

## Detailed design

Split ATF to parts:
 * Script runner
 * Test set runner
 * SDL Watchdog
 * SDL Deployer
 * Test scripts

All this parts of ATF should be partially standalone applications.
ATF should manage it's parts with git submodules system.

Such splitting will allow -> enable ATF to change any part to the one that matches environment according to current needs (SDL on target for example).
Proposed solution also allows to change some part of ATF to widely used open-source test frameworks (for example python-nose can be used as test set runner).
Each part of ATF can be separately unit tested and keep own versioning and development cycle.

### ATF Components:
![Component relations](../assets/atf_stabilization_proposal/components_model.png)
![Deployment structure](../assets/atf_stabilization_proposal/script_executor_relations.png)


#### Script runner description:

Script runner should consist from 2 parts:
 - Test case executor
 - API Facade

![Deployment structure](../assets/atf_stabilization_proposal/remote_sdl_model.png)

API Facade should provide all required API for testing SDL.
 
Test cases executor should manage results of test cases, executing Setup and TearDonw of each test case and storing test reports.

_Test cases executor functionality probably can be covered with python nose framework._


#### ATF test set executor description:

ATF test set executor should execute some list of tests scripts and collect their artifacts.
It should deploy SDL with SDL Deployer before each script run from clean environment.
Is should be able to run scripts on different SDL's in parallel mode.

_ATF test set executor functionality probably can be covered with python nose framework._


#### SDL Watchdog:

SDL Watchdog should be able to start SDL, watch it state, notify client if SDL was stopped or crashed.
SDL Watchdog should be able to manage multiple SDL's on one workstation.
API Facade provides Test script communication API with SDL Watchdog.


#### SDL Deployer
SDL Deployer should deploy on remote workstation all required data for run SDL in initial clear state.
Also SDL deploy configuration should be configurable.
Also SDL Deployer should deploy and run SDL Watchdog.

#### Test scripts
Repository of test scripts should contain:
 - Test scripts
 - Test sets
 - common modules for scripts execution
 - files for script execution

### ATF description:

ATF should contain all it's components as git submodules.
ATF should contain fabric file that will call all it's components with correct parameters and config.

ATF fabric file should contain couple of targets:
 - test set run
 - test script run
 
ATF should require path to SDL binaries for work.


## Impact on existing code

Mostly current ATF code will be kept. But additional tools and infrastructure will be created.
There would be a lot of minor changes in current ATF scripts, but they won't be retried from scratch.


## Alternatives considered

### Hold current ATF architecture and testing approach

It is possible to continue developing current approach:

ATF scripts repository contains big amount of utils routine, scripts that required for CI activities and so on.
Current approach is more time consuming than proposed one from testing side of view and needs deep test engineering expertise in using ATF.


### Test SDL manually
Functional scope of SDL is too wide for manual testing, also not all functionality of SDL could be tested in manual mode. 
