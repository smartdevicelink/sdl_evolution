# Possibility to update video streaming capabilities during ignition cycle

* Proposal: [SDL-NNNN](NNNN-Update-video-streaming-capabilities-during-ignition-cycle.md)
* Author: [Dmytro Boltovskyi](https://github.com/dboltovskyi)
* Status: **Awaiting review**
* Impacted Platforms: [Core / iOS / Java Suite]

## Introduction

The main purpose of this proposal is to make it possible to update video streaming capabilities during the ignition cycle.

## Motivation

Within the implementation of the [Pixel density and Scale](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0179-pixel-density-and-scale.md) proposal, new video streaming capabilities parameters `diagonalScreenSize`, `pixelPerInch` and `scale` were introduced.

Usually, these parameters are passed to SDL Core by the HMI in `UI.GetCapabilities` response during HMI initialization process. That means if parameters are defined in a current ignition cycle they cannot be updated until the next cycle.
However, the HMI is able to change the values of these parameters dynamically, and currently, there is no way to notify SDL Core and Mobile application about the new values.

## Proposed solution

### SDL Core changes

In order to make it possible to update the described parameters during a single ignition cycle, existing `OnSystemCapabilityUpdated` notification can be used.
Currently, `REMOTE_CONTROL` and `APP_SERVICES` capabilities can already be updated through it, so the idea is to extend this list by `VIDEO_STREAMING` capabilities.

SDL Core gets initial values through `UI.GetCapabilities` request/response.
After that, these values can be updated by the HMI through `OnSystemCapabilityUpdated` notification.

`OnSystemCapabilityUpdated` notification will be transferred to Mobile application if it has set `subscribe` to `true` using `GetSystemCapability` for `systemCapabilityType` = `VIDEO_STREAMING`.

HMI needs to be notified if a particular application is subscribed on `SystemCapability` updates.

#### HMI API

```xml
<function name="OnSystemCapabilitySubscription" messagetype="notification">
  <param name="systemCapabilityType" type="SystemCapabilityType" mandatory="true">
    <description>
      The type of system capability which app is subscribed/unsubscribed to.
    </description>
  </param>
  <param name="isSubscribed" type="Boolean" mandatory="true">
    <description>
      Defines whether the application is subscribed to get updates for the defined systemCapabilityType.
    </description>
  </param>
  <param name="appID" type="Integer" mandatory="true">
    <description>
      ID of the application that relates to this subscription status change.
    </description>
  </param>
</function>
```

In case application sends `GetSystemCapability` with the defined `subscribe` parameter, SDL has to send `OnSystemCapabilitySubscription` notification to HMI.

#### Sequence diagram

![Sequence diagram](/assets/proposals/NNNN-Update-video-streaming-capabilities-during-ignition-cycle/sequence_diagram.png)

### Mobile libraries changes (Java Suite and iOS)

Mobile applications should be able to update the streaming content window to the new video streaming capabilities received in `OnSystemCapabilityUpdated`.

## Potential downsides

N/A

## Impact on existing code

There should be a minimal impact on existing code.

## Alternatives considered

N/A
