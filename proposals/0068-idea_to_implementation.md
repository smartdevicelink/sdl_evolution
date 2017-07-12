# Idea To Implementation

* Proposal: [SDL-0068](0068-idea_to_implementation.md)
* Author: [Joey Grover](https://github.com/joeygrover)
* Status: **Accepted**
* Impacted Platforms: [Meta / RPC]

## Introduction

This proposal is to define a process on how ideas and improvements are taken from the SDL Evolution Process to actually being implemented, specifically for changes that alter the RPC spec.

## Motivation

Currently it is very hard to track how or when different proposals will be implemented. Some proposals that only affect a single project and not the protocol or RPC spec can be implemented as time allows for that specific projects release cycle. However, whenever a proposal affects the RPC spec it has to be coordinated among all the SDL projects so that proper inoperability is achieved.


## Proposed solution

This proposal is to define a process from idea to implementation. This also aims to ensure that the SDL RPC spec and its versions are well defined.

The process is defined as such:

![SDL Workflow][sdl-workflow]

#### RPC Spec Timing
The biggest roadblock with this process is that we would have to define what to include a while in advance to actual releases of the projects. 

An RPC spec would have to be accepted before the next version of the projects work started. Then it will become clear which version of the projects support which version of the RPC spec.

It is possible that sdl\_core skips RPC spec versions. For example, release 4.4 of sdl\_core could support v4.5.0 of the RPC spec. Then the next version of the RPC spec is approved (v4.6.0) and implemented into the next release of the SDL proxies. However, sdl\_core is set for two releases a year, unlike the proxies that are slated to have four. That means a new RPC spec version (v4.7.0) could be approved after v4.6.0 was implemented into the proxy libraries. Then the next release of both the proxies and sdl\_core would have v4.6.0 implemented. 


|Project| Release Version| RPC Spec version |
|----|-----|-----|
|Core| 4.3.0|4.4.0
|Android Proxy|4.3.0|4.4.0|
|iOS Proxy|4.5.0|4.4.0|
|**RPC Spec**|---|4.5.0|
|Android Proxy|4.4.0|4.5.0|
|iOS Proxy|4.6.0|4.5.0|
|**RPC Spec**|---|4.6.0|
|Core| 4.4.0|4.6.0|
|Android Proxy|4.5.0|4.6.0|
|iOS Proxy|4.7.0|4.6.0|


## Potential downside

N/A

## Impact on existing code

No actual changes to code. The SDL Core project will be able to take the MOBILE_API.XML file from the RPC spec git repo directly though. 

## Alternatives considered
N/A

[sdl-workflow]: ../assets/proposals/0068-idea_to_implementation/sdl_workflow.png
