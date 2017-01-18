# Providing AppIcon in case of app registration

* Proposal: [SDL-NNNN](NNNN-OnAppRegistered_AppIcon_to_HMI.md)
* Author: [Melnyk Tetiana](https://github.com/TMelnyk)
* Status: **Awaiting review**
* Impacted Platforms: Core / RPC

## Introduction 

This proposal is to provide the applivations _icon_ to HMI in case of app registration. 

## Motivation

**Required for FORD.**
The _icon_ is a symbol that provides notice that the registration is completed.   
Expected that if application has stored _icon_ -> SDL will notify HMI about existance and HMI will show this application _icon_.

## Proposed solution

- The head unit shall remember the name and the file of the app icon that an app has set using the RPC Request _SetAppIcon_ for each app.   
- When an app registers on the head unit it shall look out if the app used _SetAppIcon_ in a previous session.   
   1. If the app has used _SetAppIcon_ in a previous session AND the app icon still exist on the file system the head unit shall use this app icon when creating the app tile in the mobile apps list.
   2. Otherwise use the default AppLink app icon.

## Detailed design

TBD

## Impact on existing code

TBD

## Alternatives considered

TBD
