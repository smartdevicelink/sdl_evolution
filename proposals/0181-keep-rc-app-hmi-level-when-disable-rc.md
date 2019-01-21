# SDL shall not put RC applications to HMI level NONE when user disables RC in HMI

* Proposal: [SDL-0181](0181-keep-rc-app-hmi-level-when-disable-rc.md)
* Author: [Zhimin Yang](https://github.com/smartdevicelink/yang1070)
* Status: **Accepted**
* Impacted Platforms: [ Core / HMI]

## Introduction

SDL shall not put `REMOTE_CONTROL` `appHMIType` applications to HMI level `NONE` when user disables remote control in HMI.

## Motivation
The asked behavior is in the same line with other existing features, like the permission of function groups. If a user disables the application's permission to access vehicle signals like gps, speed, etc. the application will keep its current HMI level and will not be put into HMI level `NONE` by SDL. Furthermore, SDl allows activating  an application using such signals. However, SDL rejects any RPC that relates to the disallowed signals. In this proposal, we propose the following changes. SDL shall keep a RC application's HMI status unchanged if the user disables RC. SDL can activate a RC application even if RC is disabled. 


## Proposed solution

We propose the changes as in the following tables:

  | Current | Expected SDL core change
-- | -- | --
1 | HMI sends a notification to SDL that RC is disabled | No change
2 | SDL puts RC apps from `FULL`/`LIMITED` to `NONE` | SDL does not change apps' HMI level
3 | SDL sends `OnHMIStatus` (`NONE`) to all RC applications that put to `NONE` | SDL does not send `OnHMIStatus`
4 | SDL keeps RC apps registered | No change
5 | SDL unsubscribes all RC apps’ RC modules from HMI | No change
6 | SDL releases all RC modules allocated to RC apps and sends `OnRCStatus` notifications | No change
7 | SDL ignores `OnInteriorVehicleData` from HMI and SDL does not send `OnInteriorVehicleData` to apps | No change
8 | SDL disallows RC related RPC, such as `GetInteriorVehicleData`, `SetInteriorVehicleData` and `ButtonPress` requests from apps | No change
9 | HMILevel cannot change to anything other than `NONE` until RC functionality is enabled | HMI level can change like regular apps. In addition, A RC app can be activated.

  | Current | Expected HMI change
-- | -- | --
1 | HMI shows registered RC apps grey | HMI shows registered RC apps as regular apps (not greyed out)
2 | HMI does not allow activating a RC app when RC disabled | HMI allows activating a RC app. If the user tries to activate an RC app when RC is disabled, HMI shows a pop up “Enable remote control feature for all mobile apps? Please press `Yes` to enable remote control or `No` to cancel. See Settings to disable.” If user presses `Yes`, enable Remote Control. If users presses `No`, do not enable Remote Control. Activate the app regardless of user's input. If the user tries to activate an RC app when RC is enabled, HMI does not show any pop up just as regular apps. If the user tries to activate a non-RC app, HMI does not show any pop up regardless of RC enabled or disabled.

## Potential downsides
None

## Impact on existing code

SDL core change is here:  https://github.com/smartdevicelink/sdl_core/pull/2197

HMI change is here:       https://github.com/smartdevicelink/sdl_hmi/pull/83

## Alternatives considered
None

