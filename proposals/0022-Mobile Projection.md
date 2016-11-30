# Mobile Projection

* Proposal: [SDL-0022](0022-Mobile Projection.md)
* Author: Jeffrey Hu
* Status: **Awaiting review**
* Impacted Platforms: [Core / iOS / Android / RPC]

## Introduction

The aim of the Mobile Projection feature is to allow application developers to create custom application use experiences that are not limited by HMI templates.  Mobile Projection applications will be able to stream a video feed to the system and allow users to interact with the application by touching the system's screen.

## Motivation

Currently, mobile applications send information via SDL to a system, which uses the sent information to populate a provided HMI template.  While HMI templates are a simple way for applications to display information to a user, more advanced applications should be given the opportunity to completely control the user experience by creating custom views using video projection.

## Proposed solution

The solution detailed in this proposal will introduce a new AppHMIType of PROJECTION for Mobile Projection applications.  Projection based applications will use the same streaming protocol that is currently being offered for Mobile Navigation applications.  In a more general sense, we are attempting to give general application developers the ability to use the streaming protocols currently available to Mobile Navigation applications.

We will also introduce a method of allowing projection based applications to request full screen access on the system.  Applications may request full screen access by sending a SetDisplayLayout RPC with a displayLayout parameter of FULLSCREEN to the head unit.  Once the system accepts the RPC, it will return a SUCCESS response and also send an OnHMIStatus notification with a systemContext of FULLSCREEN back to the application.  The screen area that the application can stream to will be known by looking up the resolutionFullscreen parameter in the ScreenParams struct in the RegisterAppInterface RPC response, sent during the application's startup procedure.  

## Detailed design

### Additions to Mobile_API
```xml
	<enum name="AppHMIType">
		<description>Enumeration listing possible app types.</description>
		<element name="DEFAULT" />
		<element name="COMMUNICATION" />
		<element name="MEDIA" />
		<element name="MESSAGING" />
		<element name="NAVIGATION" />
		<element name="INFORMATION" />
		<element name="SOCIAL" />
		<element name="PROJECTION" />
		<element name="BACKGROUND_PROCESS" />
		<element name="TESTING" />
		<element name="SYSTEM" />
	</enum>
  
	<struct name="ScreenParams">
		<param name="resolution" type="ImageResolution" mandatory="true">
			<description>The resolution of the prescribed screen area.</description>
		</param>
		<param name="resolutionFullscreen" type="ImageResolution" mandatory="false">
			<description>The resolution of the prescribed screen area once an application requests for full screen access.</description>
		</param>
		<param name="touchEventAvailable" type="TouchEventCapabilities" mandatory="false">
			<description>Types of screen touch events available in screen area.</description>
		</param>
	</struct>
   
	<enum name="SystemContext">
			<description>Enumeration that describes possible contexts the application might be in on HU.</description>
			<description>Communicated to whichever app is in HMI FULL, except Alert.</description>
		<element name="MAIN" internal_name="SYSCTXT_MAIN">
			<description>The app's persistent display (whether media/non-media/navigation) is fully visible onscreen.</description>
			<description> There is currently no user interaction (user-initiated or app-initiated) with the head-unit</description>
		</element>
		<element name="VRSESSION" internal_name="SYSCTXT_VRSESSION">
			<description>The system is currently in a VR session (with whatever dedicated VR screen being overlaid onscreen).</description>
		</element>
		<element name="MENU" internal_name="SYSCTXT_MENU">
			<description>The system is currently displaying a system or in-App menu onscreen.</description>
		</element>
		<element name="HMI_OBSCURED" internal_name="SYSCTXT_HMI_OBSCURED">
			<description>The app's display HMI is currently obscuring with either a system or other app's overlay (except of Alert element).</description>
		</element>
		<element name="ALERT" internal_name="SYSCTXT_ALERT">
			<description>Broadcast only to whichever app has an alert currently being displayed.</description>
		</element>
		<element name="FULLSCREEN" internal_name="SYSCTXT_FULLSCREEN">
			<description>The system is currently displaying a video feed with the bottom bar lowered.</description>
		</element>
	</enum>
```

### Additions to HMI_API
```xml
	<enum name="AppHMIType">
		<description>Enumeration listing possible app types.</description>
		<element name="DEFAULT" />
		<element name="COMMUNICATION" />
		<element name="MEDIA" />
		<element name="MESSAGING" />
		<element name="NAVIGATION" />
		<element name="INFORMATION" />
		<element name="SOCIAL" />
		<element name="PROJECTION" />
		<element name="BACKGROUND_PROCESS" />
		<element name="TESTING" />
		<element name="SYSTEM" />
	</enum>
  
	<struct name="ScreenParams">
		<param name="resolution" type="Common.ImageResolution" mandatory="true">
			<description>The resolution of the prescribed screen area.</description>
		</param>
		<param name="resolutionFullscreen" type="ImageResolution" mandatory="false">
			<description>The resolution of the prescribed screen area once an application requests for full screen access.</description>
		</param>
		<param name="touchEventAvailable" type="Common.TouchEventCapabilities" mandatory="false">
			<description>Types of screen touch events available in screen area.</description>
		</param>
	</struct>
	
	<enum name="SystemContext">
			<description>Enumeration that describes possible contexts the application might be in on HU.</description>
			<description>Communicated to whichever app is in HMI FULL, except Alert.</description>
		<element name="MAIN" internal_name="SYSCTXT_MAIN">
			<description>The app's persistent display (whether media/non-media/navigation) is fully visible onscreen.</description>
			<description> There is currently no user interaction (user-initiated or app-initiated) with the head-unit</description>
		</element>
		<element name="VRSESSION" internal_name="SYSCTXT_VRSESSION">
			<description>The system is currently in a VR session (with whatever dedicated VR screen being overlaid onscreen).</description>
		</element>
		<element name="MENU" internal_name="SYSCTXT_MENU">
			<description>The system is currently displaying a system or in-App menu onscreen.</description>
		</element>
		<element name="HMI_OBSCURED" internal_name="SYSCTXT_HMI_OBSCURED">
			<description>The app's display HMI is currently obscuring with either a system or other app's overlay (except of Alert element).</description>
		</element>
		<element name="ALERT" internal_name="SYSCTXT_ALERT">
			<description>Broadcast only to whichever app has an alert currently being displayed.</description>
		</element>
		<element name="FULLSCREEN" internal_name="SYSCTXT_FULLSCREEN">
			<description>The system is currently displaying a video feed with the bottom bar lowered.</description>
		</element>
	</enum>
```

## Impact on existing code

SDL Core changes:
*	Add AppHMIType type of PROJECTION which uses the same technologies as Mobile Navigation
*	Add resolutionFullscreen parameter to ScreenParams struct in RegisterAppInterface RPC
*	Add systemContext option of FULLSCREEN field to OnHMIStatus RPC

HMI changes:
*	New HMI APIs support	

Mobile iOS/Android SDK changes:
*	New Mobile APIs support

## Alternatives considered

1. Produce a template tool for developers.
	*	Explanation: This tool would allow developers to create more complicated user interfaces within the application to stream to the system.  This implementation would still use the Mobile Projection concept of broadcasting video to the system, but developers would be assisted in producing a video stream rather than just forcing developers to create the streamed video completely on their own.
	*	Why Projection is better: This idea is simply a more structured way of introducing Mobile Projection to application developers.  Thus, it isn't a full alternative method for replacing the Mobile Projection feature.

2. Produce more complicated templates.
	*	Explanation: One of the driving forces behind Mobile Projection a request from more advanced developers who want to make more content rich and customized experiences for their users.  To help with that, SDL could potentially create a method for advanced developers to more easily create more unique templates.  These custom templates would still be limited to 8 soft buttons, 4 text fields, 2 graphics, ect.
	*	Why Projection is better: Projection is a much easier method for allowing applications to create unique interfaces because templates in SDL are still heavily controlled.  It is very difficult for a developer to introduce a new template to the open source community given the fact that templates must be general and not specific for one application.  In spirit of SDL, it would make more sense for custom interfaces to be produced from the application side rather than by SDL.
