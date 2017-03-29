# SDL must transfer RPC’s with invalid image reference parameters to the HMI
 * Proposal: [SDL-0042](0042-transfer-invalid-image-rpc.md)
 * Author: [Markos Rapitis](https://www.github.com/mrapitis)
 * Status: **Accepted**
 * Impacted Platforms: Core

## Introduction

Update SDL Core behavior to more gracefully handle RPC requests that provide an invalid image reference. Any RPC that provides a reference to an image that is not located in the AppStoreFolder is considered invalid (the AppStoreFolder is specified in the SmartDeviceLink.ini.)

## Motivation

Currently SDL Core invalidates or rejects all RPC’s that include an invalid Image reference. While sending an RPC from the mobile app with an invalid image reference is generally frowned upon, rejecting an RPC altogether by SDL Core is very unforgiving behavior – especially when an Image parameter is potentially used to only supplement the presented information.

## Proposed solution

SDL Core must transfer RPCs with both valid and invalid image reference parameters to the HMI for processing. In the case that the image parameter is invalid within an RPC, SDL Core will populate the warnings portion of the result code. The HMI can then in turn decide how to process and display the RPC given the provided context from SDL Core.

The mobile app requests an RPC that makes use of an "Image" parameter. Next SDL Core validates the Image parameter by verifying existence in the "AppStorageFolder". If the Image is invalid for any reason, SDL transfers this RPC to HMI for processing. Expected resultCode from HMI is "WARNINGS" + "message: Requested image(s) not found"

Sample state diagram:

* App -> SDL: RPC ()

* SDL checks that  does NOT exist at AppStorageFolder for this app

* SDL -> HMI: RPC ()

* HMI processes this RPC

* HMI -> SDL: RPC (WARNINGS, message: “Requested image(s) not found”)

* SDL -> app: RPC (WARNINGS, info: “Requested image(s) not found)”)

## Potential downsides
Since RPC's with invalid image references are processed successfully, the mobile app may be less likely to resolve logical errors in image processing.

## Impact on existing code

These changes impact SDL Core and HMI processing of RPC’s that make use of Image type parameters. The following RPC’s will be impacted

The following RPCs will be impacted:

1. SendLocation
2. ShowConstantTBT
3. PerformAudioPassThru
4. Show
5. AddSubMenu
6. AddCommand
7. SetGlobalProperties
8. OnWayPointChange
9. GetWayPoints_response
10. UpdateTurnList
11. PerformInteraction
12. AlertManeuver
13. ShowConstantTBT
14. ScrollableMessage
15. Alert

## Alternatives considered

Handle via API’s in the enhanced framework in the mobile library. In this case, the enhanced framework builds and sends the RPC and because of API validation and book keeping in the mobile library an RPC could never be sent to SDL Core with a reference to an invalid image.
