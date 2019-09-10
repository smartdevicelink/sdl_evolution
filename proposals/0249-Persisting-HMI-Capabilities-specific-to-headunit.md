# Persisting HMI Capabilities specific to headunit

* Proposal: [SDL-0249](0249-Persisting-HMI-Capabilities-specific-to-headunit.md)
* Author: [Ankur Tiwari](https://github.com/atiwari9)
* Status: **Returned for Revisions**
* Impacted Platforms: [Core]

## Introduction

This proposal is to change the way SDL Core initializes HMI capabilities for a headunit, which are used to communicate to apps/other SDL features.

## Motivation

Most of the HMI capabilities are static and remain constant for a headunit. That means to request these HMI capabilities every ignition cycle is simply redundant. We also encounter some scenarios where HMI needs time to compute these capabilities before sending the response back to SDL Core, which results in incorrect capabilities being cascaded to the apps.

## Proposed solution

Solution is to cache HMI capabilities received from HMI to a persisting storage (such as a file on file system) which then can be used by SDL Core to read HMI capabilities instead of requesting HMI every ignition cycle. This should be done only for capabilities which are NOT selectable by user. Based on requests sent by SDL Core to HMI during boot up, we can classify those in the following two categories:

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

Even though `UI.OnLanguageChange`, `VR.OnLanguageChange`, `TTS.OnLanguageChange` are NOT the requests/notifications SDL Core sends/receives during boot up, these notifications from HMI can change active language for respective components within an ignition cycle. Hence, we do need to consider these under _Dynamic_ APIs. Since during an ignition cycle HMI should update SDL Core with language changes using above notifications, that means that `UI.GetLanguage`, `VR.GetLanguage`, `TTS.GetLanguage` can be considered as _Static_ APIs since these would just return the language from previous ignition cycle.

SDL Core needs to persist the HMI capabilities in a new file in file system. Below are the changes SDL Core would need to make:

##### Config Changes:
1. SDL Core should add a new variable in _SmartDeviceLink.ini_ named `HMICapabilitiesCacheFile` which stores name of cache file.
   1. If this variable is null/empty, SDL Core should not persist HMI Capabilities received from headunit.
   2. Else, SDL Core should persist HMI Capabilities received from headunit as per functional logic below.

##### Functional Changes:
1. During boot up, SDL Core should check if `HMICapabilitiesCacheFile` file is present in `AppStorageFolder` from _smartDeviceLink.ini_
   1. If present, SDL Core loads the contents of the file and uses that as current system HMI capabilities.
      1. In case any capability is missing, SDL Core should default back to _hmi_capabilities.json_ file for corresponding capability and should send requests to get these capabilities from HMI.
      2. If not present, SDL Core should create the file and should send requests to get all HMI capabilities from HMI. (see [_Static_](#static) section above)
2. SDL Core, upon receiving HMI response for any of the UI/VR/TTS/Buttons/VehicleInfo/Navigation/RC capabilities, should check if `HMICapabilitiesCacheFile` file already has the data set received in HMI response
   1. If no :
      1. Write the response data to `HMICapabilitiesCacheFile` file
      2. Do not send corresponding request to get HMI capabilities to HMI for subsequent ignition cycles. SDL Core should still follow rest of launch sequence requests/notifications as applicable.
      3. SDL Core should use this new data set for usages by apps/SDL Core communication until ignition cycle is performed
   2. If yes : 
      1. Do not overwrite the response to `HMICapabilitiesCacheFile` file
      2. Do not send corresponding request to get HMI capabilities to HMI for subsequent ignition cycles. SDL Core should still follow rest of launch sequence.
3. SDL Core, upon receiving HMI response for `UI.OnLanguageChange`, `TTS.OnLanguageChange` and `VR.OnLanguageChange` ([_Dynamic_](#dynamic) APIs), should override point 2 with following requirements
   1. Overwrite contents of received responses/notifications in hmi_capabilities_cache.json file.	
   2. Should use this new data set for usages by apps/SDL Core communication until ignition cycle is performed.
4. SDL Core should delete the `HMICapabilitiesCacheFile` file when a master reset is performed.
5. SDL Core should regenerate `HMICapabilitiesCacheFile` file when system SW version changes.


## Potential downsides

This change is prone to errors by HMI. If HMI sends incorrect HMI capabilities during first boot up/after master reset, then that cannot be corrected until a master reset is performed. But we do expect HMI to send correct HMI capabilities back at all times. Therefore, this should not be an issue as long as HMI ensures that only correct values are sent to SDL Core. We should still put this as best practices/warning in HMI guidelines.

## Impact on existing code

There will be changes in boot up initialization sequence around all HMI capabilities. SDL Core waits on certain notifications/responses to send requests for HMI capabilities, all that logic would need to be reworked. This rework should yield a better boot up time for SDL Core and better app resumption behavior.

## Alternatives considered

HMI can potentially take a long time to respond with HMI capabilities, which would mean if an app registers before HMI has sent a response back to SDL Core, then the app would get incorrect capabilities. To avoid this, SDL Core can choose to wait before sending RAI response to the app. However, that has potential to break app resumption use case and would possibly cause incorrect app behavior.

## Additional Comments

1. There are recent changes to `SystemCapabilities` in [_Widgets Proposal_](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md) and [_App Services in HMI capabilities_](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0246-app-services-hmi_capabilities.md) proposal. For those, since apps get `onSystemCapability` notification upon registration with capabilities specific to template selected/services provided by app(s), this information is NOT static and would change over the course of app registration itself. That means that when app changes template (layout) or another app registers as a service provider, then the capabilities struct will change along with that. Hence there is NO super set of DisplayCapability/AppService which would be delivered to the app or SDL Core during SDL boot up/app registration.

There are two points to consider still:

   * HMI may still be slow in sending `onSystemCapabiity` -> `DisplayCapability` notification to the app. To circumvent that case, we can recommend adding this information as part of hashId persistence for the app. Since the template/capabilities are specific to the app. It makes sense to persist it on per app basis. This should be a separate proposal.
   * `UI.GetCapabilities` for `DisplayCapabilities` is being deprecated due to the [_Widgets Proposal_](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md), but the implementation will still be there for next SDL Core version (6.0). So we can keep this in the proposal as there will be a transition time period for the apps to new setup.

2. There will be multiple writes to _cache_ file during first boot up, also there will be at least three writes upon language change. To make the write process more efficient, all this data can be cached first along with a timer which checks if internal cache has changed before writing to file. Similar process is followed during PT persistence. This is however an implementation detail and can be decided upon during implementation itself.
