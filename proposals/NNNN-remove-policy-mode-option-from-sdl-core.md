# Remove Policy Mode Option From SDL Core

* Proposal: [SDL-NNNN](NNNN-remove-policy-mode-option-from-sdl-core.md)
* Author: [Jacob Keeler](https://github.com/jacobkeeler)
* Status: **Awaiting review**
* Impacted Platforms: [Core / HMI]

## Introduction

Currently the SDL Core project has a build option which allows users to choose between one of three policy modes, `HTTP`, `PROPRIETARY`, and `EXTERNAL_PROPRIETARY`. The main difference between these modes are:

1. The policy update flow is slightly different between each mode
    - `HTTP` mode does not use the HMI at all in the policy update process
    - `PROPRIETARY` mode uses the HMI to optionally encrypt the policy table snapshot, while Core handles the PTU retry sequence
    - `EXTERNAL_PROPRIETARY` mode uses the HMI to optionally encrypt the policy table snapshot and to handle the PTU retry sequence
2. `EXTERNAL_PROPRIETARY` mode supports a number of extra features, including several policy table fields that aren't implemented in `HTTP` or `PROPRIETARY` mode

The `HTTP` and `PROPRIETARY` policy modes were created for the project when it first became open-source as a way of including a version of policies with reduced functionality. It was eventually decided to include the full feature in the open, which was when `EXTERNAL_PROPRIETARY` was added to the project (see [SDL Core 4.3.0](https://github.com/smartdevicelink/sdl_core/releases/tag/4.3.0)).

Generally speaking, `EXTERNAL_PROPRIETARY` mode is the fully-featured version of policies, while the other two modes only support a subset of the features in `EXTERNAL_PROPRIETARY`. There is a significant amount of overhead in testing and development for policy-related features due to the need to support each of these modes. For these reasons, there is very little reason to continue supporting these older modes, as they are less versatile than `EXTERNAL_PROPRIETARY` mode. The goal of this proposal is to remove the `EXTENDED_POLICY` build option from SDL Core, reducing support only to `EXTERNAL_PROPRIETARY` policies.

## Motivation

Currently, the codebase for policies in SDL Core is split between two folders with similar contents:

- `policy/policy_regular` contains the codebase for both `HTTP` and `PROPRIETARY` mode.
- `policy/policy_external` contains the codebase for `EXTERNAL_PROPRIETARY` mode.

This means that each time an addition to the policy table is made, the same changes need to be made in both places, significantly increasing development time. 

In addition, having three possible configurations for the policy mode significantly increases the amount of time needed to test policy-related features. Each policy feature must be tested in all three modes, requiring three separate full builds for the feature.

Overall, there seems to be very little benefit to supporting anything besides `EXTERNAL_PROPRIETARY` mode, since it is more versatile and feature-rich than either of the other modes, while the costs of maintaining all three modes is fairly steep.

## Proposed solution

The proposed solution to this problem is to remove the `EXTENDED_POLICY` build flag from the SDL Core project entirely, keeping only the implementation for `EXTERNAL_PROPRIETARY` mode. This would reduce the complexity of the policy component of SDL Core quite significantly, speeding up development and testing for this component while reducing the chance of issues caused by any differences in the implementation of each policy mode.

## Potential downsides

If any existing systems use either `HTTP` or `PROPRIETARY` policy mode, they will need to modify their HMI to work with the `EXTERNAL_PROPRIETARY` policy update flow. This would not require a significant HMI overhaul, but is still something to keep in mind. Another note is that unfortunately `PROPRIETARY` is the default policy mode at the moment, meaning that it is quite possible that this mode is used by existing systems. One thing that could be done to help with this downside would be to include an HMI guide for transitioning to the `EXTERNAL_PROPRIETARY` policy flow.

## Impact on existing code

### SDL Core

Because this would involve removing an existing build option from the project, this change will require a major version update for SDL Core.

This proposal would require the removal of the `EXTENDED_POLICY` build option, as well as any code specifically related to the `HTTP` and `PROPRIETARY` modes. This would involve the removal of any preprocessor instructions related to the `PROPRIETARY_MODE` and `EXTERNAL_PROPRIETARY_MODE` macros, for example:

```cpp
#if defined(PROPRIETARY_MODE) || defined(EXTERNAL_PROPRIETARY_MODE)
  const std::string& file_path =
      (*message_)[strings::msg_params][hmi_notification::policyfile].asString();
  policy::BinaryMessage file_content;
  if (!file_system::ReadBinaryFile(file_path, file_content)) {
    SDL_LOG_ERROR("Failed to read Update file.");
    return;
  }
  policy_handler_.ReceiveMessageFromSDK(file_path, file_content);
#else
  SDL_LOG_WARN(
      "This RPC is part of extended policy flow. "
      "Please re-build with extended policy mode enabled.");
#endif
```

would be reduced to

```cpp
  const std::string& file_path =
      (*message_)[strings::msg_params][hmi_notification::policyfile].asString();
  policy::BinaryMessage file_content;
  if (!file_system::ReadBinaryFile(file_path, file_content)) {
    SDL_LOG_ERROR("Failed to read Update file.");
    return;
  }
  policy_handler_.ReceiveMessageFromSDK(file_path, file_content);
```

and

```cpp
  if (mobile_apis::RequestType::PROPRIETARY == request_type) {
    /* According to requirements:
       "If the requestType = PROPRIETARY, add to mobile API fileType = JSON
        If the requestType = HTTP, add to mobile API fileType = BINARY" */

#if defined(PROPRIETARY_MODE)
    AddHeader(binary_data);
#endif  // PROPRIETARY_MODE

    (*message_)[strings::msg_params][strings::file_type] = FileType::JSON;
  } else if (mobile_apis::RequestType::HTTP == request_type) {
    (*message_)[strings::msg_params][strings::file_type] = FileType::BINARY;
    if ((*message_)[strings::msg_params].keyExists(strings::url)) {
      (*message_)[strings::msg_params][strings::timeout] =
          policy_handler.TimeoutExchangeSec();
    }
  } else if (mobile_apis::RequestType::LOCK_SCREEN_ICON_URL == request_type) {
    if (binary_data.empty() &&
        (!(*message_)[strings::msg_params].keyExists(strings::url) ||
         (*message_)[strings::msg_params][strings::url].empty())) {
      SDL_LOG_ERROR(
          "discarding LOCK_SCREEN_ICON_URL request with no URL or data");
      return;
    }
  }

#if defined(PROPRIETARY_MODE) || defined(EXTERNAL_PROPRIETARY_MODE)
  if (!binary_data.empty()) {
    (*message_)[strings::params][strings::binary_data] = binary_data;
  }
#endif  // PROPRIETARY_MODE

  SendNotification();
```

would be reduced to

```cpp
  if (mobile_apis::RequestType::PROPRIETARY == request_type) {
    /* According to requirements:
       "If the requestType = PROPRIETARY, add to mobile API fileType = JSON
        If the requestType = HTTP, add to mobile API fileType = BINARY" */
    (*message_)[strings::msg_params][strings::file_type] = FileType::JSON;
  } else if (mobile_apis::RequestType::HTTP == request_type) {
    (*message_)[strings::msg_params][strings::file_type] = FileType::BINARY;
    if ((*message_)[strings::msg_params].keyExists(strings::url)) {
      (*message_)[strings::msg_params][strings::timeout] =
          policy_handler.TimeoutExchangeSec();
    }
  } else if (mobile_apis::RequestType::LOCK_SCREEN_ICON_URL == request_type) {
    if (binary_data.empty() &&
        (!(*message_)[strings::msg_params].keyExists(strings::url) ||
         (*message_)[strings::msg_params][strings::url].empty())) {
      SDL_LOG_ERROR(
          "discarding LOCK_SCREEN_ICON_URL request with no URL or data");
      return;
    }
  }

  if (!binary_data.empty()) {
    (*message_)[strings::params][strings::binary_data] = binary_data;
  }

  SendNotification();
```

In addition, it would require the removal of the following folders from the project entirely:
- `src/components/policy/policy_regular`
- `src/components/include/policy/policy_regular`

And the contents of the following folders would need to be moved:
- `src/components/policy/policy_external` to `src/components/policy`
- `src/components/include/policy/policy_external` to `src/components/include/policy`

### SDL HMI

This proposal would require the removal of the `External Policies` option from the SDL HMI, only keeping code which is relevant when this flag is set to `true`, for example:

```js
    case 'UP_TO_DATE':
    {
      messageCode = 'StatusUpToDate';
      //Update is complete, stop retry sequence
      if (FLAGS.ExternalPolicies === true) {
        SDL.SettingsController.policyUpdateRetry('ABORT');
      }
      SDL.SettingsController.policyUpdateFile = null;
      this.GetPolicyConfigurationData({
        policyType: 'module_config',
        property: 'endpoint_properties',
        nestedProperty: 'custom_vehicle_data_mapping_url'
      });
      break;
    }
    case 'UPDATING':
    {
      messageCode = 'StatusPending';
      break;
    }
    case 'UPDATE_NEEDED':
    {
      messageCode = 'StatusNeeded';
      if (FLAGS.ExternalPolicies === true && 
          SDL.SDLModel.data.policyUpdateRetry.isRetry) {
        SDL.SettingsController.policyUpdateRetry();
      }
      break;
    }
```

would be reduced to

```js
    case 'UP_TO_DATE':
    {
      messageCode = 'StatusUpToDate';
      //Update is complete, stop retry sequence
      SDL.SettingsController.policyUpdateRetry('ABORT');
      SDL.SettingsController.policyUpdateFile = null;
      this.GetPolicyConfigurationData({
        policyType: 'module_config',
        property: 'endpoint_properties',
        nestedProperty: 'custom_vehicle_data_mapping_url'
      });
      break;
    }
    case 'UPDATING':
    {
      messageCode = 'StatusPending';
      break;
    }
    case 'UPDATE_NEEDED':
    {
      messageCode = 'StatusNeeded';
      if (SDL.SDLModel.data.policyUpdateRetry.isRetry) {
        SDL.SettingsController.policyUpdateRetry();
      }
      break;
    }
```

and

```js
    if (FLAGS.ExternalPolicies === true) {
      FFW.ExternalPolicies.unpack({
        requestType: request.params.requestType,
        requestSubType: request.params.requestSubType,
        fileName: request.params.fileName
      });
    } else {
      if (request.params.requestType == 'PROPRIETARY') {
        this.OnReceivedPolicyUpdate(request.params.fileName);
      }
    }
```

would be reduced to

```js
    FFW.ExternalPolicies.unpack({
      requestType: request.params.requestType,
      requestSubType: request.params.requestSubType,
      fileName: request.params.fileName
    });
```

### Generic HMI

Similar to the SDL HMI, this proposal would require the removal of the `ExternalPolicies` flag from the Generic HMI, only keeping code which is relevant when this flag is set to `true`, for example:

```js
    let regular_ptu_flow = () => {
        if(window.flags.ExternalPolicies) {
            externalPolicies.pack({            
                requestType: 'PROPRIETARY',
                fileName: state.system.policyFile,
                urls: state.system.urls,
                retry: state.system.policyRetry,
                timeout: state.system.policyTimeout
            })
        }
        else {
            bcController.onSystemRequest(state.system.policyFile)
        }
    };
```

would be reduced to

```js
    let regular_ptu_flow = () => {
        externalPolicies.pack({            
            requestType: 'PROPRIETARY',
            fileName: state.system.policyFile,
            urls: state.system.urls,
            retry: state.system.policyRetry,
            timeout: state.system.policyTimeout
        })
    };
```

## Alternatives considered

The author did not consider any alternatives to this solution, besides maintaining support for all modes.