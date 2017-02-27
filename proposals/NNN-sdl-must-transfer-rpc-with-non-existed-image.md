# SDL must transfer RPC with non-existed "Image" to HMI

* Proposal: SDL-NNNN
* Author: Melnyk Tetiana
* Status: Awaiting review
* Impacted Platforms: Core / RPC

## Introduction

To change SDL behavior in case requested by app "Image" does NOT exist at "AppStorageFolder"

## Motivation

Currently SDL invalidates or rejects all RPC requested "Image" that does NOt exist at apps "AppStorageFolder"

## Proposed solution

SDL must transfer all RPCs to HMI for processing even if "Image" does NOT exist/was not uploaded before this request

## Detailed design

App requests "Image" via any applicable RPC. SDL checks "Image" - does NOT exist at "AppStorageFolder". SDL transfers this RPC to HMI for processing.
Expected resultCode from HMI is "WARNINGS" + "message: Requested image(s) does not exist"

## Impact on existing code

SDL behavior only

## Alternatives considered

TBD

