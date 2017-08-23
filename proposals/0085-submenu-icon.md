# SubMenu icon

* Proposal: [SDL-0085](0085-submenu-icon.md)
* Author: [Kujtim Shala](https://github.com/kshala-ford)
* Status: **In Review**
* Impacted Platforms: [Core / iOS / Android / RPC]

## Introduction

This proposal is about extending the RPC `AddSubMenu` to include a menu icon.

## Motivation

Today the RPC `AddCommand` can add menu entries including a menu command icon. This feature is not available in `AddSubMenu`.

## Proposed solution

The proposed solution is to add a parameter to `AddSubMenu`.

### Mobile API additions

```xml
<function name="AddSubMenu" functionID="AddSubMenuID" messagetype="request">
   :
   <param name="menuIcon" type="Image" mandatory="false" />
</function>
```

### HMI API additions

```xml
<function name="AddSubMenu" messagetype="request">
   :
   <param name="menuIcon" type="Common.Image" mandatory="false" />
</function>
```

## Potential downsides

The proposed change is backward compatible and will not cause a breaking change. However the API of `AddSubMenu` and `AddCommand` are inconsistent. The alternative considered is showing a consistent API which uses `MenuParams` but it's not fully backward compatible.

## Impact on existing code

The impact on existing code is very small.
- an HMI implemntation can use the logic of a menu command to show a menu icon
- Existing apps are not affected as this proposal is only adding a single parameter
- Changes on SDL core are minimal
- Only requires a minor version chagne 

## Alternatives considered

The alternative proposed solution is to use `MenuParams` to provide an image parameter to `AddCommand` and `AddSubMenu`. This could cause a breaking change. However the result would be a clean API.

- For the struct `MenuParams` add a parameter called `menuIcon` of type `Image`
- For the function `AddCommand` deprecate the parameter `cmdIcon`
- For the function `AddSubMenu` add a parameter called `menuParams` of type `MenuParams` 
- For the function `AddSubMenu` deprecate the parameters `position` and `menuName`

The result would be a consistent API through both functions affecting the apps menu.

### Mobile API

```xml
<struct name="MenuParams">
  :
  <param name="menuIcon" type="Image" mandatory="false">
    <description>A new optional parameter to specify an icon to be shown in the menu entry</description>
  </param>
</struct>

<function name="AddCommand" functionID="AddCommandID" messagetype="request">
  :
  <param name="cmdIcon" type="Image" mandatory="false">
    <description>Deprecated parameter. Please use .menuParams.menuIcon instead.</description>
  </param>
</function>

<function name="AddSubMenu" functionID="AddSubMenuID" messagetype="request">
  :
  <param name="menuParams" type="MenuParams">
    <description>A new parameter containing the data of the menu entry.</description>
  </param>
  <param name="position" type="Integer" minvalue="0" maxvalue="1000" defvalue="1000" mandatory="false">
    <description>Deprecated parameter. Please use .menuParams.position instead.</description>
  </param>
  <param name="menuName" maxlength="500" type="String">
    <description>Deprecated parameter. Please use .menuParams.menuName instead.</description>
  </param>
</function>
```

### HMI API

```xml
<struct name="MenuParams">
  :
  <param name="menuIcon" type="Common.Image" mandatory="false">
    <description>A new optional parameter to specify an icon to be shown in the menu entry</description>
  </param>
</struct>

<function name="AddCommand" messagetype="request">
  :
  <param name="cmdIcon" type="Common.Image" mandatory="false">
    <description>Deprecated</description>
  </param>
</function>
```

### Backward compatibility

- The backward compatibility should be implemented by the HMI but can also be covered by SDL core.

- On new head units 
  - If an app uses `MenuParams` the HMI ignores any data set in one of the deprecated parameter.
  - If an app is using a deprecated parameter but not its successor the HMI should use the data of that deprecated parameter.
  
- On old head units
  - If an app uses both `MenuParams` and the deprecated parameters the HMI uses the data of the deprecated parameter only.
  - If an app uses `MenuParams` only it may happen that sub menus are not being created (INVALID_DATA response because AddSubMenu.menuName is missing)
  - If an app uses the successor of `AddCommand.cmdIcon` (which is `MenuParams.menuIcon`) only the HMI adds a menu entry but without a menu icon
