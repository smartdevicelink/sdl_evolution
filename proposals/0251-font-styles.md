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

Add a new struct `TextStyle`

```xml
<struct name="TextStyle">
  <param name="bold" type="Boolean" mandatory="false">
	<description>Bold the line of text. Defaults to false.</description>	
  </param>
  <param name="italic" type="Boolean" mandatory="false">
	<description>Italicize the line of text. Defaults to false.</description>
  </param>
  <param name="underline" type="Boolean" mandatory="false">
	 <description>Underline the line of text. Defaults to false.</description>
  </param>
</struct>	
```

Add to the TextFieldStruct - this will cover Show, Alert and TBT RPCs, as well as `InitialText` for various RPCs.

```xml
<struct name="TextFieldStruct">
  .
  .
  .
  <param name="fieldName" type="Common.TextFieldName" mandatory="true">
    <description>The name of the field for displaying the text.</description>
  </param>
  <param name="fieldText" type="String" maxlength="500" mandatory="true">
    <description>The  text itself.</description>
  </param>
  <param name="fieldTypes" type="Common.MetadataType" minsize="0" maxsize="5" array="true" mandatory="false">
    <description>The type of data contained in the field.</description>
  </param>
  <param name="fieldStyle" type="Common.TextStyle" mandatory="false">
    <description>The style of text for the text field.</description>
  </param>
</struct>
```
	
Add font styles for `PerformInteraction` `Choice` 

```xml
<struct name="Choice">
  .
  .
  .
  <param name="textStyle" type "ChoiceTextStyle" mandatory="false">
	<description>The style of text for each choice field.</description>
  </param>
</struct>

<struct name="ChoiceTextStyle">
  <param name="menuNameStyle" type="Common.TextStyle" mandatory="false">
	<description>Text style for menuName in a choice.</description>	
  </param>
  <param name="secondaryTextStyle" type="Common.TextStyle" mandatory="false">
	<description>Text style for secondaryText in a choice.</description>	
  </param>
  <param name="tertiaryTextStyle" type="Common.TextStyle" mandatory="false">
	<description>Text style for tertiaryText in a choice.</description>	
  </param>
</struct>							  
```


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

Have the HMI process html tags like:
- `<b></b>`
- `<i></i>`
- `<u></u>`
But a downside of this is that older headunits would just show the tags. Also when sending a text string in a RPC, they're limited to 500 characters for the most part.  The html tags take up some of the character count.
