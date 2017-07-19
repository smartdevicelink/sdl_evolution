# Support for MultiSession protocol string

* Proposal: [SDL-0080](0080-Support-for-MultiSession-protocol-string.md)
* Author: [James Sokoll](https://github.com/jamescs), [Robin Kurian](https://github.com/robinmk)
* Status: **In Review**
* Impacted Platforms: [Core/iOS]

## Introduction

This proposal introduces a new protocol string for head units which support iOS multisession (Ability for multiple apps to connect over the same protocol string) and also identifies the changes to the iOS proxy layer.

## Motivation

The existing 'Hub' connection strategy requires an application (proxy layer) to negotiate a dedicated protocol channel with the head unit and reconnect over the dedicated protocol channel before requesting registration. This strategy was in place to overcome the limitation of an app disconnecting the connection of a previous app on head units which did not support multisession. 
Head units which support multisession would allow multiple apps to connect over the same protocol string thereby eliminating the need for the 'Hub' strategy and allowing applications to appear faster on the head unit (when it registers).

## Proposed solution

### Head Unit
Head units which support multisession should declare support for the following protocol string when setting up their iAP session.<br />
New protocol string: com.smartdevicelink.multisession<br />
Head Units would still need to support the 'Hub' protocol string and the Hub strategy inorder to support apps which do not upgrade to the latest proxy.

### iOS Proxy

When the iOS Proxy begins to setup the connection with the head unit, it should check if the system supports the new protocol string. If the Head Unit supports the new protocol string then the iOS proxy should attempt to start a data session with the head unit over the new protocol string. If the Head Unit does not support the new protocol string, the iOS proxy should continue existing behavior of attempting a control session via the Hub protocol and negotiating a dedicated protocol string over which it should start a data session.
<br />![iOS Proxy Flow][iOS-proxy-flow]

## Potential downsides

NA

## Impact on existing code

### Changes to SDL proxy - SDLGlobals.h
```objc
#define SDL_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(version) ([[[UIDevice currentDevice] systemVersion] compare:version options:NSNumericSearch] != NSOrderedAscending)
```


### Changes to SDL proxy - SDLIAPTransport.m
```objc
NSString *const multiSessionProtocolString = @"com.smartdevicelink.multisession";
```
:
```objc
(BOOL)sdl_connectAccessory:(EAAccessory *)accessory {
    BOOL connecting = NO;

    if ([accessory supportsProtocol:multiSessionProtocolString] && SDL_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9")) {
        [self sdl_createIAPDataSessionWithAccessory:accessory forProtocol:multiSessionProtocolString];
        connecting = YES;
    } else if ([accessory supportsProtocol:controlProtocolString]) {
        [self sdl_createIAPControlSessionWithAccessory:accessory];
        connecting = YES;
    } else if ([accessory supportsProtocol:legacyProtocolString]) {
        [self sdl_createIAPDataSessionWithAccessory:accessory forProtocol:legacyProtocolString];
        connecting = YES;
    }

    return connecting;
}
```
:
```objc
(void)sdl_establishSessionWithAccessory:(EAAccessory *)accessory {
    [SDLDebugTool logInfo:@"Attempting To Connect"];
    if (self.retryCounter < createSessionRetries) {
        // We should be attempting to connect
        self.retryCounter++;
        EAAccessory *sdlAccessory = accessory;
        // If we are being called from sdl_connectAccessory, the EAAccessoryDidConnectNotification will contain the SDL accessory to connect to and we can connect without searching the accessory manager's connected accessory list. Otherwise, we fall through to a search.
        if (sdlAccessory != nil && [self sdl_connectAccessory:sdlAccessory]) {
            // Connection underway, exit
            return;
        }

        // Determine if we can start a multi-app session or a legacy (single-app) session
        if ((sdlAccessory = [EAAccessoryManager findAccessoryForProtocol:multiSessionProtocolString]) && SDL_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9")) {
            [self sdl_createIAPDataSessionWithAccessory:sdlAccessory forProtocol:multiSessionProtocolString];
        } else if ((sdlAccessory = [EAAccessoryManager findAccessoryForProtocol:controlProtocolString])) {
            [self sdl_createIAPControlSessionWithAccessory:sdlAccessory];
        } else if ((sdlAccessory = [EAAccessoryManager findAccessoryForProtocol:legacyProtocolString])) {
            [self sdl_createIAPDataSessionWithAccessory:sdlAccessory forProtocol:legacyProtocolString];
        } else {
            // No compatible accessory
            [SDLDebugTool logInfo:@"No accessory supporting a required sync protocol was found."];
            self.sessionSetupInProgress = NO;
        }

    } else {
        // We are beyond the number of retries allowed
        [SDLDebugTool logInfo:@"Create session retries exhausted."];
        self.sessionSetupInProgress = NO;
    }
}

```
## Alternatives considered

NA

[iOS-proxy-flow]: ../assets/proposals/0080-Support-for-MultiSession-protocol-string/MultiSession-iOS_Proxy_Flow.png
