# Default SoftButtonCapabilities

* Proposal: [SDL-NNNN](nnnn-default-softbuttoncapabilities.md)
* Author: [Markos Rapitis](https://github.com/mrapitis) 
* Status: **Awaiting Review**
* Impacted Platforms: [iOS, Android]

## Introduction

This proposal is to update the iOS and Android mobile libraries with a specified default list size value for SoftButtonCapabilities when a headunit erroneously returns a SoftButtonCapabilities list that contains just one item.  A SoftButtonCapabilities list is received from the RegisterAppInterface and SetDisplayLayout RPC responses.  The purpose of the SoftButtonCapabilities list in these RPC's is to inform the mobile application how many SoftButtons are available for the utilized template and the capabilites of each SoftButton.

## Motivation

An existing OEM head unit implementation in the field always incorrectly returns a SoftButtonCapabilities list with just one item from both the RegisterAppInterface and SetDisplayLayout RPC responses.  Unfortunately this causes a problem for app developers as they have no way of knowing how many softbuttons are actually supported for a particular template being utilized by the app.  

## Proposed solution
To resolve this shortcoming for any given template the mobile libraries need to be updated to return default list size values to the mobile application when an incorrect headunit implementation has been detected (SoftButtonCapabilities list value equals 1).

## Potential downsides
Complexity in the mobile libraries increases to recover from incorrect HMI side implementations, however in this case the changes are warranted.

## Impact on existing code
Introduce new / update existing methods in the mobile API to accommodate for default list size values per template.

## Alternatives considered
None as the wrong HMI implementation already exists in the field.
