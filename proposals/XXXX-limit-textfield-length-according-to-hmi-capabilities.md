# Limit TextField Length According to HMI Capabilities

* Proposal: [SDL-XXXX](XXXX-limit-textfield-length-according-to-hmi-capabilities.md)
* Author: [Collin McQueen](https://github.com/iCollin)
* Status: **Awaiting review**
* Impacted Platforms: [Core]

## Introduction
This proposal defines how Core should limit the length of TextFields sent to the HMI according to the HMI Capabilities.

## Motivation
The Mobile API defines the max length of many text fields much larger than either the SDL HMI or Generic HMI support. The true maximum length of text fields is defined by the HMI Capabilities `displayCapabilities.textFields`. For example, `AddCommand.MenuParams.tertiaryText` is defined with `maxlength="500"` in the Mobile API, but the Generic HMI's capabilities inform Core that it can handle just one twenty character wide row for `tertiaryText`. This means Core may be forwarding TextFields to the HMI that are longer than the HMI can handle.

## Proposed solution
Core will enforce a maximum length on any TextFields being sent to the HMI, based on the lengths defined for TextFields in the HMI's capabilities.

### When to Truncate
Core's ability to truncate TextFields will first be controlled by an INI option.
```
[HMI]
...
+ ; Defines if Core should truncate TextFields sent to the HMI
+ ; according to the HMI Capabilities
+ TruncateTextFields = true
```
When this option is enabled, Core will truncate any TextFieldStruct being sent to the HMI who's `fieldName` is defined in the HMI's display capabilities.

### Truncation Process
When Core is evaluating a TextFieldStruct for truncation, it will first check if the length of the provided `TextFieldStruct.fieldText` is longer than the maximum length from the capabilities. The maximum length from the capabilities will be calculated as `TextField.width * TextField.rows`. If the provided `fieldText` is too long, the string will be cut off at the maximum length.

Optionally, a suffix for the truncated data may also be defined in the INI configuration file.
```
[HMI]
...
+ ; Defines a suffix Core should apply to any truncated text fields
+ TruncateTextFieldSuffix = ...
```
If this configuration option is defined, the suffix will replace the final characters in any truncated string right up to the null terminating character.

### Mobile Response after Truncation
When Core has truncated a TextField, the RPC response should make mobile aware that truncation has occurred. A string such as "$textFieldName was truncated." should be appended to the response's info and if the response code will be SUCCESS it should be overwritten to WARNINGS.

## Potential downsides
With this feature being configurable via the `TruncateTextFields` option, the author does not see any potential downsides to implementing this feature.

## Impact on existing code
This would require code changes to SDL Core to parse and truncate outgoing TextFieldStructs.

## Alternatives considered

#### Enable TextField Truncation via Build Flag
Instead of an INI option, enable truncating TextFields via a build flag.
An INI option was selected instead because build flags should be reserved for larger components.

#### Add Code to Truncate Text Fields in the HMI
It would be easy to truncate long TextFields in the HMI Code, but every HMI is different and this would add work for anyone who decides to implement an HMI. By truncating TextFields within Core, developers should not need to write custom code for this. Additionally, having Core do the truncating gives more value to the HMI Capabilities.
