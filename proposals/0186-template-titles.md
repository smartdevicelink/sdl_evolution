# Template Titles

* Proposal: [SDL-0186](0186-template-titles.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Accepted with Revisions**
* Impacted Platforms: [Core / iOS / Android / RPC]

## Introduction

Templates should have the capability to have a title to help orient the user in the UI.

## Motivation

Basic templates have nothing to orient the user to where they are in the UI. A title allows the user to know what the content of the current screen is showing them. For example, a weather app may have several template screens: the current weather, an hourly view, and a daily view. Without titles, the user must rely on knowing the button they've pressed and their intuition to know what screen they are on.

## Proposed solution

```xml
<function name="Show" functionID="ShowID" messagetype="request">
    <!-- Existing RPC -->
    <description>Updates the persistent display. Supported fields depend on display capabilities</description>

    ...

    <!-- New Additions -->
    <param name="templateTitle" type="String" minlength="0" maxlength="100" mandatory="false">
        <description>
            The title of the new template that will be displayed. 
            How this will be displayed is dependent on the OEM design and implementation of the template.
        </description>
    </param>
</function>

<enum name="TextFieldName" since="1.0">
    <!-- Existing RPCs -->

    <!-- Additions -->
    <element name="templateTitle" since="x.x">
        <description>The template title field; applies to "Show"</description>
    </element>
</enum>
```

## Potential downsides

No downsides were identified.

## Impact on existing code

This is a minor version change on all platforms.

## Alternatives considered

No alternatives were considered.
