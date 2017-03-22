# Stabilize Automated test framework

* Proposal: [SDL-NNNN](NNNN-atf-stabilization-proposal.md)
* Author: [Alexander Kutsan](https://github.com/smartdevicelink)
* Status: **Awaiting review**
* Impacted Platforms: [Core / ATF]

## Introduction
Integration SDL to OEM environment consist of 2 main activities:
 - adjustments of sdl_core 
 - integration ans verification
 
Integration requires checking SDL functionality on new platform within new infrastructure. Mission of their Automated test framework(ATF) is reducing efforts for checking existing SDL functionality. And speed up covering with tests new functionality.Also ATF should monitor regression during development cycle. 

#### Problems in current testing approaches :

 - Unable to setup SDL deployment preconditions for test script automatically
 - Verification of different SDL configurations is possible only in manual mode
 - Unable to create one unified test set for main SDL functionality
 - Unable test SDL, ran manually (or externally, for example on OEM Head-Unit) 
 - Required a lot of efforts creating and supporting of CI system
 - Poor versioning of ATF. It leads to problems with defects analysis and scripts re-usability 
 - Creating new scripts requires deep knowledge and experience in current ATF architecture 
 - Complex maintenance procedure of tests and test sets

The proposal is to make ATF more flexible, salable and easy to use and integrate with popular CI systems. ATF should be full of all required information and easy to analyze.
Also some functionality of ATF should be moved to scripts common files due to its correlation/dependency between SDL version and features.

#### Proposed solution benefits : 
 - Possibility to verify SDL integration on OEM platform automatically (with or without mobile or HMI)
 - Seamless integration ATF into CI system
 - Clear tracebility of ATF,  test scripts, and SDL version 
 - ATF facade will simplify creating and supporting test scripts and test sets
 - Unified approach for test script and test set creating
 - Proposed architecture allows flexible integration of ATF into existing SDL verification infrastructure on OEM side

## Motivation

Current ATF requires and allows changes during testing specific SDL scenarios. 
It also requires additional environment preparation/configuration and control during performing test sets
and integrating ATF to popular CI systems.
It is necessary to make ATF easy to use and extend its scaling possibilities.
A lot of common functionality should be moved from ATF to to common scripts.

## Proposed solution

There are 3 different layers of using ATF:

1. Local executing and debugging specific scenario
2. Local test set execution, logs, reports, traffic analyses. Test set can be executed on remote SDL and on local SDL build
3. CI execution of test set, collection of logs, reports, traffic logs for further analysis 

ATF should be easy to use as for executing and debugging one concrete scenario on local workstation even with custom modified SDL.

ATF architecture should be modified to support all these 3 layers of execution. Also ATF should support testing SDL on remote workstation/target. 

Automatic creating of connection and mobile session with SDL, and HMI - SDL connection should be removed from ATF.
Many scripts do not need HMI or mobile connection, or app registration with specific parameters. This functionality should be a part of scripts, but not ATF.

ATF output artifacts should be improved.
ATF should provide test engineer ability to log custom messages
Proposed output artifacts of ATF:
 * Transport logs with time stamps and test case marks
 * Collected SDL logs (via Telnet)
 * ATF junit (or other popular report format) report (if test set was executed) 
 * ATF internal log with custom messages and expectations analyses
 * Test script artifacts (files, used in test script)
 
ATF should not fail script due to internal logic. In case if something unusual occurs (SDL is down or connection is terminated) ATF should provide callback to script, and user should decide if script should be failed in this case. 

ATF should provide interface for pre and post-conditions for scripts. Post-condition should be executed even if test was failed.

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

Such splitting will allow -> enable ATF to change any part to the one that matches environment according to current needs (SDL on target for example)
It also allows to change some part of ATF to widely used open-source test frameworks (for example python-nose can be used as test set runner)
Each part of ATF can be separately unit tested and keep own versioning and development cycle. 

### ATF Components:
![Component relations](/assets/atf_stabilization_proposal/components_model.png)
![Deployment structure](/assets/atf_stabilization_proposal/script_executor_relations.png)


#### Script runner description:

Script runner should consist from 2 parts:
 - Test case executor
 - API Facade

![Deployment structure](/assets/atf_stabilization_proposal/remote_sdl_model.png)

API Facade should provide all required API for testing SDL.
 
Test cases executor should manage results of test cases, executing Setup and TearDonw of each test case and storing test reports.

_Test cases executor functionality probably can be covered with python nose framework._


#### ATF test set executor description:

ATF test set executor should execute some list of tests scripts and collect their artifacts. 
It should deploy SDL with SDL Deployer before each script run fro clean environment.
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

Mostly current ATF code will be kept. But additional tools and infrastructure should be created.
There will be a lot of minor changes in current ATF scripts, but they won't be retried from scratch. 


## Alternatives considered

### Hold current ATF architecture and testing approach 
It is possible to continue developing current approach :

Atf scripts repository contains big amount of utils routine, scripts that required for CI activities and so on. 

But It won''t allow in further testing remote SDL and it is rely inconvenient way to collect test reports, analyze SDL behavior and keep versioning of scripts for SDL testing.


### Test SDL manually 
Functionality of SDL is too big for full manual testing 
