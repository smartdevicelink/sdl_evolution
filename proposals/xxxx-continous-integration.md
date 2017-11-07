# Configuration management

* Proposal: [SDL-xxxx](xxxx-Configuration-Management.md)
* Author: [Vadym Kushnirenko](https://github.com/vkushnirenko-luxoft)
* Status: **Awaiting review**
* Impacted Platforms: [Build/Test server]

## Introduction

This proposal is about providing a set of scripts to easy manage our build/test system.

## Motivation

The building process should be transparent. Any person should be able to deploy build server on his side, use it and propose recomendations about improvements.
Build server configuration must be saved into files, be flexible and be applied in any moment from public resources.

## Proposed solution

Key components of build system are:
- jenkins master - it manages build/test processes,
- jenkins slaves - servers which builds and tests,
- artifactory - keeps archive with binaries and log files.
The solution proposes to use docker containers for components deployment. 
### 1) Jenkins - continuous integration system.
https://jenkins.io/
Jenkins is the system for automation routine operations:
- it runs jobs by timer, by trigger from github pulls and pull requests,
- it runs tests during or after succesfull finishing of building jobs and send emails to responsible persons and jenkins administrators or send notifications into slack channel,
- it has many plugins for code building, testing, email notifications,
- it is free.
### 2) Docker containers - to run clean environment quickly and scalable.
https://www.docker.com/
Docker containers allow to quickly run and stop environment for code building. At the end of job container collapses and deletes temporary files after previous job. For example, jenkins master runs docker container, then starts build process inside this container, archives artifacts and send it to artifactory, and send notifications to developers. Then it stops the container and waits for the next job.
### 3) Github - to keep Dockerfiles and Jenkins jobs.
https://github.com/
Create a repository to save to store build environment configurations. This repository includes:
- dockerfile for jenkins servers,
- dockerfile for artifactory,
- the tree of jenkins jobs with config.xml for each job,
- scripts,
- instruction how to download dockerfiles, create containers, run jenkins and run building jobs.
### 4) Artifactory - to keep artifacts - builds and test results.
https://www.jfrog.com/artifactory/
Keeps binaries and tests results as the tree of archives.
## Potential downsides
N/A
## Impact on existing code
N/A
## Alternatives considered
N/A
