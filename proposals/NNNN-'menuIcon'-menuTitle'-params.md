# Retrieving the value of 'menuIcon' and 'menuTitle' parameters from .ini file

* Proposal: [SDL-NNNN]
* Author: [Melnyk Tetiana](https://github.com/TMelnyk)
* Status: Awaiting review
* Impacted Platforms: Core
[SDL-NNNN]: https://github.com/smartdevicelink/sdl_evolution/new/master/proposals/NNNN-'menuIcon'-menuTitle'-params.md

## Introduction  
SDL must retrieve the default values of "menuName" and "menuIcon" parameters from to .ini file in case app didn't provide the last ones.  

## Motivation
SDL must retrieve these default values from .ini file in any applicable cases.  
Default values of "menuName" and "menuIcon" parameters must be added to .ini file with default values:  
menuTitle = MENU  
menuIcon = `<path_to_default_icon>`

In case 'menuIcon' param is empty'MENU' button will be displayed without any icon.
Path can be relative and absolute.

## Proposed solution
1. The "menuIcon" parameter defines the path to default menu icon for SetGlobalProperties.  
In case "menuIcon" is empty -> MENU button will be displayed without any icon 
By default the value of "menuIcon" must be empty.  
In case mobile app sends ResetGlobalProperties with "MENUICON" in "Properties" array
SDL must:  
retrieve the value of 'menuIcon' parameters from .ini file  
transfer UI.SetGlobalProperties (` <menuIcon_from_ini_file>` , params) to HMI. 

2. The "MenuTitle" parameter defines the default value of "menuName" parameter of SetGlobalProperties and must have "MENU" value.  
In case mobile app sends ResetGlobalProperties with "MENUNAME" in "Properties" array  
SDL must:  
retrieve the value of 'menuTitle' parameters from .ini file  
transfer UI.SetGlobalProperties (` <menuTitle_from_ini_file>` , params) to HMI. 

## Detailed design
TBD

## Impact on existing code
TBD

## Alternatives considered
TBD
