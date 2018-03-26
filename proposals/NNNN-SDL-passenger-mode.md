# SDL Passenger Mode

* Proposal: [SDL-NNNN](NNNN-mobile-api-versioning-revision.md)
* Author: [Brett McIsaac](https://github.com/brettywhite)
* Status: **Awaiting Review**
* Impacted Platforms: iOS, Android, Core, RPC

## Introduction

Allow a passenger to dismiss the lockscreen to improve usability of applications.

## Motivation

Having used SDL extensively, passengers of SDL enabled vehicles may find it frustrating to be locked out of in-app UI while the vehicle is in motion. SDL, for safety purposes, uses a boolean based on the vehicle's speed to enable or disable the lock screen. While this logic is good when there is only the driver in the vehicle, it is prohibitive when others are in the vehicle, forcing users to abandon their use of SDL in favor of Carplay, Android Auto, or Bluetooth. Other platforms currently allow this, with Carplay's lock screen being dismissible and Apple's *I'm not driving* action sheet being added in iOS 11. More recently, Android Auto has made dismissing their lock screen even easier and more prominent.

Additionally, this functionality would benefit app developers, allowing access to their UI by a passenger of a vehicle while maintaining the lock screen for the driver. 

## Proposed solution

Modify the `OnDriverDistraction` notification:

```xml
<function name="OnDriverDistraction" messagetype="notification">

  <!-- newly added parameter -->
  <param name="lockScreenDismissalEnabled" type="Boolean" mandatory="true">
    <description>
      If enabled, the lockscreen will be able to be dismissed while connected to SDL, allowing users 
      the ability to interact with the app. Dismissals should include a warning to the user and ensure 
      that they are not the driver.
    </description>
  </param>

</function>
```

### Part 1 - Core

In addition to modifying the notification as shown above, there needs to be an addition to the policy table that feeds into that notification. This way, the OEM can update the ability to allow / disallow this with an update to their policy table. 

### Part 2 - Proxy

In addition to modifying the notification, the proposed solution is to have a button in the default lock screen that certifies that the user *is not driving*. This will be shown if `lockScreenDismissalEnabled` is set to `true`, and hidden if set to `false`.

> "I am not driving"

This will disable the lockscreen, and for the remainder of that app's session, allow the app to discard distracted driver `DD_On` or `DD_Off` notifications from Core. This will allow access to the application's UI while allowing the features of SDL to be used in the vehicle.

## Potential downsides

Driver distraction is an issue, and there is always the ability for the driver to certify that *they aren't driving*. However, with this certification by the driver, they are pushing the liability onto themselves, similar to them using a phone while in the car regardless of the software that the head unit is running. The OEM also has the ability to not allow this or change it based on policies allowing flexibility in countries where laws may be different.

## Impact on existing code

This should be a minor version change.

## Alternatives considered

The alternative to using the policy table would be to set the true or false in the ini, however this would be less flexible in pushing updates in the future should the OEM change their mind and / or a law forces them to change. 

