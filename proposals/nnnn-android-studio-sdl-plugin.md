#Android Studio IDE SDL Plugins

*	Proposal : SDL -nnnn 
*	Author : Michael Morgan
*	Status:  Awaiting Review
*	Review Manager : TDB
*	Impacted Platforms : Android

##Introduction
The SDL Android Studio Plugins will allow for boilerplate code generation for generic SDL activities. This proposal will not impact the SDL code base in anyway and will be available as an IntelliJ Plugin for use with Android Studio. While this proposal does not impact the SDL code, it does use the code and it will be beneficial to be advertised on the SDL websites. This current proposal is focusing on Android development, but there is plan for the creation of iOS plugins being created as well.
Motivation

To assist developers looking to integrate SDL classes into their apps in order to work with In-Vehicle Infotainment systems.
 
##Proposed Solution
The solution proposed here will create a plugin to be used in conjunction with Android Studio that will be able to generate generic SDL activities and the corresponding library imports. The idea is that it will assist in the development of Apps with SDL integration.  

##Detailed Design
The plugin will be part of IntelliJ and will offer the developer the ability to generate the SDL activities in the same manner as they can use the built in generate functions. 

The plugin provides three major functions:
	1)	Add required SDL
	2)	Generate Generic SDL Activity
	3)	Right Click Generate Groups

Add Required SDL: The function will be able to create all required SDL activities, including both main and lock screen activities. If the main application class does not exist the function will create it, if the class does exist the plugin will inject required statements into the onCreate function.  The function will also make necessary permission, services, receiver, and newly created activities updates to the AndroidManifest.xml file.   
Generate Generic SDL Activity:  This function will create a generic SDL activity class with lifecycle functions. It will also generate SDLTemplateView, SDLTextView, SDLButtonView, and SDLGraphicView examples. 
To Add Required SDL or Generate Generic SDLActivity to an Android Studio project by the following step(s): 
File -> New -> Add Required SDL   OR    File -> New - > Generate Generic SDLActivity

Right Click Generate Groups:   This functionality allows generating multiple SDL examples by using Android Studio built in Generate function. 

The following functions will generate examples in the onCreateView function:
	a.	GenerateSDLTextField
	b.	GenerateSDLImage
	c.	GenerateSDLButton
	
The following functions will generate examples where the mouse anchor is positioned:
	a.	GenerateSDLAlert
	b.	GenerateSDLMenu
	c.	Generate SDLPerformInteraction
These functions can be accessed by either of the following:
Right-Click -> Generate   OR   Alt + Insert 

##Impact on Existing Code
There will be no impact to any of the existing code for SDL. This plugin will just use the current existing code in generation of the SDL activities.
However, SDL code change(s) may cause some of the generated functions to be incorrect at a future date. There will need to be some discussion around how to maintain the SDL plugin.




