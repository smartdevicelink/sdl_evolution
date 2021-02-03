# App Service Subscription Resumption

* Proposal: [SDL-0330](0330-app-service-resumption.md)
* Author: [JackLivio](https://github.com/jacklivio)
* Status: **In Review**
* Impacted Platforms: [Core]

## Introduction

This proposal is needed to define rules for how App Services should be treated during resumption.

## Motivation

The implementation of the feature [SDL 190 Handle response from HMI during resumption data](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0190-resumption-data-error-handling.md) did not include resumption logic for App Service subscriptions. During the review it was determined by Livio and Luxoft that implementing App Service subscription resumption was significantly more complex than other subscriptions that are mentioned in the original proposal. Both parties agreed that defining App Service behavior during resumption would require a proposal. 


## Proposed solution

### Consumer resumption triggers GetAppServiceData

Currently when an app is resuming and previously had an active subscription to an app service, SDL Core will internally mark the consumer as subscribed to the service type. There is no communication to the app service provider that there is at least one consumer subscribed to their app service.

Requirement #1: When an app service consumer resumes its app service subscription, SDL Core should send a GetAppServiceData request with parameter `subscribe=true` to the active app service provider. This message should be skipped if there are other consumers already subscribed to the app service provider.

### Consumer resumption of embedded providers

If an app consumer is resuming a subscription to an embedded app service provider, the author thinks it is expected that the embedded service will be available at the time of mobile resumption. Because of this assumption, Core should be more strict with restoring embedded service subscriptions.

Requirement #2: If an app consumer is resuming a subscription to an embedded service provider, that service provider must be active and available in order for resumption to be successful. If the embedded service provider unpublished its service, the resuming mobile consumer will receive a RESUME_FAILED response code for their RegisterAppInterface request.

### Consumer Resumption for Mobile Providers

If a resuming app consumers was previously subscribed to a non-embedded app service provider, SDL Core should automatically mark the subscription as active and not require the app service provider to be active at the time of resumption. The reason for allowing a softer stance for non-embedded service providers is to prevent race conditions when multiple apps are resuming that previously were app service providers or consumers. 

Requirement #3: If an app consumer is resuming a subscription to a mobile app service provider, SDL Core should not require the app service to be active at the moment of resumption. SDL Core should should mark the resuming consumer as subscribed to that specific service type.

Additional note: When resuming, SDL Core should not delay a mobile consumer's RegisterAppInterface response in an attempt to wait for a mobile app service provider to re-connect to SDL Core.

### Mobile Provider Resumption

If an app resumes and was previously an app service provider, SDL Core will restore its status as an app service provider with the same AppServiceRecord that was saved when the service was active. If there are app service consumers subscribed to the resuming provider, SDL Core will also send a GetAppServiceData request with parameter `subscribe=true`.

Requirement #4: A resuming application that was an app service provider will have its AppServiceRecord restored if resumption is successful. The app does not need to republish its app service if resuming.

Requirement #5: SDL Core should send a GetAppServiceData request with `subscribe=true` to a successfully resumed mobile app service provider if there are consumers subscribed to its app service type.

Requirement #6: SDL Core should save mobile providers' app service records in the app_info.dat to be used for resumption scenarios.

### Send Providers Unsubscribe Message

If an app service provider suddenly loses all of its consumers (ie device disconnects), SDL Core should send a GetAppServiceData request with parameter `subscribe=false`. This will let the provider know it does not need to send app service data to Core because there are no connected consumers.

Requirement #7: SDL Core should send an app service provider a GetAppServiceRequest with `subscribe=false` if all of its consumers are suddenly disconnected from SDL Core.

## Potential downsides

The only downside the author notes is that soft subscriptions for resuming mobile app service providers are used. A resuming app service consumer may be marked as subscribed to a mobile app service provider that does not reconnect to SDL Core. 

## Impact on existing code

This proposal does not require any changes to the RPC Spec or to the HMI API. All changes are contained within Core. Most changes will be contained within the class AppServiceAppExtension. SDL Core will need to:

- Update logic for sending GetAppServiceData requests to app service providers.
- Extend PendingResumptionHandler class for App Services to check the status of embedded app service providers at time of an apps resumption.
- Save app service records to app_info.dat to be used for resumption across ignition cycles.


## Alternatives considered

An alternate solution would be to require app service providers to respond to a GetAppServiceRequest with `subscribe=true` before counting a resumption by a consumer as successful. This solution was not chosen because of the complexities introduced by resuming app services from providers across different devices that may have been disconnected and reconnected to the head unit.
