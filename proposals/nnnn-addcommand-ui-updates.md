# Main Menu UI Updates

* Proposal: [SDL-NNNN](NNNN-addcommand-ui-updates.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Awaiting review**
* Impacted Platforms: [Core / iOS / Java Suite / HMI / RPC]

## Introduction
This proposal is to update the main menu `AddCommand` and `AddSubMenu` RPCs to allow for the main menu to have the same UI capabilities as `Choice` in `PerformInteraction` popup menus.

## Motivation
Due to several deficiencies in the `AddCommand` / `AddSubmenu` UI and UX, some developers use `PerformInteraction` popup menus as their primary menu navigation structure. We should try to fix those deficiencies as much as possible. This particular proposal seeks to solve some of the UI differences to enable more information in the main menu cells.

## Proposed solution
The proposed solution is to add additional parameters to `AddCommand` and `AddSubmenu` to allow main menu UI to display the same information that `PerformInteraction` popup menus do.

### General HMI Documentation Notes
* We should add an integration guideline stating that OEMs which implement these UI elements should design them in the same way as the `Choice` UI. In other words, the `AddCommand` / `AddSubmenu` and `Choice` UI should be close to equivalent.

### RPC_Spec Updates
###### AddSubmenu
```xml
<function name="AddSubMenu" functionID="AddSubMenuID" messagetype="request" since="1.0">
    <description>Adds a sub menu to the in-application menu.</description>
    
    <!-- New Parameters -->
    <param name="secondaryText" maxlength="500" type="String" mandatory="false" since="x.x">
        <description>Optional secondary text to display</description>
    </param>
    <param name="tertiaryText" maxlength="500" type="String" mandatory="false" since="x.x">
        <description>Optional tertiary text to display</description>
    </param>
    <param name="secondaryImage" type="Image" mandatory="false" since="x.x">
        <description>Optional secondary image struct for sub-menu cell</description>
    </param>
</function>
```

###### AddCommand
```xml
<function name="AddCommand" functionID="AddCommandID" messagetype="request" since="1.0">
    <description>
        Adds a command to the in application menu.
        Either menuParams or vrCommands must be provided.
    </description>
    
    <!-- New Parameters -->
    <param name="secondaryText" maxlength="500" type="String" mandatory="false" since="x.x">
        <description>Optional secondary text to display</description>
    </param>
    <param name="tertiaryText" maxlength="500" type="String" mandatory="false" since="x.x">
        <description>Optional tertiary text to display</description>
    </param>
    <param name="secondaryImage" type="Image" mandatory="false" since="x.x">
        <description>Optional secondary image struct for menu cell</description>
    </param>
</function>
```

#### Capabilities
We also need to expand our capabilities so that developers and high-level managers know which fields are supported.

###### Text
```xml
<enum name="TextFieldName" since="1.0">
    <!-- New Parameters -->
    <element name="menuCommandSecondaryText" since="x.x">
        <description> Secondary text for AddCommand</description>
    </element>
    <element name="menuCommandTertiaryText" since="x.x">
        <description> Tertiary text for AddCommand</description>
    </element>
    <element name="menuSubmenuSecondaryText" since="x.x">
        <description> Secondary text for AddSubmenu</description>
    </element>
    <element name="menuSubmenuTertiaryText" since="x.x">
        <description> Tertiary text for AddSubmenu</description>
    </element>
</enum>
```

###### Images
```xml
<enum name="ImageFieldName" since="3.0">
    <!-- New Parameters -->
    <element name="menuCommandSecondaryImage" since = "x.x">
        <description>The secondary image field for AddCommand</description>
    </element>
    <element name="menuSubmenuSecondaryImage" since = "x.x">
        <description>The secondary image field for AddSubmenu</description>
    </element>
</enum>
```

### HMI_API Updates
Updates also need to be made to the HMI_API so that Core can communicate with the HMI about the new types.

###### AddSubmenu
```xml
<function name="UI.AddSubMenu" messagetype="request">
    <!-- New Parameters -->
    <param name="secondaryText" maxlength="500" type="String" mandatory="false">
        <description>Optional secondary text to display</description>
    </param>
    <param name="tertiaryText" maxlength="500" type="String" mandatory="false">
        <description>Optional tertiary text to display</description>
    </param>
    <param name="secondaryImage" type="Image" mandatory="false">
        <description>Optional secondary image struct for menu cell</description>
    </param>
</function>
```

###### AddCommand
```xml
<function name="UI.AddCommand" messagetype="request">
    <!-- New Parameters -->
    <param name="secondaryText" maxlength="500" type="String" mandatory="false">
        <description>Optional secondary text to display</description>
    </param>
    <param name="tertiaryText" maxlength="500" type="String" mandatory="false">
        <description>Optional tertiary text to display</description>
    </param>
    <param name="secondaryImage" type="Image" mandatory="false">
        <description>Optional secondary image struct for menu cell</description>
    </param>
</function>
```

### High-Level Manager Updates
Additional changes will need to be made to the high-level managers to account for these RPC changes.

#### iOS Library
```objc
@interface SDLMenuCell: NSObject
// New Parameters
@property (copy, nonatomic, readonly, nullable) NSString *secondaryText;
@property (copy, nonatomic, readonly, nullable) NSString *tertiaryText;
@property (strong, nonatomic, readonly, nullable) SDLArtwork *secondaryArtwork;

@end
```

#### Java Library
```java
public class MenuCell implements Cloneable{
    private String secondaryText, tertiaryText;
    private SdlArtwork secondaryArtwork;

    // Provide appropriate getters, setters, and initializers
}
```

#### General Notes
The manager layer will have to strip any data that cannot be sent (e.g. if the head unit doesn't support `tertiaryText`, then don't send that field).

## Potential downsides
The primary potential downside is that this introduces more variability between both versions and HMIs. First, older versions won't support these new UI elements. Second, HMIs may not place these UI elements in the same places. However, this downside is shared with all SDL template UI updates.

## Impact on existing code
This is a minor version change to the affected platforms and requires low impact app library screen manager updates.

## Alternatives considered
No alternatives were considered for this proposal.

```
