  # Processing of unknown enum values by SDL Core
  * Proposal: [SDL-0298](0298-Processing-of-unknown-enum-values-by-SDL-Core.md)
  * Authors: [Igor Gapchuk](https://github.com/IGapchuk), [Dmitriy Boltovskiy](https://github.com/dboltovskyi/)
  * Status: **In Review**
  * Impacted Platforms: [Core]

## Introduction
The main purpose of this proposal is to gracefully handle unknown enum values from a mobile RPC request with any given SDL Core version. This can be achieved by improving the way SDL Core processes and validates unknown enum values.

## Motivation

The current filtering and data validation mechanism used by SDL Core needs be improved upon to issues related to possible differences in Mobile API/RPC spec versions between parameters in the request from a mobile application and an instance of SDL Core.

To better understand what kinds of issues we could face, let's assume the next example:

A mobile application with a newer version of the Mobile API (5.0) while connecting to SDL Core, which has an older Mobile API version (4.3), sends a `RegisterAppInterface` request to SDL Core with an array of `AppHMITypes` which has the next values: `[DEFAULT, REMOTE_CONTROL]` (The `AppHMIType::DEFAULT` was introduced in the Mobile API since 2.0 version, since the time the `AppHMIType` type was added into the API, and `AppHMIType::REMOTE_CONTROL` was introduced in the 4.5 version of the Mobile API). SDL Core tries to validate the parameters in the RAI request, finds an unknown enum value of `AppHMIType::REMOTE_CONTROL`. As a result, the SDL Core sends a failure response to a mobile application with the `INVALID_DATA` result code. Thus, the mobile application fails to register with SDL Core, which is an unacceptable user experience. Additionally, the mobile application cannot conclusively determine the cause of failure since `INVALID_DATA` can be returned for a number of reasons.
With the changes provided by this proposal, SDL Core will be able to process all unknown enums in mobile requests in the correct way and respond to mobile applications with informative messages about experienced failures.

## Proposed solution

When SDL Core receives a request from a mobile application, it starts the validation of all incoming parameters.
If a parameter includes an unknown enum value, SDL Core has to cut off such value from the parameter.

  This means the following cases are possible:

  1. The type of parameter is a non-array enum (see example 1).

      SDL Core has to remove this parameter from the request since the value after cutting off becomes empty.

  2. A parameter is an array of enum types (see example 2).

      SDL Core has to remove an unknown value from the array.
      A case is possible when all values are unknown and thus get removed.
      In this case, SDL Core has to proceed the same way as in case 1.

  3. A parameter is part of the structure (see example 3).

      SDL Core has to proceed the same way as in case #1 or #2 and remove this parameter from the structure.
      However, if the parameter is mandatory the structure becomes invalid.
      In this case, SDL Core has to remove the whole structure from the request.
      During this process, SDL Core has to proceed recursively from the very bottom level up to the top.

  4. A parameter is a part of the structure which is a part of an array (see example 4).

      SDL Core has to process it the same way as in case #3 and remove the structure as an item of the array.
      Once all the parameters are processed SDL Core has to proceed with the request as usual.

  If at least one value of at least one parameter was cut off, SDL Core has to update the response to the mobile application as follows:

  1. If the response was processed successfully, SDL Core has to provide the `WARNINGS` result code instead of `SUCCESS`.
  2. SDL Core has to provide removed enum items in the `info` string of the response.

      Since there could be more than one parameter with cut-off value, `info` message can be constructed the following way:

      `Invalid enums were removed: <param_1>:<enum_value_1>,<enum_value_2>;<param_2>:<enum_value_3> ...`

      If the `info` parameter contains other value(s) belonging to the original processing result SDL Core has to append information about cut-off enum value(s) to the existing value.

  **Examples:**

  In each example below the mobile application sends a request to SDL Core.

  **NOTE**

  The negotiated RPC spec version is the version that should be used for determining if a parameter is mandatory or not, as mandatory=true/false can change between different RPC spec versions.

  In the case when mobile application has the 7.0 Mobile API/RPC spec version and the SDL Core has the 6.0 Mobile API/RPC spec version, the negotiated version will be 6.0 (the version of the SDL Core).

  In the case when mobile application has the 6.0 Mobile API/RPC spec version and the SDL Core has the 7.0 Mobile API/RPC spec version, the negotiated version will be 6.0 (the version of the mobile application).

  1. The request contains a parameter which value is an enum item.

      Request: `SetMediaClockTimer`

      1.1 Parameter is mandatory: `updateMode="UNKNOWN"`.

      SDL Core removes the item `UNKNOWN` from the request.
      The value of the `updateMode` parameter becomes empty.
      SDL Core omits an empty parameter from the request.
      Since the parameter is mandatory, the request fails with the following response to a mobile application:
      `success=false, resultCode = "INVALID_DATA", info="Invalid enums were removed: updateMode:UNKNOWN"`

      1.2 Parameter is optional: `audioStreamingIndicator="UNKNOWN"`.

      SDL Core removes the `UNKNOWN` item from the request.
      The value of the `audioStreamingIndicator` parameter becomes empty.
      SDL Core omits the empty parameter in the request.
      Since the parameter is optional, the request is successfully processed with the following response to a mobile application:
      `success=true, resultCode = "WARNINGS", info="Invalid enums were removed: audioStreamingIndicator:UNKNOWN"`

  2. The request contains a parameter for which the value is an array of enum items.

      Request: `RegisterAppInterface`.

      2.1 Only one enum item is unknown: `appHMIType = [ "DEFAULT", "UNKNOWN"]`.

      SDL Core removes the `UNKNOWN` item from the request.
      The value of the `appHMIType` parameter now contains only `DEFAULT` item (which is known one).
      The request is successfully processed with the following response to a mobile application:
      `success=true, resultCode = "WARNINGS", info="Invalid enums were removed: appHMIType:UNKNOWN"`

      2.2 All enum items are unknown: `appHMIType = [ "UNKNOWN_1", "UNKNOWN_2"]`.

      SDL Core removes both `UNKNOWN_1` and `UNKNOWN_2` items from the request.
      The value of `appHMIType` parameter becomes empty.
      Since `minsize` of the parameter is `1`, the request fails with the following response to mobile application:
      `success=false, resultCode = "INVALID_DATA", info="Invalid enums were removed: appHMIType:UNKNOWN_1, UNKNOWN_2"`

  3. The request contains a parameter (with enum item value) which is a part of the structure.

      Request: `SetGlobalProperties`.

      Parameter `menuIcon="Image"`, sub-parameter: `imageType`, `type="ImageType"`

      ```
      menuIcon = {
        imageType = "UNKNOWN"
      }
      ```

      SDL Core removes the `menuIcon` parameter from the request since the parameter `imageType` is mandatory for the `ImageType` structure.
      However, request will be processed successfully since the `menuIcon` parameter is optional for `SetGlobalProperties` request and the following response will be provided to mobile application:

      `success=true, resultCode = "WARNINGS", info="Invalid enums were removed: menuIcon.imageType:UNKNOWN"`

  4. The request contains a parameter which is an array of elements and each element has a parameter which value is an enum item.

      Request: `Show`.

      Parameter: `softButtons`, `type="SoftButton"`, sub-parameter: `type`, `type="SoftButtonType"`.

      There are 2 soft buttons provided in the request:

      ```
      softButtons = [
        { softButtonID = 1, type = "UNKNOWN" },
        { softButtonID = 2, type = "IMAGE" }
      ]
      ```

      SDL Core removes the whole element with the button `1` from the request since the `type` parameter is mandatory for `SoftButton` structure:

      ```
      softButtons = [
        { softButtonID = 2, type = "IMAGE" }
      ]
      ```

      The request is successfully processed with the remaining button `2` and the following response is  provided to mobile application:
      `success=true, resultCode = "WARNINGS", info="Invalid enums were removed: softButtons[1].type:UNKNOWN"`

## Potential downsides

There is the case when a mobile application has an older Mobile API version (for example 6.0) than SDL Core and SDL Core has the newer Mobile API version (for example 7.0).

In the mobile application, some parameters are not mandatory and in SDL Core, the same parameter has become mandatory. One should keep in mind that the implementation of SDL Core is updated according to the last Mobile API version. And in the described case, if the mobile application will not send the parameter, that could bring SDL Core to the incorrect behavior.

This proposal doesn't cover this case and changes for that should be described in a separate proposal.

## Impact on existing code

Extend SDL Core logic by additional functionality of unknown values filtering.

## Alternatives considered

The authors were unable to determine any alternative solutions.
