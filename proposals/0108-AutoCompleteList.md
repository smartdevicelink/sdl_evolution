# AutoCompleteList
* Proposal: [SDL-0108](0108-AutoCompleteList.md)
* Author: [Derrick Portis](https://github.com/dportis)
* Status: **In Review** 
* Impacted Platforms: [Core / iOS / Android / RPC]

## Introduction

The AutoCompleteList will give apps the ability to have multiple listing options while searching for things like destination and information; instead of giving a single suggestion.

## Motivation

Our goal is to make things as simple as possible for our users, and the current implementation for auto-complete suggestions while searching is limited to a single suggestion. The single suggestion is inefficient in cases where a user has to type the entire address due to having one suggestion. The autoCompleteList is a technique used by many domains that are used for searching, e.g, Google, Apple Maps, or any search engine.

## Proposed solution

The functionality that autoCompleteList provides is the ability to receive a list of suggestions from the app to use while the user types in a destination or any other search. As the user types in location, for example Walmart, when the user types "Wal" there will be a list of results based on factors like proximity and popularity. The user should get a list of suggestion which include several Walmarts or Walgreens with the address attached. The user should also see the list update as characters are typed, meaning once the user types "Walm", other suggestions like Walgreens and others should remove themselves from the list.

The autoCompleteList is a new parameter to the KeyboardProperties struct. This param will be referenced by SDL when an app sends a request that requires the use of a keyboard. The app will provide a list of matching entries as a key phrase is being typed into the search bar. This list should be deleted and replaced if the app sends a new list to the system.

### Current Implementation:
The system currently only allows for a single suggestion while using the keyboard to type.

```xml
<param name="autoCompleteText" type="String" maxlength="1000" mandatory="false">
      <description>Allows an app to prepopulate the text field with a suggested or completed entry as the user types</description>
     </param>
```

### Proposed Implementation:

There is a new parameter for KeyboardProperties which uses an array to allow multiple listing instead of one. 

```xml
<param name="autoCompleteList" type="String" maxlength="1000" minsize="1" maxsize="100" array="true" mandatory="false">
    <description>Allows an app to prepopulate the text field with a list of suggested or completed entry as the user types</description>
 </param>   
```

If an app send both an autoCompleteText and an autoCompleteList parameter in a request to a HU that supports autoCompleteList, the response is successful, and the autoCompleteText is ignored all together.

## Potential downsides

N/A

## Impact on existing code

Mobile API's, HMI API's, and SDL Core all need to be updated to accommodate the new parameters proposed. Older HUs that do not support autoCompleteList will ignore the 'autoCompleteList' parameter and the SetGlobalProperties request itself would be successful.

## Alternatives considered

It was briefly considered to use the existing AutoCompleteText parameter and use a text delimiter key that would allow the system to separate different entries. 
