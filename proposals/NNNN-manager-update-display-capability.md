# Manager Update for DisplayCapability

* Proposal: [SDL-NNNN](NNNN-manager-update-display-capability.md)
* Author: [SDL Developer](https://github.com/kshala-ford)
* Status: **Awaiting review**
* Impacted Platforms: [iOS / Java Suite]

## Introduction

This proposal adds display capabilities redesign described in SDL 0216 Widget Support (see #664) to ScreenManager and SystemCapabilityManager.

## Motivation

The widget proposal is very vague in describing how the managers should support the new display capability redesign. It also gives some interpretation in when the manager change should be done (together with the widget code donation or later?). The Java and iOS code was reviewed in order to make a decision if manager changes can be seen as development details. The result is that there is a major conflict with an Android proposal and also a quite complex behavior change of how to provide objects of `DisplayCapabilities`, `DisplayCapability` and `WindowCapability`. The system capability manager needs a major change to support backward and forward compatibility and provide the correct data in the correct format to the depending managers (e.g. ScreenManager).

## Proposed solution

The solution for the java suite is to extend the system capability manager to return the `DisplayCapability` array when `SystemCapabilityType.DISPLAYS` is used as a param. Different to other async types the manager will not subscribe to `DISPLAYS` as auto subscription is provided to applications.

### Deprecate custom Java capability types

Following system capability types that are **not** part of the mobile API should be deprecated with the `@Deprecated` annotation.

```java
public enum SystemCapabilityType {
    @Deprecated
    DISPLAY (false),
    @Deprecated
    BUTTON (false),
    @Deprecated
    SOFTBUTTON (false),
    @Deprecated
    PRESET_BANK (false),
}
```

In order to avoid clashes with the mobile API the enum should not be extended any further without adding the enum values to the mobile API. 

### Convert capability type objects

At the time of writing this proposal, the source of the capability types will be deprecated with the next major SDL release (Core 6.0). In order to keep backward and forward compatibility a bi-directional conversion of capability objects should be introduced:

#### Convert from `DisplayCapabilities` to `DisplayCapability` and vice versa

If the application is connected to a < 6.0 or if the head unit did not provide `DisplayCapability` or `WindowCapability` for the `DEFAULT_WINDOW` yet, the system capability manager should convert `DisplayCapabilities`, `ButtonCapabilities`, `SoftButtonCapabilities` and `PresetBankCapabilities` objects and the string of `displayName` from `RegisterAppInterfaceResponse` and `SetDisplayLayoutResponse` into a new `DisplayCapability` object. This object should be stored in the `DISPLAYS` enum value.

For the Java Suite this means `parseRAIResponse` continues reading the deprecated types. However if they are present it triggers a conversion:

```java
private List<DisplayCapability> createDisplayCapabilityList(RegisterAppInterfaceResponse rpc) {
    return createDisplayCapabilityList(rpc.getDisplayCapabilities(), rpc.getButtonCapabilities(), rpc.getSoftButtonCapabilities());
}

private List<DisplayCapability> createDisplayCapabilityList(SetDisplayLayoutResponse rpc) {
    return createDisplayCapabilityList(rpc.getDisplayCapabilities(), rpc.getButtonCapabilities(), rpc.getSoftButtonCapabilities());
}

private List<DisplayCapability> createDisplayCapabilityList(DisplayCapabilities display, List<ButtonCapabilities> button, List<SoftButtonCapabilities> softButton) {
    // Based on deprecated Display capabilities we don't know if widgets are supported,
    // The Default MAIN window is the only window we know is supported
    WindowTypeCapabilities windowTypeCapabilities = new WindowTypeCapabilities(WindowType.MAIN, 1);

    DisplayCapability displayCapability = new DisplayCapability();
    displayCapability.setDisplayName(display != null ? display.getDisplayName() : null);
    displayCapability.setWindowTypeSupported(Collections.singletonList(windowTypeCapabilities));

    // Create an window capability object for the default MAIN window
    WindowCapability defaultWindowCapability = new WindowCapability();
    defaultWindowCapability.setWindowID(PredefinedWindows.DEFAULT_WINDOW);
    defaultWindowCapability.setButtonCapabilities(button);
    defaultWindowCapability.setSoftButtonCapabilities(softButton);
    
    // return if display capabilities don't exist.
    if (display == null) {
        displayCapability.setWindowCapabilities(Collections.singletonList(defaultWindowCapability));
        return Collections.singletonList(displayCapability);
    }

    // copy all available display capabilities 
    defaultWindowCapability.setTemplatesAvailable(display.getTemplatesAvailable());
    defaultWindowCapability.setNumCustomPresetsAvailable(display.getNumCustomPresetsAvailable());
    defaultWindowCapability.setTextFields(display.getTextFields());
    defaultWindowCapability.setImageFields(display.getImageFields());
    ArrayList<ImageType> imageTypeSupported = new ArrayList<>();
    imageTypeSupported.add(ImageType.STATIC); // static images expected to always work on any head unit
    if (display.getGraphicSupported()) {
        imageTypeSupported.add(ImageType.DYNAMIC);
    }
    defaultWindowCapability.setImageTypeSupported(imageTypeSupported);
    
    displayCapability.setWindowCapabilities(Collections.singletonList(defaultWindowCapability));
    return Collections.singletonList(displayCapability);
}

private DisplayCapabilities createDisplayCapabilities(String displayName, WindowCapability defaultMainWindow) {
    DisplayCapabilities convertedCapabilities = new DisplayCapabilities();
    convertedCapabilities.setDisplayType(DisplayType.SDL_GENERIC); //deprecated but it is mandatory...
    convertedCapabilities.setDisplayName(displayName);
    convertedCapabilities.setTextFields(defaultMainWindow.getTextFields());
    convertedCapabilities.setImageFields(defaultMainWindow.getImageFields());
    convertedCapabilities.setTemplatesAvailable(defaultMainWindow.getTemplatesAvailable());
    convertedCapabilities.setNumCustomPresetsAvailable(defaultMainWindow.getNumCustomPresetsAvailable());
    convertedCapabilities.setMediaClockFormats(Collections.singletonList(MediaClockFormats.CLOCK3)); // mandatory field...
    convertedCapabilities.setGraphicSupported(defaultMainWindow.getImageTypeSupported().contains(ImageType.DYNAMIC));
    
    return convertedCapabilities;
}
```

#### Listen for `DISPLAYS` notifications

All properties from the old capabilities can be transferred to the new capabilities objects. In order to remember that the `DisplayCapability` object is converted from a RAI response (and not received by a SystemCapability RPC) the SystemCapability manager should store a flag `convertDeprecatedDisplayCapabilitiesNeeded` which is `true` by default and set to `false` if actual `DisplayCapability` data is received.

```java
public class SystemCapabilityManager {
    private boolean convertDeprecatedDisplayCapabilitiesNeeded;
    :
    public SystemCapabilityManager(ISdl callback){
        this.convertDeprecatedDisplayCapabilitiesNeeded = true;
        :
    }
    :
    public void parseRAIResponse(RegisterAppInterfaceResponse response){
		if(response!=null && response.getSuccess()) {
            this.convertDeprecatedDisplayCapabilitiesNeeded = true; // reset the flag
            setCapability(SystemCapabilityType.DISPLAYS, createDisplayCapabilityList(response));
        :
    }

    private void setupRpcListeners(){
        :
        if (RPCMessage.KEY_RESPONSE.equals(message.getMessageType())) {
            switch (message.getFunctionID()) {
                case SET_DISPLAY_LAYOUT:
                    SetDisplayLayoutResponse response = (SetDisplayLayoutResponse) message;
                    if (convertDeprecatedDisplayCapabilitiesNeeded) {
                        setCapability(SystemCapabilityType.DISPLAYS, createDisplayCapabilityList(response));
                    }
                    :
                case GET_SYSTEM_CAPABILITY:
                    GetSystemCapabilityResponse response = (GetSystemCapabilityResponse) message;
                    SystemCapability systemCapability = response.getSystemCapability();
                    if (response.getSuccess() && systemCapabilityType.DISPLAYS.equals(systemCapability.getSystemCapabilityType())) {
                        this.convertDeprecatedDisplayCapabilitiesNeeded = false; // Successfully got DISPLAYS data. No conversion needed anymore
                        List<DisplayCapability> newCapabilities = systemCapability.getDisplayCapabilities();
                        updateCachedDisplayCapabilityList(newCapabilities);
                    }
            :
        } else if (RPCMessage.KEY_NOTIFICATION.equals(message.getMessageType())){
            switch (message.getFunctionID()) {
                case ON_SYSTEM_CAPABILITY_UPDATED:
                :
                    switch (systemCapabilityType) {
                        case DISPLAYS:
                            this.convertDeprecatedDisplayCapabilitiesNeeded = false; // Successfully got DISPLAYS data. No conversion needed anymore
                            // this notification can return only affected windows (hence not all windows)
                            List<DisplayCapability> newCapabilities = (List<DisplayCapability>)capability;
                            updateCachedDisplayCapabilityList(newCapabilities);
            :
```

#### Apply SystemCapability update 

After receiving the first `DISPLAYS` system capability update (via response or notification) the flag is set to false indicating that no conversion from deprecated display capabilities is needed anymore. The method `updateCachedDisplayCapabilityList` is used to merge the cached object with the new display capability object as the new object could contain only partial window capability updates.

```java
void updateCachedDisplayCapabilityList(List<DisplayCapability> newCapabilities) {
    List<DisplayCapability> oldCapabilities = getCapability(SystemCapabilityType.DISPLAYS);
    
    if (oldCapabilities == null) {
        setCapability(SystemCapabilityType.DISPLAYS, newCapabilities);
        return;
    }

    DisplayCapability oldDefaultDisplayCapabilities = oldCapabilities.get(0);
    ArrayList<WindowCapability> copyWindowCapabilities = new ArrayList<>(defaultDisplayCapabilities.getWindowCapabilities());

    DisplayCapability newDefaultDisplayCapabilities = newCapabilities.get(0);
    List<WindowCapability> newWindowCapabilities = newDefaultDisplayCapabilities.getWindowCapabilities();

    for (windowCapability newWindow : newWindowCapabilities) {
        ListIterator iterator = copyWindowCapabilities.listIterator();
        boolean oldFound = false;
        while (iterator.hasNext()) {
            WindowCapability oldWindow = iterator.next();
            if (newWindow.getWindowID().equals(oldWindow.getWindowID())) {
                iterator.set(newWindow); // replace the old window caps with new ones
                oldFound = true;
                break;
            }
        }

        if (!oldFound) {
            copyWindowCapabilities.add(newWindow); // this is a new unknown window
        }
    }

    // replace the window capabilities array with the merged one.
    newDefaultDisplayCapabilities.setWindowCapabilities(copyWindowCapabilities);

    setCapability(SystemCapabilityType.DISPLAYS, Collections.singletonList(newDefaultDisplayCapabilities));

    WindowCapability defaultMainWindowCapabilities = newDefaultDisplayCapabilities.getWindowCapabilities(PredefinedWindows.DEFAULT_WINDOW); // assume the function exist returning window capability of a specified window
    
    // cover the deprecated capabilities for backward compatibility
    setCapability(SystemCapability.DISPLAY, createDisplayCapabilities(newDefaultDisplayCapabilities.getDisplayName(), defaultMainWindowCapabilities));
    setCapability(SystemCapability.BUTTON, defaultMainWindowCapabilities.getButtonCapabilities());
    setCapability(SystemCapability.SOFTBUTTON, defaultMainWindowCapabilities.getSoftButtonCapabilities());
}
```

For convenience, the system capability manager should provide a method to fetch a window capability object per window ID

```java
public WindowCapability getWindowCapability(int windowID) {
    // return the cached WindowCapability object of the window with the specified window ID
}
```

### Deprecate iOS changes

For the SDL iOS library the changes are less invasive. The `SDLSystemCapabilityManager` should deprecate properties that return deprecated objects.

```objc
@interface SDLSystemCapabilityManager : NSObject
:
@property (nullable, strong, nonatomic, readonly) SDLDisplayCapabilities *displayCapabilities __deprecated_msg("Use displays instead.");
@property (nullable, copy, nonatomic, readonly) NSArray<SDLSoftButtonCapabilities *> *softButtonCapabilities __deprecated_msg("Use displays instead.");
@property (nullable, copy, nonatomic, readonly) NSArray<SDLButtonCapabilities *> *buttonCapabilities __deprecated_msg("Use displays instead.");
@property (nullable, strong, nonatomic, readonly) SDLPresetBankCapabilities *presetBankCapabilities __deprecated_msg("Use displays instead.");
```

### Convert capability type objects

Same as for the Java library the `SDLSystemCapabilityManager` should convert old `DisplayCapabilities` into `DisplayCapability` and vice versa. The logic should be following the Java code already described in the proposal.

```objc
- (NSArray<SDLDisplayCapability *> *)createDisplayCapabilityListFromRegisterResponse:(SDLRegisterAppInterfaceResponse *)rpc {
    return [self createDisplayCapabilityList:rpc.displayCapabilities buttons:rpc.buttonCapabilities softButton:rpc.softButtonCapabilities];
}

- (NSArray<SDLDisplayCapability *> *)createDisplayCapabilityListFromSetDisplayLayoutResponse:(SDLSetDisplayLayoutResponse *)rpc {
    return [self createDisplayCapabilityList:rpc.displayCapabilities buttons:rpc.buttonCapabilities softButton:rpc.softButtonCapabilities];
}

- (NSArray<SDLDisplayCapability *> *)createDisplayCapabilityList:(SDLDisplayCapabilities *)display buttons:(NSArray<SDLButtonCapabilities *> *)buttons softButtons:(NSArray<SDLSoftButtonCapabilities *> *)softButton {
    // Convert objects Similar to Java code
}

- (SDLDisplayCapabilities *)createDisplayCapabilitiesWithDisplayName:(NSString *)displayName windowCapability:(SDLWindowCapability *)windowCapability {
    // Convert object similar to Java code
}
```

### Fetch `DisplayCapability` and specific `WindowCapability`

The `SDLSystemCapabilityManager` should provide the `DisplayCapability` array (either converted or received from an RPC) with a new property and method:

```objc
@interface SDLSystemCapabilityManager : NSObject

@property (nullable, copy, nonatomic, readonly) NSArray<SDLDisplayCapability *> *displays;

// returns WindowCapability of the window specified or nil if the window doesn't exist
- (nullable SDLWindowCapability *)windowWithID:(NSNumber<SDLInt> *)windowID; 
```

The property name `displays` should be sufficient as it is within the context of the system **capability** manager. Developers should understand that the property returns capabilities of displays.

#### Listen for `DISPLAYS` notifications

Similar to the Java code the iOS based system capability manager should also listen to `RegisterAppInterfaceResponse` and `SetDisplayLayoutResponse` and convert the old capabilities into the new type as long as no `OnSystemCapabilityUpdated` or `GetSystemCapabilityResponse` is received.

```objc
- (void)sdl_registerResponse:(SDLRPCResponseNotification *)notification {
    SDLRegisterAppInterfaceResponse *response = (SDLRegisterAppInterfaceResponse *)notification.response;
    if (!response.success.boolValue) { return; }
    self.convertDeprecatedDisplayCapabilitiesNeeded = YES; // reset the flag
    self.displays = [self createDisplayCapabilityListWithRegisterResponse:response];
    :
- (void)sdl_displayLayoutResponse:(SDLRPCResponseNotification *)notification {
    SDLSetDisplayLayoutResponse *response = (SDLSetDisplayLayoutResponse *)notification.response;
    if (!response.success.boolValue) { return; }
    if (self.convertDeprecatedDisplayCapabilitiesNeeded) {
        self.displays = [self createDisplayCapabilityListWithSetDisplayLayoutResponse:response];
    }

- (BOOL)sdl_saveSystemCapability:(SDLSystemCapability *)systemCapability completionHandler:(nullable SDLUpdateCapabilityHandler)handler {
    :
    } else if ([systemCapabilityType isEqualToEnum:SDLSystemCapabilityTypeDisplays]) {
        self.convertDeprecatedDisplayCapabilitiesNeeded = NO;
        [self sdl_updateCachedDisplayCapabilityList:systemCapability.displayCapabilities];
    }
}

- (void)sdl_updateCachedDisplayCapabilityList(List<DisplayCapability> newCapabilities) {
    // Similar to Java Code:
    // 1. Copy the existing Array of existing window capabilities
    // 2. Replace occurrences of new window capabilities in the copy
    // 3. Apply the updated copy into the DisplayCapability
    // 4. Store the new object in the `displays` property.
    // 5. Convert objects into the properties `displayCapabilities`, `buttonCapabilities`, `softButtonCapabilities` and `presetBankCapabilities`
}
```

## Potential downsides

The downside of the DisplayCapabilities replacement is the fact that the developer has two different options of fetching them. Using deprecation flags and converting capabilities in both directions should be helpful to understand which API is the modern one. Existing apps may have issues with modern head units that don't provide old display capabilities anymore. These apps should be supported with the conversion but they need to do a library update.

## Impact on existing code

`DisplayCapabilities` is a widely used object which now gets deprecated. Compatibility is guaranteed with the object conversion. However applications and also the SDL libraries will face many deprecation notes by the IDE.

The screen managers will be affected by the deprecations hence should upgrade to the new display capability. From a brief code review only private screen manager code is affected therefore the changes are considered as implementation details.

## Alternatives considered

An addition to the system capability mangers could be adding listeners for windows with a specified window ID instead of listening for all windows in a `DISPLAYS` notification. This would be helpful and convenient for screen managers and the application to be notified on specific window changes only.