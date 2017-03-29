# External Policy Manager

* Proposal: [SDL-0045](0045-external-policy-manager.md)
* Author: [Jack Byrne](https://github.com/JackLivio)
* Status: **In Review**
* Impacted Platforms: [Core]

## Introduction

This proposal is for the addition of an example external policy manager to the sdl core repository. The external policy manager is an application/service that runs on the vehicle’s head unit and is responsible for encrypting/decrypting policy table data when a policy table update takes place.

## Motivation

The 4.3 release candidate for SDL Core includes a new flag “EXTENDED_POLICY” that can be set to one of three configurations:
HTTP
PROPRIETARY
EXTERNAL_PROPRIETARY

The “EXTERNAL_PROPRIETARY” option is probably the recommended policy configuration for production vehicles since it is the only build configuration that allows for the encryption/decryption of policy table data during a policy table update.

[This flowchart shows a complete policy table update sequence between SDL Core, the HMI, and a mobile device.](https://cloud.githubusercontent.com/assets/11158563/23221356/885931ec-f92d-11e6-9cd7-37f7de8197fd.png)


In the chart the “HMI” is essentially the rest of the head unit’s software components outside of SDL Core.

This sequence requires the HMI to encrypt the policy table and create the HTTP request header before sending a snapshot of the current policy table to the sdl server. After receiving the new policy table data from the sdl server, the HMI must decrypt the policy table data for Core to be able to complete the policy table update. 

Currently the tasks of the HMI encrypting the policy table snapshot, creating the HTTP request header, and decrypting the returned policy table data is expected to be implemented by integrators on there own since this functionality does not exist in any of the SDL repositories.


## Proposed solution

The solution is to include an example “external policy manager” to be run with sdl core and the sdl web hmi. The example program would be a python script that talks to the web hmi over websockets. When the HMI receives a PolicyUpdate rpc from sdl core, it will tell the external policy manager to encrypt the file at the path sent from core. The policy manager will the create the http request header with the encrypted policy data as the HTTP request body. The policy manager will write the complete http request to a file and pass that file path back to the web hmi, which will then initiate an onSystemRequest to sdl core.

When the web hmi receives a SystemRequest message from core, the web hmi will need to tell the external policy manager to decrypt the new policy table data returned from the sdl server. The policy manager will tell the web hmi the file path of the newly decrypted policy table data and the hmi will send an OnReceivedPolicyUpdate to core with the file path as a parameter.

## Potential downsides

This is not a production ready feature and OEM’s will need to recreate their own external policy manager with proprietary methods of encrypting and decrypting policy table data. This external policy manager would only serve as an example for future integrators.

## Impact on existing code

No changes to the sdl core code itself, but I would like for this sample external policy manager to live in the sdl core repository instead of maintaining it in its own separate repository. The python script would be integrated into the sdl core configuration/compilation process so that a policy manager executable will be built without extra setup needed for the developer. I would also suggest the addition of a startup script for core that would start the core application and the external policy manager at the same time.  

Adjustments to the web hmi will need to be made to support connections to the external policy manager, as well as the ability to request for the encryption/decryption of the policy table data.

Adjustments will need to be made to the sdl server to encrypt/decrypt policy table data received from SDL during a policy table update sequence.

## Alternatives considered

I considered adding this functionality directly to the web hmi but it is not possible to read/write/modify files only using client side javascript.
