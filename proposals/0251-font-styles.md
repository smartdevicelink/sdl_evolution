# Font Styles

* Proposal: [SDL-0251](0251-font-styles.md)
* Author: [Michael Crimando](https://github.com/MichaelCrimando)
* Status: **Returned for Revisions**
* Impacted Platforms: [Core / iOS / Java Suite / RPC ]

## Introduction

This feature would let apps bold, underline or italicize text within Alert, Show or Perform Interaction RPCS.

## Motivation

As an app partner, I want to be able to customize text on main layouts and popups so that I can have a visually pleasing and easy to use UI.

## Proposed solution


When an app wants a more visually appealing UI experience,  it can add a font style customization onto each line of text if desired.  If no font style is provided, then it is assumed that the font is normal.  

![Example Screen](../assets/proposals/0251-font-styles/0251-font-styles.png)

## Hyper Text Capabilities

The HMI should be able to provide a list of supported hyper text elements to SDL and to  the applications:

### HMI & Mobile API changes

```xml
<struct name="TextField" since="1.0">
:
    <param name="hyperTextSupported" type="String" array="true" mandatory="false" minvalue="1" maxvalue="100" since="6.x">    
    </param>
</struct>
```

The HMI API equivalent should exclude the versioning attributes.

Alternative: An enum can be added that lists all the hyper text elements.

## Automatic tag cleanup using managers 

The manager API of sdl_ios and sdl_java_suite should recognize the new parameter `hyperTextSupported` and scan strings to see if unsupported elements are requested by the app. When a manager wants to generate a RPC it should scan the string and send a cleaned up version of the string in the RPC. For instance when the `ScreenManager` generates a new `Show` request it should set the main fields to a cleaned up version of the manager's text fields.

Example:
The head unit provided information that `mainField1` can support the hyper text elements `b` and `i`. If a developer sets `screenManager.textField1` to a string like `<b>Hello <u>World!</u></b>`, the manager should scan the text field and clean it up to `<b>Hello World!</b>` before setting the string to `Show.mainField1` in the RPC request.

Following managers should need to scan and clean text fields before generating RPCs:
1. ScreenManager
2. TextAndGraphicManager
3. SoftButtonManager
4. ChoiceSetManager
5. MenuManager


## Potential downsides

With this implementation, the whole line of text has to have the same font style. It's not possible to bold only a part of a line of text. Also this adds some HMI complexity.

Currently not considering these as there is no current or immediate need:
- SendLocation
- Media clock
- Media track
- Scrollable message body

## Impact on existing code

It's a new parameter so this would not affect older SDL versions.

## Alternatives considered
Potentially have pre-defined styles like in Android "Header 1", "Header 2", "Body 1", "Body 2" etc.

OR

Add a `FontStyle` struct to all text fields that defines if bold, italic, or underline.
