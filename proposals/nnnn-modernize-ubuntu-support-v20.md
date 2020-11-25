# Modernize Ubuntu Support V20 LTS

* Proposal: [SDL-NNNN](nnnn-modernize-ubuntu-support-v20.md)
* Author: [Jack Byrne](https://github.com/JackLivio)
* Status: **Accepted**
* Impacted Platforms: [Core, ATF]

## Introduction

This proposal would like to provide support for Ubuntu 20 LTS and bump the minimum required version of Ubuntu to Ubuntu 18 LTS. Currently Ubuntu 18 is the recommended platform and Ubuntu 16 is the minimum required version.

These changes will mainly affect the build process for SDL Core and ATF.

## Motivation

Ubuntu 16 will lose support on April 30, 2021, therefore it is important that we update the minimum required version for using SDL Core and related platforms that use a linux environment.

This type of proposal needs to be entered every couple of years to keep up with new versions and retire older environments.

## Proposed solution

The proposed solution is to make necessary updates for SDL Core and ATF to use Ubuntu 20, while maintaining compatibility with Ubuntu 18.

The main updates will include resolving compiler issues and warnings from using the Ubuntu 20 LTS environment which includes GCC version 9.3. 

Currently Ubuntu 18 LTS uses GCC 7.5.

An additional note is that Ubuntu 20 comes installed with only Python3 (not 2.7), but this should not be an issue as all of the support scripts used by SDL Core have been updated to use python3 in a previous release.


## Potential downsides

Changing environments is bound to cause compiler and runtime issues that will require resources to fix. Switching to a newer Ubuntu version should be done earlier in a release cycle in order to find non-obvious issues over the course of the development cycle.

## Impact on existing code

Updates may be needed to the build scripts used in SDL Core and ATF. Any runtime issues will need to be fixed. Runtime issues will be discovered via a full regression test run via ATF.

SDL Core and related platform documentation must be updated to note support of Ubuntu 20.

## Alternatives considered

- Only update the minimum version of Ubuntu to 18 LTS and do not add support for version 20.
