# Choice-VR optional

* Proposal: [SDL-0064](0064-choice-vr-optional.md)
* Author: [Kujtim Shala](https://github.com/kshala-ford)
* Status: **Returned for Revisions**
* Impacted Platforms: [Core / iOS / Android / RPC]

## Introduction

This proposal is about changing Choice.vrCommands to be not mandatory.

## Motivation

Creating choice sets takes a lot of time to be computed on the head unit which makes it very difficult to provide a good and interactive user experience. Some interactions cannot/should not be performed in a voice session (POI finder benefit from secondary and tertiary text). Besides that SDL is now capable to support Non-VR head units (impl. VR.isReady()).

## Proposed solution

This proposal is to make the parameter `vrCommands` optional. This would allow apps to avoid unnecessary vr commands if they want to perform an interaction in manual mode. On the other hand it saves a lot of time of grammar computing on the head unit side.

### HMI & Mobile API

```xml
<struct name="Choice">
    <param name="vrCommands" type="String" minsize="1" maxsize="100" maxlength="99" array="true" mandatory="false" />
</struct>
```

With this parameter being optional many different scenarios are possible

#### 1. CreateInteractionChoiceSet all choices including `vrCommands`
This is the known scenario. The choice set should be created as it's done today.

#### 2. CreateInteractionChoiceSet no choice contains `vrCommands`
Same as above but skip creating voice grammars.

#### 3. CreateInteractionChoiceSet some choices include `vrCommands`
Don't accept the request. The response should be
- `success` = `false`
- `resultCode` = `INVALID_DATA`,
- `info` = "Some choices don't contain VR commands."

#### 4. PerformInteraction (VR) at least one choice set without `vrCommands`
Every ID of `interactionChoiceSetIDList` should be checked at core. If at least one of those sets is created without `vrCommands` the interaction should not be successful. The response should be
- `success` = `false`
- `resultCode` = `INVALID_DATA`,
- `info` = "Some choices don't contain VR commands."

A planned proposal for a choice set manager could benefit from this proposal by automatically omitting `vrCommands` if `vrCapabilities` is empty (assuming it already exists and the app is using it...).

## Potential downside

This proposal would change an existing parameter to become optional. This may cause issues on existing SDL head units. This issue can be solved with a carefully versioned HMI and mobile API.

## Impact on existing code

- This proposal is a major change on Core and HMI.
- It's a very minor change for the SDKs. Properties have to become optional/nullable.
- Existing apps are not affected by this change as sending vrCommands is still allowed.

## Alternatives considered

No alternatives considered. Will be added if proposed.
