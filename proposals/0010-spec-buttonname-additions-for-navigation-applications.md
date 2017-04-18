# ButtonName Additions for Navigation Applications

* Proposal: [SDL-0010](0010-spec-buttonname-additions-for-navigation-applications.md)
* Author: [Alex Muller](https://github.com/asm09fsu)
* Status: **Rejected**
* Impacted Platforms: iOS, Android, Core, RPC

## Introduction
Navigation applications currently have the ability to register for a single subscribe-able button, search, which is placed on the HMI screen by the OEM. This proposal is relating to adding additional subscribe-able, on screen buttons for usage with navigation apps.

## Motivation
This proposal addresses concerns relating to developers whom do not have a desire or expertise of drawing buttons on the screen for common navigation tasks. Currently, this requires knowledge of existing on screen HMI views put in place by an OEM that may overlap the visible drawable area, or other HMI controls by another OEM, resulting in complicated drawing implementations. The idea is to add a few desired buttons that are subscribe-able by the developer if they so choose to use them. The buttons that are up for proposal are:

- Map Center
	* Map Center is most likely the most desirable addition, as when using a navigation app, the user should have an easy way to re-center the map on the current location
* Zoom In
	* For developers with the inability to implement multi-touch logic, or OEMs that do not have a high-fidelity screen this could be automagically subscribed on Navigation Apps.
* Zoom Out
	* For developers with the inability to implement multi-touch logic, or OEMs that do not have a high-fidelity screen this could be automagically subscribed on Navigation Apps.
* Pan Up
	* For developers with the inability to implement pan-touch logic, or OEMs that do not have a high-fidelity screen this could be automagically subscribed on Navigation Apps.
* Pan Down
	* For developers with the inability to implement pan-touch logic, or OEMs that do not have a high-fidelity screen this could be automagically subscribed on Navigation Apps.
* Pan Left
	* For developers with the inability to implement pan-touch logic, or OEMs that do not have a high-fidelity screen this could be automagically subscribed on Navigation Apps.
* Pan Right
	* For developers with the inability to implement pan-touch logic, or OEMs that do not have a high-fidelity screen this could be automagically subscribed on Navigation Apps.

> This proposal should also be considered an open forum for any other possible buttons that could be desirable by OEMs/developers until reviewed.

## Proposed solution
Currently, if a developer wishes to have non-supplied controls on their navigation applications, the developer needs to design and add these to the map frame themselves. This adds a few issues:
	1. The controls are usually not designed following NHTSA guidelines for graphics on the screen, whereas OEMs (usually) have a fine understanding of these.
	2. Currently it is impossible to know whether an OEM has any HMI views overlaid on the screen, making it difficult for a developer to know where to draw their controls in conjunction with the OEM's.
	3. The developer has to add logic in for developing touch event recognizers for these drawn controls, and that may impact the map touch recognizer.
	4. Drawing these controls will add processing time for sent frames depending on how they plan to add them to the frame being drawn.

Adding in new subscribe-able buttons will give OEMs the chance to place them in the most ideal locations they deem for their navigation template layout. 

The implementation on a developer would be just as they would use any other Subscribe Button request, except they would use the new enum values to specify the button they wish to use. There is no limit to what combination the developer could use (all, none, or just some). The developer would expect to receive a Subscribe Button response, and also would expect to receive all button states via Button Event Notifications and Button Press Notifications.	


## Detailed design
The design of the addition to the ButtonName enum means that all 3 current platforms (Core, iOS and Android) must be modified (however not in parallel) to support. One possible question is pertaining to whether or not these are only available in app type "NAVIGATION" and it's corresponding template. ~I propose that this is the route to go down~, as it does not make sense in any other app types or template layouts at the current time. Below is definitive modifications needed on the Spec, iOS and Android platforms. The Core side is a best guess, and the only code snippet added is where we would add a check for subscribing buttons and confirming if the app connected is a navigation app. On all platforms, the ability for ~both~ Subscribing and Unsubscribing must be supported.

#### Spec Impact:
Mobile_API.xml
```xml
...
<enum name="ButtonName">
		...
    <element name="CENTER_MAP" />
    <element name="ZOOM_IN" />
    <element name="ZOOM_OUT" />
    <element name="PAN_UP" />
    <element name="PAN_DOWN" />
    <element name="PAN_LEFT" />
    <element name="PAN_RIGHT" />		
  </enum>
...
```

#### iOS Impact:
SDLButtonName.h:
```objc
@interface SDLButtonName : SDLEnum
...
+ (SDLButtonName*)CENTER_MAP;
+ (SDLButtonName*)ZOOM_IN;
+ (SDLButtonName*)ZOOM_OUT;
+ (SDLButtonName*)PAN_UP;
+ (SDLButtonName*)PAN_DOWN;
+ (SDLButtonName*)PAN_LEFT;
+ (SDLButtonName*)PAN_RIGHT;

@end
```

SDLButtonName.m:
```objc
...
SDLButtonName *SDLButtonName_CENTER_MAP = nil;
SDLButtonName *SDLButtonName_ZOOM_IN = nil;
SDLButtonName *SDLButtonName_ZOOM_OUT = nil;
SDLButtonName *SDLButtonName_PAN_UP = nil;
SDLButtonName *SDLButtonName_PAN_DOWN = nil;
SDLButtonName *SDLButtonName_PAN_LEFT = nil;
SDLButtonName *SDLButtonName_PAN_RIGHT = nil;

...

+ (NSArray *)values {
    if (SDLButtonName_values == nil) {
        SDLButtonName_values = @[
			  ...
            SDLButtonName.CENTER_MAP,
            SDLButtonName.ZOOM_IN,
            SDLButtonName.ZOOM_OUT,
            SDLButtonName.PAN_UP,
            SDLButtonName.PAN_DOWN,
            SDLButtonName.PAN_LEFT,
            SDLButtonName.PAN_RIGHT
        ];
    }
    return SDLButtonName_values;
}

...

+ (SDLButtonName *)CENTER_MAP {
    if (SDLButtonName_CENTER_MAP == nil) {
        SDLButtonName_CENTER_MAP = [[SDLButtonName alloc] initWithValue:@"CENTER_MAP"];
    }
    return SDLButtonName_CENTER_MAP;
}

+ (SDLButtonName*)ZOOM_IN {
    if (SDLButtonName_ZOOM_IN == nil) {
        SDLButtonName_ZOOM_IN = [[SDLButtonName alloc] initWithValue:@"ZOOM_IN"];
    }
    return SDLButtonName_ZOOM_IN;
}
+ (SDLButtonName*)ZOOM_OUT {
	  if (SDLButtonName_ZOOM_OUT == nil) {
        SDLButtonName_ZOOM_OUT = [[SDLButtonName alloc] initWithValue:@"ZOOM_OUT"];
    }
    return SDLButtonName_ZOOM_OUT;
}

+ (SDLButtonName*)PAN_UP {
	  if (SDLButtonName_PAN_UP == nil) {
        SDLButtonName_PAN_UP = [[SDLButtonName alloc] initWithValue:@"PAN_UP"];
    }
    return SDLButtonName_PAN_UP;
}

+ (SDLButtonName*)PAN_DOWN {
	  if (SDLButtonName_PAN_DOWN == nil) {
        SDLButtonName_PAN_DOWN = [[SDLButtonName alloc] initWithValue:@"PAN_DOWN"];
    }
    return SDLButtonName_PAN_DOWN;
}

+ (SDLButtonName*)PAN_LEFT {
	  if (SDLButtonName_PAN_LEFT == nil) {
        SDLButtonName_PAN_LEFT = [[SDLButtonName alloc] initWithValue:@"PAN_LEFT"];
    }
    return SDLButtonName_PAN_LEFT;
}

+ (SDLButtonName*)PAN_RIGHT {
	  if (SDLButtonName_PAN_RIGHT == nil) {
        SDLButtonName_PAN_RIGHT = [[SDLButtonName alloc] initWithValue:@"PAN_RIGHT"];
    }
    return SDLButtonName_PAN_RIGHT;
}

```

#### Android Impact:
ButtonName.java
```java
public enum ButtonName {
	...,
	CENTER_MAP,
	ZOOM_IN,
	ZOOM_OUT,
	PAN_UP,
	PAN_DOWN,
	PAN_LEFT,
	PAN_RIGHT;
	...
}
```

#### Core Impact (Definitely much more):
subscribe_button_request.cc
```c
...

bool SubscribeButtonRequest::IsSubscriptionAllowed(
    ApplicationSharedPtr app, mobile_apis::ButtonName::eType btn_id) {

...

  if (!/*some way to detect is nav app*/ &&
      ((mobile_apis::ButtonName::CENTER_MAP == btn_id) ||
       (mobile_apis::ButtonName::ZOOM_IN == btn_id)||
       (mobile_apis::ButtonName::ZOOM_OUT == btn_id)   ||
       (mobile_apis::ButtonName::PAN_UP == btn_id)||
		 (mobile_apis::ButtonName::PAN_DOWN == btn_id)   ||
		 (mobile_apis::ButtonName::PAN_LEFT == btn_id)||
		 (mobile_apis::ButtonName::PAN_RIGHT == btn_id))) {
    return false;
  }
...

}
```

v4_protocol_v1_2_no_extra.xml
```xml
...
<enum name="ButtonName">
	  ...
	  <element name="CENTER_MAP" />
    <element name="ZOOM_IN" />
    <element name="ZOOM_OUT" />
    <element name="PAN_UP" />
    <element name="PAN_DOWN" />
    <element name="PAN_LEFT" />
    <element name="PAN_RIGHT" />	
</enum>
...
```

## Impact on existing code
This change should cause no inadvertent affects to previous versions of SDL. Core could potentially send a button event or button press notification, but the developer would ignore it unless they are not properly monitoring for their specific button (if they had any they were monitoring). Core should also ignore any unknown enum values passed in for ButtonName.

## Alternatives considered
The only alternatives is to expect developers to draw these controls themselves. This, in the long term, is not beneficial to SDL or the developers.
