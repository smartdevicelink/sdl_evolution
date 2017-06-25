# Adding Metadata Types

* Proposal: [SDL-NNNN](NNNN-Adding-Metadata-Types.md)
* Author: [Scott Betts](https://github.com/Toyota-Sbetts)
* Status: **In Development**
* Impacted Platforms: [Core / iOS / Android / RPC]

## Introduction

This proposal introduces metadata types to the text field struct in order to allow for more robust HMI designs.

## Motivation

Traditionally, the SDL HMI is unaware of the context of the data provided in each text field by the application.  For specific common types of data such as song title, arist or temperature, some HMIs may benefit from knowing what type of data is contained in a mainField parameter.  This would allow for more robust HMI design and allowing for further differentiation between designs of the same template.  Additionally, this would allow the HMI to display specific data types outside of the main SDL template.  For example, an HMI could display a thermometer icon next to the temperature in a weather app and also display the information contained in the mainField tagged as temperature inside native screens or in other applications.

## Proposed Solution

For each text field, a new optional parameter "fieldType" could be set by applications to describe what type of data is available in the associated text field.  The "fieldType" parameter would consist of an enumeration of common metadata types.

### Additions to HMI_API

```xml
<struct name="TextFieldStruct">
  <param name="fieldName" type="Common.TextFieldName" mandatory="true">
    <description>The name of the field for displaying the text.</description>
  </param>
  <param name="fieldText" type="String" maxlength="500" mandatory="true">
    <description>The  text itself.</description>
  </param>
  <param name="fieldType" type="Common.TextFieldType" mandatory="false">
    <description>The type of data contained in the field.</description>
  </param>
</struct>

<enum name="TextFieldType">
  <element name="audioTitle">
    <description>The data in this field contains the title of the currently playing audio track.</description>
  </element>
  <element name="audioArtist">
    <description>The data in this field contains the artist or creator of the currently playing audio track.</description>
  </element>
  <element name="audioAlbum">
    <description>The data in this field contains the album title of the currently playing audio track.</description>
  </element>
  <element name="audioYear">
    <description>The data in this field contains the creation year of the currently playing audio track.</description>
  </element>
  <element name="audioGenre">
    <description>The data in this field contains the genre of the currently playing audio track.</description>
  </element>
  <element name="rating">
    <description>The data in this field is a rating.</description>
  </element>
  <element name="currentTemperature">
    <description>The data in this field is the current temperature.</description>
  </element>
  <element name="maximumTemperature">
    <description>The data in this field is the maximum temperature for the day.</description>
  </element>
  <element name="minimumTemperature">
    <description>The data in this field is the minimum temperature for the day.</description>
  </element>
  <element name="weatherTerm">
    <description>The data in this field describes the current weather (ex. cloudy, clear, etc.).</description>
  </element>
  <element name="humidity">
    <description>The data in this field describes the current humidity value.</description>
  </element>
  <element name="none">
    <description>The data in this field is not of a common type or should not be processed.  Any time a field does not have a type parameters it is considered as the none type.</description>
  </element>
</enum>
```

### Additions to MOBILE_API

The changes to enums and structs in the HMI API should also be applied to the Mobile API.

## Potential downsides

Not all applications will utilize this new parameter and the HMI will not be able to always distinguish the proper data types it wants to for the best user experience.

Also, currently there is no clear best practice on when applications should update their text fields. If an application is not updating data in LIMITED or BACKGROUND HMI level, then the information displayed in other screens may not be accurate.  This should be resolved in another proposal.

## Impacts on existing code

This change would required adding new optional parameters in SDL Core, both Android and iOS SDKs and the RPC spec.  This would require a minor version change and legacy HMIs would just ignore this added parameter.

## Alternatives considered

A few alternatives were considered:

1. SDL could define a best practice for specific data types. For example, for audio the song title should always be in mainField1 and artist in mainField2.  This is not ideal as it asks applications to follow the SDL defined behavior which may not match the standard application behavior.
2. We keep data fields ambiguous and HMI will not be able to distinguish data types.  This is not preferred because we have seen many HMIs want to design around specific data types (ex. bolding the song title or putting a CD icon next to the album title).
3. We create a new RPC that applications can use to broadcast information.  This may increase chatter as multiple RPCs could be sent for the same information (ex. Show and new RPC every time a song changes).