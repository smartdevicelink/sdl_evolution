# Main Menu Updating and Pagination

* Proposal: [SDL-0268](0268-main-menu-updating.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Returned for Revisions**
* Impacted Platforms: [Core / iOS / Java Suite / HMI / RPC]

## Introduction
This proposal seeks to add the ability to update the main menu with artworks and sub-menus on demand so that we can improve the performance and usability of the menu.

## Motivation
The current state of the main menu is such that it is not performant to create a large menu, especially if that menu has sub-menus and/or artworks. This will become especially prominent if and when more than one submenu depth is implemented.

## Proposed solution
The proposed solution is to implement dynamic sub-menu pagination and on-demand artwork updates (see [SDL-0042](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0042-transfer-invalid-image-rpc.md) for a related proposal implemented in SDL Core 5.0). Specifically, we are going to enable two features:

1. The module can dynamically request which artworks it needs per menu cell. For example, if the menu is displaying the first five items, it may request only those five artworks (or 10 to allow for user-scrolling, or however many the HMI desires). Then, if the user scrolls down to display the next five items, the head unit will request five additional artworks. Theoretically, the head unit could even "unload" previous artworks and re-request them at a later time automatically.
3. The module can dynamically request an entire sub-menu it needs. For example, if an `AddSubMenu` is sent by the app, the app may not send the sub-menu's contents right away. When the user clicks to display the sub-menu, the head unit can then request that the app send over the sub-menu data at that time (or when the `AddSubMenu` cell goes on-screen, or any other time the HMI desires).

### Additional File Requests
While (1) above refers specifically to menu cell artwork, this feature can be used for any type of artwork, such as `Choice.image` artwork, `Show.primaryGraphic` artwork, `SetGlobalProperties.menuIcon` artwork, etc. For the purposes of this proposal, we will consider the implications only to the main menu system (due to the ), and that is the only system that will have app library manager support in this proposal. A future proposal could enable support for the ChoiceSet manager (or other managers) to support this feature, and the RPCs will exist for the feature to work manually if developers wish to do so.

### RPC API Updates
We're going to need to add a few new RPC notifications to support dynamic updating artworks and sub-menus.

###### New RPC Notifications
In order to support this feature, new notifications have to be enabled from the head unit to the app library to indicate which menu items need updating.

```xml
<function name="OnUpdateFile" functionID="OnUpdateFileID" messagetype="notification" since="x.x">
    <description>This notification tells an app to upload and update a file with a given name.</description>

    <param name="fileName" type="String" maxlength="255" mandatory="true">
        <description>File reference name.</description>
    </param>
</function>
```

```xml
<function name="OnUpdateSubMenu" functionID="UpdateSubMenuID" messagetype="notification" since="x.x">
    <description>This notification tells an app to update the AddSubMenu or its 'sub' AddCommand and AddSubMenus with the requested data</description>

    <param name="menuID" type="Integer" minvalue="0" maxvalue="2000000000" mandatory="true">
        <description>This menuID must match a menuID in the current menu structure</description>
    </param>

    <param name="updateSubCells" type="Bool" mandatory="false">
        <description>If not set, assume false. If true, the app should send AddCommands with parentIDs matching the menuID. These AddCommands will then be attached to the submenu and displayed if the submenu is selected.</description>
    </param>
</function>
```

#### Capabilities Updates
Updates will need to be made so that the app libraries and developers know if the head unit supports this feature or if they need to stick to the old-style of sending the entire menu at once.

```xml
<!-- New Struct -->
<struct name="DynamicUpdateCapabilities" since="X.X">
    <param name="supportedDynamicImageFieldNames" type="ImageFieldName" array="true" mandatory="false" minsize="1">
        <description>An array of ImageFieldName values for which the system supports sending OnFileUpdate notifications. If you send an Image struct for that image field with a name without having uploaded the image data using PutFile that matches that name, the system will request that you upload the data with PutFile at a later point when the HMI needs it. The HMI will then display the image in the appropriate field. If not sent, assume false.</description>
    </param>

    <param name="supportsDynamicSubMenus" type="Bool" mandatory="false">
        <description>If true, the head unit supports dynamic sub-menus by sending OnUpdateSubMenu notifications. If true, you should not send AddCommands that attach to a parentID for an AddSubMenu until OnUpdateSubMenu is received with the menuID. At that point, you should send all AddCommands with a parentID that match the menuID. If not set, assume false.</description>
    </param>
</struct>

<struct name="WindowCapability" since="6.0">
    <!-- New Parameters -->
    <param name="dynamicUpdateCapabilities" type="DynamicUpdateCapabilities" mandatory="false" />
</struct>
```

`ImageFieldName` currently doesn't support noting whether or not `AddSubMenu.menuIcon` is supported. We will need to add that for this to work properly.

```xml
<enum name="ImageFieldName" since="3.0">
    <!-- New Values -->
    <element name="subMenuIcon" since="X.X">
        <description>The image field for AddSubMenu.menuIcon</description>
    </element>
</enum>
```

### HMI API Updates
The HMI will have to support this feature and tell Core when to request menu updates.

#### New Requests
```xml
<function name="UI.OnUpdateFile" messagetype="request">
    <description>For the HMI to tell Core that a file needs to be retrieved from the app.</description>

    <param name="fileName" type="String" maxlength="255" mandatory="true">
        <description>File reference name.</description>
    </param>
</function>

<function name="UI.OnUpdateSubMenu" messagetype="request">
    <description>For the HMI to tell Core that a submenu needs updating</description>

    <param name="menuID" type="Integer" minvalue="0" maxvalue="2000000000" mandatory="true">
        <description>This menuID must match a menuID in the current menu structure</description>
    </param>

    <param name="updateSubCells" type="Bool" mandatory="false">
        <description>If not set, assume false. If true, the app should send AddCommands with parentIDs matching the menuID. These AddCommands will then be attached to the submenu and displayed if the submenu is selected.</description>
    </param>
</function>
```

### Manager-Level Updates
The app library menu manager will need updates to work properly with this system. The menu manager will have to know when dynamic menu features are available and send only the appropriate data.

When `WindowCapability.supportedDynamicImageFieldNames` contains `cmdIcon` and / or `subMenuIcon`, the menu managers will not upload artworks until `OnUpdateFile` is called with the appropriate artwork name. At this point, the menu manager will have to upload the artwork. 

The menu manager with `WindowCapability.supportsDynamicMenus == true` will not send that sub-menu `AddCommand`s until `OnUpdateSubMenu` is called with `updateSubCells = true` for the appropriate `menuID`. At that point, it will have to send `AddCommand` for all the submenu cells.

No new public APIs will need to be added to the manager system. Any implementation details will be at the discretion of the project maintainer.

## Potential downsides
This adds complexity to the HMI. The HMI will have to keep track of which items have artwork available but not on the system. The HMI will also need to determine when it wants to send the `OnUpdateXXX` notifications. For example, should it send the notification when the cell / sub-menu is on screen, or at some point before? This change is a moderate complexity increase for the HMI to make those determinations.

## Impact on existing code
This is a minor version change to the RPC spec and HMIs will be able to update without supporting these features by returning the correct data in `WindowCapability`. This will take significant work for HMI integrators to support this feature and significant internal updates to the app library menu managers. However, the author believes that the performance and usability improvements of this proposal are worth the work and complexity increase.

## Alternatives considered
1. The author attempted to find a solution to the slowdown caused by head units processing VR grammars attached to `AddCommand` and `AddSubmenu` but was unable to find a solution. The VR grammars have to be sent entirely (i.e. they can't be paginated) so that the user can say any of them at any given time. This also means that the entire menu should be sent at once. The menu VR grammars can't be paginated or else VR grammars don't fulfill their intended purpose. While the text could be paginated, the text alone is a much smaller set of data to send and isn't worth paginating.
2. The author considered adding "dynamic menu updating" to `ChoiceSetManager` menus as well, but determined that it would be better to separate those two proposals so they could be implemented in separate releases if necessary.
3. The author considered using the existing `GetFile` request / response pair instead of `OnFileUpdate`, but that was not in the requested revision, so he could not use it in this iteration. However, using `GetFile` does seem like it would work.