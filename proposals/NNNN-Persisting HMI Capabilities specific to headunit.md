# Persisting HMI Capabilities specific to headunit

* Proposal: [SDL_NNNN](NNNN-Persisting HMI Capabilities specific to headunit.md)
* Author: [Ankur Tiwari](https://github.com/atiwari9)
* Status: **Awaiting review**
* Impacted Platforms: [Core]

## Introduction

This proposal is to change the way core initializes HMI capabilities for a headunit, which are used to communicate to apps/other SDL features.

## Motivation

Most of the HMI capabilities are static and remain constant for a headunit. That means to request these HMI capabilities every ignition cycle is simply redundant. We also encounter some scenarios where HMI needs time to compute these capabilities before sending the response back to core, that results on incorrect capabilities being cascaded to the apps.

## Proposed solution

Solution is to cache HMI capabilities received from HMI to a persisting storage(such as a file on file system) which then can be used by core to read HMI capabilities instead of requesting HMI every ignition cycle. This should be done only for capabilities which are NOT selectable by user. Based on requests sent by core to HMI during boot up, we can classify those in following two categories:

#### Static
  * UI.GetSupportedLanguages
  * UI.GetCapabilities
  * VR.GetSupportedLanguages
  * VR.GetCapabilities
  * TTS.GetSupportedLanguages
  * TTS.GetCapabilities
  * Buttons.GetCapabilities
  * VehicleInfo.GetVehicleType
  * RC.GetCapabilities
  * UI.GetLanguage
  * VR.GetLanguage
  * TTS.GetLanguage

#### Dynamic
  * UI.OnLanguageChange
  * VR.OnLanguageChange
  * TTS.OnLanguageChange

Even though `UI.OnLanguageChange`, `VR.OnLanguageChange`, `TTS.OnLanguageChange` are NOT the requests/notifications core sends/receives during boot up. These notifications from HMI can change active language for respective components with-in an ignition cycle. Hence, we do need to consider these under _Dynamic_ APIs. Since during an ignition cycle, HMI should update core with language changes using above notificatons, that means that `UI.GetLanguage`, `VR.GetLanguage`, `TTS.GetLanguage` can be considered as _Static_ APIs since these would just return the language from previous ignition cycle.

Core needs to persist the HMI capabilities in a new file in file system. Below are the changes core would need to make:

##### Config Changes:
1. Core should add a new variable in _SmartDeviceLink.ini_ named `HMICapabilitiesCacheFile` which stores name of cache file.
   1. If this variable is null/empty, core should not persist HMI Capabilities received from headunit.
   2. Else, core should persist HMI Capabilities received from headunit as per functional logic below.

##### Functional Changes:
1. During boot up, SDL core should check if `HMICapabilitiesCacheFile` file is present in `AppStorageFolder` from _smartDeviceLink.ini_
   1. If present, SDL core loads the contents of the file and uses that as current system HMI capabilities.
      1. In case any capability is missing, SDL core should default back to _hmi_capabilities.json_ file for corresponding capability and should send requests to get these capabilities from HMI.
      2. If not present, SDL core should create the file and should send requests to get all HMI capabilities from HMI. (see [_Static_](#static) section above)
2. SDL core, upon receiving HMI response for any of the UI/VR/TTS/Buttons/VehicleInfo/Navigation/RC capabilities, should check if `HMICapabilitiesCacheFile` file already has the data set received in HMI response
   1. If no :
      1. Write the response data to `HMICapabilitiesCacheFile` file
      2. Do not send corresponding request to get HMI capabilities to HMI for subsequent ignition cycles. SDL core should still follow rest of launch sequence requests/notifications as applicable.
      3. SDL core should use this new data set for usages by apps/SDL core communication untill ignition cycle is performed
   2. If yes : 
      1. Do not overwrite the response to `HMICapabilitiesCacheFile` file
      2. Do not send corresponding request to get HMI capabilities to HMI for subsequent ignition cycles. SDL core should still follow rest of launch sequence.
3. SDL core, upon receiving HMI response for `UI.OnLanguageChange`, `TTS.OnLanguageChange` and `VR.OnLanguageChange` ([_Dynamic_](#dynamic) APIs), should override point 2 with following requirements
   1. Overwrite contents of received responses/notifications in hmi_capabilities_cache.json file.	
   2. Should use this new data set for usages by apps/SDL core communication until ignition cycle is performed.
4. SDL core should delete the `HMICapabilitiesCacheFile` file when a master reset is performed.
5. SDL core should regenerate `HMICapabilitiesCacheFile` file when system SW version changes.


## Potential downsides

This change is prone to errors by HMI. If HMI sends incorrect HMI capabilities during first boot up/after master reset, then that cannot be corrected until a master reset is performed. But we do expect HMI to send correct HMI capabilities back at all times. Therefore, this should not be an issue as long as HMI ensures that only correct values are sent to SDL core. We should still put this as best practices/warning in HMI guidelines.

## Impact on existing code

There will be changes in bootup initialization sequence around all HMI capabilities. Core waits on certain notifications/responses to send requests for HMI capabilities, all that logic would need to be reworked. This rework should yield a better bootup time for core and better app resumption behavior.

## Alternatives considered

HMI can potentially take long time to respond with HMI capabilities, that would mean if an app registers before HMI has sent response back to core then app would get incorrect capabilities. To avoid this, core can choose to wait before sending RAI response to the app. However, that has potential to break app resumption use case and would possibly cause incorrect app behavior.

## Additional Comments

1. There are recent changes to `SystemCapabilities` in _Widgets_Proposal_ and _App_Services_ proposal. For those, since apps get `onSystemCapability` notification upon registration with capabilities specific to template selected/services provided by app(s), this information is NOT static and would change over the course of app registration itself. That means that when app changes template(layout) or another apps register as service providers then the capabilities struct will change along with that. Hence there is NO super set of DisplayCapability/AppService which would be delivered to the app or core during SDL bootup/app registration.

There are two points to consider still:

   * HMI may still be slow in sending `onSystemCapabiity` -> `DisplayCapability` notification to the app. To circumvent that case, we can recommend adding this information as part of hashId persistence for the app. Since the template/capabilities are specific to the app. It makes sense to persist it on per app basis. This should be a separate proposal.
   * `UI.GetCapabilities` for `DisplayCapabilities` is being deprecated due to WidgetProposal. But the implementation will still be there for next core version. So we can keep this in the proposal as there will be a transition time period for the apps to new setup.

2. There will be multiple writes to _cache_ file during first boot up, also there will be atlease three writes upon language change. To make write process more efficient, all this data can be cached first along with a timer which checks if internal cache has changed before writing to file. Similar process is followed during PT persitence. This is however is implementation detail and can be decided during implementation itself.
