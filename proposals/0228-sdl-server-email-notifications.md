# SDL Server Email Notifications

* Proposal: [SDL-0228](0228-sdl-server-email-notifications.md)
* Author: [Nick Schwab](https://github.com/nickschwab)
* Status: **In Review**
* Impacted Platforms: [SDL Server]

## Introduction

The goal of this proposal is to alert an OEM when a new (or updated) application is ready for review in their SDL Server dashboard.

## Motivation

OEMs are not currently notified when a new application version is awaiting review on their SDL Server. This can result in delayed application reviews, leading to poor experiences for app developers and the OEM's customers.

## Proposed solution

Since the use of SDL Server is not required for OEMs to use the SmartDeviceLink platform, these email alerts should be configured on - and sent by - an OEM's respective SDL Server installation via SMTP.

When a new application version is received by SDL Server from SHAID and is pending review, an email alert should be immediately sent to the appropriate members of the OEM's team to encourage quick turnaround times.

The following new optional settings should be added to `settings.js` (using environment variables) for an OEM to allow SDL Server to send emails using their SMTP server:
* *host*: the hostname or IP address of the SMTP server to connect to (default `localhost`)
* *port*: the port of the SMTP server to connect to (default `25`)
* *username*: the username of the SMTP user to authorize as
* *password*: the password of the SMTP user to authorize as
* *from*: the email address mail should be sent from

Example addition to `settings.js`:
```
smtp: {
    host: "mail.oem.com",
    port: 25,
    username: "noreplysender",
    password: "sendthemails!",
    from: "no-reply@oem.com"
}
```

The following optional settings should also be added to `settings.js` to _enable_ pending application review notifications:
* *to*: A string of comma-separated email address(es) to send notifications to, e.g. `one@oem.com,two@oem.com,three@oem.com`
* *frequency*: Enumeration [REALTIME]. How frequently to send the email notifications. Only `REALTIME` is recommended in this initial proposal, but additional frequency options may be added through future proposals. `REALTIME` would send a notification upon every new application version ready for review.

Example addition to `settings.js`:
```
notifications: {
    appsPendingReview: {
        to: "app-review-team@oem.com",
        frequency: "REALTIME"
    }
}
```

Using these new settings, SDL Server should attempt to connect to the given SMTP server upon start-up and use the connection to send emails at appropriate times (as defined above with `frequency`) throughout the application's lifecycle.


#### Visual Configuration Options
To indicate whether or not these email notifications are enabled, a new indicator should be placed on the `About` tab of SDL Server, similar to the one below:

![visual-config-preview][visual-config-preview]

#### Pending App Review Email Notification

![email-preview][email-preview]
> Mock email sent when a new application version has arrived and is pending review


## Impact on Existing Code
The proposed solution has only minor impact on existing code since no APIs or key visual elements are affected. The implementation would involve connecting to an SMTP server upon startup and utilizing that connection to send email notifications asynchronously when a new application version is retrieved from SHAID and is pending review.

## Potential Downsides
* Requires OEMs to have access to an SMTP server (internal or external)
* Increases complexity of SDL Server configuration settings

## Alternatives Considered

### Send Emails from SHAID/Developer Portal
This alternative solution would require the least amount of work for OEMs to opt-in to the email notifications, but is outweighed by weaknesses:
* Cannot guarantee accuracy of which applications are still pending review by an OEM since the review process happens on an OEM's server
* Mail deliverability issues due to potential OEM firewalls
* Requires recipient list management APIs, storage, and interfaces
* Requires an opt-in confirmation process for each recipient, or requires all recipients to be a member of the OEM's company on SmartDeviceLink.com

### Provide an SDLC-owned SMTP Server with Accounts Per OEM
Although this extension of the proposed solution would reduce technical requirements of OEMs to be able to take advantage of the notification feature, it would introduce:
* Security vulnerabilities due to shared access by multiple OEMs
* Mail deliverability issues due to potential OEM firewalls
* Many senders on one server increases likelihood of high bounce rates which would harm overall deliverability

[email-preview]: ../assets/proposals/NNNN-sdl-server-email-notifications/email-preview.jpg
[visual-config-preview]: ../assets/proposals/NNNN-sdl-server-email-notifications/visual-config-preview.png
