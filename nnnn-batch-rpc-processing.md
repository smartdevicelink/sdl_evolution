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

For example, when an app is placed into full for the first time it is expected that all resources utilized by the app are requested for the first time and made available to the user as soon as possible -- these resources can potentially include a large number (in the thousands) of add commands and createinteractionchoicesets.  
In addition, other RPC's are also traditionally requested at startup like button subscriptions and the setting of global properties.  Similarly, at times removing a large number of resources (like deleting commands and choicesets) needs to occur very quickly. 

In the cases mentioned, sending an individual RPC request for each command is not ideal as the amount of bandwidth and time needed to process thousands of RPC requests is significant.  
A more efficient approach would be to utilize the generic data transfer flow, sending a batch file via putfile with a list of RPC's to be processed and a system request to reference the batch file.


## Proposed Solution
The solution proposed is to utilize the existing generic data transfer flow as a base and enhance the flow to include the processing of RPC's from a defined file format.  
Utilizing a batch file will reduce the number of RPC's sent and received between the mobile and core from the thousands to just a few as shown below:

Proposed Process (general happy path):
* Mobile constructs a formatted (BATCH_RPC) file of RPC requests based on app needs
* -> Mobile sends a putfile request containing the formatted file of RPC requests
* <- Core sends a putfile response signaling the success of the putfile request
* -> Mobile sends a SystemRequest with RequestType BATCH_RPC and a file reference to the successful putfile
* Core validates and processes the BATCH_RPC file that was provided by the mobile and constructs a BATCH_RPC response file based on request results 
* <- Core sends an OnSystemRequest Notification containing a formatted file with RPC responses

	
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
Since we are adding an item to the existing RequestType enum (without changing other enums), existing SystemRequest functionality should not be impacted.  
It is expected that all core side functionality outside of the new BATCH_RPC flow will remain unchanged.

## Alternatives considered
Adding new RPC's to allow for arrays of RPC's like choicesets and addcommands was briefly considered, however the BATCH_RPC flow provides a more generic and suitable approach for usability and long-term maintenance.
