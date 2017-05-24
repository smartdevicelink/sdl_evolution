# Steering wheel location

* Proposal: [NNNN](NNNN-steering-wheel-location.md)
* Author: [Kujtim Shala](https://github.com/kshala-ford)
* Status: **Review ready**
* Impacted Platforms: [Core / iOS / Android / RPC ]

## Introduction

This proposal is about adding a new parameter to the `VehicleType` structure to inform the app about the steering wheel location within the vehicle.

## Motivation

Some apps want to use different templates based on the steering wheel location. As an example TEXT_WITH_BUTTONS_AND_GRAPHIC works great for left handed drives as buttons are closer to the driver. For right handed drives apps would want to use GRAPHIC_WITH_TEXT_AND_BUTTONS. Today apps would use the language/region code and **guess** the location of the steering wheel.

## Proposed solution

In order to improve the user experience for right handed drive the app should know the steering wheel location. This information can be provided to the app right after the app's registration on the head unit. This newly added parameter should be optional for backwards compatibility. The type of the parameter should be an enum. Following values should be allowed:

- `null`: Either the head unit is of an old version and/or the steering wheel location is not known.
- `.LEFT`: The steering wheel location is on the left hand side.
- `.RIGHT`: The steering wheel location is on the right hand side.
- `.CENTER`: The steering wheel location is centered.
- `.NONE`: The vehicle does not contain a steering wheel (e.g. autonomous. different to `null` the app would definitely know that no steering wheel exists).

### HMI and mobile API:

```xml
<enum name="SteeringWheelLocation">
  <description>Describes the location of the Steering Wheel.</description>
  <element name="LEFT" />
  <element name="RIGHT" />
  <element name="CENTER" />
  <element name="NONE" />
</enum>
   :
<struct name="VehicleType">
   :
  <param name="steeringWheelLocation" type="SteeringWheelLocation" mandatory="false">
    <description>See SteeringWheelLocation</description>
  </param>
</struct>
```

## Impact on existing code

- The proposal should just require a minor version change.
- Core and mobile libraries would just implement the API changes.

## Alternatives considered

Language/country code can be used instead. An app can assume that majority of the vehicles e.g. EN_GB are right hand drive.
