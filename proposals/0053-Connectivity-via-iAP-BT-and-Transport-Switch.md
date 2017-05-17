# Connectivity via iAP-BT and Transport Switch

* Proposal: [SDL-0053](0053-Connectivity-via-iAP-BT-and-Transport-Switch.md)
* Author: [Robin Kurian](https://github.com/robinmk), [Alexandr Galiuzov](https://github.com/AGaliuzov)
* Status: **In Review**
* Impacted Platforms: [Core]

## Introduction

This feature allows iOS devices to be connected with the Head Unit via Bluetooth without requiring a wired USB connection for registering media and non-media apps and also provides provision for transitioning to USB connection once the iOS device is also connected via USB.

## Motivation

An area of pain for iPhone users is the need to plug the iOS device into the Head Unit’s USB port for the apps to register on the Head Unit. On the other hand, Android users are able to register their apps on the Head Unit wirelessly using Bluetooth. The main motivation for this proposal is to lower this entry barrier by making apps register from an iOS device via Bluetooth.
When the same iOS device is connected via a wireless transport and wired transport, Apple specification require the wired transport to be preferred. Another motivation for this proposal is to provide as seamless an experience as possible to the user while complying with Apple specifications.

## Proposed Solution
When an iOS device is connected via Bluetooth the HMI shall setup an iAP session over the Bluetooth transport. After the HMI has setup the iAP session over the Bluetooth transport HMI shall pass information about the mount path to SDL Core and SDL Core shall listen for incoming registration requests from Applications on the Hub protocol string (com.smartdevicelink.prot0). SDL Core shall continue accepting registrations as it would normally do for the USB transport.

A big concern for this feature is the impact to the user when an iOS device connected via BT is also connected via USB. Per Apple specifications the iAP session over the wired transport should be preferred once a determination has been made that the Head Unit is connected to the same iOS device via different transports. In order to make this determination the HMI shall pass the device’s UUID to the SDL Core. Once SDL Core determines that the same device is connected to the Head Unit via multiple transports it shall notify the HMI. HMI can then proceed with closing the iAP session over the Bluetooth transport. Apps which are connected over BT would get disconnected when the iAP session over BT is closed and would need to register over USB.

When the device connects over USB, SDL core shall notify HMI about the change in transportType via the UpdateDeviceList RPC. To mitigate the disruption to the user’s UI experience, the solution proposes SDL Core to hold off on sending to HMI the information about disconnect of the applications till a pre-configured “reconnection” timer expires. This “reconnection” timer would be added to the SmartDeviceLink.ini file. The following cases would apply during the transport switch:

Case A: App re-registers over the alternate transport before the expiry of the “reconnection timer” and provides a valid hash id
*	The app experience would continue almost seamlessly since SDL Core has not deleted any of the AddCommands, AddSubMenus etc from the HMI and all these elements continue to be valid and available to the HMI.

Case B: App re-registers over the alternate transport after the expiry of the “reconnection timer” and provides a valid hash id
*	When the “reconnection timer” times out, SDL core would notify HMI about the app being unregistered. If the app re-registers it would be considered as a fresh registration.
*	Since the app provides a valid hash id, SDL core will perform data resumption.

Case C: App re-registers over the alternate transport before the expiry of the “reconnection timer” and provides an invalid hash id or does not provide a hash id
*	Since the hash id is invalid SDL core will provide a response of RESUME_FAILED to the application’s registration request.
*	SDL core will delete the resumption data for that application.
*	Since the app icon is not part of resumption data and will not be deleted, HMI can continue to show the app icon.

Case D: App re-registers over the alternate transport after the expiry of the “reconnection timer” and provides an invalid hash id or does not provide a hash id
*	When the “reconnection timer” times out, SDL core would notify HMI about the apps being unregistered. The re-registration would be considered as a fresh registration.
*	Since the app provides an invalid hash id, SDL core will not perform data resumption and will proceed to delete previously stored data.

Responses to any requests made by the app just prior to the transport switch would be discarded by SDL Core. If the user triggers any interaction to the app, such interactions will be buffered by SDL Core till the app reconnects (within reconnection timeout period) at which point the requests will be sent to the app or till the expiry of the reconnection timer after which the requests will be discarded. HMI can use the UpdateDeviceList request from SDL core to display any message to the user informing about the transport switch.

## Impact on existing code
*	SDL Core - Transport layer
	*	Implementing logic for waiting for app re-registration during “reconnection time”.
	*	Handling user requests and responses to app requests while transport switch is underway.
	*	Updating the transport type of the device
*	SDL Core - Application Manager
	*	Implementation of connection switching mechanism
	*	Update Waiting timeout for reconnecting procedure
*	SDL Core - Policy
	*	Updating info about Transport Type.
*	SDL Core - Resumption
	*	Case A: App re-registers over the alternate transport before the expiry of the “reconnection timer” and provides a valid hash id
		* The app experience would continue almost seamlessly since SDL Core has not deleted any of the AddCommands, AddSubMenus etc from the HMI and all these elements continue to be valid and available to the HMI.
	
	*	Case B: App re-registers over the alternate transport after the expiry of the “reconnection timer” and provides a valid hash id
		* When the “reconnection timer” times out, SDL core would notify HMI about the app being unregistered. If the app re-registers it would be considered as a fresh registration.
		* Since the app provides a valid hash id, SDL core will perform data resumption.
	
	*	Case C: App re-registers over the alternate transport before the expiry of the “reconnection timer” and provides an invalid hash id or does not provide a hash id
		* Since the hash id is invalid SDL core will provide a response of RESUME_FAILED to the application’s registration request.
		* SDL core will delete the resumption data for that application.
		* Since the app icon is not part of resumption data and will not be deleted, HMI can continue to show the app icon.
	
	*	Case D: App re-registers over the alternate transport after the expiry of the “reconnection timer” and provides an invalid hash id or does not provide a hash id
		* When the “reconnection timer” times out, SDL core would notify HMI about the apps being unregistered. The re-registration would be considered as a fresh registration.
		* Since the app provides an invalid hash id, SDL core will not perform data resumption and will proceed to delete previously stored data.

## Potential downsides
The extent to which a seamless experience can be presented to the user will also be dependent upon the time it would take for the app to re-register over the alternate transport. This factor is beyond the control of the SDL Core.

## Alternatives considered
No alternatives were considered
