# Batch RPC Processing

* Proposal: nnnn-batch-rpc-processing.md
* Author: [Markos Rapitis]
* Status: "Awaiting Review"
* Review manager: TBD
* Impacted Platforms: iOS, Android, Core, RPC

## Introduction
This proposal introduces the ability to utilize a generic data transfer flow to allow for processing of RPC's via a defined batch file format.

## Motivation
Currently all RPC's are sent individually from the mobile to core and vice versa.  When processing a large number of RPC's (e.g. thousands) the communication between the mobile and core can become a huge and unnecessary bottle neck.
In the SDL application lifecycle, there are important cases where the mobile needs to send and receive a large number of RPC's very quickly.  

For example, when an app is placed into full for the first time it is expected that all resources utilized by the app are requested for the first time and made available to the user as soon as possible -- these resources can potentially include a large number (in the thousands) of AddCommands and CreateInteractionChoiceSets.  
In addition, other RPC's are also traditionally requested at startup like button subscriptions and the setting of global properties.  Similarly, at times removing a large number of resources (like deleting commands and choicesets) needs to occur very quickly. 

In the cases mentioned, sending an individual RPC request for each command is not ideal as the amount of bandwidth and time needed to process thousands of RPC requests is significant.  
A more efficient approach would be to utilize the generic data transfer flow, sending a batch file via PutFile with a list of RPC's to be processed and a system request to reference the batch file.


## Proposed Solution
The solution proposed is to utilize the existing generic data transfer flow as a base and enhance the flow to include the processing of RPC's from a defined file format.  
Utilizing a batch file will reduce the number of RPC's sent and received between the mobile and core from the thousands to just a few as shown below:

Proposed Process (general happy path):
* Mobile constructs a formatted (BATCH_RPC) file of RPC requests based on app needs
* -> Mobile sends a PutFile request containing the formatted file of RPC requests
* <- Core sends a PutFile response signaling the success of the PutFile request
* -> Mobile sends a SystemRequest with RequestType BATCH_RPC and a file reference to the successful PutFile
* Core validates and processes the BATCH_RPC file that was provided by the mobile and constructs a BATCH_RPC response file based on request results 
* <- Core sends an OnSystemRequest Notification containing a formatted file with RPC responses

To provide further clarity, part of the intent in sending a single file across to core for processing is to free up blocked incoming and outgoing message queues when sending and receiving thousands of RPC messages.  In addition, the file format utilized could be compressed which would provide more efficiency when compared to sending raw data through protocol messages to core.

Please see included Batch_RPC_processing.png for process & state diagram details. 
https://github.com/FordDev/sdl_evolution/blob/nnnn-batch-rpc-processing/Batch_RPC_processing.png

## Detailed Design

### Changes to Mobile API and HMI_API
  ```xml
  <enum name="RequestType">
    <description>Enumeration listing possible asynchronous requests.</description>
    <element name="HTTP" />
    <element name="FILE_RESUME" />
    <element name="AUTH_REQUEST" />
    <element name="AUTH_CHALLENGE" />
    <element name="AUTH_ACK" />
    <element name="PROPRIETARY" />
    <element name="QUERY_APPS" />
    <element name="LAUNCH_APP" />
    <element name="LOCK_SCREEN_ICON_URL" />
    <element name="TRAFFIC_MESSAGE_CHANNEL" />
    <element name="DRIVER_PROFILE" />
    <element name="VOICE_SEARCH" />
    <element name="NAVIGATION" />
    <element name="PHONE" />
    <element name="CLIMATE" />
    <element name="SETTINGS" />
    <element name="VEHICLE_DIAGNOSTICS" />
    <element name="EMERGENCY" />
    <element name="MEDIA" />  
    <element name="FOTA" />
    <element name="BATCH_RPC" /> <!--New item added to this enum-->
  </enum>
  ```


## Impact on existing code

### Compatibility
Since we are adding an item to the existing RequestType enum (without changing other enums), existing SystemRequest functionality should not be impacted.

### [iOS][github_sdl_ios] and [Android][github_sdl_android] SDK
* Add batch file construction
* Update SystemRequest and OnSystemRequest for BATCH_RPC request type
* Add result batch data processing

### [Core][github_sdl_core]
* Add new [component][core_sad_components] - *BatchRequestController* with a following logic:
    * Verification Mobile batch file
    * Parsing batch file into existing [Commands][core_sad_components_commands]
        * *Note:* for following current commands restrictions and rules
    * Construction batch file to HMI
    * Exchange SystemRequest(BATCH_RPC) with HMI
    * Waiting HMI batch file processing results
    * Verification batch file from HMI
    * Construction batch file to Mobile
    * Sending OnSystemRequest Notification to Mobile
* Update [Command component][core_sad_components_commands] with SystemRequest(BATCH_RPC) and OnSystemRequest(BATCH_RPC) logic
* Update [Application Manager][core_sad_components_am] for processing batch and single RPCs in the common way

### [HMI][github_sdl_hmi]
* Update SystemRequest and OnSystemRequest for BATCH_RPC request type
* Add batch file processing
* Add batch result file construction

### [Policy Cloud][github_sdl_server] data
* Update allowance BATCH_RPC request type for SystemRequest

[github_sdl_ios]: https://github.com/smartdevicelink/sdl_ios
[github_sdl_android]: https://github.com/smartdevicelink/sdl_android
[github_sdl_core]: https://github.com/smartdevicelink/sdl_core
[github_sdl_hmi]: https://github.com/smartdevicelink/sdl_hmi
[github_sdl_server]: https://github.com/smartdevicelink/sdl_server
[core_sad_components]: https://smartdevicelink.com/en/guides/core/software-architecture-document/components-view/
[core_sad_components_commands]: https://smartdevicelink.com/en/guides/core/software-architecture-document/components-view/#commands
[core_sad_components_am]: https://smartdevicelink.com/en/guides/core/software-architecture-document/components-view/#application-manager


## Alternatives considered
Adding new RPC's to allow for arrays of RPC's like ChoiceSets and AddCommands was briefly considered, however the BATCH_RPC flow provides a more generic and suitable approach for usability and long-term maintenance.
