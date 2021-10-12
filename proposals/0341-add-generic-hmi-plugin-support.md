# Add Generic HMI Plugin Support

* Proposal: [SDL-0341](0341-add-generic-hmi-plugin-support.md)
* Author: [Jacob Keeler](https://github.com/smartdevicelink)
* Status: **Returned for Revisions**
* Impacted Platforms: [HMI]

## Introduction

The Generic HMI is currently missing a number of components which are available in the SDL project. The main reason behind this is that several HMI interfaces require data from components of the vehicle beyond SDL (ex. climate module data). This means that many of these vehicle components would need to be emulated in a test environment, and would need to use faked/test data. This makes including these components in the Generic HMI a difficult task, as the project is meant to be a definitive reference implementation for an SDL integration, and introducing faked data to the project would go against that design. Ideally, it should be possible to include the Generic HMI in a production system with minimal modification. This proposal provides a potential solution to this issue by introducing swappable plugins for the Generic HMI. These can be used to easily integrate both test and production implementations of these missing interfaces in the Generic HMI.

## Motivation

The main motivation behind this proposal is to bring the Generic HMI to a state where it can support all available SDL features. Currently a number of the available HMI interfaces aren't implemented (or are only partially implemented) within the Generic HMI, specifically:

- VR
- RC
- VehicleInfo
- Buttons (with the exception of media app buttons and softbuttons)
- Navigation (with the exception of video streaming)
- AppService (HMI provider support)

## Proposed solution

The ideal way to add support for these vehicle-specific components in the Generic HMI would be to introduce external plugins to the project. These plugins are separate applications with limited scope which run alongside the HMI and interact with it as needed. Basic plugins which emulate vehicle functionality can be included in the project for testing and reference purposes, while tailored plugins can be written to work with a specific system in production cases. Each of these plugins would maintain their own connection to SDL Core using a message broker, which can be borrowed from the Manticore project (see [here](https://github.com/smartdevicelink/manticore-images/blob/master/cores/broker/index.js)). Much of the test functionality needed in the Generic HMI is already available in the Manticore project (ex. vehicle data), so these components could be ported and used as a baseline for several of the test plugins detailed in this proposal.

An additional benefit to this approach is that plugins which run in the background can be written in any desired language; they only need to connect to the router service.

### Plugin Configuration

It should be possible to add, remove, disable, and replace these plugins with minimal configuration changes where feasible. Ideally, this configuration could be handled using the existing `Flags.js` file, which is currently used by the Generic HMI for any runtime configurations. A potential format for this configuration could be:

```
window.flags = {
    VRPlugin: {
        Enabled: false, //Plugin is disabled, HMI will ignore this entry
        Url: 'http://127.0.0.1:3010', //URL path to plugin application, for web applications
        TestViewEnabled: true, //Plugin application has a test UI (accessible via the "Url" field), which should be displayed beside the main HMI
        TestViewTitle: 'Voice', //Title to display alongside the plugin's test UI
        MenuNavEnabled: true, //Plugin has a custom integrated component within the Generic HMI, accessible via settings menu
        MenuNavTitle: 'Voice Commands' //Text to display with the item in the settings menu directing to this plugin's custom component
    },
    ...
};
```

**Note:** This format is tentative and could change depending on the final implementation.

### Message Broker

In order to communicate with each of these plugins, a message broker will be added to the project to route messages between SDL Core and each HMI component (using [Manticore's message broker](https://github.com/smartdevicelink/manticore-images/blob/master/cores/broker/index.js) as a base). Each plugin (in addition to the Generic HMI itself) will connect to this message broker in place of SDL Core and register one or more HMI interfaces using the [MB.registerComponent](https://smartdevicelink.com/en/guides/core/integrating-your-hmi/sdl-core-and-hmi-communication/#component-registration) request. The message broker will then automatically route messages from SDL Core to all appropriate plugins based on which interfaces they registered (multiple plugins can register to the same interface, if needed). 

Some interfaces (such as VehicleInfo) only have stub implementations in the Generic HMI at the moment because, as mentioned previously, they require information from an actual vehicle to work properly. If an appropriate plugin is available for one of these unimplemented interfaces, then the Generic HMI itself will skip registration for that interface, allowing the plugin to handle all messages related to the given interface instead.

In addition, the message broker can be used to send messages between individual plugins as well as the main HMI, such messages are described in [this section](#messages-between-components).

### Web-based plugins

In the case of web-based plugins, the Generic HMI should be able to run these plugins directly in-browser when the HMI itself is started. This feature would be configured using the options defined in the [Plugin Configuration](#plugin-configuration) section of this proposal. In order to run these applications within the browser, the Generic HMI could open the provided `Url` in the plugin configuration within a hidden `iframe` or something similar, allowing the plugin to run alongside the HMI.

#### Displaying test plugins in-browser

For any web-based test plugins, the UI of the plugin should be possible to display directly in the browser window beside the main HMI using the provided `Url` config parameter. These plugin UIs could be arranged in a similar manner to Manticore using tabs, with each tab containing a window (also possible using `iframe`) to display the test UI.

![Plugin Tabs](../assets/proposals/0341-add-generic-hmi-plugin-support/plugin-tabs-example.png)

The test UI for each plugin should be possible to include or exclude using the plugin configuration file (See `TestViewEnabled` in the configuration example).

### Plugin Types

Detailed in this section is a list of all of the plugin types needed to allow for full feature coverage in the Generic HMI. Each plugin description includes details about which features the plugin needs to support, along with the RPCs it must handle to cover each feature. As part of this proposal, an example plugin of each type should be created for testing purposes, and these examples can then be used as a reference for production implementations.

#### Voice Recognition Plugin

Connects to the `VR` interface, overriding the Generic HMI's implementation of this component.

*Features:*

- General interface functions
    - VR.IsReady
    - VR.GetCapabilities
- Voice commands (both "Command" and "Choice" type), test implementation can be ported from Manticore
    - VR.AddCommand
    - VR.DeleteCommand
    - VR.PerformInteraction
    - VR.OnCommand
- Voice recognition state control
    - VR.Started
    - VR.Stopped
- Language switching support
    - VR.OnLanguageChange
    - VR.GetLanguage
    - VR.GetSupportedLanguages
    - VR.ChangeRegistration
- The "Help" command, which will trigger the TTS component to speak the app's `helpPrompt`

#### Vehicle Info Plugin

Connects to the `VehicleInfo` interface, overriding the Generic HMI's implementation of this component.

*Features:*

- General interface functions
    - VehicleInfo.IsReady
- Vehicle data, test implementation can be ported from Manticore
    - VehicleInfo.GetVehicleData
    - VehicleInfo.SubscribeVehicleData
    - VehicleInfo.UnsubscribeVehicleData
    - VehicleInfo.OnVehicleData
    - VehicleInfo.GetVehicleType
- Raw vehicle info requests
    - VehicleInfo.ReadDID
    - VehicleInfo.GetDTCs
    - VehicleInfo.DiagnosticMessage

#### Remote Control Plugin

Connects to the `RC` interface, overriding the Generic HMI's implementation of this component. This could potentially be split into several plugins (by module type) depending on the system.

*Features:*

- General interface functions
    - RC.IsReady
    - RC.GetCapabilities
- Remote Control data, test implementation can be ported from Manticore
    - RC.SetInteriorVehicleData
    - RC.GetInteriorVehicleData
    - RC.OnInteriorVehicleData
- Remote Control settings and status control
    - RC.OnRCStatus
    - RC.OnRemoteControlSettings
    - RC.SetGlobalProperties
    - RC.GetInteriorVehicleDataConsent
- Alternate audio source (ex. radio)

#### Buttons Plugin

Connects to the `Buttons` interface. This plugin would also communicate `ButtonPress` events to other plugins where needed.

*Features:*

- General interface functions
    - Buttons.GetCapabilities
- Button Event Notifications, test implementation can be ported from Manticore
    - Buttons.OnButtonPress
    - Buttons.OnButtonEvent
    - Buttons.OnButtonSubscription
- Button Presses
    - Buttons.ButtonPress
- Media Button Names, test implementation can be ported from Manticore
    - PLAY_PAUSE
    - SEEKLEFT, SEEKRIGHT
    - TUNEUP, TUNEDOWN
- Climate Button Names, test implementation can be ported from Manticore
    - AC, AC_MAX, RECIRCULATE, UPPER_VENT, LOWER_VENT
    - FAN_UP, FAN_DOWN, TEMP_UP, TEMP_DOWN
    - DEFROST, DEFROST_MAX, DEFROST_REAR
- Radio Button Names, test implementation can be ported from Manticore
    - VOLUME_UP, VOLUME_DOWN
    - EJECT, SOURCE
    - SHUFFLE, REPEAT
- Navigation Button Names
    - NAV_CENTER_LOCATION
    - NAV_ZOOM_IN, NAV_ZOOM_OUT
    - NAV_PAN_UP, NAV_PAN_UP_RIGHT, NAV_PAN_RIGHT, etc.
    - NAV_TILT_TOGGLE, NAV_HEADING_TOGGLE
    - NAV_ROTATE_CLOCKWISE, NAV_ROTATE_COUNTERCLOCKWISE
- Preset Button Names
    - PRESET_0...9

#### App Service Plugin

Connects to the `AppService` interface, registering IVI services for each type. This could potentially be split into several plugins (by service type) depending on the system.

*Features:*

- Media, Weather, and Navigation App Service Data Providers, test implementations can be ported from Manticore
    - AppService.PublishAppService
    - AppService.UnpublishAppService
    - AppService.GetAppServiceData
    - AppService.OnAppServiceData
    - AppService.PerformAppServiceInteraction
- App Service settings
    - AppService.GetAppServiceRecords
    - AppService.AppServiceActivation
    - AppService.GetActiveServiceConsent

#### Phone Plugin

Connects to the `BasicCommunication` interface.

*Features:*

- Phone calls
    - BasicCommunication.DialNumber
    - OnEventChanged(PHONE_CALL)

#### Navigation Plugin

Connects to the `Navigation` interface.

*Features:*

- General interface functions
    - Navigation.IsReady
- Navigation data popups, will need to interact with the UI component
    - Navigation.AlertManeuver
    - Navigation.ShowConstantTBT
- Navigation instructions
    - Navigation.UpdateTurnList
    - Navigation.SendLocation
- Embedded navigation support
    - Navigation.GetWayPoints
    - Navigation.SubscribeWayPoints
    - Navigation.UnsubscribeWayPoints
    - Navigation.OnWayPointChange
    - BasicCommunication.OnEventChanged(EMBEDDED_NAVI)

#### General Settings Plugin

Connects to the `BasicCommunication` and `UI` interfaces, also communicates with the main HMI to control settings via custom messages.

*Features:*

- General settings, replaces the buttons that are currently placed below the main HMI screen. The test implementation for this feature can be ported from Manticore.
    - UI.OnDriverDistraction
    - Toggle HMI Theme
- General HMI events
    - BasicCommunication.OnEventChanged(EMERGENCY_EVENT)
    - BasicCommunication.OnEventChanged(DEACTIVATE_HMI)

#### TTS Plugin

Connects to the `TTS` interface, overriding the Generic HMI's implementation of this component.

*Features:*

- General interface functions
    - TTS.IsReady
    - TTS.GetCapabilities
- Speech support
    - TTS.Speak
    - TTS.StopSpeaking
    - TTS.Started
    - TTS.Stopped
- Language switching support
    - TTS.OnLanguageChange
    - TTS.GetLanguage
    - TTS.GetSupportedLanguages
    - TTS.ChangeRegistration
- Prompt support, will require custom message from other components
    - TTS.SetGlobalProperties
    - TTS.Speak(helpPrompt) when "Help" option is selected
    - TTS.Speak(timeoutPrompt) when timeout occurs

### Messages between components

While ideally each of the HMI components would be isolated, there are a number of places where one component will need information from other components. For that reason, we will need to define a messaging scheme for HMI-specific messages which can be sent between components. These messages are routed using the message broker as well.

Each message would include the `Plugin` prefix and can include a `destination` parameter if targeting a specific component (ex. VR).

A few examples of the potential messages that would be needed:

**DISMISS_INTERACTION**

- Sender: VR/UI
- Receiver: UI/VR
- Description: Sent when a choice is selected for `PerformInteraction` via VR or UI, informing the other component that the interaction is complete.
- Parameters: `appID`

**BUTTON_PRESS**

- Sender: Buttons
- Receiver: RC
- Description: Sent when a button related to RC is pressed, informing the RC component to update its data where appropriate.
- Parameters: `buttonName`

**DEACTIVATE_APP**

- Sender: Various
- Receiver: Main HMI
- Description: Sent when an HMI event (such as EMERGENCY_EVENT) which should disable the active app is started. Closes the active app and returns to the app screen in the main HMI.
- Parameters: `appID`

**SEND_NAV_CAPABILITIES**

- Sender: Navigation
- Receiver: Main HMI
- Description: Sent when the navigation plugin is registered, communicating its capabilities to be sent in `UI.GetCapabilities`.
- Parameters: `navigationCapabilities`

**SPEAK**

- Sender: Various
- Receiver: TTS
- Description: Sent when any TTS prompt is triggered outside of the TTS interface (ex. `helpPrompt`/`timeoutPrompt` in `VR.PerformInteraction`). The TTS plugin will speak whatever data is provided.
- Parameters: `ttsChunks`

**ALERT_MANEUVER**

- Sender: Navigation
- Receiver: UI
- Description: Sent whenever a `Navigation.AlertManeuver` request is received by the Navigation plugin. The UI should display an alert maneuver popup with the provided softbuttons.
- Parameters: `softButtons`, `appID`

**SETTINGS_UPDATE**

- Sender: Settings
- Receiver: Main HMI
- Description: Sent whenever any HMI settings are changed in the Settings plugin.
- Parameters: `hmiTheme`, etc.

**POPUP**

- Sender: Various
- Receiver: Main HMI
- Description: Sent whenever a plugin needs to display a prompt to the user (ex. `RC.GetInteriorVehicleDataConsent` or `AppService.GetActiveServiceConsent`). Response is sent when an option is selected.
- Parameters: `text`, `softButtons`
- Response Parameters: `buttonID`

**Note:** This is not a comprehensive list. Other interactions between components may need to be added as necessary during implementation. In addition, customized messages will likely need to be created for production systems to accommodate differences in plugin design.

### Integrated Plugin Controls

While a majority of the functionality for these plugins can be handled in the background, production implementations will need the ability to integrate some portion of these plugins directly into the Generic HMI (such as a set of controls/settings for the plugin). To accommodate this, stubs for these integrated components can be included in the project and these can be expanded to fit a specific system.  

![Plugin UI Stub](../assets/proposals/0341-add-generic-hmi-plugin-support/vr-plugin-stub-example.png)

In order to incorporate this functionality, we will need to include an entry point within the Generic HMI for each of these integrated plugin components. These entry points could be included in the existing settings menu, as shown in this example:

![Menu Navigation](../assets/proposals/0341-add-generic-hmi-plugin-support/menu-example.png)

These integrated components should be possible to include or exclude from the menu using the plugin configuration file (See `MenuNavEnabled` in the configuration example).

## Potential downsides

Besides the general overhead of maintaining these plugins, the author does not see any significant downsides to this approach. Using plugins may be slightly more complicated than integrating these interfaces directly into the HMI, but it also allows for extra flexibility, and would not require any sizable design changes to the Generic HMI.

## Impact on existing code

With the additional components being added outside of the main component of the HMI, it would likely be worthwhile to include a startup script in the Generic HMI project. This script could start the HMI, python backend, and any configured plugins all at once using a single command.

As far as existing Generic HMI code, a few additions are needed:

- Logic to handle plugin configuration (either through `Flags.js` or a new configuration file)
- A sidebar for displaying test plugins next to the main portion of the HMI (via iframes, etc.)
- Logic to disable registration of unimplemented components when appropriate plugins are available
- Logic to handle new inter-component messages from connected plugins
- Logic for including additional settings menu items to navigate to integrated plugin components based on plugin configuration
- Basic stub components for each plugin to be expanded in production applications

Example plugin stub:

```
import React from 'react';

import AppHeader from './containers/Header';

export default class VRPlugin extends React.Component {
    render() {
        return (
            <div>
                <AppHeader icon="store" backLink="" appName="Menu" title={window.flags.VRPlugin.MenuName ? window.flags.VRPlugin.MenuName : "Voice Recognition"} />
                {
                    //Add your Voice Recognition controls here
                }
            </div>
        )
    }
}
```

Overall, a majority of the changes needed for this proposal will be in the form of test plugins, which will be isolated from any existing code.

## Alternatives considered

- The main alternative to this proposal was to implement a full IVI system around the Generic HMI. Most of this functionality would have to be emulated to a degree, which would make it harder to integrate into a production system. As such, this approach didn't seem ideal given the current design of the Generic HMI.
