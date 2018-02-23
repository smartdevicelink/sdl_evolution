# Allow clients to specify legacy nicknames

* Proposal: [SDL-0144](0144-app-nicknames.md)
* Author: [Timon Kanters](https://github.com/tvkanters) (TomTom)
* Status: **In Review**
* Impacted Platforms: [Core, Android, iOS]


## Introduction

In the [application policies](https://smartdevicelink.com/zh-hans/docs/sdl-server/master/policy-table/application-policies/), each application is assigned a list of nicknames. This field is [used in the SDL Core](https://github.com/smartdevicelink/sdl_core/blob/master/src/components/application_manager/src/commands/mobile/register_app_interface_request.cc#L925) to ensure that an app's name is valid.

When a client connects to an SDL core, app developers can currently only provide one name. In order to allow developers to update their name in the future, they should also be able to provide nicknames that they used in the past to connect to cores with outdated sets of nicknames.


## Motivation

On the [developer profile](https://www.smartdevicelink.com/profile/companies/), developers can specify which nicknames should be valid for their app IDs. However, there is no guarantee that the core's application policies are up-to-date with the latest set of nicknames provided. (E.g., when a car is not configured to have an internet connection.) If an old snapshot of this information is used by the core and a developer updates their app's name, the app would not be able to connect anymore.

For developers, there currently does not seem to be a clean way to work around this issue. It might be possible to try reconnecting to the core with older nicknames in case of a connection failure, but this is not ideal for a number of a reasons:
* Connectivity will be unnecessarily slowed down.
* The reconnection attempts may be futile because the core does not give a reason as to _why_ the connection was disallowed.
* Each app developer would need to create their own logic for this mechanism.
* If there are issues in a certain client version with creating multiple SDL proxy instances or disposing of old ones (which is not uncommon), the custom solution might not work.


## Proposed solution

When creating an SDL proxy to instantiate the connection in the client, the developer should be able to provide a list of app names instead of just a single one. This list should be in order of preference, such that preferred names precede less desired legacy names. The core should use this list to determine which name to show for the app. If the first name is in their application policies for the given app ID, it should select that. If not, it should try the second, and so on. If none of the provided names are present, the connection would be disallowed as is currently the case.

The documentation for nicknames should also be clarified and aligned across all SDL modules. That is, by reading the documentation for app names or nicknames it should be clear to developers how the names affect the authentication process and what they should consider when specifying the names. E.g., the fact that they're used for authentication along with the app ID is not apparent at all from the documentation of [application policies](https://smartdevicelink.com/zh-hans/docs/sdl-server/master/policy-table/application-policies/), [`RegisterAppInterface`](https://www.smartdevicelink.com/en/docs/android/master/com/smartdevicelink/proxy/rpc/RegisterAppInterface/) or [`SdlProxyALM`](https://www.smartdevicelink.com/en/docs/android/master/com/smartdevicelink/proxy/SdlProxyALM/). It should also be clear how the newly introduced nicknames should be used and why they're there.


## Potential downsides

The user may see an outdated name of the app in the core's UI, potentially causing confusion if the app presents itself using the new name.


## Impact on existing code

In the Android and iOS clients, we should expand the SDL proxy interface to accept a list of app names instead of just a single one. This list of app names should be sent to the core upon connection.

The core, upon connecting to a client that provides a list of app names, should use the list in the [validation process](https://github.com/smartdevicelink/sdl_core/blob/master/src/components/application_manager/src/commands/mobile/register_app_interface_request.cc#L925) instead of the regular app name.

Regarding backward/forward compatibility:
* An old client SDK version will be compatible with newer cores if the core continues accepting a single app name as is currently the case.
* An old core version will be compatible with newer client SDKs if the client SDK sends the preferred name in the list as a single, main, app name. Naturally, this will still cause a name change to break the connection for some users with older cores.


## Alternatives considered

Instead of letting the client provide a list of nicknames in the client, we could allow developers to make the nicknames field optional. This would allow them to change the name of their app at any time without leading to connectivity issues for some users. This has the added benefit of showing users an old name, but comes with the downside of allowing other apps to use others' app IDs without naming constraints.


