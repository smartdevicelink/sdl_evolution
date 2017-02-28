# Providing AppIcon in case of app registration

* Proposal: [SDL-NNNN](NNNN-OnAppRegistered_providing_AppIcon_of_app_registration.md)
* Author: [Melnyk Tetiana](https://github.com/TMelnyk)
* Status: **Awaiting review**
* Impacted Platforms: Core / RPC

## Introduction 

This proposal is to provide the applications _icon_ to HMI in case of app registration. 

## Motivation

The _icon_ is a symbol that provides notice that the registration is completed.   
Expected that if application has stored _icon_ -> SDL will notify HMI about existance and HMI will show this application _icon_.

## Proposed solution

The head unit shall remember the name and the file of the app icon that an app has set using the RPC Request _SetAppIcon_ for each app.   
When an app registers on the head unit it shall look out if the app used _SetAppIcon_ in a previous session.   
      - If the app has used _SetAppIcon_ in a previous session AND the app icon still exist on the file system the head unit shall use this app icon when creating the app tile in the mobile apps list.   
      - Otherwise use the default AppLink app icon.
   
1. In case mobile app has stored apps icon at "AppStorageFolder" and this mobile app sends SetAppIcon (<syncFileName>) to SDL, _SDL must_:   
  - transfer SetAppIcon (<syncFileName>) to HMI;   
  - respond with <resultCode_received_from_HMI> to mobile app;   
  - replace the old icon with new one <syncFileName> at "AppIconsFolder" ONLY in case of successfull response from HMI;    
  - rename <syncFileName> to apps string-valued <appID>.
   
2. In case mobile app has NO related apps icon stored at "AppIconsFolder" and this mobile app sends SetAppIcon (<syncFileName>) request to SDL and this <syncFileName> exists at apps sub-directory of "AppStorageFolder" (the value defined at .ini file) _SDL must_:   
  - transfer SetAppIcon (<syncFileName>) to HMI;
  - respond with <resultCode_received_from_HMI> to mobile app;
  - copy <syncFileName> from "AppStorageFolder" to "AppIconsFolder" ONLY in case of successfull response from HMI; 
  - rename <syncFileName> to apps string-valued <appID>.

3. In case mobile app sends RegisterAppInterface_request to SDL and the apps icon does NOT exist at <AppIconsFolder>, _SDL must_:
  - respond RegisterAppInterface (SUCCESS, "iconResumed" = false, params) to mobile app;
  - send OnAppRegistered_notifcation to HMI without "icon" parameter;
  - omit the <icon> via UpdateAppList to HMI.
 
4. In case mobile app sends RegisterAppInterface_request to SDL and SDL checks the existence of apps icon at <AppIconsFolder> and the apps icon exists at <AppIconsFolder>, _SDL must_:
  - respond RegisterAppInterface (SUCCESS, "iconResumed" = true, params) to mobile app;
  - provide the <icon> via OnAppRegistered_notification to HMI;
  - provide the <icon> via UpdateAppList also to HMI.

## Detailed design

N/A

## Impact on existing code

`<function name="RegisterAppInterface" functionID="RegisterAppInterfaceID" messagetype="response">`   
`<description>The response to registerAppInterface</description>`   
...   
`<param name="info" type="String" maxlength="1000" mandatory="false" platform="documentation">`   
`<description>Provides additional human readable info regarding the result.</description>   
</param>`   
...   
`<param name="systemSoftwareVersion" type="String" maxlength="100" mandatory="false" platform="documentation">   
<description>The software version of the system that implements the SmartDeviceLink core.</description>`   
`</param>`    
`<param name="iconResumed" type="Boolean" mandatory="true">`

`<description>Existence of apps icon at system.    
If true, apps icon was resumed at system.     
If false, apps icon is not resumed at system</description>`    
`</param>    
</function>`   

## Alternatives considered

N/A
