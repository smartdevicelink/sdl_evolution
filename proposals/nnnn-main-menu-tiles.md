# Add Tiles as an Option for Main Menus

* Proposal: [SDL-NNNN](NNNN-main-menu-tiles.md)
* Author: [Joel fischer](https://github.com/joeljfischer)
* Status: **Awaiting review**
* Impacted Platforms: [Core / iOS / Android / Cloud Proxy / RPC]

## Introduction
In addition to a list of menu items, we should allow the developers the option to use a tiled layout for their menu.

## Motivation
We already provide a tiled template layout using soft buttons. In some cases, it may be desirable for the developer to create a menu with tiles instead of a list of menu items, for example if they have only a few menu options, or if each menu option leads to a distinct "template" screen.

## Proposed solution

### MOBILE_API Updates
We will add an enum for the various menu layout options:

```xml
<enum name="MenuLayout" since="X.Y">
    <description>How the main menu or submenu is laid out on screen</description>
    <element name="LIST" />
    <element name="TILES" />
</enum>
```

We will add new capabilities so that developers can know if the head unit supports tiled menus:

```xml
<struct name="DisplayCapabilities" since="1.0">
    <!-- All existing params -->

    <param name="menuLayouts" type="MenuLayout" array="true" minValue="1" maxValue="1000" mandatory="false">
        <description>An array of available menu layouts. If this parameter is not provided, only the `LIST` layout is assumed to be available</description>
    </param>
</struct>
```

We will then add the ability to change the menu to a tiled layout using `SetGlobalProperties`. Submenus can be tiled as well using the `AddSubmenu` command:

```xml
<function name="SetGlobalProperties" functionID="SetGlobalPropertiesID" messagetype="request">
    ...
    <!-- Additions -->
    <param name="menuLayout" type="MenuLayout" defvalue="LIST" mandatory="false" since="X.Y">
        <description>Sets the layout of the main menu screen. If this is sent while a menu is already on-screen, the head unit will change the display to the new layout type.</description>
    </param>
</function>

<function name="AddSubMenu" functionID="AddSubMenuID" messagetype="request">
    <description>Adds a sub menu to the in-application menu.</description>
    
    ...
    <!-- Additions -->
    <param name="menuLayout" type="MenuLayout" defvalue="LIST" mandatory="false" since="X.Y">
        <description>Sets the layout of the submenu screen.</description>
    </param>
</function>
```

If a `SetGlobalProperties` is sent with an unsupported `menuLayout` but is otherwise successful, then the request succeeds, with a `WARNINGS` `resultCode` with an `info` field stating, "The `MenuLayout` specified is unsupported, the default `MenuLayout` will be used". The same will occur for an `AddSubMenu` request.

### HMI_API Updates
The HMI_API updates are very similar to the MOBILE_API updates.

```xml
<enum name="MenuLayout">
    <description>How the main menu or submenu is laid out on screen</description>
    <element name="LIST" />
    <element name="TILES" />
</enum>
```

```xml
<struct name="DisplayCapabilities">
    <!-- All existing params -->

    <param name="menuLayouts" type="MenuLayout" array="true" minValue="1" maxValue="1000" mandatory="false">
        <description>An array of available menu layouts. If this parameter is not provided, only the `LIST` layout is assumed to be available</description>
    </param>
</struct>
```

```xml
<function name="UI.SetGlobalProperties" messagetype="request">
    ...
    <!-- Additions -->
    <param name="menuLayout" type="MenuLayout" defvalue="LIST" mandatory="false">
        <description>Sets the layout of the main menu screen. If this is sent while a menu is already on-screen, the head unit will change the display to the new layout type.</description>
    </param>
</function>

<function name="UI.AddSubMenu" messagetype="request">
    <description>Adds a sub menu to the in-application menu.</description>
    
    ...
    <!-- Additions -->
    <param name="menuLayout" type="MenuLayout" defvalue="LIST" mandatory="false" since="X.Y">
        <description>Sets the layout of the submenu screen.</description>
    </param>
</function>
```

### Proxy Library Manager Updates

#### iOS
A new property would be added to the screen manager:

```objc
@property (strong, nonatomic, null_resettable) SDLMenuConfiguration *menuConfiguration;
```

This property is of a new class type:

```objc
@interface SDLMenuConfiguration: NSObject

/**
 * Changes the default main menu layout. Defaults to `SDLMenuLayoutList`.
 */
@property (strong, nonatomic, readonly) SDLMenuLayout *mainMenuLayout;

/**
 * Changes the default submenu layout. To change this for an individual submenu, set the `menuLayout` property on the `SDLMenuCell` initializer for creating a cell with sub-cells. Defaults to `SDLMenuLayoutList`.
 */
@property (strong, nonatomic, readonly) SDLMenuLayout *defaultSubmenuLayout;

@end
```

Finally, the `SDLMenuCell *` class will be updated to allow for submenus with different layouts:

```objc
@interface SDLMenuCell : NSObject
// Everything that's already there

@property (strong, nonatomic, readonly, nullable) SDLMenuLayout *submenuLayout;

/**
 Create a menu cell that has subcells and when selected will go into a deeper part of the menu

 @param title The cell's primary text
 @param icon The cell's image
 @param layout The submenu's layout that the subCells will be shown in. If `nil`, the default submenu layout in the screen manager's `SDLMenuConfiguration` will be used.
 @param subCells The subcells that will appear when the cell is selected
 @return The menu cell
 */
- (instancetype)initWithTitle:(NSString *)title menuLayout:(nullable SDLMenuLayout)layout icon:(nullable SDLArtwork *)icon subCells:(NSArray<SDLMenuCell *> *)subCells;

@end
```

#### Android
A new property would be added to the `BaseMenuManager`. These methods would be exposed via the `BaseScreenManager` to allow developers to set and get the values:

```java
MenuConfiguration menuConfiguration;
...

/**
* This method is called via the screen manager to set the menuConfiguration. 
* This will be used when a menu item with sub-cells has a null value for menuConfiguration
* @param menuConfiguration - The default menuConfiguration
*/
public void setMenuConfiguration(MenuConfiguration menuConfiguration) {
	this.menuConfiguration = menuConfiguration;
}
	
public MenuConfiguration getMenuConfiguration(){
	return this.menuConfiguration;
}
```

The property is a new class called `MenuConfiguration`:

```java
public class MenuConfiguration {

  /**
	 * Changes the default main menu layout. Defaults to `MenuLayoutList`.
	 * @param mainMenuLayout - the layout of the main menu
	 */
	public void setMenuLayout(MenuLayout mainMenuLayout){}

	public MenuLayout getMenuLayout { return mainMenuLayout; }
	
  /**
	 * Changes the default submenu layout. To change this for an individual submenu, set the `menuLayout` property on the `MenuCell` constructor for creating a cell with sub-cells. Defaults to `MenuLayoutList`.
	 * @param defaultSubmenuLayout - the MenuLayout for this sub menu
	 */
	public void setSubMenuLayout(MenuLayout defaultSubmenuLayout){}

	public MenuLayout getSubMenuLayout { return defaultSubmenuLayout; }

}
```

Finally, the `MenuCell` class would be updated to allow the setting of an individual `MenuConfiguration` for each submenu.

```java
private MenuConfiguration subMenuLayout;


/**
* Creates a new MenuCell Object with multiple parameters set
* @param title The cell's primary text
* @param menuLayout The submenu's layout that the subCells will be shown in. If `null`, the default submenu layout set via the screen manager's `MenuConfiguration` will be used.
* @param icon The cell's image
* @param subCells The sub-cells for the sub menu that will appear when the cell is selected
*/
public MenuCell(@NonNull String title, @Nullable MenuConfiguration menuLayout, @Nullable SdlArtwork icon, @Nullable List<MenuCell> subCells) {}


/**
* The submenu's layout that the subCells will be shown in. If `null`, the default submenu layout set via the screen manager's `MenuConfiguration` will be used.
* @param subMenuLayout - the layout used for the sub menu
*/
public void setSubMenuLayout(MenuConfiguration subMenuLayout) {
	this.subMenuLayout = subMenuLayout;
}

public MenuConfiguration getSubMenuLayout() {
	return subMenuLayout;
}
```

## Potential downsides
1. Adding a new value to the `DisplayCapabilities` bloats the `RegisterAppInterfaceResponse`, however, the author could not think of a valid alternate location. The author welcomes feedback on locations it could be moved to.

## Impact on existing code
This would be a minor version change on Core, the RPC spec, and proxy libraries. The proxy libraries would need to update their menu managers to support the new layout and associated capabilities.

## Alternatives considered
No alternatives were considered
