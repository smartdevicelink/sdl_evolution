# Continuous integration and testing

* Proposal: [SDL-NNNN](NNNN-Continuous-Integration-And-Testing.md)
* Author: [Pavel Zhdanov](https://github.com/ZhdanovP), [Mykyta Nikora](https://github.com/MNikora)
* Status: **Awaiting Review**
* Impacted Platforms: [Core]

## Introduction

This proposal is about implementation of the Continuous Integration (CI) process for keeping SDL in a trouble-free state. 

## Motivation

Continuous Integration provides a lot of advantages for all actors involved in software product creation such as software developers, product managers, and enterprises.

CI simplifies new features adding, helps to produce high-quality code and makes the development process more predictable by early detection of bugs, regression, and other potential risks.

## Proposed solution

After this proposal is implemented all necessary scripts and environment configuration files, running checks and test results will be ready to use. The main part of the scripts will be used by developers to unify the workstations and work processes. The new repository will be created for storing all configuration needed files. The scripts can be used to deploy the CI on any server, and server resources (cores, memory, disk space, etc.) can be expanded through the cluster tools usage. So, this is what we will get as a result of the implementation, now let us take a look at implementation details.

Currently, the branches that constantly need code health monitoring can be classified into two types:

1. **develop\master branch** - the branch that has to be under permanent testing of the main functionality. There is a potential risk that committed changes can break something. 
2. **feature branch** - this branch type is used when new feature should be developed and added.

Let's consider a few goals that have to be achieved using CI.

### 1. Continuous testing on a specific branch to maintain the current working condition

The following entities are specific types of checks that should be considered on the develop and feature branches:

- Smoke Tests
- Regression Tests
- Feature Tests (applicable only for the feature branches)
- Unit Tests + Coverage Report
- Coding Style Check
- Static Code Analysis
- Dynamic Analysis on Smoke Tests

**! Note that each of the above checks (except Coding Style Check and Static Code Analysis) should be run for all supported Policies flows (External proprietary, Proprietary, HTTP).**

Also, it would be nice to perform project compilation with the different sets of flags: with and without ENABLE_LOG, ENABLE_SECURITY, DEBUG/RELEASE mode etc - since this allows to find hidden problems.

#### ATF/smoke tests running

There are smoke tests to check the main life functions of SDL (such as `run`, `shutdown`, etc.) This type of tests should be run for each `pull` and `push` events. Smoke testing, also known as build acceptance testing (BAT), is a critical aspect of quality assurance that delivers quick and decisive answers on the viability of a particular build.

Ideally, each smoke test should meet these criteria:

- Tests core features only
- The test should be repeatable indefinitely
- Very fast execution
- Should generate few or no false positives

Now SDL includes the following scopes for smoke testing: Registration, API, Heartbeat, Policy, Shutdown, Resumption.

#### ATF/regression tests running

Regression Testing is a full or partial selection of already executed test cases which are re-executed to ensure existing functionality works fine. This testing is done to make sure that new code changes should not have side effects on the existing functionality. It ensures that the old code still works once the new code changes are done. When the new feature is accepted and corresponding code is integrated to sdl_core a new corresponding test scope is integrated to the sdl_atf_test_scripts as well as regression tests extended.

#### Feature Tests

The aim of feature testing is to make sure that new changes for SDL works properly and meet all the intended specifications. All bugs and defects in the features should be found during testing stages otherwise it could cause huge productivity loss. By performing feature testing CI can improve quality of the end product and deliver products with exceptional functionality.

#### Unit testing and coverage

The unit tests are aware of the project's smallest implementation details and control that these parts are operational. Developers run the unit tests locally to test their work. However, the unit tests must be run for all possible events such as `push` and `pull` requests on the develop and feature branches.

#### Coding Style Check

In SDL designing, a certain coding style is accepted that allows us to keep the code consistent. It is important to consider the accepted coding style and check it during delivering of new changes to the codebase. Accordingly, the check style should be executed on:

- Push to develop/feature
- PR to develop/feature
- Nightly on develop/feature
- Weekly on develop/feature

#### **Static code analysis benefits**

* Static Code Analysis helps to identify potential software quality issues during the development phase and before the software goes into production.
* It detects areas in the code that need simplification and improvements.
* The analysis detects programming errors or flaws.
* Static Code Analysis improves communication in the development team and helps developers to produce high-quality code. 

Static analysis tools:
* Cppcheck
* Clang static analyzer
* PVS-studio
* Coverity

#### **Dynamic code analysis benefits**

Dynamic testing is most important in the areas where program reliability, response time, and consumed resources are the crucial criteria. Any bug that occurs in these systems may be critical.

* In most cases, generation of false positives is impossible, as error detection occurs right at the moment of its occurrence, thus, the error detected is not a prediction based on the analysis of the program model, but a statement of the fact of its occurrence;
* It allows us to test proprietary code.

Dynamic code analysis is the method of analyzing an application right during its execution. The dynamic analysis process can be divided into several steps: preparing input data, running a test program launch and gathering the necessary parameters, and analyzing the output data. When performing the test launch. Dynamic analysis tasks should be executed on the Smoke test sets to check the most vital behavior of SDL.

Dynamic analysis tools of Clang sanitizer:
* Address sanitizer
* Thread sanitizer
* Memory sanitizer
* Undefined behavior sanitizer
* Leak sanitizer

Having its own weak and strong points, the dynamic analysis technology can be used most effectively together with the static analysis technology.

### 2. Solving current SDL issues

We have conducted a preliminary analysis of the sdl_core source code by potential analyzing tools and have got a set of actual problems that have to be fixed in scope of this proposal.

For instance, **Cppcheck** has shown more than 200 issues. **PVS-studio** shows a few dozens of issues. Address sanitizer is showing problems of SDL during a shutdown. **Address, thread, memory sanitizers** can show a significantly larger number of issues when it will be executed on ATF tests.

### 3. Creating a subfolder for storing infrastructure files

During the development of Continuous integration infrastructure, a large number of scripts will be created to automate processes and configure the environment. We propose the creation of the separate subfolder in sdl_core named sdl_infrastructure. sdl_infrastructure should contain two subfolders: sdl_ci for storing stuff related to the CI setting up and sdl_workspace for having environment dependencies and stuff for developers.

- sdl_core
    - sdl_infrastructure
        - sdl_tools - will migrate from sdl_core/tools
        - sdl_ci
            - scripts and other stuff
        - sdl_workspace
            - docker containers
            - config. scripts

## Detailed design

The following triggers should be regarded to run checks on each branch (branches were specified in previous paragraph): **Push**, **Pull Request**, **Nightly**, and **Weekly** for some long checks.

The minimum set of checks is:

- Coding Style Check (45s)
- Build project (15m)
- Smoke Tests (18m)
- Build project + Unit Tests (UT) (44m)

CI Build jobs:

| **NIGHTLY**<br>Build check | **WEEKLY**<br>Build check | **PullRequest**<br>Build check | **Push**<br>Build check |
|:--------:|:-------------:|:-----------:|:-----------:|
|   BUILD_TESTS=OFF   |               |             |   BUILD_TESTS=OFF   |
|    BUILD_TESTS=ON    |               |     BUILD_TESTS=ON      |    BUILD_TESTS=ON    |
|          | BUILD_TESTS=ON<br>ENABLE_GCOV=ON<br>+ Coverage |             |          |

CI ATF jobs:

|**ATF TEST SET**|**Trigger**|
|:----------------------:|:--- |
|Smoke|noUT,<br>UT (for PullRequest jobs only)|
|Feature|noUT|
|Regression|noUT|

- **Smoke** - Run ATF tests from the Smoke test set (basic project checks and happy paths of all main features)
- **Feature** - Run ATF tests from the Feature test set (such test set is created for each feature, and includes tests for checking functionality of a new feature). It is applicable only for Feature branches.
- **Regression** - Run ATF tests from all Feature test sets, which are already merged to the develop branch.

### 1. Optimizing of building process and resources usage

To optimize the CI processes and resources usage it is necessary to separate the third-party libraries building from the SDL building. Further, the third-party libraries as preloaded files should be used for all testing related tasks. This approach saves server time and can allow getting the CI status faster.

### 2. Using cluster for a High Availability and Fault Tolerance of the CI processes

To minimize risks of fails, and to optimize CI processes we need to use the Best Practices of computation, and keep project infrastructure on the top level using **Mesos** cluster and **Docker** container-based services. Containers allow building and testing applications in standard, portable ways.
A server cluster is a centralized fault-tolerant system for managing resources. The use of the cluster is appropriate for distributed computing environments in order to ensure the isolation of resources and convenient management. The cluster allows allocating CPU, memory, and other resources for any tasks like CI jobs.

For example **Mesos** can be used as a cluster core to allocate an environment for working tasks. Such frameworks as: Jenkins, Spark, Marathon, Aurora can be used to implement the logic of launching tasks, monitoring their work, scaling, etc.

When the product is growing up, and count of the same time features is growing up too, wee need to have an ability to **scale our CI system fast and without any downtime**. The key to success here is usage of cluster.

Another one point is a **Foult Tolerance**. When you're using a cluster systems you are completely safe from disk failures or even entire server crashes.

Schema of cluster
![img][cluster_schema]

## Potential downsides

No obvious places can be affected.

## Impact on existing code

Can be expected a lot of places in scope of fixing existing issues reported by static/dynamic analysis tools.

## Alternatives considered

Instead of the proposed solutions as Jenkins and Messos the other alternative solutions can be used for CI implementation. Among such alternative solutions for CI: Travis, Github Actions, Drone, GoCD, Bamboo, CircleCI, etc. For cluster technology: Kubernetes, Docker Swarm, Vagrant, and dozens of others.

[cluster_schema]: ./assets/proposals/NNNN-Continuous-Integration-And-Testing/ClusterSchema.png
