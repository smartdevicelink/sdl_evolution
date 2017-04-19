# Retrieving the value of 'menuIcon' and 'menuTitle' parameters from .ini file

* Proposal: [SDL-0039](0039-'menuIcon'-menuTitle'-params.md)
* Author: [Melnyk Tetiana](https://github.com/TMelnyk)
* Status: **Deferred**
* Impacted Platforms: Core

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
###### Extend `profile.h` with neccessary interfaces
```c++
class Profile {

std::string get_menu_icon();
std::string get_menu_title();

}
```
###### Add appropriate logic into `ResetGlobalProperties` class.
####### Old
```c++
 if (menu_name) {
      msg_params[hmi_request::menu_title] = "";
      app->set_menu_title(msg_params[hmi_request::menu_title]);
    }
```
####### New
```c++
 if (menu_name) {
      msg_params[hmi_request::menu_title] =  application_manager_.get_settings().get_menu_title();
      app->set_menu_title(msg_params[hmi_request::menu_title]);
    }
```
## Impact on existing code
The `Profile` class has to be extended with additional api. In `ResetGlobalProperties` hardcoded `menu_icon` and `menu_title`
have to be substituted with parameters from ini file.

smartDeviceLink.ini file has to be extended with `MenuIcon` and `MenuTitle` parameters.

## Alternatives considered
The only alternative is to kepp using hardcoded values.
