# Facilitating OEM Communication with App Developers

* Proposal: [SDL-NNNN](NNNN-developer-oem-communication.md)
* Author: [Nick Schwab](https://github.com/nickschwab), [Jonathan Cooper](https://github.com/jnthncpr)
* Status: **Awaiting review**
* Impacted Platforms: [SHAID / Developer Portal]

## Introduction

The goal of this proposal is to provide OEMs and application developers a simple, intuitive, and organized way to communicate with each other for the purpose of establishing a business relationship, discussing the application's journey through certification, and to follow up about any issues discovered during the application's lifecycle.

## Motivation

Currently, OEMs are offered a simple form via the [SDL Developer Portal](https://smartdevicelink.com) which sends an email to the selected application developer. However, this method does not allow for the tracking and organization of specific issues an OEM has identified with an application on their head units, fragments the SDL developer experience by requiring the use of an external communication method (email) for additional follow-up, and creates a high risk of leaving important stakeholders out of the communication loop.

Ideally, all communication between an OEM and an application developer should be viewable and actionable from the [SDL Developer Portal](https://smartdevicelink.com). From the Developer Portal, OEMs should be able to:
* Initiate, view, and reply to general text-based messages from an application developer
* Open issues against an app - each with a title, description, and whether or not the issue should be public to other OEMs
* See all open and closed issues for apps which were either created by the OEM or made public by another OEM
* Close self-authored issues that have been deemed solved or irrelevant
* Re-open self-authored closed issues
* Exchange text-based messages with the app developer regarding a specific issue
* Delete any self-authored text-based message

App developers should be able to:
* Initiate, view, and reply to general text-based messages from all OEMs
* See all open and closed issues against their app
* Exchange text-based messages with the OEM regarding a specific issue
* Delete any self-authored text-based message

SDLC Administrators should be able to:
* See the opened and closed issues for each app, but not the messages exchanged between OEMs and app developers

## Proposed solution

### Overview
The proposed solution is to create an administrative enhancement to SHAID to support the creation, retrieval, updating, and deletion (as appropriate) of text-based messages and issues between an OEM and app developer with the behavior defined above.

This would require the following new APIs which would be utilized by the Developer Portal:

* POST `/application/message`: creates a new text-based message for an application-level thread
* DELETE `/application/message`: deletes a target text-based message for an application-level thread
* GET `/application/message`: retrieves text-based messages for an application-level thread

* POST `/application/issue`: creates a new issue for an application
* GET `/application/issue`: retrieves issues for an application
* PUT `/application/issue`: update an issue as closed or open

* POST `/application/issue/message`: creates a new text-based discussion message for a specific issue
* DELETE `/application/issue/message`: deletes a target text-based discussion message for a specific issue
* GET `/application/issue/message`: retrieves text-based messages for a specific issue

And modifications for existing APIs as follows:

* GET `/application`: to retrieve applications with a negative OEM allowance filter (that is, retrieve SDLC-certified applications which have not been granted access to a specific OEM by the app developer)
* GET `/vendor`: to retrieve vendors with a negative OEM allowance filter ()

### Data Storage
The data for these new features would be stored in new relational tables in the existing SHAID Postgres database, as follows:
* `application_vendor_message`: stores an auto-generated ID, which application the message is regarding, which OEM thread the message is associated with, who the message is from (OEM or app developer ID), the name of the individual who authored the message, the message contents, creation time, deletion time
* `application_issue`: stores a globally-unique auto-generated ID, an application-specific unique auto-generated ID, which application the issue is regarding, which OEM created the issue, the issue title, description, whether it is accessible by other OEMs, it's opened/closed status, creation time, updated time
* `application_issue_message`: stores an auto-generated ID, which issue ID the message is targeted to, who the message is from (OEM or app developer ID), the message type ('DISCUSSION', 'CLOSED', 'OPENED'), the name of the individual who authored the message, the message contents, creation time, deletion time

### User Interface
By taking a custom-built approach, the SDLC is able to retain more control of the OEM and developer experiences for greater flexibility and ease-of-use. Since the proposed solution does not rely on any third-party integrations, the features would be instantly available to all OEMs and application developers without requiring additional setup/configuration from them. Please see the proposed design illustrations below.

#### Starting a Conversation
To start a conversation (general or issue-specific), an OEM must first select which application they wish to discuss. Similarly, an app developer must first select which OEM they would like to talk with.

#### General App Chat
App developers and granted OEMs to be able to partake in general discussion with each other about an app through "Chat".

![app-chat-oem][app-chat-oem]
> From an OEM's perspective

![app-chat-dev][app-chat-dev]
> From an app developer's perspective

App developers and OEMs will select which opposite party they wish to talk to via the following interfaces.

![catalog-of-apps][catalog-of-apps]
> From an OEM's perspective, choosing an app

![catalog-of-oems][catalog-of-oems]
> From an app developer's perspective, choosing an OEM

#### App Issue List
App developers and granted OEMs will be able to see a list of issues for an app. OEMs will see issues that were self-authored or shared by another OEM. App developers will see all issues for their app authored by any granted OEM.

![issue-list-oem][issue-list-oem]
> From an OEM's perspective

![issue-list-dev][issue-list-dev]
> From an app developer's perspective

#### Viewing an App Issue
App developers and granted OEMs will be able to view the details of the issue and participate in an issue-specific discussion. The authoring OEM is able to discuss, close, and re-open the issue. The app developer and other OEMs (if the issue is shared with all OEMs) may only participate in the discussion of the issue.

![issue-view-oem][issue-view-oem]
> From an OEM's perspective

![issue-view-dev][issue-view-dev]
> From an app developer's perspective

#### Create an App Issue
Granted OEMs may open new issues against an app and select whether or not they would like the issue to be shared with other authorized OEMs.

![issue-create-oem][issue-create-oem]
> From an OEM's perspective

## Impact on Existing Code
This is a new addition to the SHAID database and APIs, so it would have no direct impact on existing SHAID tables and APIs. However, the features outlined in this proposal - regardless of the implementation method chosen - would require several modifications and additions to the Developer Portal user interface, as well as minor back-end changes to the Developer Portal to call the appropriate SHAID APIs. This includes removing the legacy app developer contact email form which exists today and creating new pages and navigation elements to support the new enhanced functionality. Please see the `User Interface` section above for visual design previews of the proposed solution.

## Potential Downsides
As a custom-built solution, the downsides are:
* Requires custom maintenance and incremental improvements
* Potentially longer implementation time than an off-the-shelf solution
* Nominal increase in ongoing database storage

## Alternatives Considered
Several alternatives were considered to store and manage messages and issues for each application instead of a custom solution through SHAID. The primary downsides of most of these alternatives are:

* Requires all Developer Portal users to create accounts on a third-party service
* Requires all Developer Portal users to link their third-party service account to their Developer Portal account
* Results in occasional communication by the third-party service without the knowledge/authorization of the SDLC
* Risk of user terminating their third-party service account
* Risk of third-party modifying their service offerings or pricing

Brief evaluations of each specific alternative below:

### GitHub
GitHub offers a comprehensive API to manage repositories, issues, and issue comments, but their documentation is noted with a message that reads:

>The API may change without advance notice during the preview period. Preview features are not supported for production use.

GitHub uses oauth2 for authentication, which would require OEM and app developer users of the Developer Portal to have GitHub accounts and link them to their SDL Developer Portal account. Free private repositories on GitHub only allow 3 collaborators, which would be problematic for apps built by larger teams and/or OEMs with multiple reviewers.

### GitLab
Similar to GitHub, GitLab also offers a comprehensive oauth2-powered API to manage repositories ("projects"), issues, and issue comments ("issue notes"). There are no limits to the number of private repositories or collaborators, but the friction of requiring all Developer Portal users to register for a GitLab account and link it to the Developer Portal would be a considerable barrier to the user experience.

### Trello
Trello offers an oauth-based API capable of managing boards, lists, cards, and card comments. There are no documented limits to the number of boards, board members, or lists. Similar to GitHub and GitLab, users would be required to sign up for Trello and link their Trello account to the Developer Portal. Members added to a Trello board via API would likely receive an email from Trello with a direct link to the board, along with other Trello-specific emails.

### Open-source Forum Software
There are various open-source forum (or forum-like) solutions which we could host such as NodeBB, phpBB, myBB, Discourse, etc, but in my investigation I was only able to find one (Discourse) which offers a comprehensive, documented API. These out-of-the-box generic solutions contain many features which we would likely never use (read: overcomplicated; technical debt), are mostly built upon older technology stacks (PHP, MySQL, Apache) than the rest of SDL's infrastructure, and would likely require heavy customization to achieve seamless integration into the Developer Portal.

[catalog-of-apps]: ../assets/proposals/NNNN-developer-oem-communication/catalog-of-apps.jpg
[catalog-of-oems]: ../assets/proposals/NNNN-developer-oem-communication/catalog-of-oems.jpg

[app-chat-oem]: ../assets/proposals/NNNN-developer-oem-communication/app-chat-oem.jpg
[issue-list-oem]: ../assets/proposals/NNNN-developer-oem-communication/issue-list-oem.jpg
[issue-view-oem]: ../assets/proposals/NNNN-developer-oem-communication/issue-view-oem.jpg
[issue-create-oem]: ../assets/proposals/NNNN-developer-oem-communication/issue-create-oem.jpg

[app-chat-dev]: ../assets/proposals/NNNN-developer-oem-communication/app-chat-dev.jpg
[issue-list-dev]: ../assets/proposals/NNNN-developer-oem-communication/issue-list-dev.jpg
[issue-view-dev]: ../assets/proposals/NNNN-developer-oem-communication/issue-view-dev.jpg
