# Main Menu Updating and Pagination

* Proposal: [SDL-NNNN](nnnn-main-menu-updating.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Awaiting review**
* Impacted Platforms: [Core / iOS / Java Suite / HMI / RPC]

## Introduction
This proposal seeks to add the ability to update the main menu with artworks and sub-menus on demand so that we can improve the performance and usability of the menu.

## Motivation
The current state of the main menu is such that it is not performant to create a large menu, especially if that menu has sub-menus and/or artworks. This will become especially prominent if and when more than one submenu depth is implemented.

## Proposed solution
The proposed solution is to implement dynamic sub-menu pagination and on-demand artwork updates. Specifically, we are going to enable two features:

1. The module can dynamically request which artworks it needs per menu cells. For example, if the menu is displaying the first five items, it can request only those five artworks (or 10 to allow for user-scrolling, or however many the HMI desires). Then, if the user scrolls down to display the next five items, the head unit will request five additional artworks. Theoretically, the head unit could even "unload" previous artworks and re-request them at a later time automatically.
2. The module can dynamically request an entire sub-menu it needs. For example, if a menu cell that contains a sub-menu is sent by the app, the app may not send the sub-menu's contents right away. When the user clicks to display the sub-menu, the head unit can then request that the app send over the sub-menu data at that time.

### RPC API Updates
We're going to need to update `AddCommand` and `AddSubmenu` and add a few new RPC notifications to support dynamic updating artworks and sub-menus.

###### New RPC Notifications
In order to support this feature, new notifications have to be enabled from the head unit to the app library to indicate which menu items need updating.

```xml
<function name="UpdateCommand" functionID="UpdateCommandID" messagetype="notification" since="x.x">
    <description>This notification tells an app to update the AddCommand with the requested data</description>

    <param name="cmdID" type="Integer" minvalue="0" maxvalue="2000000000" mandatory="true">
        <description>This cmdID must match a cmdID in the current menu structure.</description>
    </param>

    <param name="updateArtwork" type="Bool" mandatory="false">
        <description>If not set, assume false. If true, the app should send a new AddCommand with the same cmdID as the previous one with the cmdIcon set. This will replace the UI cell with a new cell with the artwork displayed.</description>
    </param>
</function>
```

```xml
<function name="UpdateSubMenu" functionID="UpdateSubMenuID" messagetype="notification" since="x.x">
    <description>This notification tells an app to update the AddSubMenu or its 'sub' AddCommand and AddSubMenus with the requested data</description>

    <param name="menuID" type="Integer" minvalue="0" maxvalue="2000000000" mandatory="true">
        <description>This menuID must match a menuID in the current menu structure</description>
    </param>

    <param name="updateArtwork" type="Bool" mandatory="false">
        <description>If not set, assume false. If true, the app should send a new AddSubMenu with the same menuID as the previous one with the menuIcon set. This will replace the UI cell with a new cell with the artwork displayed. If subcells have already been sent, they should be transferred to the new AddSubmenu cell (and don't need to be re-sent).</description>
    </param>

    <param name="updateSubCells" type="Bool" mandatory="false">
        <description>If not set, assume false. If true, the app should send AddCommands with parentIDs matching the menuID. These AddCommands will then be attached to the submenu and displayed if the submenu is selected.</description>
    </param>
</function>
```

#### Capabilities Updates
Updates will need to be made so that the app libraries and developers know if the head unit supports this feature or if they need to stick to the old-style of sending the entire menu at once.

```xml
<struct name="WindowCapability" since="6.0">
    <!-- New Parameters -->
    <param name="supportsDynamicMenus" type="Bool" mandatory="false">
        <description>If true, the head unit will send UpdateCommand and UpdateSubMenu notifications, and it will support updating menu cells by sending the same cmdID / menuID with new data. If not set, assume false.</description>
    </param>
</struct>
```

#### Dynamic Menu Updates
As of this version of Core, sending an `AddCommand` or `AddSubMenu` with a `cmdID` that already exists **must not** be rejected but should update the existing command or submenu with the data from the new RPC. For `AddSubMenu` all existing commands that are attached to the submenu should be transferred.

If data is not passed that previously existed, that data should be removed. e.g. If an `AddCommand` is sent with text and no image, then a new `AddCommand` (with the same `cmdID`) is sent with no text and an image, the displayed menu cell should display no text and an image.

The `AddCommand` and `AddSubmenu` RPCs are going to need to be updated to account for these new features:

```xml
<function name="AddCommand" functionID="AddCommandID" messagetype="request" since="1.0">
    <param name="cmdID" type="Integer" minvalue="0" maxvalue="2000000000" mandatory="true" />
    <param name="menuParams" type="MenuParams" mandatory="false" />
    <param name="vrCommands" type="String" minsize="1" maxsize="100" maxlength="99" array="true" mandatory="false" />
    <param name="cmdIcon" type="Image" mandatory="false" since="2.0" />

    <!-- New Parameters -->
    <param name="hasIcon" type="Bool" mandatory="false" since="x.x">
        <description>If not set, assume false. If set, then the AddCommand has an icon that has not been set in cmdIcon but can be set if the module requests with UpdateCommand.</description>
    </param>
</function>
```

```xml
<function name="AddSubMenu" functionID="AddSubMenuID" messagetype="request" since="1.0">
    <param name="menuID" type="Integer" minvalue="1" maxvalue="2000000000" mandatory="true" />
    <param name="position" type="Integer" minvalue="0" maxvalue="1000" defvalue="1000" mandatory="false" />
    <param name="menuName" maxlength="500" type="String" mandatory="true" />
    <param name="menuIcon" type="Image" mandatory="false" since="5.0" />

    <!-- New Parameters -->
    <param name="hasIcon" type="Bool" mandatory="false" since="x.x">
        <description>If not set, assume false. If set, then the AddSubMenu has an icon that has not been set in menuIcon but can be set if the module requests with UpdateSubMenu.</description>
    </param>
</function>
```

### HMI API Updates
The HMI will have to support this feature and tell Core when to request menu updates.

#### New Requests
```xml
<function name="UI.UpdateCommand" messagetype="request">
    <description>For the HMI to tell Core that a menu command needs updating</description>

    <param name="cmdID" type="Integer" minvalue="0" maxvalue="2000000000" mandatory="true">
        <description>This cmdID must match a cmdID in the current menu structure</description>
    </param>

    <param name="updateArtwork" type="Bool" mandatory="false">
        <description>If not set, assume false. If true, the app should send a new AddCommand with the same cmdID as the previous one with the cmdIcon set. This will replace the UI cell with a new cell with the artwork displayed.</description>
    </param>
</function>

<function name="UI.UpdateCommand" messagetype="response">
</function>

<function name="UI.UpdateSubMenu" messagetype="request">
    <description>For the HMI to tell Core that a submenu needs updating</description>

    <param name="menuID" type="Integer" minvalue="0" maxvalue="2000000000" mandatory="true">
        <description>This menuID must match a menuID in the current menu structure</description>
    </param>

    <param name="updateArtwork" type="Bool" mandatory="false">
        <description>If not set, assume false. If true, the app should send a new AddSubMenu with the same menuID as the previous one with the menuIcon set. This will replace the UI cell with a new cell with the artwork displayed. If subcells have already been sent, they should be transferred to the new AddSubmenu cell (and don't need to be re-sent).</description>
    </param>

    <param name="updateSubCells" type="Bool" mandatory="false">
        <description>If not set, assume false. If true, the app should send AddCommands with parentIDs matching the menuID. These AddCommands will then be attached to the submenu and displayed if the submenu is selected.</description>
    </param>
</function>

<function name="UI.UpdateSubMenu" messagetype="response">
</function>
```

#### Modifications
```xml
<function name="UI.AddCommand" messagetype="request">
    <!-- New Parameters -->
    <param name="hasIcon" type="Bool" mandatory="false" since="x.x">
        <description>If not set, assume false. If set, then the AddCommand has an icon that has not been set in menuIcon but can be set if the module requests with UpdateCommand.</description>
    </param>
</function>

<function name="UI.AddSubMenu" messagetype="request">
    <!-- New Parameters -->
    <param name="hasIcon" type="Bool" mandatory="false" since="x.x">
        <description>If not set, assume false. If set, then the AddSubMenu has an icon that has not been set in menuIcon but can be set if the module requests with UpdateSubMenu.</description>
    </param>
</function>
```

### Manager-Level Updates
The app library Menu Manager will need updates to work properly with this system. The menu manager will have to know when dynamic menu features are available and send only the appropriate data. 

When `WindowCapability.supportsDynamicMenus` is `true` the menu managers will not send artworks until `UpdateCommand` or `UpdateSubMenu` is called with `UpdateArtwork`. At this point, the menu manager with `WindowCapability.supportsDynamicMenus = true` will have to upload the artwork and once that's finished, send a new `AddCommand` or `AddSubMenu` with the file name in the `image` parameter. 

The menu manager with `WindowCapability.supportsDynamicMenus = true` will also not send sub-menus until `UpdateSubMenu` is called with `UpdateSubCells` as `true`. At that point, it will have to send `AddCommand` for all the submenu cells (while still respecting).

However, I do not believe any new APIs will need to be added to the manager system, and therefore this does not need to be designed in this proposal.

## Potential downsides
This adds complexity to the HMI. The HMI will have to keep track of which menu items exist, have artwork available but not on the system, and so forth. The HMI will need to determine when it wants to send the `UpdateXXX` notifications. For example, should it send when the cell / sub-menu is on screen, or at some point before? This change is a moderate complexity increase for the HMI to make those determinations. The internal database of which cells need artwork is not too difficult due to the `AddCommand` / `AddSubMenu` not setting an image name until the artwork is actually uploaded.

There is an additional complexity increase to replace, instead of rejecting, `AddCommand`s and `AddSubMenu`s that have the same `cmdID` / `menuID` as an already existing menu cell.

## Impact on existing code
This is a minor spec change to the RPC spec and implementations will be able to update without supporting this feature by sending `false` for `WindowCapability.supportsDynamicMenus`. This will take significant work for HMI integrators and significant internal updates to the app library menu managers. However, the author believes that the performance and usability improvements of this proposal are worth it.

## Alternatives considered
1. The author attempted to find a solution to the slowdown caused by head units processing VR grammars attached to `AddCommand` and `AddSubmenu` but was unable to find a solution. The VR grammars have to be sent entirely (i.e. they can't be paginated) so that the user can say any of them at any given time.
2. The author considered separating out `WindowCapability.supportsDynamicMenus` into `.supportsDynamicMenuArtwork` and `.supportsDynamicSubMenus`, but determined it was worth the simplicity to require an HMI to support all dynamic menu features or none.
3. The author considered adding "dynamic menu updating" to `PerformInteraction` menus as well, but determined that is less of an issue and would be better suited for a separate proposal.
