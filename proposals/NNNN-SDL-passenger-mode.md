# SDL Passenger Mode

* Proposal: [SDL-NNNN](NNNN-mobile-api-versioning-revision.md)
* Author: [Brett McIsaac](https://github.com/brettywhite)
* Status: **Awaiting Review**
* Impacted Platforms: iOS, Android

## Introduction

Allow a passenger to dismiss the lockscreen to improve usability of applications.

## Motivation

Having used SDL extensively, passengers of SDL enabled vehicles may find it frustrating to be locked out of in-app UI while the vehicle is in motion. SDL, for safety purposes, uses a boolean based on the vehicle's speed to enable or disable the lock screen. While this logic is good when there is only the driver in the vehicle, it is prohibitive when others are in the vehicle, forcing users to abandon their use of SDL in favor of Carplay, Android Auto, or Bluetooth. Other platforms currently allow this, with Carplay's lock screen being dismissible and Apple's *I'm not driving* action sheet being added in iOS 11.

Additionally, this functionality would benefit app developers, allowing access to their UI by a passenger of a vehicle while maintaining the lock screen for the driver. 

## Proposed solution

The proposed solution is to have a button in the default lock screen that certifies that the user *is not driving*.

> "I am not driving"

This will disable the lockscreen, and for the remainder of that app's session, allow the app to discard distracted driver `DD_On` or `DD_Off` notifications from Core. This will allow access to the application's UI while allowing the features of SDL to be used in the vehicle.

## Potential downsides

Driver distraction is an issue, and there is always the ability for the driver to certify that *they aren't driving*. However, with this certification by the driver, they are pushing the liability onto themselves, similar to them using a phone while in the car regardless of the software that the head unit is running. There are slightly more complicated ways of ensuring this, that I will go over in Alternatives. 

## Impact on existing code

This should be a minor version change, it would be adding additional parameters to existing APIs.

## Alternatives considered

1. If the certification button is not enough, we can allow apps the specific ability to `getBeltStatus()` without needing special permission. As this is currently part of the `GetVehicleDataResponse`, thought would be needed to ensure all apps have access to this information. From there, if there is indeed a passenger or other riders, the passenger button would appear on the lockscreen and allow access to the app while the vehicle is in motion. While this is more complicated, it futher ensures that the driver cannot override the system as easily. 

