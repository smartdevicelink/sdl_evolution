# OnDataResumed Notification

* Proposal: [SDL-0329](0329-on-data-resumed.md)
* Author: [JackLivio](https://github.com/JackLivio)
* Status: **Returned for Revisions**
* Impacted Platforms: [Core / iOS / Java Suite / JavaScript Suite / Policy Server / SHAID / RPC ]

## Introduction

This proposal creates a new RPC notification that relays app resumption info from SDL Core to the mobile app after registration. The notification is named `OnDataResumed`.

## Motivation

Currently the resumption behavior of SDL Core requires developers to read documentation to understand what type of information can be resumed by the head unit. There is no direct communication to the app regarding what data or subscriptions were resumed after registering. Also, data available for resumption is different across versions of SDL Core, which increases the complexity and required knowledge for an app developer.

The motivation of creating this new RPC notification is to better communicate the resumption behavior of SDL Core to the app if a valid hashID was supplied in the app's RegisterAppInterface request. 


The information in this new RPC can be used by app developers to better understand what data was resumed by the version of SDL Core that an app has connected to. This information can help app integrations avoid sending duplicate requests such as AddCommands, SubMenus, ChoiceSets, and Subscriptions.

## Proposed solution

The proposed solution is to create a new RPC notification named "OnDataResumed". This RPC is sent to an application directly after a RegisterAppInterfaceRequest only if an app supplies a valid hashID and resumption was successful during registration. 

Ths notification will be sent to the connected application before Core sends the OnHMIStatus notification.

SDL Core will not send this notification if there was no valid hashID provided, or resumption was failed. Failed resumption is noted by the result code: `RESUME_FAILED` in the RegisterAppInterfaceResponse.

The OnDataResumed notification contains boolean values for each type of data resumed. True if the resumption was successful, False if it was not successful. 

If the app did not use a particular resumption data item, that value will be omitted from the notification. For example if an app resumes and was not using Remote Control subscriptions, the `remoteControlSubscriptionsResumed` parameter would be omitted.

As of this proposal, resumption data is implemented for:

- Interaction Choice Sets
- Add Commands
- Persistent Files
- SubMenus
- Global Properties
- Button Subscriptions
- Remote Control Subscriptions
- Way Point Subscriptions
- System Capability Subscriptions
- Vehicle Info Subscriptions
- Widget Windows

### Mobile API Additions


```xml
<function name="OnDataResumed" functionID="OnDataResumed" messagetype="notification" since="x.x">
    <description>
        Relays resumption information to an application
    </description>

    <param name="choiceSetsResumed" type="Bool" mandatory="false">
    </param>

    <param name="mainMenuResumed" type="Bool" mandatory="false">
    </param>

    <param name="ephemeralFilesResumed" type="Bool" mandatory="false">
    </param>

    <param name="globalPropertiesResumed" type="Bool" mandatory="false">
    </param>

    <param name="vehicleDataSubscriptionsResumed" type="Bool" mandatory="false">
    </param>

    <param name="remoteControlSubscriptionsResumed" type="Bool" mandatory="false">
    </param>

    <param name="windowInfoResumed" type="Bool" mandatory="false">
    </param>
</function>
```

## Potential downsides

Currently SDL Core will broadly accept resumption as a success or a failure. Due to the implementations of proposals [SDL 188](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0188-get-interior-data-resumption.md) and [SDL 190](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0190-resumption-data-error-handling.md), if any single resumption component fails, all other resumption items will be reversed.

Essentially this means that the values in onDataResumed will come back as either all true, or all false. Note: this does not include omitted values that were not used during resumption process.

The author is recognizing this as a downside but the OnDataResumed notification will still allow apps to know which items are resumed based on the version of the head unit. This may be more helpful in the future if there are new resumption items added or Core behavior is changed to allow for higher resolution of resumed items.

## Impact on existing code

This proposal adds a new RPC therefore it will impact SDL Core, App Libraries, and the RPC Spec. Policy Server and SHAID were also included as impacted platforms because they will need to make this new RPC available for policy configuration.

### SDL Core

The impact of SDL Core is low. The OnDataResumed notification will be constructed based on the resumption related responses received by the HMI.

### Mobile Libraries

This proposal is only requiring mobile libraries to implement the base requirements for handling an RPC notification. The notification should be made available to app developers. 

If any of the app managers can benefit from receiving resumption info, the implementation of managers handling this data should be added in a separate proposals. 

## Alternatives considered

An alternate solution would be to include this information in the RegisterAppInterface Response since the resumption state is known before SDL Core sends the RegisterAppInterfaceResponse to an app. The author did not choose this path due to the current size of the RegisterAppInterFace response.

Other alternates considered would be to change this notification to a request so an app can request this info when necessary, or to implement a more robust resumption manager into the App Library.

