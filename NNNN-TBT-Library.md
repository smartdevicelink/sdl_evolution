# TBT Library

* Proposal: [SE-NNNN](NNNN-filename.md)
* Author: [Kujtim Shala](https://github.com/kshala-ford)
* Status: **Awaiting review**
* Review manager: TBD
* Impacted Platforms: [iOS / Android]

## Introduction

This proposal is to provide app developers offering POI search a solution to navigate the driver to the selected POI even though the head unit does not offer a navigation API (older head units and others without embedded navigation). OEMs can cooperate with suppliers of navigation SDKs to provide routes and instructions which are used by the mobile libraries to show them on the head unit.

## Motivation

POI related apps are typically using the native maps app (Apple Maps or Google Maps) on the phone to provide users a way to navigate to the desired destination. Over SDL these native maps apps cannot be used as it would be necessary to pick up the phone to get them to run and therefore would violate driver distraction rules. The SDL API provides a way to send a location to the embedded navigation but still the majority of SDL enabled head units are not equiped with embedded navigation or are running an older version of SDL which are not capable of the location API.

## Proposed solution

The idea is to provide an API in the mobile libraries to app developers to navigate to a desired destination. On the other side suppliers of navigation SDKs can develop against APIs and create a TBT proxy to accept requests to navigate to a destination. Furthermore these navigation SDKs can provide notifications for instructions, a maneuver icon and a map view to be shown inside the lock screen. Inbetween SDL can receive the information from the navigation SDKs and send them to the HMI of the head unit. Implementing the HMI related work inside the mobile libraries would unify the behavior of different navigation SDKs and make it very easy for app developers to integrate a navigation feature into their apps.

## Detailed design

* Provide a TBT navigation manager to interact and communicate to one or more TBT navigation proxies
  * Offer an interface for initialization to the app to accept 
    * a list of potential TBT proxies
    * a location necessary to select a valid TBT proxy
    * a listener for asynchronous communication to the app
* The TBT manager should support multiple TBT proxies from different navigation SDKs.
* When initializing:
  * Read out app and vehicle information when being connected to a head unit
  * Probe and ask which TBT proxy is capable of the environment. A TBT proxy validates:
    * Is the TBT proxy valid for the vehicle make
    * Is the app allowed to use a TBT proxy
    * Is the location inside the region the TBT proxy can operate
  * Create an instance of a TBT proxy which is valid for the environment
* Manage permissions TBT related permissions
  * Listen to permission changes for vehicle GPS and push notifications
  * Tell the TBT proxy instance if the permission of vehicle GPS has changed
  * Automatically subscribe for vehicle GPS if allowed
  * Pass the vehicle GPS to a TBT proxy instance
* Offer an interface to the app to accept a request to start the navigation to a destination
  * Use the TBT proxy instance to perform the request
* During navigation:
  * Create a TBT activity instance managing the UI/voice related operations
  * Accept a map view from the TBT proxy instance to be shown on the apps lock screen
    * Pass through the view to the lock screen activity
    * Configure the lock screen to be shown even if the vehicle is not in motion
  * Accept navigation summary updates from the TBT proxy about 
    * the time of arrival 
    * the duration and distance of the route and the current step / the next maneuver
  * Accept notification for an instruction from the TBT proxy with
    * Maneuver icon
    * Display instruction
    * Voice instruction
  * Pass through navigation summary updates and instruction to the TBT activity.
* Provide a TBT activity managing UI/voice related operations
  * Accept navigation summary updates from the TBT manager
  * Accept navigation instructions from the TBT manager
    * Show the maneuver icon if graphics are supported
    * Show the instruction text on the apps base screen
    * Perform a push notification to notify through UI and voice
  * Offer a mute/unmute feature to the user on the head unit
    * While being muted the TBT activity should not use voice functionality
  * Offer a stop feature to the user on the head unit
    * Pass a stop request to the TBT manager to stop the navigation

## Impact on existing code

The proposal would requrie the design of the enhanced framework and would impact the lock screen code.

## Alternatives considered

As an alternative a separate mobile library could be created that provides this proposal. This could work similar to the way how OpenGL provides their utilities (glu) and the utility toolkit (glut) libraries. This proposal was chosen because the alternative would overcomplicate the intergration of all the libraries and communication between the app, SDL and the navigation SDKs.
