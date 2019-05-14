# Update Published App Services

* Proposal: [SDL-0225](0225-update-published-app-services.md)
* Author: [Jacob Keeler](https://github.com/jacobkeeler)
* Status: **Accepted with Revisions**
* Impacted Platforms: [Core / iOS / Java Suite / Policy Server / SHAID / RPC]

## Introduction

Currently there is no way for an application to update the manifest of an app service or manually unpublish this service once it has been published. This proposal will detail the additions necessary to support this functionality.

## Motivation

In the original [App Services proposal](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0167-app-services.md#notifying-potential-consumers), a `MANIFEST_UPDATE` value was included in the `ServiceUpdateReason` enum to be used when an app service was updated. The proposal did not detail a way to trigger this update reason, however, and as a result the enum was left unused in the initial implementation of the feature.

In addition, the `REMOVED` value for `ServiceUpdateReason` is only used when an application is unregistered, leaving no way to manually remove an app service once it has been published.

## Proposed solution

The simplest way to allow an app to update the manifest of a service it published is to extend the `PublishAppService` RPC. After receiving a `PublishAppService` SDL Core will check if this application has already published a service of this type. If such a service was already published, Core would overwrite the existing manifest for that service (rather than publish a new service) and send a `OnSystemCapabilityUpdated(APP_SERVICES, MANIFEST_UPDATE)` notification if the manifest was changed as a result.

To unpublish an already published service, a new RPC will need to be introduced, `UnpublishAppService`:

```
    <enum name="FunctionID" internal_scope="base" since="1.0">
        ...
        
        <element name="UnpublishAppServiceID" value="XX" hexvalue="XX" since="X.X" />
    </enum>

    <function name="UnpublishAppService" functionID="UnpublishAppServiceID" messagetype="request" since="X.X">
        <description> Unpublish an existing service published by this application. </description>

        <param name="serviceID" type="String" mandatory="true">
            <description> The ID of the service to be unpublished. </description>
        </param>
    </function>
    
    <function name="UnpublishAppService" functionID="UnpublishAppServiceID" messagetype="response" since="X.X">
        <description> The response to UnpublishAppService </description>
        <param name="success" type="Boolean" platform="documentation" mandatory="true">
            <description> true, if successful; false, if failed </description>
        </param>
       
        <param name="resultCode" type="Result" platform="documentation" mandatory="true">
            <description>See Result</description>
            <element name="SUCCESS"/>
            <element name="REJECTED"/>
            <element name="DISALLOWED"/>
            <element name="INVALID_DATA"/>
            <element name="INVALID_ID"/>
            <element name="OUT_OF_MEMORY"/>
            <element name="TOO_MANY_PENDING_REQUESTS"/>
            <element name="APPLICATION_NOT_REGISTERED"/>
            <element name="GENERIC_ERROR"/>
        </param>

        <param name="info" type="String" maxlength="1000" mandatory="false" platform="documentation">
            <description>Provides additional human readable info regarding the result.</description>
        </param>
    </function>
```

## Potential downsides

This solution would not allow an application to publish multiple services of the same type in the future. Currently, SDL Core's behavior is designed with this limitation anyway, as it seems that this is an underlying assumption with the original proposal.

## Impact on existing code

The logic for `PublishAppService` would need to be updated in the Core codebase accordingly. For `UnpublishAppService`, an app should only be able to unpublish services which were published by itself, and Core would need logic to enforce this.

In the RPC spec, the `UnpublishAppService` RPC would need to be added (as described in the "Proposed Solution" section).  The description for `PublishAppService` would need to be updated:

```
    <function name="PublishAppService" functionID="PublishAppServiceID" messagetype="request" since="5.1">
        <description>
            Registers a service offered by this app on the module.
            Subsequent calls with the same service type will update the manifest for that service.
        </description>

        <param name="appServiceManifest" type="AppServiceManifest" mandatory="true">
            <description>
                The manifest of the service that wishes to be published. 
                If already published, the updated manifest for this service.
            </description>
        </param>
    </function>
```

The `UnpublishAppService` RPC would be needed to all other affected platforms.

## Alternatives considered

1. Add a new `UpdateAppService` RPC in place of using `PublishAppService` for this purpose.
