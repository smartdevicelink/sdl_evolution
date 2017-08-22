# Mobile Projection

* Proposal: [SDL-0031](0031-mobile-projection.md)
* Author: [Jeffrey Hu](https://github.com/jyh947)
* Status: **Accepted**
* Impacted Platforms: [Core / iOS / Android / RPC]

## Introduction

The aim of the Mobile Projection feature is to allow application developers to create custom application use experiences that are not limited by HMI templates.  Mobile Projection applications will be able to stream a video feed to the system and allow users to interact with the application by touching the system's screen.

## Motivation

Currently, mobile applications send information via SDL to a system, which uses the sent information to populate a provided HMI template.  While HMI templates are a simple way for applications to display information to a user, more advanced applications should be given the opportunity to completely control the user experience by creating custom views using video projection.

## Proposed solution

The solution detailed in this proposal will introduce a new AppHMIType of PROJECTION for Mobile Projection applications.  PROJECTION based applications will use the same streaming protocol that is currently being offered for Mobile Navigation applications.  In a more general sense, we are attempting to give general application developers the ability to use the streaming protocols currently available to Mobile Navigation applications.

As a limitation, iOS devices are not allowed to stream video over iAP if they are not in the foreground.  This downside could potentially affect all NAVIGATION and PROJECTION applications, as users who use these applications cannot turn off their device's screen while these applications are streaming.  This limitation is not an issue on Android devices.

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
```

## Impact on existing code

RPC changes:
*	Add AppHMIType type of PROJECTION which uses the same technologies as Mobile Navigation

HMI changes:
*	New HMI APIs support

Mobile iOS/Android SDK changes:
*	New Mobile APIs support

## Alternatives considered

1. Produce more complicated templates.
	*	Explanation: One of the driving forces behind Mobile Projection a request from more advanced developers who want to make more content rich and customized experiences for their users.  To help with that, SDL could potentially create a method for advanced developers to more easily create more unique templates.  These custom templates would still be limited to 8 soft buttons, 4 text fields, 2 graphics, ect.
	*	Why Projection is better: Projection is a much easier method for allowing applications to create unique interfaces because templates in SDL are still heavily controlled.  It is very difficult for a developer to introduce a new template to the open source community given the fact that templates must be general and not specific for one application.  Overall, it would make more sense for custom interfaces to be produced from the application side rather than be saved as a general template to reduce overall complexity.
