# Default SoftButtonCapabilities

* Proposal: [SDL-0114](0114-default-softbuttoncapabilities.md)
* Author: [Markos Rapitis](https://github.com/mrapitis) 
* Status: **In Review**
* Impacted Platforms: [iOS, Android]

## Introduction

This proposal is to update the iOS and Android mobile libraries with a specified default list size value for SoftButtonCapabilities when a headunit erroneously returns a SoftButtonCapabilities list that contains just one item.  The purpose of the SoftButtonCapabilities list is to inform the mobile application how many SoftButtons are available for the utilized template and the capabilities of each SoftButton. The  SoftButtonCapabilities list is received by the mobile application from the RegisterAppInterface and SetDisplayLayout RPC responses.

## Motivation

An existing OEM head unit implementation in the field always incorrectly returns a SoftButtonCapabilities list with just one item from both the RegisterAppInterface and SetDisplayLayout RPC responses.  Unfortunately this causes a problem for app developers as they have no way of knowing how many softbuttons are actually supported for a particular template being utilized by the app.  

## Proposed solution
To resolve this shortcoming for any given template, the mobile libraries need to be updated to return default list size values to the mobile application when an incorrect headunit implementation has been detected (SoftButtonCapabilities list value count is one). The table below contains default SoftButtonCapabilities lists sizes for each supported template:

| Template Name                      | SoftButton's Avail |
| ---------------------------------- |:--------:|
| MEDIA                              | 8    |
| GRAPHIC_WITH_TEXT                  | 0    |
| TEXT_WITH_GRAPHIC                  | 0    |
| TILES_ONLY                         | 7    |
| TEXTBUTTONS_ONLY                   | 8    |
| GRAPHIC_WITH_TILES                 | 3    |
| TILES_WITH_GRAPHIC                 | 3    |
| GRAPHIC_WITH_TEXT_AND_SOFTBUTTONS  | 2    |
| TEXT_AND_SOFTBUTTONS_WITH_GRAPHIC  | 2    |
| GRAPHIC_WITH_TEXTBUTTONS           | 3    |
| TEXTBUTTONS_WITH_GRAPHIC           | 3    |
| LARGE_GRAPHIC_WITH_SOFTBUTTONS     | 8    |
| DOUBLE_GRAPHIC_WITH_SOFTBUTTONS    | 8    |
| LARGE_GRAPHIC_ONLY                 | 0    |
| NON_MEDIA                          | 8    |

## Potential downsides
Complexity in the mobile libraries is being introduced to recover from incorrect HMI side implementations, however in this case the changes are warranted.

## Impact on existing code
Introduce new / update existing methods in the mobile API to accommodate for default list size values per template.

## Alternatives considered
Setting a fixed number of SoftButtons per template was also considered in our SoftButtonCapabilities workshop.
