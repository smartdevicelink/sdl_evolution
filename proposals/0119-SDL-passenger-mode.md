# SDL Passenger Mode

* Proposal: [SDL-0119](0119-SDL-passenger-mode.md)
* Author: [Brett McIsaac](https://github.com/brettywhite)
* Status: **Accepted with Revisions**
* Impacted Platforms: iOS, Android, Core, RPC, Policy Server

## Introduction

Allow a passenger to dismiss the lock screen to improve usability of applications. This re-visited proposal now includes a way for individual OEMs to control this mode via policy updates.

## Motivation

Having used SDL extensively, passengers of SDL enabled vehicles may find it frustrating to be locked out of in-app UI while the vehicle is in motion. SDL, for safety purposes, uses a boolean based on the vehicle's speed to enable or disable the lock screen. While this logic is good when there is only the driver in the vehicle, it is prohibitive when others are in the vehicle, forcing users to abandon their use of SDL in favor of Carplay, Android Auto, or Bluetooth. Other platforms currently allow this, with Carplay's lock screen being dismissible and Apple's *I'm not driving* action sheet being added in iOS 11. More recently, Android Auto has made dismissing their lock screen even easier and more prominent.

Additionally, this functionality would benefit app developers, allowing access to their UI by a passenger of a vehicle while maintaining the lock screen for the driver. 

## Proposed solution

Modify the `OnDriverDistraction` notification:

```xml
<function name="OnDriverDistraction" messagetype="notification">

  <!-- newly added parameter -->
  <param name="lockScreenDismissalEnabled" type="Boolean" mandatory="false">
    <description>
      If enabled, the lock screen will be able to be dismissed while connected to SDL, allowing users 
      the ability to interact with the app.
    </description>
  </param>
  <param name="lockScreenDismissalWarning" type="String" mandatory="false">
    <description>
      Warning message to be displayed on the lock screen when dismissal is enabled.
      This warning should be used to ensure that the user is not the driver of the vehicle, 
      ex. `Swipe down to dismiss, acknowledging that you are not the driver.`.
      This parameter must be present if "lockScreenDismissalEnabled" is set to true.
    </description>
  </param>
</function>
```

### Part 1 - Core

In addition to modifying the notification as shown above, there needs to be an addition to the policy table that feeds into that notification. This way, the OEM can update the ability to allow / disallow this with an update to their policy table.  The exact values used for `lockScreenDismissalEnabled` and `lockScreenDismissalWarning` would be defined by the following new policy table fields:

```json
{
    "policy_table": {
        "module_config": {
            ...
            "lock_screen_dismissal_enabled": true
        },
        ...
        "consumer_friendly_messages" : {
            ...
            "LockScreenDismissalWarning": 
                "languages": {
                    "en-us": {
                        "textBody": "Swipe down to dismiss, acknowledging that you are not the driver"
                    },
                    ...
                }
            }
        }
    }
}
```

The `lockScreenDismissalWarning` text would specifically be pulled from the `textBody` field of the appropriate consumer-friendly message (corresponding to the active UI language), all other fields will be ignored.

### Part 2 - Proxy

In addition to modifying the notification, the proposed solution is to add a swipe down gesture to dismiss the lock screen (as well as display the provided warning message), similar to Android Auto. This gesture will be allowed if `lockScreenDismissalEnabled` is set to `true`, and disabled if set to `false`. If a subsequent notification is received that changes the `lockScreenDismissalEnabled` parameter, the lockscreen will re-appear.

## Potential downsides

Driver distraction is an issue, and there is always the ability for the driver to certify that *they aren't driving*. However, with this certification by the driver, they are pushing the liability onto themselves, similar to them using a phone while in the car regardless of the software that the head unit is running. The OEM also has the ability to not allow this or change it based on policies allowing flexibility in countries where laws may be different.

## Impact on existing code

This should be a minor version change.

## Alternatives considered

The alternative to using the policy table would be to set the true or false in the ini, however this would be less flexible in pushing updates in the future should the OEM change their mind and / or a law forces them to change. 
