  # Strict Versioning for Outgoing Core Messages
  * Proposal: [SDL-0336](0336-strict-versioning-for-outgoing-core-messages.md)
  * Authors: [Jacob Keeler](https://github.com/jacobkeeler)
  * Status: **Returned for Revisions**
  * Impacted Platforms: [Core]

## Introduction

The main purpose of this proposal is to verify that SDL Core follows the Mobile API spec properly when communicating with older apps. Currently, due to changes in the Mobile API spec over time, there are cases where SDL Core can send a message to an older app which isn't valid for its API version.

## Motivation

The current data validation mechanism used by SDL Core doesn't factor in an app's negotiated API version when sending outgoing notifications or responses. This means that it can send messages to the app which aren't valid for that app, potentially causing unexpected behavior on the app's end.

As an example, if an application with an API version of `4.5.1` is subscribed to `gps` and `speed`, and the HMI sends `VehicleInfo.OnVehicleData` for these items without `utcSeconds`:

```
{
   "speed":55,
   "gps":{
      "longitudeDegrees":42.5,
      "latitudeDegrees":-83.3,
      "utcYear":2013,
      "utcMonth":2,
      "utcDay":14,
      "utcHours":13,
      "utcMinutes":16,
      "compassDirection":"SOUTHWEST",
      "pdop":8.4,
      "hdop":5.9,
      "vdop":3.2,
      "actual":false,
      "satellites":8,
      "dimension":"2D",
      "altitude":7.7,
      "heading":173.99,
      "speed":2.78,
      "shifted":false
   }
}
```

The mobile application would expect `utcSeconds` to be present in this message, since it was mandatory prior to API version 5.0.0, potentially causing unexpected behavior in the app (even a crash in the worst case).

In order to prevent this from happening, this proposal will detail a sanitization process which can filter and/or fill out these mismatched parameters. In this example, the following parameters would be sent to the mobile app after sanitization:

```
{
   "speed": 55,
   "gps":{
      "longitudeDegrees":42.5,
      "latitudeDegrees":-83.3,
      "utcYear":2013,
      "utcMonth":2,
      "utcDay":14,
      "utcHours":13,
      "utcMinutes":16,
      "utcSeconds":0,
      "compassDirection":"SOUTHWEST",
      "pdop":8.4,
      "hdop":5.9,
      "vdop":3.2,
      "actual":false,
      "satellites":8,
      "dimension":"2D",
      "altitude":7.7,
      "heading":173.99,
      "speed":2.78,
      "shifted":false
   }
}
```

## Proposed solution

For the most part, SDL Core would follow a similar process for filtering outgoing messages as it does for filtering invalid enums for incoming messages (see [SDL-0248](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0298-Processing-of-unknown-enum-values-by-SDL-Core.md)), with additional logic to replace mandatory parameters where appropriate.
When SDL Core is about to send a message to any mobile application, it performs the process of sanitizing any mismatched parameters in the message based on the app's negotiated RPC spec version.

### Sanitization Rules

Using SDL-0248 as a base, the following cases need to be covered to sanitize the message:

  1. The invalid/unknown parameter is a single value (non-array).

      If optional, SDL Core will remove this parameter from the outgoing message. 
      If mandatory, SDL Core will replace this value with an appropriate generated dummy value (described in the next section)

  2. The invalid parameter is a structure.

      Filtering is performed for each parameter in the structure.
      If the structure is missing any mandatory parameters after filtering has been performed, then those values will be replaced by generated dummy values.

  3. The invalid parameter is an array of values or structures.

      SDL Core will remove all unknown or invalid elements from the array based on the criteria in cases 1 and 2.
      
      - Special case: If a struct element in the array contained an unknown enum value for a mandatory parameter (which would have been replaced in case 1), that full struct element should be filtered from the array as well.
      
      If the array is invalid after this process (due to its size being outside of defined bounds), then: 
        
      - If optional, the array itself will be filtered from the message.
      - If mandatory, the array will be truncated or padded with dummy values appropriately. 

SDL Core performs this process recursively from the bottom up.

Any parameters that were cut or modified during this process should be logged by SDL Core, as well as included in the message's `info` string where applicable. If parameters were replaced or added, a `WARNINGS` result code should also be sent in place of a `SUCCESS` code, where applicable.

### Replacement

Where appropriate, SDL Core will generate dummy values to replace mandatory parameters which have missing, invalid, or unknown values for the negotiated RPC version. This prevents useful information from being erased from the message when other parts of the message are invalid due to changes in the RPC spec.

The dummy values SDL Core uses for this process are generated based on the parameter constraints using the following set of rules:

- Boolean: The parameter will be set to **false**
- Integer/Float: 
    - If the parameter is omitted, the parameter will be set to **0** or **minvalue**, whichever is larger. 
        - ex. `altitude: 0`, `utcDay: 1`
    - If an invalid value is provided, the parameter will be set to **minvalue** or **maxvalue**, whichever is closer to the provided value.
        - ex. `hdop: 15.0` -> `10.0`
- String: 
    - If the parameter is omitted, the parameter will be set to a string of size **minlength** (note, this defaults to 1 if omitted) filled with spaces. 
        - ex. `moduleName: " "`
    - If an invalid value is provided, the parameter will be set to a truncated or space-padded version of the invalid value, either **maxlength** or **minlength** in length accordingly.
        - ex. `hashId: "12345...(90 characters)...6789012345"` -> `"12345...(90 characters)...67890"`
- Enum: The parameter will be set to the first defined enum value in the data type
    - ex. `compassDirection: "NORTH"`
- Structs: The parameter will be set to a structure with all mandatory subparameters filled out with dummy values (generated using each of the rules defined above)


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

  2. The request is missing a parameter which is a mandatory part of the structure in the given message version.

      Message: `GetVehicleData` response.
      
      Negotiated Message Version: `4.5.1`

      Parameter `gps`, sub-parameters: `satellites` and `compassDirection` (missing, made non-mandatory in 5.0.0)

      Original message: 
      
      ```
      {
         "speed":55,
         "gps":{
            "longitudeDegrees":42.5,
            "latitudeDegrees":-83.3,
            "utcYear":2013,
            "utcMonth":2,
            "utcDay":14,
            "utcHours":13,
            "utcMinutes":16,
            "utcSeconds":12,
            "pdop":8.4,
            "hdop":5.9,
            "vdop":3.2,
            "actual":false,
            "dimension":"2D",
            "altitude":7.7,
            "heading":173.99,
            "speed":2.78,
            "shifted":false
         },
         "success": true,
         "resultCode": "SUCCESS"
      }
      ```
      
      After sanitization: 
      
      ```
      {
         "speed":55,
         "gps":{
            "longitudeDegrees":42.5,
            "latitudeDegrees":-83.3,
            "utcYear":2013,
            "utcMonth":2,
            "utcDay":14,
            "utcHours":13,
            "utcMinutes":16,
            "utcSeconds":12,
            "compassDirection":"NORTH",
            "pdop":8.4,
            "hdop":5.9,
            "vdop":3.2,
            "actual":false,
            "dimension":"2D",
            "altitude":7.7,
            "heading":173.99,
            "satellites":0,
            "speed":2.78,
            "shifted":false
         },
         "success": true,
         "resultCode": "WARNINGS",
         "info": "RPC.params.gps.satellites: Added missing value\nRPC.params.gps.compassDirection: Added missing value"
      }
      ```

  3. The request contains an invalid value for a parameter which is a mandatory part of the structure in the given message version.
  
      Message: `GetVehicleData` response.
      
      Negotiated Message Version: `4.5.1`

      Parameter `gps`, sub-parameters: `dimension` (invalid, made non-mandatory in 5.0.0) and `pdop` (range expanded in 5.0.0)

      Original message: 
      
      ```
      {
         "speed":55,
         "gps":{
            "longitudeDegrees":42.5,
            "latitudeDegrees":-83.3,
            "utcYear":2013,
            "utcMonth":2,
            "utcDay":14,
            "utcHours":13,
            "utcMinutes":16,
            "utcSeconds":12,
            "compassDirection":"SOUTHWEST",
            "pdop":18.4,
            "hdop":5.9,
            "vdop":3.2,
            "actual":false,
            "dimension":"4D",
            "altitude":7.7,
            "heading":173.99,
            "satellites":8,
            "speed":2.78,
            "shifted":false
         },
         "success": true,
         "resultCode": "SUCCESS"
      }
      ```
      
      After sanitization: 
      
      ```
      {
         "speed":55,
         "gps":{
            "longitudeDegrees":42.5,
            "latitudeDegrees":-83.3,
            "utcYear":2013,
            "utcMonth":2,
            "utcDay":14,
            "utcHours":13,
            "utcMinutes":16,
            "utcSeconds":12,
            "compassDirection":"SOUTHWEST",
            "pdop":10.0,
            "hdop":5.9,
            "vdop":3.2,
            "actual":false,
            "dimension":"2D",
            "altitude":7.7,
            "heading":173.99,
            "satellites":8,
            "speed":2.78,
            "shifted":false
         },
         "success": true,
         "resultCode": "WARNINGS",
         "info": "RPC.params.gps.satellites: Added missing value\nRPC.params.gps.compassDirection: Added missing value"
      }
      ```
  
  4. The request contains a parameter which is an array of values, some of which are unknown to the app.

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

  5. The request contains a parameter which is an array of structures and contains an unknown/invalid element for the given message version.

      Message: `GetSystemCapability` Response (VIDEO_STREAMING)
      
      Negotiated Message Version: `7.0.0`
  
      Parameter: `supportedFormats`, sub-parameter: `codec` (with future value).
      
      Original message: 
      
      ```
      {
          "resultCode":"SUCCESS",
          "success":true,
          "systemCapability":{
              "systemCapabilityType":"VIDEO_STREAMING",
              "videoStreamingCapability":{
                  "diagonalScreenSize":8,
                  "hapticSpatialDataSupported":true,
                  "maxBitrate":400000,
                  "pixelPerInch":96,
                  "preferredResolution":{
                      "resolutionHeight":380,
                      "resolutionWidth":800
                  },
                  "scale":1,
                  "supportedFormats":[
                      {
                          "codec":"H264",
                          "protocol":"RAW"
                      },
                      {
                          "codec":"H264",
                          "protocol":"RTP"
                      },
                      {
                          "codec":"FUTURE",
                          "protocol":"RAW"
                      }
                  ]
              }
          }
      }
      ```
      
      After sanitization: 
      
      ```
      {
          "resultCode":"SUCCESS",
          "success":true,
          "info": "RPC.params.systemCapability.videoStreamingCapability.supportedFormats[2].codec: Removed mismatched value - FUTURE",
          "systemCapability":{
              "systemCapabilityType":"VIDEO_STREAMING",
              "videoStreamingCapability":{
                  "diagonalScreenSize":8,
                  "hapticSpatialDataSupported":true,
                  "maxBitrate":400000,
                  "pixelPerInch":96,
                  "preferredResolution":{
                      "resolutionHeight":380,
                      "resolutionWidth":800
                  },
                  "scale":1,
                  "supportedFormats":[
                      {
                          "codec":"H264",
                          "protocol":"RAW"
                      },
                      {
                          "codec":"H264",
                          "protocol":"RTP"
                      }
                  ]
              }
          }
      }
      ```

**Note:**

As with general filtering rules for incoming messages, this process should not be applied to App Service related RPCs. These messages are designed to be forward-compatible, as they involve communication between apps.

## Potential downsides

It is possible that this sanitization process could cause some errors in Core or the HMI if they send invalid data at any point. Logging any modifications that are made (and providing details to the app, where possible) should make debugging easier if this scenario were to happen, but this is still something to keep in consideration.

Because of the replacement process described in this proposal, Core will occasionally be sending faked data to the application, which could potentially cause an older app to work improperly. 

Some cases (such as `url` in `OnSystemRequest`, which had `maxlength` removed in `7.0.0`) cannot be fixed properly with this mechanism, so edge cases will still need to be identified and handled manually going forward.

## Impact on existing code

Fortunately, much of the enum filtering code added in [SDL-0248](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0298-Processing-of-unknown-enum-values-by-SDL-Core.md) can be reused in a similar manner for this proposal. This process would just need to be expanded to filter any invalid values (not just enums), then applied to outgoing messages. New logic to generate dummy values would need to be added to the SmartObject component of SDL Core as well.

## Alternatives considered

- One alternative that was considered was to manually determine which edge cases with versioning to handle, allowing parameters/values which are unknown to the app in most cases. This approach would likely be fairly time consuming, but would maybe allow more flexibility.
- Another alternative discussed was letting Core filter out any mismatched parameters within a message without replacing any of them with dummy values. This would potentially reduce functionality for older apps, but would not require faking any data.
