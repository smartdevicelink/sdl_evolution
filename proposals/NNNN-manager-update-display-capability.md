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
public void parseRAIResponse(RegisterAppInterfaceResponse response){
		if(response!=null && response.getSuccess()) {
            :
            setCapability(SystemCapabilityType.DISPLAY, response.getDisplayCapabilities());
            :
            setCapability(SystemCapabilityType.DISPLAYS, createDisplayCapabilityList(response));
        }
}

private void createDisplayCapabilityList(RegisterAppInterfaceResponse rpc) {
    
}

private List<DisplayCapability> createDisplayCapabilityList(SetDisplayLayoutResponse rpc) {

}

private List<DisplayCapability> createDisplayCapabilityList(DisplayCapabilities display, ButtonCapabilities button, SoftButtonCapabilities softButton, PresetBankCapabilities presetBank) {
    // TODO add some code how to convert
    return new ArrayList<>(newCapability);
}
```

In order to remember that the `DisplayCapability` converted from a RAI response and not received by a 

## Potential downsides

Describe any potential downsides or known objections to the course of action presented in this proposal, then provide counter-arguments to these objections. You should anticipate possible objections that may come up in review and provide an initial response here. Explain why the positives of the proposal outweigh the downsides, or why the downside under discussion is not a large enough issue to prevent the proposal from being accepted.

## Impact on existing code

Describe the impact that this change will have on existing code. Will some SDL integrations stop compiling due to this change? Will applications still compile but produce different behavior than they used to? Is it possible to migrate existing SDL code to use a new feature or API automatically?

## Alternatives considered

Describe alternative approaches to addressing the same problem, and why you chose this approach instead.
