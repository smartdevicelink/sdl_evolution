  # Strict Versioning for Outgoing Core Messages
  * Proposal: [SDL-NNNN](NNNN-strict-versioning-for-outgoing-core-messages.md)
  * Authors: [Jacob Keeler](https://github.com/jacobkeeler)
  * Status: **Awaiting review**
  * Impacted Platforms: [Core]

## Introduction

The main purpose of this proposal is to verify that SDL Core follows the Mobile API spec properly when communicating with older apps. Currently, due to changes in the Mobile API spec over time, there are cases where SDL Core can send a message to an older app which isn't valid for it's API version.

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

In order to prevent this from happening, this proposal will detail how to filter out these mismatched parameters. In this example, the following parameters being sent to mobile after filtering:

```
{
  "speed": 55
}
```

## Proposed solution

For the most part, SDL Core would follow a similar process for filtering outgoing messages as it does for filtering invalid enums for incoming messages (see [SDL-0248](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0298-Processing-of-unknown-enum-values-by-SDL-Core.md)).
When SDL Core is about to send a message to any mobile application, it performs the process of cutting off any invalid or unknown parameters from the message based on the app's negotiated RPC spec version.

Using SDL-0248 as a base, the following rules need to be covered to handle this filtering:

  1. The invalid/unknown parameter is a single value (non-array).

      SDL Core will remove this parameter from the outgoing message.

  2. The invalid parameter is a structure.

      Filtering is performed for each parameter in the structure.
      If the structure is missing a mandatory value after filtering has been performed, then the structure itself will be filtered from the message.

  3. The invalid parameter is an array of values or structures.

      SDL Core will remove all invalid or unknown elements from the array based on the criteria in cases 1 and 2.
      If the array is invalid after this process (for example, the number of elements is lower than `minsize`), then the array itself will be filtered from the message.

SDL Core performs this process recursively from the bottom up.
Any parameters that were cut during this process should be logged by SDL Core.


**Examples:**

In each example below, SDL Core sends a notification or response to the mobile application.

  1. The request contains a invalid/unknown parameter for the given message version.

    1.1 Unknown Parameter

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
      
      After filtering: 
      
      ```
      {
        "hmiLevel": "FULL",
        "audioStreamingState": "NOT_AUDIBLE"
      }
      ```
	
	1.2 Invalid Parameter
	   
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
      
      After filtering: 
      
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

      Message: `OnVehicleData`.
      
      Negotiated Message Version: `4.5.1`

      Parameter `gps`, sub-parameter: `satellites` (missing, made non-mandatory in 5.0.0)

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
            "pdop":8.4,
            "hdop":5.9,
            "vdop":3.2,
            "actual":false,
            "dimension":"2D",
            "altitude":7.7,
            "heading":173.99,
            "speed":2.78,
            "shifted":false
         }
      }
      ```
      
      After filtering: 
      
      ```
      {
        "speed":55
      }
      ```

  3. The request contains a parameter which is an array of values, some of which are unknown to the app.

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
         "syncMsgVersion":{
            "majorVersion":4,
            "minorVersion":5,
            "patchVersion":1
         },
         "systemSoftwareVersion":"12345_US",
         ...
      }
      ```
      
      After filtering: 
      
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
         "syncMsgVersion":{
            "majorVersion":4,
            "minorVersion":5,
            "patchVersion":1
         },
         "systemSoftwareVersion":"12345_US",
         ...
      }
      ```

  4. The request contains a parameter which is an array of structures and contains an unknown/invalid element for the given message version.

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
                          "protocol":"FUTURE"
                      }
                  ]
              }
          }
      }
      ```
      
      After filtering: 
      
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
                      }
                  ]
              }
          }
      }
      ```

**Note:**

As with general filtering rules for incoming messages, this process should not be applied to App Service related RPCs. These messages are designed to be forward-compatible, as they involve communication between apps.

## Potential downsides

It is possible that this filtering mechanism could cause some errors in Core or the HMI if they send invalid data at any point. Logging any filtering that is done should make it easier to debug if this scenario were to happen, but this is something to keep in consideration.

In addition, some cases (such as `url` in `OnSystemRequest`, which had `maxlength` removed in `7.0.0`) cannot be fixed properly with this mechanism, so edge cases will still need to be identified and handled manually going forward.

## Impact on existing code

Fortunately, much of the enum filtering code added in [SDL-0248](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0298-Processing-of-unknown-enum-values-by-SDL-Core.md) can be reused in a similar manner for this proposal. This process would just need to be expanded to filter any invalid values (not just enums), then applied to outgoing messages.

## Alternatives considered

- One alternative that was considered was to manually determine which edge cases with versioning to handle, allowing parameters/values which are unknown to the app in most cases. This approach would likely be quite time consuming, but would maybe allow more flexibility.
