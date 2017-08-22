# SDL Policy Server Enhancements

* Proposal: [SDL-0077](0077-sdl-policy-server-enhancements.md)
* Author: [Christopher Rokita](https://github.com/crokita), [Nick Schwab](https://github.com/nickschwab), and [Joey Grover](https://github.com/joeygrover)
* Status: **Accepted**
* Impacted Platforms: [Policy Server]

## Introduction

This proposal addresses the current state of the policy server template and how it can be improved upon so that OEMs can have a production ready policy server implementation.

## Motivation
The current policy server example on Github is severely limited in functionality. The current implementation raises many questions by OEMs looking to host their own copy of a policy server. The policy server example currently lacks integration with SHAID, and fails to offer an intuitive way to change any aspect of the policy table. The proposed changes below will address these concerns.

## Proposed solution

#### About
The policy server will be written in NodeJS. It will replace the old sdl_server project currently on Github. The release of this new policy server will be developed over multiple stages. This proposal describes only the initial stage of the project; more proposals will follow that build out the project (front end UI, encryption, etc).

#### SHAID Integration
The server will communicate with SHAID through its APIs.  This includes returning the initial list of apps during setup. It also includes getting alerts when applications have been modified as reported by through the developer portal. The authentication keys, accessible via the developer portal, can be used to authenticate the policy server with SHAID. A wrapper for calling the SHAID API will be available as a node module on the npm registry. Anyone will be able to download it for use, and the SDL Policy Server will use it to interact with SHAID. 

#### Data Storage and Versioning
The server will be able to connect to a SQL database by default for storing application version history, policy table component history, and other data. It will be designed to easily support multiple SQL database engines by being limited to using basic SQL commands. 

There will be database migration scripts which allow easy use of setting up and tearing down the tables. There will also be initial data created that is necessary for the policy server to function. Static tables such as languages, RPC names and vehicle data component names will be defined, and initial data creation will include consumer friendly messages and the module config from the default policy table. Another piece of the initial data will be generated through SHAID API calls, which include category names and country information. The pieces of the policy table stored will be designed to be extendable for other OEMs who wish to add their own information to their database. The structure of the tables will be documented and posted on the policy server github.

Lastly, the versioning system will have two independent fields. There will be a unique ID for data such as the module config object and the function groups object so that many different objects can be created. Secondly, there will be a status field for these versioned objects that determine whether they should exist on production or in a testing state. Therefore, there will be a staging version and a production version of a policy table that can be used.

#### Permitting Apps
The server will be configurable to react differently when an app's information changes. For example, the policy server could automatically approve all future versions of an app once it has been approved once, or a change in the app's information could warrant a re-approval every time. Determining whether an app will get these permissions will also exist.

The first iteration of the policy server will have a system of approval that is as simple as it can be. A route will be exposed by the server that will allow the user's browser to show all pending application permission requests. Only application requests that are in the pending state and are the most recent version will be displayed. An approve and deny button will be displayed for each application request. For this iteration, the developer will not be notified when a decision is made on the application request; custom logic will be necessary for notifications to happen over email, for instance. 

The method of authentication will involve specifying a secret string as an environment variable to the policy server. When a user accesses the webpage of app requests they will need to match the secret string correctly in order to continue.

#### Policy Table Creation
All apps requesting permission that have approval will cause the policy server to automatically create a policy table that gives precisely the permissions the applications asked for and return it in response to a policy table request. 

The server will be able to generate policy tables in a staging context and in a production context. In a production context, only apps that have been chosen to be approved will be allowed permissions. In a staging context, all apps approved or pending will be allowed permissions.

All functional groups that are necessary to allow specific RPC and vehicle data permissions will be automatically created by the policy server when using the migration up script. Therefore, the policy server user will never need to deal with creating and assigning function groups on their own.

## Potential downsides

One downside is that OEMs would still need to host and maintain their policy server on their own. However, since each OEM may have different security requirements in their organization, having a hosted solution may violate some of their internal policies or create unnecessary complications for SDL project maintainers.

Another argument is that some may find the policy server template to be too opinionated in how it approaches data storage and how it suggests the approval process of applications should function. Since this is an open-source repository, OEMs are free to build additional modules to support or alter functionality.

## Impact on existing code

The changes proposed will involve replacing the current template with a new one. Since each OEM manages their own policy server with no intention of merging their changes back to the repository, the effects caused by replacing the old code will have no impact on existing clones of the policy server. 

## Alternatives considered

OEMs would either have to write a custom integration with SHAID and a solution to manage policy tables from scratch or simply not use the policy feature. Our goal is to limit the amount of effort required by OEMs to adopt SDL.
