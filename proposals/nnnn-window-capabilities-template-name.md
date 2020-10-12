# Add Current Template Name to Window Capabilities

* Proposal: [SDL-NNNN](nnnn-window-capabilities-template-name.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Awaiting review**
* Impacted Platforms: [Core / iOS / Java Suite / JavaScript Suite / HMI / RPC]

## Introduction
This proposal adds a new optional parameter to the `WindowCapability` struct containing the current template name, and a new app library `ScreenManager` parameter to assist app developers in tracking the current template.

## Motivation
Currently, it's impossible for an app developer to know what the current template name is when they first connect. The only way to track what the current template name is at any time after that is to track the `SetDisplayLayout / Show` request and responses. The window capability should contain information about the current template name in addition to its capabilities.

## Proposed solution

### RPC Changes
The proposed solution is to add a new parameter to the MOBILE_API RPC spec:

```xml
 <struct name="WindowCapability" since="6.0">
    <!-- Current params -->
    <param name="template" type="String" maxlength="500" mandatory="false">
        <description>The name of the current template of this window. The other parameters describe the capabilities of this template layout.</description>
    </param>
</struct>
```

The same change will be made to the HMI_API spec:

```xml
<struct name="WindowCapability">
    <!-- Current params -->
    <param name="template" type="String" maxlength="500" mandatory="false">
        <description>The name of the current template of this window. The other parameters describe the capabilities of this template layout.</description>
    </param>
</struct>
```

#### Additional Notes on RPC Implementation
1. This should not return `DEFAULT`, but should instead return the actual template that `DEFAULT` is referring to, such as `MEDIA`, `NON-MEDIA`, or `NAV_FULLSCREEN_MAP`.

### App Library Manager Changes
In addition, the app library should provide an API for developers to retrieve the current template layout that is being displayed for their app. This will be added to the screen manager as a readonly property. When this RPC change is made, this property will pull the information from `WindowCapability` updates. On older systems that do not support the `WindowCapability` property, this property will initially return `null`, but will then display the current template as determined by the last successful template update accomplished through the `ScreenManager.changeLayout()` method.

#### iOS
```objc
@interface SDLScreenManager: NSObject
// All current properties and methods

/// The name of the current template displayed on the screen, or nil if this cannot be determined with confidence.
@property (copy, nonatomic, readonly, nullable) NSString *currentTemplateName;

@end
```

#### Java Suite
```java
public String getCurrentTemplateName()
```

#### JavaScript Suite
```js
getCurrentTemplateName()
```

## Potential downsides
1. The manager property will not be able to determine the current template name with 100% confidence on older systems. For example, if a developer sets the layout using `ScreenManager.changeLayout()`, then updates it manually through the `SetDisplayLayout` RPC, then the `ScreenManager.currentTemplateName` property will show an incorrect value.

2. It could be argued that this change isn't entirely necessary after the first template update because the developer should know, based on `SetDisplayLayout / Show` successes and failures, what the current template is. However, that can be difficult to track well and keep track of throughout app code. It is better to have a perfectly reliable update whenever the template changes that speaks to which template is being referred to.

## Impact on existing code
This will require a minor version change on all major platforms due to the HMI_API and RPC_SPEC changes. The app libraries' `ScreenManager`s already privately track the current template name, so adding that as public will not be difficult.

## Alternatives considered
No alternatives were considered.