# Configuration management

* Proposal: [SDL-xxxx](xxxx-Configuration-Management.md)
* Author: [Vadym Kushnirenko](https://github.com/vkushnirenko-luxoft)
* Status: **Awaiting review**
* Impacted Platforms: [Core/??]

## Introduction

This proposal is about configuration management system for continuous building and testing code.

## Motivation

The development process should be open and transparent. Any person could deploy it on his own side, use it and propose recomendations about improvements.
Configuration must be saved as a code, be flexible and be renewal in any moment from public resources.

## Proposed solution

The solution proposes to use docker containers for deploying all components. For building and keeping artifacts we must use next tools:
1) Jenkins - continuous integration system.
2) Docker containers - to up clean build environment quickly and scalable.
3) Github - to keep Dockerfiles and Jenkins jobs.
4) Artifactory - to keep artifacts - builds and test results.

### Github
Create a repository to save code of environment. This repository includes:
- dockerfile for jenkins master, 
- dockerfiles jenkins slaves, 
- dockerfile for artifactory,
- the tree of jenkins jobs with config.xml for each job,
- scripts for running during building process,
- instruction how to download dockerfiles, create containers, run jenkins and run building jobs.

### Jenkins
Jenkins is the system for automation routine operations:
- it runs jobs by timer, by trigger from github pulls and pull requests,
- it runs tests during or after succesfull finishing of building jobs and send emails to responsible persons and jenkins administrators or send notifications into slack channel,
- it has many plugins for code building, testing, email notifications,
- it is free.

### Docker
Docker containers allow quickly run new environment for code building. At the end of job container collapses and deletes temporary files after previous job.

### Artifactory
Keeps binaries and tests results as the tree of archives.

## Potential downsides
N/A

## Impact on existing code
N/A

## Alternatives considered
N/A
