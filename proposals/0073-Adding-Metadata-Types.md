# Adding Metadata Types

* Proposal: [SDL-0073](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0073-Adding-Metadata-Types.md)
* Author: [Scott Betts](https://github.com/Toyota-Sbetts)
* Status: **Accepted**
* Impacted Platforms: [Core / iOS / Android / RPC]

## Introduction

This proposal introduces metadata types to the text field struct in order to allow for more robust HMI designs.

## Motivation

Traditionally, the SDL HMI is unaware of the context of the data provided in each text field by the application.  For specific common types of data such as song title, artist or temperature, some HMIs may benefit from knowing what type of data is contained in a text field.  This would allow for more robust HMI design and allowing for further differentiation between designs of the same template.  For example, an HMI could display a thermometer icon next to the temperature in a weather app or bold the song title of the current media.

## Proposed Solution

For each text field in the HMI API, a new optional parameter "fieldType" can be set to describe what type of data is available in the associated text field.  The "fieldType" parameter would consist of an enumeration of common metadata types and is an array to account for multiple metadata types associated with one text field.

### Additions to HMI_API

```xml
<struct name="TextFieldStruct">
  <param name="fieldName" type="Common.TextFieldName" mandatory="true">
    <description>The name of the field for displaying the text.</description>
  </param>
  <param name="fieldText" type="String" maxlength="500" mandatory="true">
    <description>The  text itself.</description>
  </param>
  <param name="fieldType" type="Common.TextFieldType" minsize="0" maxsize="5" array="true" mandatory="false">
    <description>The type of data contained in the field.</description>
  </param>
</struct>

<enum name="TextFieldType">
  <element name="mediaTitle">
    <description>The data in this field contains the title of the currently playing audio track.</description>
  </element>
  <element name="mediaArtist">
    <description>The data in this field contains the artist or creator of the currently playing audio track.</description>
  </element>
  <element name="mediaAlbum">
    <description>The data in this field contains the album title of the currently playing audio track.</description>
  </element>
  <element name="mediaYear">
    <description>The data in this field contains the creation year of the currently playing audio track.</description>
  </element>
  <element name="mediaGenre">
    <description>The data in this field contains the genre of the currently playing audio track.</description>
  </element>
  <element name="mediaStation">
    <description>The data in this field contains the name of the current source for the media.</description>
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
    <description>The data in this field is not of a common type or should not be processed.  Any time a field does not have a type parameter it is considered as the none type.</description>
  </element>
</enum>
```

In the Mobile API, an optional metadata struct "textFieldMetadata" will be introduced.  This struct will utilize each text field as a key and allow them to be assigned multiple metadata tags.  If a textfield or the entire metadata struct is omitted, the currently assigned tags will remain unchanged.  If the text field is included but has no tags assigned, any currently assigned tags will be removed.  For self proclaiming metadata types (ex. "mediaClock", "statusBar" and "mediaTrack"), the HMI can already determine their type and are not included.

### Additions to MOBILE_API

```xml
  <function name="Show" functionID="ShowID" messagetype="request">
    <description>Updates the persistent display. Supported fields depend on display capabilities.</description>

    <param name="mainField1" type="String" minlength="0" maxlength="500" mandatory="false">
      <description>
      	The text that should be displayed in a single or upper display line.
      	If this text is not set, the text of mainField1 stays unchanged.
      	If this text is empty "", the field will be cleared.
      </description>
    </param>

    <param name="mainField2" type="String" minlength="0" maxlength="500" mandatory="false">
      <description>
      	The text that should be displayed on the second display line.
      	If this text is not set, the text of mainField2 stays unchanged.
      	If this text is empty "", the field will be cleared.
      </description>
    </param>
	:
    <param name="softButtons" type="SoftButton" minsize="0" maxsize="8" array="true" mandatory="false">
        <description>
            App defined SoftButtons.
            If omitted on supported displays, the currently displayed SoftButton values will not change.
        </description>
    </param>
    
    <param name="customPresets" type="String" maxlength="500" minsize="0" maxsize="10" array="true" mandatory="false">
        <description>
            App labeled on-screen presets (i.e. on-screen media presets or dynamic search suggestions).
            If omitted on supported displays, the presets will be shown as not defined.
        </description>
    </param>

    <param name="textFieldMetadata" type="MetadataStruct" mandatory="false">
        <description>
            App defined metadata information. See MetadataStruct. Uses mainField1, mainField2, mainField3, mainField4.
            If omitted on supported displays, the currently set metadata tags will not change.
            If any text field contains no tags or the none tag, the metadata tag for that textfield should be removed.
        </description>
    </param>
  </function>

<struct name="MetadataStruct">
  <param name="mainField1" type="Common.TextFieldType" minsize="0" maxsize="5" array="true" mandatory="false">
    <description>The type of data contained in the "mainField1" text field.</description>
  </param>
  <param name="mainField2" type="Common.TextFieldType" minsize="0" maxsize="5" array="true" mandatory="false">
    <description>The type of data contained in the "mainField2" text field.</description>
  </param>
  <param name="mainField3" type="Common.TextFieldType" minsize="0" maxsize="5" array="true" mandatory="false">
    <description>The type of data contained in the "MainField3" text field.</description>
  </param>
  <param name="mainField4" type="Common.TextFieldType" minsize="0" maxsize="5" array="true" mandatory="false">
    <description>The type of data contained in the "mainField4" text field.</description>
  </param>
</struct>

<enum name="TextFieldType">
  <element name="mediaTitle">
    <description>The data in this field contains the title of the currently playing audio track.</description>
  </element>
  <element name="mediaArtist">
    <description>The data in this field contains the artist or creator of the currently playing audio track.</description>
  </element>
  <element name="mediaAlbum">
    <description>The data in this field contains the album title of the currently playing audio track.</description>
  </element>
  <element name="mediaYear">
    <description>The data in this field contains the creation year of the currently playing audio track.</description>
  </element>
  <element name="mediaGenre">
    <description>The data in this field contains the genre of the currently playing audio track.</description>
  </element>
  <element name="mediaStation">
    <description>The data in this field contains the name of the current source for the media.</description>
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
</enum>
```
## Potential downsides

Not all applications will utilize metadata tags and the HMI will not be able to always distinguish the proper data types it wants to for the best user experience.  In this case, the HMI should behave according to the legacy SDL behavior.

## Impacts on existing code

This change would required adding new optional parameters to support the metadata tags for each defined text field in SDL Core, both Android and iOS SDKs and the RPC spec. Each SDK should abstract the RPC spec so applications can set the metadata tags easily.  This would be a minor version change.

## Alternatives considered

As discussed in the workshop, a few viable alternatives exist:

1. The TextFieldStruct array "showStrings" could be added to the mobile API in addition to the current existing parameters.  This would move the Mobile API closer to the HMI API design without making a breaking change, but it would add duplicated data within the show message and require more work to implement and maintain moving forward.  This requires each SDK (Android and iOS) to handle filling in the appropriate parameters based on the input from the application. Changes to Mobile API (Respective enums defined above are not redefined):

```xml
  <function name="Show" functionID="ShowID" messagetype="request">
    <description>Updates the persistent display. Supported fields depend on display capabilities.</description>

    <param name="mainField1" type="String" minlength="0" maxlength="500" mandatory="false">
      <description>
      	The text that should be displayed in a single or upper display line.
      	If this text is not set, the text of mainField1 stays unchanged.
      	If this text is empty "", the field will be cleared.
      </description>
    </param>

    <param name="mainField2" type="String" minlength="0" maxlength="500" mandatory="false">
      <description>
      	The text that should be displayed on the second display line.
      	If this text is not set, the text of mainField2 stays unchanged.
      	If this text is empty "", the field will be cleared.
      </description>
    </param>
	:
    <param name="showStrings" type="Common.TextFieldStruct" mandatory="true" array="true" minsize="0" maxsize="7">
      <description>Array of lines of show text fields. See TextFieldStruct. Uses mainField1, mainField2, mainField3, mainField4. If some field is not set, the corresponding text should stay unchanged. If field's text is empty "", the field must be cleared.
          mainField1: The text that should be displayed in a single or upper display line.
          mainField2: The text that should be displayed on the second display line.
          mainField3: The text that should be displayed on the second "page" first display line.
          mainField4: The text that should be displayed on the second "page" second display line.
          statusBar: statusBar.
          mediaClock: Text value for MediaClock field.
          mediaTrack: The text that should be displayed in the track field. This field is only valid for media applications on NGN type ACMs.
      </description>
    </param>
  </function>

<struct name="TextFieldStruct">
  <param name="fieldName" type="Common.TextFieldName" mandatory="true">
    <description>The name of the field for displaying the text.</description>
  </param>
  <param name="fieldText" type="String" maxlength="500" mandatory="true">
    <description>The  text itself.</description>
  </param>
  <param name="fieldType" type="Common.TextFieldType" minsize="0" maxsize="5" array="true" mandatory="false">
    <description>The type of data contained in the field.</description>
  </param>
</struct>

<enum name="TextFieldType">
  <element name="mediaTitle">
    <description>The data in this field contains the title of the currently playing audio track.</description>
  </element>
  :
  <element name="mediaClock">
    <description>The data in this field contains the string value for the Media Clock.</description>
  </element>
  <element name="mediaTrack">
    <description>The data in this field contains the string value for the Media Track field.</description>
  </element>
  <element name="statusBar">
    <description>The data in this field contains the text to be displayed in the Status Bar.</description>
  </element>
  <element name="none">
    <description>The data in this field is not of a common type or should not be processed.  Any time a field does not have a type parameter it is considered as the none type.</description>
  </element>
</enum>
```

2. A combination between the main proposal and alternative #1, we could define a metadata struct which only supports "fieldName" and "fieldType".  This avoids duplication of data but makes the metadata array more easily expandable and allows the metadata struct to be used within other RPCs. Changes to Mobile API (Respective enums defined above are not redefined):

```xml
  <function name="Show" functionID="ShowID" messagetype="request">
    <description>Updates the persistent display. Supported fields depend on display capabilities.</description>

    <param name="mainField1" type="String" minlength="0" maxlength="500" mandatory="false">
      <description>
      	The text that should be displayed in a single or upper display line.
      	If this text is not set, the text of mainField1 stays unchanged.
      	If this text is empty "", the field will be cleared.
      </description>
    </param>

    <param name="mainField2" type="String" minlength="0" maxlength="500" mandatory="false">
      <description>
      	The text that should be displayed on the second display line.
      	If this text is not set, the text of mainField2 stays unchanged.
      	If this text is empty "", the field will be cleared.
      </description>
    </param>
	:
    <param name="textFieldMetadata" type="Common.MetadataStruct" mandatory="true" array="true" minsize="0" maxsize="4">
      <description>
        App defined metadata information. See MetadataStruct. Uses mainField1, mainField2, mainField3, mainField4.
        If omitted on supported displays, the currently set metadata tags will not change.
        If any text field contains no tags or the none tag, the metadata tag for that textfield should be removed.
      </description>
    </param>
  </function>

<struct name="MetadataStruct">
  <param name="fieldName" type="Common.TextFieldName" mandatory="true">
    <description>The name of the field for displaying the text.</description>
  </param>
  <param name="fieldType" type="Common.TextFieldType" minsize="0" maxsize="5" array="true" mandatory="false">
    <description>The type of data contained in the field.</description>
  </param>
</struct>

<enum name="TextFieldName">
  <element name="mainField1">
    <description>The first line of first set of main fields of the persistent display; applies to "Show"</description>
  </element>
  <element name="mainField2">
    <description>The second line of first set of main fields of the persistent display; applies to "Show"</description>
  </element>
  <element name="mainField3">
    <description>The first line of second set of main fields of persistent display; applies to "Show"</description>
  </element>
  <element name="mainField4">
    <description>The second line of second set of main fields of the persistent display; applies to "Show"</description>
  </element>
  <element name="statusBar">
    <description>The status bar on NGN; applies to "Show"</description>
  </element>
  <element name="mediaClock">
    <description>Text value for MediaClock field; applies to "Show"</description>
  </element>
  <element name="mediaTrack">
    <description>The track field of NGN and GEN1.1 MFD displays. This field is only available for media applications; applies to "Show"</description>
  </element>
  <element name="alertText1">
    <description>The first line of the alert text field; applies to "Alert"</description>
  </element>
  <element name="alertText2">
    <description>The second line of the alert text field; applies to "Alert"</description>
  </element>
  <element name="alertText3">
    <description>The third line of the alert text field; applies to "Alert"</description>
  </element>
  <element name="scrollableMessageBody">
    <description>Long form body of text that can include newlines and tabs; applies to "ScrollableMessage"</description>
  </element>
  <element name="initialInteractionText">
    <description> First line suggestion for a user response (in the case of VR enabled interaction</description>
  </element>
  <element name="navigationText1">
    <description> First line of navigation text</description>
  </element>
  <element name="navigationText2">
    <description> Second line of navigation text</description>
  </element>
  <element name="ETA">
    <description> Estimated Time of Arrival time for navigation</description>
  </element>
  <element name="totalDistance">
    <description> Total distance to destination for navigation</description>
  </element>
  <element name="audioPassThruDisplayText1">
    <description> First line of text for audio pass thru</description>
  </element>
  <element name="audioPassThruDisplayText2">
    <description> Second line of text for audio pass thru</description>
  </element>
  <element name="sliderHeader">
    <description> Header text for slider</description>
  </element>
  <element name="sliderFooter">
    <description> Footer text for slider</description>
  </element>
  <element name="menuName">
    <description> Primary text for Choice</description>
  </element>
  <element name="secondaryText">
    <description> Secondary text for Choice</description>
  </element>
  <element name="tertiaryText">
    <description> Tertiary text for Choice</description>
  </element>
  <element name="menuTitle">
    <description> Optional text to label an app menu button (for certain touchscreen platforms).</description>
  </element>
  <element name="navigationText">
    <description>Navigation text for UpdateTurnList.</description>
  </element>
  <element name="notificationText">
    <description>Text of notification to be displayed on screen.</description>
  </element>
  <element name="locationName">
    <description> Optional name / title of intended location for SendLocation.</description>
  </element>
  <element name="locationDescription">
    <description> Optional description of intended location / establishment (if applicable) for SendLocation.</description>
  </element>
  <element name="addressLines">
    <description> Optional location address (if applicable) for SendLocation.</description>
  </element>
  <element name="phoneNumber">
    <description> Optional hone number of intended location / establishment (if applicable) for SendLocation.</description>
  </element>
  <element name="timeToDestination"/>
    <!-- TO DO to be removed -->
    <element name="turnText"/>
</enum>
```
