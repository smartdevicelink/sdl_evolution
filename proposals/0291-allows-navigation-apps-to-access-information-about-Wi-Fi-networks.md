# Allow navigation apps to access information about WiFi networks


* Proposal: [SDL-0291](0291-allows-navigation-apps-to-access-information-about-Wi-Fi-networks.md)
* Author: [Zhou Xin](https://github.com/zhouxin627)
* Status: **Returned for Revisions**
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

Basically, the problem is that NaviAPPs start video streaming unsuccessfully in the following use cases:

1. Activate the NaviAPP, then enable WiFi on the head unit within 150 seconds.
2. Activate the NaviAPP, wait more than 150 seconds, then enable WiFi on the head unit.

3. Activate the NaviAPP, after more than 150 seconds, then enable WiFi on the phone

To fix these issues, navigation apps need to access information about WiFi networks.

It would help SDL greatly improve the user experience on VideoStreaming via BT+WiFi.



## Proposed solution
Add manifest permission to navigation apps that allows them to access information about WiFi networks.

```xml
    <!-- Required to check if WiFi is enabled -->
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
+   <uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
```

## Potential downsides
No downsides were identified.

## Impact on existing code
This will be a minor version change to the Java Suite Library.

## Alternatives considered
No alternatives were identified.
