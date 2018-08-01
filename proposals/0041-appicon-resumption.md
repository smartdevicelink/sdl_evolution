# Provide AppIcon resumption across app registration requests

 * Proposal: [SDL-0041](0041-appicon-resumption.md)
 * Author: [Markos Rapitis](https://github.com/mrapitis)
 * Status: **Accepted**
 * Impacted Platforms: [Core / iOS / Android / RPC ]
 
## Introduction
 
This proposal is to simplify (and speed up) the process of setting an app icon across app registration requests.
 
## Motivation

Currently we have a lengthy process for setting a custom app icon by the mobile app for use by the HMI.  The process consists of the following: 

* App: RAI Request -> SDL Core
* SDL Core: RAI Response -> App
* SDL Core: HMI_STATUS -> App
* App: PutFile Request -> SDL Core
* SDL Core: PutFile Response -> App
* App: SetAppIcon Request -> SDL Core
* SDL Core: SetAppIcon Request -> HMI
* HMI: SetAppIcon Response -> SDL Core
* SDL Core: SetAppIcon Response -> App

As a result of the lengthy process highlighted above, an app’s icon will not be immediately available upon registration of the app.  Making use of the process above, the app will be presented on the HMI for a moment before a custom app icon is presented.  In addition, subsequent app registration requests require a redundant exchange of RPC’s to process subsequent set app icon requests.

## Proposed solution
 
The following proposal has been developed in order to provide a custom app icon immediately after app re-registration.  The existing process would be maintained for initial app registration or future app requested icon updates.
The head unit shall keep track and store the name and file referencing the app icon each time a successful SetAppIcon request occurs from the mobile app.

When a mobile app registers on the head unit, SDL Core shall determine if the mobile app previously successfully set its app icon (in a previous session).

* If the mobile app previously successfully set its app icon AND the app icon exists on the file system, the SDL Core and the HMI shall use this app icon reference when creating the app icon representation in the mobile apps list.

* If the mobile app had not previously set an app icon successfully and / or the file does not exist on the head unit, SDL Core and the HMI will utilize the default app icon.

* The mobile app will be notified if an app icon was successfully resumed via a Boolean iconResumed parameter in the RegisterAppInterface Response message from SDL Core.
  * If the app icon has been successfully resumed, the mobile app can ignore processing the existing set app icon sequence.
  * If the app icon has not been successfully resumed, the mobile app needs to follow the existing app icon sequence.

* The existing app icon sequence can always be utilized to change or update an app icon via the mobile app at will.

```xml
<function name="RegisterAppInterface" functionID="RegisterAppInterfaceID" messagetype="response">`   
  <description>The response to registerAppInterface</description>
  
...

 <param name="iconResumed" type="Boolean" mandatory="false">
    <description>
    Existence of apps icon at system.    
    If true, apps icon was resumed at system.     
    If false, apps icon is not resumed at system
    </description>
  </param>
</function>
```

 
## Potential downsides

A potential downside includes the case of first app registration; since the existing app icon sequence is utilized the custom app icon will not be available on an apps very first connection with core and the HMI.
 
## Impact on existing code
This is a minor version change

## Alternatives considered
 
* Option 1: 
Utilize the binary data section of the RegisterAppInterface Request RPC to allow the mobile device to provide an app icon immediate during registration with the system.  This would solve the glaring 1st case registration when an app icon is not present on the system, however this may require more compensating code from a mobile perspective.

* Option 2:
Supplement the proposal above with utilizing the hash id parameter in the RegisterAppInterface Request to allow the mobile app to decide when an app icon is resumed.


## Previous Versions
* A previous version of this proposal indicated the `iconResumed` parameter was mandatory, which was a major version change.