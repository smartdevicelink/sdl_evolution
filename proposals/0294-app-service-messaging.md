# App Service - Messaging
* Proposal: [SDL-0294](0294-app-service-messaging.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **In Review**
* Impacted Platforms: [Core / iOS / Java Suite / HMI / Policy Server / Developer Portal / RPC]

## Introduction
This proposal adds a new "messaging" app service for apps that provide messaging features.

## Motivation
We should provide app services for common app types that can integrate with the head unit or other SDL applications. Messaging apps are a big part of any user's life in the vehicle and could include dedicated chat apps (like Facebook Messenger), apps with a chat component (like Twitter DMs or replies), or even e-mail apps and more. We should provide additional ways for these apps to integrate with the system.

## Proposed solution

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
    <param name="recentMessageThreads" type="MessageContact" mandatory="false" />
</struct>

<struct name="MessageContact">
    <param name="name" type="String" maxlength="500" mandatory="true" />
    <param name="imageName" type="String" maxlength="255" mandatory="false" />
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

### PerformAppServiceInteraction Extensions
To enable the `callback` parameter above, we need an extension to `PerformAppServiceInteraction` to bring the app to the foreground directly to the place the user wants to be (e.g. to see the message thread that just had a new message).

```xml
<function name="PerformAppServiceInteraction" functionID="PerformAppServiceInteractionID" messagetype="request">
	<!-- Existing Parameters -->
    <param name="bringToForeground" type="Boolean" mandatory="false">
        <description>If true, the HMI should bring this app to HMI_FULL before sending it the serviceUri.</description>
    </param>
</function>
```

## Potential downsides
1. Currently, only one service can be "active" at a time, which means that only one app can have its data subscribed to. However, for this app service, we want the head unit to display data from multiple apps, e.g. if the user has two messaging apps and an email app installed, they may want to see when a combined count of unread messages. This is currently not a supported case with app services, and to properly support this service, we should add a way to subscribe to inactive services. However, the author considers this out of scope of the current proposal.

## Impact on existing code
This would have impact on the RPC spec, which impacts Core and all app libraries. Additionally, changes will need to be made to the Policy Server and Developer Portal for this new app service to add a new request from developers to use this app service.

## Alternatives considered
1. We could add subscribing to inactive services to this proposal as well since it would greatly improve this feature, however the author considered it out of scope for this proposal.
