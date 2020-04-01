# App Service - Messaging
* Proposal: [SDL-0294](0294-app-service-messaging.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **In Review**
* Impacted Platforms: [Core / iOS / Java Suite / HMI / Policy Server / Developer Portal / RPC]

## Introduction
This proposal adds a new "messaging" app service for apps that provide messaging features.

## Motivation
We should provide app services for common app types that can integrate with the head unit or other SDL applications. Messaging apps are a big part of any user's life in the vehicle and could include dedicated chat apps (like Facebook Messenger), apps with a chat component (like Twitter DMs or replies), e-mail apps and more. We should provide additional ways for these apps to integrate with the system.

## Proposed solution
The proposed solution adds a messaging `AppServiceType` and associated app service manifests and data. This also adds the ability for consumer apps to send messages using messaging app service providers using a new `SendMessage` RPC and associated changes. 

### Messaging App Service (MOBILE_API / HMI_API Changes)
```xml
<enum name="AppServiceType" platform="documentation">
    <!-- Existing values -->
    <element name="MESSAGING" />
</enum>

<struct name="MessagingServiceManifest">
</struct>

<struct name="MessagingServiceData">
    <description> This data is related to what a messaging service would provide </description>
    <param name="recentMessageThreads" type="MessageContact" array="true" minSize="1" maxSize="100" mandatory="false" />
</struct>

<struct name="MessageContact">
    <param name="name" type="String" maxlength="500" mandatory="true">
        <description>The title / name of this group / contact for display</param>
    </param>
    <param name="contactID" type="String" mandatory="false">
        <description>A unique ID for this contact to allow consumers to send a message using the SendMessage RPC. If not provided, messages cannot be sent to this contact.</param>
    </param>
    <param name="imageName" type="String" maxlength="255" mandatory="false">
        <description>An already uploaded image for this contact for display.</param>
    </param>
    <param name="numUnreadMessages" type="Integer" minValue="0" maxValue="9999999" mandatory="true">
        <description>If provided, the number of messages that are unread in this group.</description>
    </param>
    <param name="openInAppCallbackUri" type="String" mandatory="false">
        <description>If provided, this is a URI string that should be sent using PerformAppServiceInteraction serviceUri to open the message group in the providing app. The head unit should make the service active and open the app. If not present, assume no action can be taken.</description>
    </param>
    <param name="isGroup" type="Boolean" mandatory="false">
        <description>If true, this contact relates to a group with more than two members (where one is the current user), if false, the message relates to only one other person. If not present, assume false.</description>
    </param>
    <param name="mostRecentMessage" type="Message" mandatory="false">
        <description>Details about the most recent message in the chat for previewing purposes.</description>
    </param>
</struct>

<struct name="Message">
    <param name="isIncoming" type="Boolean" mandatory="true">
        <description>If true, the message is incoming from the other contact, if false, the message is outgoing.</description>
    </param>
    <param name="messageText" type="String" minLength="1" maxLength="500" mandatory="false">
        <description>The text of the most recent message or some preview text of the message.</description>
    <param>
</struct>
```

### SendMessage RPC
The `SendMessage` RPC will be created to allow messaging app service consumers to send a message to a contact via a messaging app service provider. If the `MessageContact` does not have a `contactID`, a message cannot be sent to that user. If the app service provider does not support `SendMessage`, no messages can be sent through this provider.

The active service will receive this request if it is sent via normal RPC channels. If sent via `PerformAppServiceInteraction`, a non-active messaging provider can be specified.

```xml
<function name="SendMessage" functionID="SendMessageID" messagetype="request" since="X.X">
    <description>Request for sending a message to a contact</description>
    <param name="contactID" type="String" mandatory="true">
        <description>The contactID retrieved from the app service's MessageContact struct</description>
    </param>
    <param name="messageText" type="String" mandatory="true"/>
</function>

<function name="SendMessage" functionID="SendMessageID" messagetype="response" since="X.X">
    <param name="success" type="Boolean" platform="documentation" mandatory="true">
        <description> true, if successful; false, if failed </description>
    </param>       
        
    <param name="resultCode" type="Result" platform="documentation" mandatory="true">
        <description>See Result. All results will be available for this response.</description>
    </param>
    
    <param name="info" type="String" maxlength="1000" mandatory="false" platform="documentation">
        <description>Provides additional human readable info regarding the result.</description>
    </param>
</function>
```

#### HMI_API
This will be identical to the above, in the `AppService` interface.

### PerformAppServiceInteraction Updates (MOBILE_API + HMI_API)
To enable the `callback` parameter above, we need an extension to `PerformAppServiceInteraction` to bring the app to the foreground directly to the place the user wants to be (e.g. to see the message thread that just had a new message).

We are also adding an RPC request parameter to the `PerformAppServiceInteraction` request, and an RPC response parameter to the response. This allows us to send a `SendMessage` RPC request / response pair to a particular app service while telling the app service about the origin app (to verify which app is trying to send a message, for example).

```xml
<function name="PerformAppServiceInteraction" functionID="PerformAppServiceInteractionID" messagetype="request">
	<!-- Existing Parameters -->
    ...

    <!-- New Parameters -->
    <param name="bringToForeground" type="Boolean" mandatory="false" since="X.X">
        <description>If true, the HMI should bring this app to HMI_FULL before sending it the serviceUri.</description>
    </param>

    <param name="rpcRequest" type="String" mandatory="false">
        <description>A stringified version of an RPC request. Only RPCs defined in the RPC spec should be used.</description>
    </param>
</function>

<function name="PerformAppServiceInteraction" functionID="PerformAppServiceInteractionID" messagetype="response">
    <!-- Existing parameters -->
    ...

    <!-- New parameters -->
    <param name="rpcResponse" type="String" mandatory="false">
        <description>A stringified version of an RPC response. Only RPCs defined in the RPC spec should be used.</description>
    </param>
</function>
```

### GetAppServiceData Updates (MOBILE_API + HMI_API)
To enable consumer apps to subscribe to inactive services' app data, we will extend `GetAppServiceData` with a `serviceID` parameter.

```xml
<function name="GetAppServiceData" functionID="GetAppServiceDataID" messagetype="request" since="5.1">
    <!-- Existing Parameters -->
    ...

    <!-- New Parameters -->
    <param name="serviceID" type="String" mandatory="false" since="X.X">
        <description>If set, this will return data from the specified service. If not set, this will return data from the active service, if there is one.</description>
    </param>
</function>
```

## Potential downsides
1. Currently, only one service can be "active" at a time, which means that only one app can have its data subscribed to. However, for this app service, we want the head unit to display data from multiple apps, e.g. if the user has two messaging apps and an email app installed, they may want to see when a combined count of unread messages. This is currently not a supported case with app services, and to properly support this service, we should add a way to subscribe to inactive services. However, the author considers this out of scope of the current proposal.

2. When a messaging app sends messages with `messageText`, this means that the user's message data will be available to any app consumer. This parameter is optional, however, which means that the developer can choose not to provide the message text if desired or if the text is sensitive.

3. There is the potential for bad actor apps to send spam messages using `SendMessage`. Access to this RPC should be restricted using policy table functional groups and the developer portal to prevent bad apps from spamming a user's contacts.

## Impact on existing code
This would have impact on the RPC spec, which impacts Core and all app libraries. Additionally, changes will need to be made to the Policy Server and Developer Portal for this new app service  and RPC to add a new request from developers to use the `MESSAGING` app service and for consumers to use the `SendMessage` RPC, since that RPC allows for potential spam.

## Alternatives considered
1. ~~We could add subscribing to inactive services to this proposal as well since it would greatly improve this feature, however the author considered it out of scope for this proposal.~~ **INCORPORATED**
2. We could add the ability to have multiple active services instead of (1).
