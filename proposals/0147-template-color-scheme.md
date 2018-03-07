# Template Improvements: Color Scheme

* Proposal: [SDL-0147](0147-template-color-scheme.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **In Review**
* Impacted Platforms: [RPC, Android, iOS, Core]

## Introduction

This proposal enables apps to provide a custom color scheme. This will allow OEMs to still strictly control layout and design while allowing apps some amount of branding and customization.

## Motivation

Currently, nearly no customizability is available to developers and their apps for branding outside of the app icon. Most apps and developers have their own branding colors, and that is an easy way to help provide developers customization that competitor solutions do not.

## Proposed solution

The proposed solution is to add a few new structs:

```xml
<struct name="RGBColor">
    <description>
    </description>
    <param name="red" type="Integer" minValue="0" maxValue="255" mandatory="true" />
    <param name="green" type="Integer" minValue="0" maxValue="255" mandatory="true" />
    <param name="blue" type="Integer" minValue="0" maxValue="255" mandatory="true" />
    </param>
</struct>

<struct name="TemplateColorScheme">
    <description>
        A color scheme for all display layout templates.
    </description>
        <param name="brandColor1" type="RGBColor" mandatory="false">
        <description>The primary "accent" color</description>
        </param>
        <param name="backgroundColor" type="RGBColor" mandatory="false">
        <description>The color of the background</description>
        </param>
</struct>
```

Along with an addition to the RegisterAppInterface request:

```xml
<function name="RegisterAppInterface" functionID="RegisterAppInterfaceID" messagetype="request">
...
<param name="dayColorScheme" type="TemplateColorScheme" mandatory="false">
<param name="nightColorScheme" type="TemplateColorScheme" mandatory="false">
...
</function>
```

The developer may provide either a day color scheme, a night scheme, or both. If the dev doesn't offer one or the other, the HMI can decide what to do. My recommendation would be to use the default color scheme for whatever is not supported.

The text color will be calculated using an algorithm based on the background color and will always be either full white or full black.

The `backgroundColor` should change the background color. The recommendation for the `brandColor1` is to change the background of soft buttons and hard buttons (e.g. play / pause).

## Potential downsides

This **must** be implemented consistently across platforms. If it is not, then apps may have colors appearing where they do not expect across platforms. Either a platform needs to integrate it in a consistent manner across other platforms, or they should not have the capability at all and use their own color scheme(s).

The app may provide a color scheme that no text color will work well for. App certification may be necessary for this case. I would recommend we follow the [W3C accessibility guidelines](https://www.w3.org/TR/WCAG20/), with an [example algorithm](https://stackoverflow.com/a/3943023/1221798).

## Impact on existing code

This should be a minor version change. There are HMI API changes required.

## Alternatives considered

1. Require both a day and night color scheme. This would be accomplished by adding another struct containing mandatory day / night parameters, then the struct itself would be not mandatory on the Register App Interface.
2. Additional colors could be provided. Currently only 2 colors are used, with the ability to expand later. The background and a single accent (the primary brand color) are considered enough for now. If there were more colors, it would be more likely that they would be implemented differently across head units.
3. Additional specific colors could be provided, such as soft button background color, hard button background color (e.g. Play), etc.
4. More generic names could be used for the template colors, for example, primary and secondary. This was judged to not be specific enough and could result in varying implementations across platforms.
