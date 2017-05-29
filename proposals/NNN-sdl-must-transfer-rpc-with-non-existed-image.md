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

* App -> SDL: RPC (<Image>)
* SDL checks that <Image> does NOT exist at AppStorageFolder for this app

* SDL -> HMI: RPC (<Image>)
* HMI processes this RPC

* HMI -> SDL: RPC (WARNINGS, message: “Requested image(s) is not found”) //in case of NO any failures

* SDL -> app: RPC (WARNINGS, info: “Requested image(s) is not found”)


## Impact on existing code

The following RPCs will be impacted:
* 1. SendLocation
* 2. ShowConstantTBT
* 3. PerformAudioPassThru
* 4. Show
* 5. AddSubMenu
* 6. AddCommand
* 7. SetGlobalProperties
* 8. OnWayPointChange
* 9. GetWayPoints_response
* 10. UpdateTurnList
* 11. PerformInteraction
* 12. AlertManeuver
* 13. ShowConstantTBT
* 14. ScrollableMessage
* 15. Alert


## Alternatives considered

TBD

