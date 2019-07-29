# Manager Update for DisplayCapability

* Proposal: [SDL-NNNN](NNNN-manager-update-display-capability.md)
* Author: [SDL Developer](https://github.com/kshala-ford)
* Status: **Awaiting review**
* Impacted Platforms: [iOS / Java Suite]

## Introduction

This proposal adds display capabilities redesign described in SDL 0216 Widget Support (see #664) to ScreenManager and SystemCapabilityManager.

## Motivation

The widget proposal is very vague in describing how the managers should support the new display capability redesign. It also give's some interpretation in when the manager change should be done (together with the widget code donation or later?). The Java and iOS code was reviewed in order to make a decision if manager changes can be seen as development details. The result is that there's a major conflict with an Android proposal and also a quite complex behavior change of how to provide objects of `DisplayCapabilities`, `DisplayCapability` and `WindowCapability`. The system capability manager needs a major change to support backward and forward compatibility and provide the correct data in the correct format to the depending managers (e.g. ScreenManager).

## Proposed solution

The solution for the java suite is to extend the system capability manager to return the `DisplayCapability` array when `SystemCapabilityType.DISPLAYS` is used as a param. Different to other async types the manager won't subscribe to `DISPLAYS` as auto subscription is provided to applications.

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

At the time of writing this proposal the source of the capability types will be deprecated with the next major SDL relase (Core 6.0). In order to keep backward and forward compatibility a bi-directional conversion of capability objects should be introduced:

#### Convert from old capabilities to `DisplayCapability`

If the application is connected to a < 6.0 or if the head unit did not provide `DisplayCapability` or `WindowCapability` for the `DEFAULT_WINDOW` yet, the system capability manager should convert `DisplayCapabilities`, `ButtonCapabilities`, `SoftButtonCapabilities` and `PresetBankCapabilities` objects and the string of `displayName` from `RegisterAppInterfaceResponse` and `SetDisplayLayoutResponse` into a new `DisplayCapability` object. This object should be stored in the `DISPLAYS` enum value.

For the Java Suite this means `parseRAIResponse` continues reading the deprecated types. However if they are present it triggers a conversion:

```java
private void createDisplayCapabilityList(RegisterAppInterfaceResponse rpc) {
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
    imageTypeSupported.add(ImageType.STATIC); // static images expecte to always work
    if (display.getGraphicSupported()) {
        imageTypeSupported.add(ImageType.DYNAMIC);
    }
    defaultWindowCapability.setImageTypeSupported(imageTypeSupported);
    
    displayCapability.setWindowCapabilities(Collections.singletonList(defaultWindowCapability));
    return Collections.singletonList(displayCapability);
}
```

All properties from the old capabilities can be transferred to the new capabilities objects. In order to remember that the `DisplayCapability` object is converted from a RAI response (and not received by a SystemCapability RPC) the SystemCapability manager should store a flag `convertDisplayCapabilitiesNeeded` which is `true` by default and set to `false` if actual `DisplayCapability` data is received.

```java
public class SystemCapabilityManager {
    private boolean convertDisplayCapabilitiesNeeded;
    :
    public SystemCapabilityManager(ISdl callback){
        this.convertDisplayCapabilitiesNeeded = true;
        :
    }
    :
    public void parseRAIResponse(RegisterAppInterfaceResponse response){
		if(response!=null && response.getSuccess()) {
            this.convertDisplayCapabilitiesNeeded = true; // reset the flag
            setCapability(SystemCapabilityType.DISPLAYS, createDisplayCapabilityList(response));
        :
    }

    private void setupRpcListeners(){
        :
        if (RPCMessage.KEY_RESPONSE.equals(message.getMessageType())) {
            switch (message.getFunctionID()) {
                case SET_DISPLAY_LAYOUT:
                    SetDisplayLayoutResponse response = (SetDisplayLayoutResponse) message;
                    if (convertDisplayCapabilitiesNeeded) {
                        setCapability(SystemCapabilityType.DISPLAYS, createDisplayCapabilityList(response));
                    }
                    :
                case GET_SYSTEM_CAPABILITY:
                    GetSystemCapabilityResponse response = (GetSystemCapabilityResponse) message;
                    SystemCapability systemCapability = response.getSystemCapability();
                    if (response.getSuccess() && systemCapabilityType.DISPLAYS.equals(systemCapability.getSystemCapabilityType())) {
                        this.convertDisplayCapabilitiesNeeded = false; // Successfully got DISPLAYS data. No conversion needed anymore
                        setCapability(SystemCapabilityType.DISPLAYS, systemCapability.getDisplayCapabilities());
                    }
            :
        } else if (RPCMessage.KEY_NOTIFICATION.equals(message.getMessageType())){
            switch (message.getFunctionID()) {
                case ON_SYSTEM_CAPABILITY_UPDATED:
                :
                    switch (systemCapabilityType) {
                        case DISPLAYS:
                            // this notification can return only affected windows (hence not all windows)
                            List<DisplayCapabilities> displayCapabilities = (List<DisplayCapabilities>)capability;
                            List<DisplayCapabilities> newCapabilities = cachedSystemCapabilities.get(SystemCapabilityType.DISPLAYS);
                            for ()

```

## Potential downsides

Describe any potential downsides or known objections to the course of action presented in this proposal, then provide counter-arguments to these objections. You should anticipate possible objections that may come up in review and provide an initial response here. Explain why the positives of the proposal outweigh the downsides, or why the downside under discussion is not a large enough issue to prevent the proposal from being accepted.

## Impact on existing code



## Alternatives considered

Describe alternative approaches to addressing the same problem, and why you chose this approach instead.
