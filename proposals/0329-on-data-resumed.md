# OnDataResumed Notification

* Proposal: [SDL-NNNN](0329-on-data-resumed-notification.md)
* Author: [JackLivio](https://github.com/JackLivio)
* Status: **In Review**
* Impacted Platforms: [Core / iOS / Java Suite / JavaScript Suite / Policy Server / SHAID / RPC ]

## Introduction

This proposal creates a new RPC notification that relays app resumption info from SDL Core to the mobile app after registration. The notification is named `OnDataResumed`.

## Motivation

Currently the resumption behavior of SDL Core requires developers to read documentation to understand what type of information can be resumed by the head unit. There is no direct communication to the app regarding what data or subscriptions were resumed after registering. Also, data available for resumption is different across versions of SDL Core, which increases the complexity and required knowledge for an app developer.

The motivation of creating this new RPC notification is to better communicate the resumption behavior of SDL Core to the app if a valid hashID was supplied in the app's RegisterAppInterface request. 


The information in this new RPC can be used by app developers to better understand what data was resumed by the version of SDL Core that an app has connected to. This information can help app integrations avoid sending duplicate requests such as AddCommands, SubMenus, ChoiceSets, and Subscriptions.

## Proposed solution

The proposed solution is to create a new RPC notification named "OnDataResumed". This RPC is sent to an application directly after a RegisterAppInterfaceRequest only if an app supplies a valid hashID and resumption was successful during registration. SDL Core will not send this notification if there was no valid hashID provided, or resumption was failed. Failed resumption is noted by the result code: `RESUME_FAILED` in the RegisterAppInterfaceResponse.

The OnDataResumed notification contains parameters for all resumption data that is implemented in SDL Core today.

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

Note: There are quite a few structs created to wrap parameters already seen in the RPC's that create the data to be resumed (CreateChoiceSet, AddCommand, AddSubMenu, Putfile, etc).

```xml
<struct name="ApplicationChoiceSet">
    <param name="choiceSet" type="Choice" minsize="1" maxsize="100" array="true"  mandatory="true"/>

    <param name="interactionChoiceSetID" type="Integer"/>
</struct>

<struct name="Command">
    <param name="cmdID" type="Integer" minvalue="0" maxvalue="2000000000" mandatory="true">
        <description>unique ID of the command to add.</description>
    </param>
    
    <param name="menuParams" type="MenuParams" mandatory="false">
        <description>Optional sub value containing menu parameters</description>
    </param>
    
    <param name="vrCommands" type="String" minsize="1" maxsize="100" maxlength="99" array="true" mandatory="false">
        <description>
            An array of strings to be used as VR synonyms for this command.
            If this array is provided, it may not be empty.
        </description>
    </param>
    
    <param name="cmdIcon" type="Image" mandatory="false" since="2.0">
        <description>
            Image struct determining whether static or dynamic icon.
            If omitted on supported displays, no (or the default if applicable) icon shall be displayed.
        </description>
    </param>
</struct>

<struct name="File">
    <param name="syncFileName" type="String" maxlength="255" mandatory="true">
        <description>File reference name.</description>
    </param>
    
    <param name="fileType" type="FileType" mandatory="true">
        <description>Selected file type.</description>
    </param>
    
    <param name="persistentFile" type="Boolean" defvalue="false" mandatory="false">
        <description>
            Indicates if the file is meant to persist between sessions / ignition cycles.
            If set to TRUE, then the system will aim to persist this file through session / cycles.
            While files with this designation will have priority over others, they are subject to deletion by the system at any time.
            In the event of automatic deletion by the system, the app will receive a rejection and have to resend the file.
            If omitted, the value will be set to false.
        </description>
    </param>
</struct>

<struct name="SubMenu">
    <param name="menuID" type="Integer" minvalue="1" maxvalue="2000000000" mandatory="true">
        <description>unique ID of the sub menu to add.</description>
    </param>
    
    <param name="position" type="Integer" minvalue="0" maxvalue="1000" defvalue="1000" mandatory="false">
        <description>
            Position within the items that are at top level of the in application menu.
            0 will insert at the front.
            1 will insert at the second position.
            If position is greater or equal than the number of items on top level, the sub menu will be appended to the end.
            Position of any submenu will always be located before the return and exit options
            If this param was omitted the entry will be added at the end.
        </description>
    </param>
    
    <param name="menuName" maxlength="500" type="String" mandatory="true">
        <description>Text to show in the menu for this sub menu.</description>
    </param>

    <param name="menuIcon" type="Image" mandatory="false" >
        <description>The image field for AddSubMenu</description>
    </param>

    <param name="menuLayout" type="MenuLayout" mandatory="false" >
        <description>Sets the layout of the submenu screen.</description>
    </param>

    <param name="parentID" type="Integer" minvalue="0" maxvalue="2000000000" defvalue="0" mandatory="false" >
        <description>
            unique ID of the sub menu, the command will be added to.
            If not provided or 0, it will be provided to the top level of the in application menu.
        </description>
    </param>

</struct>

<struct name="GlobalProperties">

    <param name="userLocation" type="SeatLocation" mandatory="false" >
        <description>Location of the user's seat. Default is driver's seat location if it is not set yet.</description>
    </param>
    <param name="helpPrompt" type="TTSChunk" minsize="1" maxsize="100" array="true" mandatory="false" >
        <description>
            The help prompt.
            An array of text chunks of type TTSChunk. See TTSChunk.
            The array must have at least one item.
        </description>
    </param>
    
    <param name="timeoutPrompt" type="TTSChunk" minsize="1" maxsize="100" array="true" mandatory="false" >
        <description>
            Help text for a wait timeout.
            An array of text chunks of type TTSChunk. See TTSChunk.
            The array must have at least one item.
        </description>
    </param>
    
    <param name="vrHelpTitle" type="String" maxlength="500" mandatory="false" >
        <description>
            VR Help Title text.
            If omitted on supported displays, the default module help title shall be used.
            If omitted and one or more vrHelp items are provided, the request will be rejected.
        </description>
    </param>
    
    <param name="vrHelp" type="VrHelpItem" minsize="1" maxsize="100" array="true" mandatory="false" >
        <description>
            VR Help Items.
            If omitted on supported displays, the default SmartDeviceLink VR help / What Can I Say? screen shall be used.
            If the list of VR Help Items contains nonsequential positions (e.g. [1,2,4]), the RPC shall be rejected.
            If omitted and a vrHelpTitle is provided, the request will be rejected.
        </description>
    </param>
    <param name="menuTitle" maxlength="500" type="String" mandatory="false" >
        <description>Optional text to label an app menu button (for certain touchscreen platforms).</description>
    </param>
    
    <param name="menuIcon" type="Image" mandatory="false" >
        <description>Optional icon to draw on an app menu button (for certain touchscreen platforms).</description>
    </param>
    
    <param name="keyboardProperties" type="KeyboardProperties" mandatory="false" since="3.0">
        <description>On-screen keyboard configuration (if available).</description>
    </param>

    <param name="menuLayout" type="MenuLayout" mandatory="false" since="6.0">
        <description>Sets the layout of the main menu screen. If this is sent while a menu is already on-screen, the head unit will change the display to the new layout type.</description>
    </param>

</struct>

<struct name="ApplicationSubscriptions">
    <param name="subscribedButtons" type="ButtonName" array="true" mandatory="false" />

    <param name="subscribedModuleData" type="ModuleData" array="true" mandatory="false" />

    <param name="subscribedWayPoints" type="Boolean" mandatory="false" />

    <param name="subscribedSystemCapabilities" type="SystemCapabilityType" array="true" mandatory="false" />

    <param name="subscribedVehicleInfo" type="String" array="true" mandatory="false" />

</struct>

<struct name="WindowInfo">

    <param name="windowID" type="Integer" mandatory="true">
        <description>
            A unique ID to identify the window. The value of '0' will always be the default main window on the main display and should not be used in this context as it will already be created for the app. See PredefinedWindows enum. Creating a window with an ID that is already in use will be rejected with `INVALID_ID`.
        </description>
    </param>

    <param name="windowName" type="String" maxlength="100" mandatory="true">
        <description>
            The window name to be used by the HMI. The name of the pre-created default window will match the app name.
            Multiple apps can share the same window name except for the default main window.
            Creating a window with a name which is already in use by the app will result in `DUPLICATE_NAME`.
        </description>
    </param>

    <param name="type" type="WindowType" mandatory="true">
        <description>The type of the window to be created. Main window or widget.</description>
    </param>

    <param name="associatedServiceType" type="String" mandatory="false">
        <description>
            Allows an app to create a widget related to a specific service type.
            As an example if a `MEDIA` app becomes active, this app becomes audible and is allowed to play audio. Actions such as skip or play/pause will be
            directed to this active media app. In case of widgets, the system can provide a single "media" widget which will act as a placeholder for the active media app.

            It is only allowed to have one window per service type. This means that a media app can only have a single MEDIA widget. Still the app can create widgets omitting this parameter. Those widgets would be available as app specific widgets that are permanently included in the HMI.

            This parameter is related to widgets only. The default main window, which is pre-created during app registration, will be created based on the HMI types specified in the app registration request.
        </description>
    </param>
    <param name="duplicateUpdatesFromWindowID" type="Integer" mandatory="false">
        <description>
            Optional parameter. Specify whether the content sent to an existing window
            should be duplicated to the created window.
            If there isn't a window with the ID, the request will be rejected with `INVALID_DATA`.
        </description>
    </param>
</struct>


<function name="OnDataResumed" functionID="OnDataResumed" messagetype="notification" since="x.x">
    <description>
        Relays resumption information to an application
    </description>

    <param name="applicationChoiceSets" type="ApplicationChoiceSet" array="true" mandatory="false">
    </param>

    <param name="applicationCommands" type="Command" array="true" mandatory="false">
    </param>

    <param name="applicationFiles" type="File" array="true" mandatory="false">
    </param>

    <param name="applicationSubMenus" type="SubMenu" array="true" mandatory="false">
    </param>

    <param name="globalProperties" type="GlobalProperties" mandatory="false">
    </param>

    <param name="ApplicationSubscriptions" type="ApplicationSubscriptions" mandatory="false">
    </param>

    <param name="appWindowInfo" type="WindowInfo" array="true" mandatory="false">
    </param>
</function>
```

## Potential downsides

A downside is that this RPC is pretty verbose. Handling the amount of data presented in this notification will add to the App's complexity when connecting to a head unit. This point could also be a testement for why this RPC is necessary. There are many resumption items so it may be hard for an app developer to account for all of these on their own. 

## Impact on existing code

This proposal adds a new RPC therefore it will impact SDL Core, App Libraries, and the RPC Spec. Policy Server and SHAID were also included as impacted platforms because they will need to make this new RPC available for policy configuration.

### SDL Core

The impact of SDL Core is low. The OnDataResumed notification was constructed from data that Core already stores for resumption. SDL Core would need to translate the existing resumption info into this RPC to send to an app after registration with successful resumption.

### Mobile Libraries

This proposal is only requiring mobile libraries to implement the base requirements for handling an RPC notification. The notification should be made available to app developers. 

If any of the app managers can benefit from receiving resumption info, the implementation of managers handling this data should be added in a separate proposals. 

## Alternatives considered

An alternate solution would be to include this information in the RegisterAppInterface Response since the resumption state is known before SDL Core sends the RegisterAppInterfaceResponse to an app. The author did not choose this path due to the current size of the RegisterAppInterFace response.

Other alternates considered would be to change this notification to a request so an app can request this info when necessary, or to implement a more robust resumption manager into the App Library.

