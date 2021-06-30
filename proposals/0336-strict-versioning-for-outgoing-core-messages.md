  # Strict Versioning for Outgoing Core Messages
  * Proposal: [SDL-0336](0336-strict-versioning-for-outgoing-core-messages.md)
  * Authors: [Jacob Keeler](https://github.com/jacobkeeler)
  * Status: **Accepted**
  * Impacted Platforms: [Core]

## Introduction

The main purpose of this proposal is to verify that SDL Core follows the Mobile API spec properly when communicating with older apps (where possible). Currently, due to changes in the Mobile API spec over time, there are cases where SDL Core can send a message to an older app which isn't valid for its API version.

## Motivation

The current data validation mechanism used by SDL Core doesn't factor in an app's negotiated API version when sending outgoing notifications or responses. This means that it can send messages to the app which aren't valid for that app, potentially causing unexpected behavior on the app's end.

As an example, if an application with an API version of `4.5.1` is subscribed to `RADIO` module data, and the HMI sends `RC.OnInteriorVehicleData` for this module with the following parameters:

```
{
  {
    "moduleData":{
      "moduleType":"RADIO",
      "moduleId":"d38e4a05-b17c-28e3-9d38-e4a05b17c28e",
      "radioControlData":{
        "frequencyInteger":87,
        "frequencyFraction":9,
        "availableHdChannels":[
            0,
            1,
            2,
            3,
            4,
            5,
            6,
            7
        ],
        "hdChannel":6
      }
    }
  }
}
```

The mobile application would expect `hdChannel` to have a value of 3 or lower, since its range was was smaller prior to API version 5.0.0, potentially causing unexpected behavior in the app (even a crash in the worst case).

In order to prevent this from happening where possible, this proposal will detail a sanitization process which will filter out some of these mismatched parameters. In this example, the following parameters would be sent to the mobile app after sanitization:

```
{
  {
    "moduleData":{
      "moduleType":"RADIO",
      "moduleId":"d38e4a05-b17c-28e3-9d38-e4a05b17c28e",
      "radioControlData":{
        "frequencyInteger":87,
        "frequencyFraction":9
      }
    }
  }
}
```

## Proposed solution

For the most part, SDL Core would follow a similar process for filtering outgoing messages as it does for filtering invalid enums for incoming messages (see [SDL-0248](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0298-Processing-of-unknown-enum-values-by-SDL-Core.md)).
When SDL Core is about to send a message to any mobile application, it performs the process of sanitizing any mismatched optional parameters in the message based on the app's negotiated RPC spec version.

*Note:* Mismatched mandatory parameters will be left as-is during the sanitization process, as there is no way to correct this data without any significant potential drawbacks (see "Alternatives considered"). It is recommended that integrators update their [minimum RPC spec version](https://github.com/smartdevicelink/rpc_spec/blob/master/MOBILE_API.xml#L4) if their HMI sends data that is not valid for older apps.

### Sanitization Rules

Using SDL-0248 as a base, the following cases will be covered to sanitize the message:

  1. The invalid/unknown parameter is a single value (non-array).

      If optional, SDL Core will remove this parameter from the outgoing message. 
      If mandatory, SDL Core will leave this parameter as-is.

  2. The invalid parameter is a structure.

      Filtering is performed for each parameter in the structure.

  3. The invalid parameter is an array of values or structures.

      SDL Core will remove all unknown or invalid elements from the array based on the criteria in cases 1 and 2.
      If the array is invalid after this process (due to its size being outside of defined bounds), then: 
        
      - If optional, the array itself will be filtered from the message.
      - If mandatory, the array will be left as-is.

Any parameters that were cut during this process should be logged by SDL Core, as well as included in the message's `info` string where applicable.

### Examples

In each example below, SDL Core sends a notification or response to the mobile application.

  1. The request contains an invalid/unknown optional parameter for the given message version.

      1.1. Unknown Parameter

      Message: `OnHMIStatus`
      
      Negotiated Message Version: `4.5.1`
  
      Parameter: `videoStreamingState` (introduced in `5.0.0`).
      
      Original message: 
      
      ```
      {
        "hmiLevel": "FULL",
        "audioStreamingState": "NOT_AUDIBLE",
        "videoStreamingState": "NOT_STREAMABLE"
      }
      ```
      
      After sanitization: 
      
      ```
      {
        "hmiLevel": "FULL",
        "audioStreamingState": "NOT_AUDIBLE"
      }
      ```

      1.2. Invalid Parameter

      Message: `OnInteriorVehicleData`
      
      Negotiated Message Version: `4.5.1`

      Parameter: `hdChannel` (range expanded in `5.0.0`).
      
      Original message: 
      
      ```
      {
        "moduleData":{
          "moduleType":"RADIO",
          "moduleId":"d38e4a05-b17c-28e3-9d38-e4a05b17c28e",
          "radioControlData":{
            "frequencyInteger":87,
            "frequencyFraction":9,
            "availableHdChannels":[
                0,
                1,
                2,
                3,
                4,
                5,
                6,
                7
            ],
            "hdChannel":6
          }
        }
      }
      ```
      
      After sanitization: 
      
      ```
      {
        "moduleData":{
          "moduleType":"RADIO",
          "radioControlData":{
            "frequencyInteger":87,
            "frequencyFraction":9
          }
        }
      }
      ```
  
  2. The request contains a parameter which is an array of values, some of which are unknown to the app.

      Message: `RegisterAppInterface` response.
      
      Negotiated Message Version: `4.5.1`

      Parameter `speechCapabilities`, `FILE` value included (introduced in `5.0.0`)

      Original message: 
      
      ```
      {
         "audioPassThruCapabilities":[
            {
               "audioType":"PCM",
               "bitsPerSample":"8_BIT",
               "samplingRate":"44KHZ"
            }
         ],
         ...
         "speechCapabilities":[
            "TEXT",
            "PRE_RECORDED",
            "FILE"
         ],
         "success":true,
         "resultCode": "SUCCESS"
         "syncMsgVersion":{
            "majorVersion":4,
            "minorVersion":5,
            "patchVersion":1
         },
         "systemSoftwareVersion":"12345_US",
         ...
      }
      ```
      
      After sanitization: 
      
      ```
      {
         "audioPassThruCapabilities":[
            {
               "audioType":"PCM",
               "bitsPerSample":"8_BIT",
               "samplingRate":"44KHZ"
            }
         ],
         ...
         "speechCapabilities":[
            "TEXT",
            "PRE_RECORDED"
         ],
         "success":true,
         "resultCode": "SUCCESS",
         "info": "RPC.params.speechCapabilities[2]: Removed mismatched value - FILE",
         "syncMsgVersion":{
            "majorVersion":4,
            "minorVersion":5,
            "patchVersion":1
         },
         "systemSoftwareVersion":"12345_US",
         ...
      }
      ```

**Note:**

As with general filtering rules for incoming messages, this process should not be applied to App Service related RPCs. These messages are designed to be forward-compatible, as they involve communication between apps.

## Potential downsides

It is possible that this sanitization process could cause some errors in Core or the HMI if they send invalid data at any point. Logging any modifications that are made (and providing details to the app, where possible) should make debugging easier if this scenario were to happen, but this is still something to keep in consideration. 

Some cases (such as `url` in `OnSystemRequest`, which had `maxlength` removed in `7.0.0`) cannot be fixed properly with this mechanism, so edge cases will still need to be identified and handled manually going forward.

## Impact on existing code

Fortunately, much of the enum filtering code added in [SDL-0248](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0298-Processing-of-unknown-enum-values-by-SDL-Core.md) can be reused in a similar manner for this proposal. A simplified version of this process would just need to be applied to outgoing messages.

## Alternatives considered

- One alternative that was considered was to manually determine which edge cases with versioning to handle, allowing parameters/values which are unknown to the app in most cases. This approach would likely be fairly time consuming, but would maybe allow more flexibility.
- Another alternative discussed was letting Core filter out any mismatched parameters, including those which are mandatory, then filtering out any structures which are missing mandatory parameters recursively. This would potentially reduce functionality for older apps, but would guarantee that Core would always follow the spec.
- Similar to the previous alternative, replacing missing mandatory values with generated data was also considered. This would also verify that Core would always follow the spec, but would require Core to send fake data in some cases, which could cause other issues on the app's end.
