# Allow navigation apps to access information about WiFi networks


* Proposal: [SDL-NNNN](NNNN-allows-navigation-apps-to-access-information-about-Wi-Fi-networks.md)
* Author: [zhouxin627](https://github.com/zhouxin627)
* Status: **Awaiting review**
* Impacted Platforms: [Java Suite]

## Introduction
This proposal requires all current navigation apps to include a new permission (android.permission.ACCESS_WIFI_STATE) to benefit from the issue fix as follows:

https://github.com/smartdevicelink/sdl_java_suite/pull/1259


## Motivation
Currently, there are some issues with navigation apps when users enable WiFi after the navigation apps are activated.

For example:
1. SDL failed to start video streaming if users enable WiFi on the head unit after the NaviAPP is activated.
https://github.com/smartdevicelink/sdl_java_suite/issues/1235
2. SDL failed to start video streaming if users enable WiFi on the phone more than 150s after the NaviAPP is activated.

https://github.com/smartdevicelink/sdl_java_suite/issues/1236

To fix these issues, navigation apps need to access information about Wi-Fi networks.
It would help SDL greatly improve the user experience on VideoStreaming via BT+Wi-Fi.


## Proposed solution
Add manifest permission to navigation apps that allows them to access information about Wi-Fi networks.
```xml
    <!-- Required to check if WiFi is enabled -->
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
+   <uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
```

## Potential downsides
No downsides were identified.

## Impact on existing code
This proposal has no breaking change, so there should be no impact on existing code.

## Alternatives considered
No alternatives were identified.
