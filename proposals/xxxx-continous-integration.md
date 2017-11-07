# Configuration management

* Proposal: [SDL-xxxx](xxxx-Configuration-Management.md)
* Author: [Vadym Kushnirenko](https://github.com/vkushnirenko-luxoft)
* Status: **Awaiting review**
* Impacted Platforms: [Core/??]

## Introduction

This proposal is about configuration management system for continuous integration and delivery program components and tests. The process of building and binaries now implemented as Jenkins server on the private cloud. Anyone can watch it. 

## Motivation

The development process should be open and transparent. Than any person could deploy it on his own side, improve it and modernize and give recomendations about upgrading it.
Configuration must be saved as a code, be flexible and be renewal in any moment from public resources.

## Proposed solution

The solution proposes to use  docker containers for deploying all components. For building and keeping artifacts we must use next tools:
1) Jenkins - continous integration system.
2) Docker containers - to up clean build environment quickly and scalable.
3) Github - to keep Dockerfiles and Jenkins jobs.
4) Ansible - to prevent human mistakes.
5) Artifactory - to keep artifacts - builds and test results.


### HMI


## Potential downsides

NA

## Impact on existing code

- requires changes on SDL core, both SDKs (Android, iOS) and APIs (mobile, HMI).


## Alternatives considered

NA
