  # Processing of unknown enum values by SDL Core and Mobile Libraries
  * Proposal: [SDL-NNNN](NNNN-Processing-of-unknown-enum-values-by-SDL-and-Mobile-libraries.md)
  * Authors: [Igor Gapchuk](https://github.com/IGapchuk), [Dmitriy Boltovskiy](https://github.com/dboltovskyi/), [Kostiantyn Boskin](https://github.com/kostyaboss), [Yurii Lokhmatov](https://github.com/yoooriii)
  * Status: **Awaiting review**
  * Impacted Platforms: [Core / iOS / JavaSuite]

## Introduction
The main purpose of this proposal is to gracefully handle incompatible enum values in a mobile RPC request with any given SDL Core version. This can be achieved by improving the way SDL Core processes and validates unknown enum values and by extending mobile library functionality to properly format RPC requests when RPC API’s (RAPI) are mismatched.

## Motivation

The current filtering and data validation mechanism used by SDL Core needs be improved upon to avoid application registration issues and other RPC failures that result from differences in RAPI versions between the SDL mobile library and SDL Core.  To maintain backwards compatibility, the mobile libraries also need to be updated to format RPC requests by cutting off or ignoring unknown and unsupported enum values when a difference in RAPI sets have been detected.

To better understand the issue at hand, please take note of the following example:

Let us assume that a mobile application with a newer version of the RAPI attempts to connect to an SDL Core instance which is using an older RAPI version. In this example, the SDL Core RAPI version is set to 4.3 whereas the mobile application RAPI version is set to 6.0. Let us also assume that the mobile application has an AppHMIType of DEFAULT and REMOTE_CONTROL set.  The DEFAULT AppHMIType has been present in the RAPI since its inception, however REMOTE_CONTROL was introduced in version 6.0 of the RAPI.

In the case above, the mobile application will try to register itself by sending a RegisterAppInterface (RAI) request to SDL Core with an array of AppHMITypes : appHMIType[DEFAULT, REMOTE_CONTROL]. SDL Core will next try to validate the parameters in the RAI request, it will immediately find an unknown enum value of REMOTE_CONTROL. A failure response will then be sent to the mobile application with the INVALID_DATA result code (this is because the REMOTE_CONTROL AppHMIType has only been available since version RAPI 4.5, however we are communicating with a version of SDL Core that only supports RAPI 4.3). As a result of the scenario above, the mobile application fails to register with SDL Core providing an unacceptable user experience. In addition the mobile application cannot conclusively determine the cause of failure since INVALID_DATA can be returned for any number of reasons.  Ideally the mobile app would be registered successfully with a warning provided in the result code stating "some AppHMITypes could not be processed."

To fix the case stated above as well as similar cases originating from the same cause, the validation logic inside of SDL Core should be updated to cutoff / ignore unknown enums present in RPC requests.  These failure cases should instead be replaced with SUCCESS cases with warnings result codes.
To ensure backward compatibility with earlier versions of SDL Core, mobile libraries should be updated to process, filter and format enums inside of RPC requests when a difference in RAPI sets have been detected.

## Proposed solution

### SDL Core changes

When SDL Core receives a request from a mobile application, it starts validation of all incoming parameters.
If a parameter includes an unknown enum value, SDL Core has to cut off such value from the parameter.

  This means the following cases are possible:

  1. Type of parameter is non-array enum (see example 1).

      SDL Core has to remove this parameter from the request since the value after cutting off becomes empty.

  2. Parameter is an array of enum types (see example 2).

      SDL Core has to remove an unknown value from the array.
      A case is possible when all values are unknown and thus get removed.
      In this case, SDL Core has to proceed the same way as in case 1.

  3. Parameter is part of the structure (see example 3).

      SDL Core has to proceed the same way as in case #1 or #2 and remove this parameter from the structure.
      However, if the parameter is mandatory the structure becomes invalid.
      In this case, SDL Core has to remove the whole structure from the request.
      During this process, SDL Core has to proceed recursively from the very bottom level up to the top.

  4. Parameter is a part of the structure which is a part of an array (see example 4).

      SDL Core has to process it the same way as in case #3 and remove the structure as an item of the array.
      Once all the parameters are processed SDL Core has to proceed with the request as usual.

  If at least one value of at least one parameter was cut off, SDL Core has to update the response to the mobile application as follows:

  1. If the response was processed successfully, SDL Core has to provide the `WARNINGS` result code instead of `SUCCESS`.
  2. SDL Core has to provide removed enum items in `info` string of the response.

      Since there could be more than one parameter with cut-off value, `info` message can be constructed the following way:

      `Invalid enums were removed: <param_1>:<enum_value_1>,<enum_value_2>;<param_2>:<enum_value_3> ...`

      If `info` parameter contains other value(s) belonging to the original processing result SDL Core has to append information about cut-off enum value(s) to the existing value.

  **Examples:**
  In each example below the mobile application sends a request to SDL Core.
  1. Request contains a parameter which value is an enum item.

      Request: `SetMediaClockTimer`

      1.1 Parameter is mandatory: `updateMode="UNKNOWN"`.

      SDL Core removes the item `UNKNOWN` from the request.
      The value of `updateMode` parameter becomes empty.
      SDL Core omits empty parameter from the request.
      Since parameter is mandatory (according to Mobile API), the request fails with the following response to mobile application:
      `success=false, resultCode = "INVALID_DATA", info="Invalid enums were removed: updateMode:UNKNOWN"`

      1.2 Parameter is optional: `audioStreamingIndicator="UNKNOWN"`.

      SDL Core removes the `UNKNOWN` item from the request.
      The value of `audioStreamingIndicator` parameter becomes empty.
      SDL Core omits the empty parameter in the request.
      Since the parameter is optional (according to Mobile API), the request is successfully processed with the following response to mobile application:
      `success=true, resultCode = "WARNINGS", info="Invalid enums were removed: audioStreamingIndicator:UNKNOWN"`

  2. Request contains a parameter for which the value is an array of enum items.

      Request: `RegisterAppInterface`.

      2.1 Only one enum item is unknown: `appHMIType = [ "DEFAULT", "UNKNOWN"]`.

      SDL Core removes the `UNKNOWN` item from the request.
      The value of `appHMIType` parameter now contains only `DEFAULT` item (which is known one).
      Request is successfully processed with the following response to mobile application:
      `success=true, resultCode = "WARNINGS", info="Invalid enums were removed: appHMIType:UNKNOWN"`

      2.2 All enum items are unknown: `appHMIType = [ "UNKNOWN_1", "UNKNOWN_2"]`.

      SDL Core removes both `UNKNOWN_1` and `UNKNOWN_2` items from the request.
      The value of `appHMIType` parameter becomes empty.
      Since `minsize` of the parameter is `1` (according to Mobile API), the request fails with the following response to mobile application:
      `success=false, resultCode = "INVALID_DATA", info="Invalid enums were removed: appHMIType:UNKNOWN_1, UNKNOWN_2"`

  3. Request contains a parameter (with enum item value) which is a part of the structure.

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

  4. Request contains a parameter which is an array of elements and each element has a parameter which value is an enum item.

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

### Mobile libraries changes (JavaSuite and iOS)

  This solution affects the mobile application in 2 ways:

  1. The way the mobile application registers itself with SDL Core.

  2. The way the mobile application sends requests to SDL Core.

#### Changes related to mobile application connecting to SDL Core
  To filter out unsupported items we need to know the exact protocol version, not only the major part of it but the minor part as well since certain parameters were added in between the major change. For instance, `AppHMIType` items `PROJECTION` and `REMOTE_CONTROL` were rolled in as early as 4.5. There is a possible case when we know the major version is 4 but the information about the minor part of it is unknown before `RegisterAppInterface` request is sent and responded. However, even upon receipt of the response, the minor version of the protocol may still be not confirmed since both `syncMsgVersion` and `sdlVersion` are not mandatory parameters and thus can be absent in the response.

  ***Note** for SDL *PROTOCOL* version less than 4.3 in StartServiceACK response Proxy can get only *MAJOR* version.*

  ***Note** for SDL *PROTOCOL* version higher than or equal to 4.4 in in StartServiceACK response Proxy can get *MAJOR*.*MINOR*.*PATCH* versions.*

  ***Note** since that moment (StartServiceACK response) and until `RegisterAppInterface` successful response, Proxy should use PROTOCOL version to filter out all unknown enum values.*

  So the workflow should be implemented as follows:
  1. The mobile application (Android/IOS) creates a proxy object (proxy) to communicate with the SDL Core.
  2. The mobile application passes to the Proxy entity the configurations.
  3. Among other properties the configuration object has the following parameters:
      * Minimum SDL Core version
      * Application HMI type(s) (`AppHMIType` array)

#### Changes related to sending request(s) from mobile application to SDL Core
  After the connection is established and mobile application is registered with SDL Core, mobile application works as usual but requires the request parameters validation. An issue will occur when the mobile application calls a method and passes an enum values array as a parameter that belongs to the higher SDL version. In this case, the Mobile Proxy should filter out unsupported params before sending the request and provide warning in logs as `unsupported_values`.

  The validation sequence:

  1. Mobile application sends request to SDL Core through the proxy.
  2. The proxy checks the request parameters:
     * If there are no enum values unknown to SDL, the proxy forwards the request to SDL Core without changes.

     * If some of the enum values are unknown to SDL Core the proxy should:
          * Filter out all RPCs' unsupported enum values including nested RPCs if those are present, before making a request to make sure it is compliant with the current spec
          * Log a warning level with «unsupported_values» (enum’s/struct’s names)

  **Note**: For `RegisterAppInterface` to filter we should use version of PROTOCOL, but not the MOBILE_API according to system’s flow. **iOS** should be extended with similar mechanism in order to encapsulate filtering logic.

  **For example** :
  If the UI app requested unsupported `AppHMIType` and version which are not compatible, then the proxy must filter unsupported HMI types.

   - Before filtering :
       ```
       "AppHMIType" : ["DEFAULT", "MEDIA", "UKNOWN"]
       ```

   - After filtering :
       ```
       AppHMIType" : ["DEFAULT", "MEDIA"]
       ```

  ***Note**: In case no HMI types are left after filtering, Mobile Library should throw an exception, otherwise `RegisterAppInterface` RPC will be sent with remaining HMI types.*

  ***Note**: Now system flow is the following: if `RegisterAppInterface` fails with an error then Mobile library should pass the error status to the Mobile Library adding failure reason.*

  ***Note**: The protocol version control logic is partly implemented in Android and not implemented in iOS. However, what is implemented has its flaws and should be updated following the logic above.*


## Potential downsides
  In the case, new RPCs would added, the new structures/enums should be implemented with additional implementation of filtering mechanism for particular objects.

  **Note:** For `RegisterAppInterface` we cannot keep connection if invalid param is present due to the current flow of the older SDL versions. The connection can be dropped (End Session) by SDL Core but not by mobile device (SDL library).

## Impact on existing code
  **Android/iOS**

   * Each `RPCStruct` should be extended with the implementation of filtering mechanism
   * Implement logging for unsupported values

**SDL Core:**

Extend SDL Core logic by additional functionality of unknown values filtering.

## Alternatives considered

The authors were unable to determine any alternative solutions.
