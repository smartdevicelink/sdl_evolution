# Facilitating OEM Communication with App Developers

* Proposal: [SDL-NNNN](NNNN-developer-oem-communication.md)
* Author: [Nick Schwab](https://github.com/nickschwab), [Jonathan Cooper](https://github.com/jnthncpr)
* Status: **Awaiting review**
* Impacted Platforms: [SHAID / Developer Portal]

## Introduction

The goal of this proposal is to provide OEMs and application developers a simple, intuitive, and organized way to communicate with each other for the purpose of evaluating an application before making it available on the OEM customers' head units.

## Motivation and Desired Outcome

Currently, OEMs are offered a simple form via the [SDL Developer Portal](https://smartdevicelink.com) which sends an email to the selected application developer. However, this method does not allow for the tracking and organization of specific issues an OEM has identified with an application on their head units, fragments the SDL developer experience by requiring the use of an external communication method (email) for additional follow-up, and creates a high risk of leaving important stakeholders out of the communication loop.

Ideally, all communication between an OEM and an application developer should be viewable and actionable from the [SDL Developer Portal](https://smartdevicelink.com). From the Developer Portal, OEMs should be able to:
* Initiate, view, and reply to general text-based messages from an application developer
* Open issues against an app - each with a title, description, and whether or not the issue should be public to other OEMs
* See all open and closed issues for the app which were either created by the OEM or made public by another OEM
* Close self-authored issues that have been deemed solved or irrelevant
* Re-open self-authored closed issues
* Mark an open self-authored issue as resolved or unresolved
* Exchange text-based messages with the app developer regarding a specific issue
* Delete any self-authored text-based message

App developers should be able to:
* Initiate, view, and reply to general text-based messages from an OEM
* See all open and closed issues against their app
* Mark an open issue as resolved or unresolved
* Exchange text-based messages with the OEM regarding a specific issue
* Delete any self-authored text-based message

SDLC Administrators should be able to:
* See the opened and closed issues for each app, but not the messages exchanged within them

## Proposed solution

### Overview
The proposed solution is to create an administrative enhancement to SHAID to support the creation, retrieval, updating, and deletion (as appropriate) of text-based messages and issues between an OEM and app developer with the behavior defined above. This would require the following new APIs which would be utilized by the Developer Portal:

* POST `/application/message`: creates a new text-based message for an application-level thread
* DELETE `/application/message`: deletes a target text-based message for an application-level thread
* GET `/application/message`: retrieves text-based messages for an application-level thread

* POST `/application/issue`: creates a new issue for an application
* GET `/application/issue`: retrieves issues for an application
* PUT `/application/issue`: update an issue as resolved, unresolved, closed, or open

* POST `/application/issue/message`: creates a new text-based discussion message for a specific issue
* DELETE `/application/issue/message`: deletes a target text-based discussion message for a specific issue
* GET `/application/issue/message`: retrieves text-based messages for a specific issue

### Data Storage
The data for these new features would be stored in new relational tables in the existing SHAID Postgres database, as follows:
* `application_vendor_message`: stores an auto-generated ID, which application the message is regarding, which OEM (vendor) thread the message is associated with, who the message is from (OEM or app developer vendor ID), the name of the individual who authored the message, the message contents, creation time, deletion time
* `application_issue`: stores a globally-unique auto-generated ID, an application-specific unique auto-generated ID, which application the issue is regarding, which OEM (vendor) created the issue, the issue title, description, whether it is accessible by other OEMs, it's opened/closed status, it's resolved/unresolved status, creation time, updated time
* `application_issue_message`: stores an auto-generated ID, which issue ID the message is targeted to, who the message is from (OEM or app developer vendor ID), the message type ('DISCUSSION', 'RESOLVED', 'UNRESOLVED', 'CLOSED', 'OPENED'), the name of the individual who authored the message, the message contents, creation time, deletion time

### User Interface
App developers and granted OEMs to be able to partake in general discussion with each other about an app through "Chat".
![app-chat][app-chat]

App developers and granted OEMs will be able to see a list of issues for an app. OEMs will see issues that were self-authored or shared by another OEM. App developers will see all issues for their app authored by any granted OEM.
![issue-list][issue-list]

App developers and granted OEMs will be able to view the details of the issue and participate in an issue-specific discussion. The authoring OEM is able to discuss, close, re-open, resolve, and un-resolve the issue. Other OEMs may only participate in the discussion. The app developer may participate in the discussion and mark the issue as resolved or un-resolved.
![issue-view][issue-view]

Granted OEMs may open new issues against an app and select whether or not they would like the issue to be shared with other authorized OEMs.
![issue-create][issue-create]

## Impact on Existing Code
This is a new addition to the SHAID database and APIs, so it would have no direct impact on existing SHAID tables and APIs. However, the features outlined in this proposal - regardless of the implementation method chosen - would require several modifications and additions to the Developer Portal user interface, as well as nominal back-end changes to the Developer Portal to call the appropriate SHAID APIs. This includes removing the legacy app developer contact email form which exists today and creating new pages and navigation elements to support the new enhanced functionality. Please see the `User Interface` section above for visual design previews of the proposed solution.

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

[app-chat]: ../assets/proposals/NNNN-developer-oem-communication/chat.png
[issue-list]: ../assets/proposals/NNNN-developer-oem-communication/issue-list.png
[issue-view]: ../assets/proposals/NNNN-developer-oem-communication/issue-view.png
[issue-create]: ../assets/proposals/NNNN-developer-oem-communication/issue-create.png
