# Open Menu RPC

* Proposal: [NNNN](NNNN-open-menu.md)
* Author: [Kujtim Shala](https://github.com/kshala-ford)
* Status: **Awaiting review**
* Impacted Platforms: [Core / iOS / Android / RPC ]

## Introduction

This proposal is about providing the capability to open the built-in app-menu which is provided by the native UI.

## Motivation

Projection apps like mobile navigation apps made it difficult to keep a built-in menu button on the screen which shows the list of menu entries added with `AddCommand`. The initial solution was to hide everything on top of the projection app's viewport. It doesn't make much sense anymore for a projection app to continue to use `AddCommand` for menu entries if this menu is not accessible anymore. Furthermore it also leads to the problem that "Exit {AppName}" is not available anymore to the user.

## Proposed solution

The proposed solution is to specify the built-in "menu" button to not exist anymore at all for projection apps. Instead those apps should be allowed to send a request to show the menu view.

```xml
<function name="Show" messagetype="request">
  <param name="appMenu" type="Integer" mandatory="false">
    <description>
      If set to the value 0 (zero) the HMI opens the built-in menu. 
      Any other value than 0 opens the corresponding sub-menu 
      previously added using `AddSubMenu`.
  </description>
</function>
```

This parameter should only be allowed if the app is in the level `HMI_FULL` with System context being `MAIN` or `MENU`. Otherwise it should not be allowed for an app to show the apps menu.

Projection apps would project a button which the user can press. The app would react on this button press and send the Show request.

## Potential downsides

There's no downside identified.

## Impact on existing code

This proposal is an additional feature which allows projection apps to decide how they want to manage the apps menu.

## Alternatives considered

### `ShowAppMenu` RPC

Instead of a parameter the feature could also be provided by adding another RPC.

```xml
<function name="ShowAppMenu" messagetype="Request">
</function>
```

However compared to an additional parameter it is of more effort to add a new RPC.

### Make "Menu" button moveable

The alternative solution is to add another parameter to `SetGlobalProperties` called `menuPosition` to specify the relative position of the menu button. The app should be able to specify a position like left, top-left etc. However this still leads into a visible UI element on top of the viewport of the projection app.

#### Mobile API change

```xml
<enum name="Position">
  <element name="TOP" />
  <element name="TOP_LEFT" />
  <element name="TOP_RIGHT" />
  <element name="BOTTOM" />
  <element name="BOTTOM_LEFT" />
  <element name="BOTTOM_RIGHT" />
  <element name="RIGHT" />
  <element name="LEFT" />
</enum>

<function name="SetGlobalProperties" functionID="SetGlobalPropertiesID" messagetype="request">
  <param name="menuPosition" type="Position" mandatory="false" />
</function>
```
