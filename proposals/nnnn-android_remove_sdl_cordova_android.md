# Remove SmartDeviceLink Cordova plugin

* Proposal: [SDL-nnnn](nnnn-android_remove_sdl_cordova_android)
* Author: [Bilal Alsharifi](https://github.com/bilal-alsharifi)
* Status: **awaiting review**
* Impacted Platforms: [Android]

## Introduction

The [SmartDeviceLink Cordova plugin](https://github.com/smartdevicelink/sdl_cordova_android) was developed to enable web-based apps to access vehicle data via SDL. When the plugin was written, Apache Cordova Framework was more popular among mobile developers. In recent years, however, Cordova started to become less popular. Moreover, SmartDeviceLink Cordova plugin hasn't had any updates in the last three years.


## Motivation

Apache Cordova is a framework that lets developers write mobile applications using HTML, CSS, and JavaScript inside a native app container. Mobile developers were excited about it because of its simplicity. However, in recent years, it started to lose popularity in favor of other hybrid development frameworks. The SmartDeviceLink Cordova plugin was written to allow developers to write SDL enabled apps utilizing Cordova to communicate with Sdl Core.
According to [AppBrain](http://www.appbrain.com/stats/libraries/details/phonegap/phonegap-apache-cordova), Cordova takes up only 6.94% apps and 1.20% installs of the Android apps market. Also, Cordova apps account for only 3.41% of new Android apps.


## Proposed solution
The [SmartDeviceLink Cordova plugin](https://github.com/smartdevicelink/sdl_cordova_android) will be removed because it has not been updated in the last three years, and because of lack of community interest.


## Potential downsides

Some mobile developers may be still using the SmartDeviceLink Cordova plugin to develop SDL apps. Those developers will have to start using SDL Android to develop SDL enabled apps. However, because Corodva is not very used currently, this is not going to have a big impact.


## Impact on existing code

The proposal suggests that we remove the [SmartDeviceLink Cordova plugin](https://github.com/smartdevicelink/sdl_cordova_android) which will affect any developer who is still using the plugin. Sdl Android should be used by the developers for creating native Android SDL apps. 

## Alternatives considered

Even though Apache Corodva Framework is not as popular nowadays, an alternative solution is to keep supporting and updating SmartDeviceLink Cordova plugin because some mobile developers are still using the plugin.
