# SDL Evolution Process
The SmartDeviceLink Consortium (SDLC) seeks the help of the community to help guide and shape how SDL changes. To do that effectively, we outline in this document a process for introducing ideas to SDL and how the SDLC Steering Committee will guide those ideas through the review process.  

The process outlined in this document should be strictly adhered to by all parties working on SDL, and any requests to diverge from the process outlined here will first require the Steering Committee to approve revisions to this document. 

## Scope
Any changes to the [SDL RPC spec](https://github.com/smartdevicelink/rpc_spec), the [SDL protocol](https://github.com/smartdevicelink/protocol_spec), enhancements or major API changes to the SDL [iOS](https://github.com/smartdevicelink/sdl_ios), [Java Suite](https://github.com/smartdevicelink/sdl_java_suite), or [JavaScript Suite](https://github.com/smartdevicelink/sdl_javascript_suite) SDKs, and [SDL Core](https://github.com/smartdevicelink/sdl_core) must go through the SDL evolution proposal and review process. An enhancement is defined as changing any behavior in a way that is different from the original definition of the behavior.  Please reference the [Proposals versus Issues document][proposals_versus_issues] for more information on what constitutes an Evolution Proposal versus a bug fix.  Major changes are defined according to [semantic versioning](http://www.semver.org).

Bug fixes should go through the normal contribution process, for example, [this is the iOS repository's process](https://github.com/smartdevicelink/sdl_ios/blob/master/.github/CONTRIBUTING.md).

If you have questions about if a particular case should be an Evolution Proposal or bug fix, please ask on [SDL Slack][sdl_slack].

## Participation
Everyone is welcome to discuss and propose new changes to SDL on the [#sdl_evolution channel][sdl_evolution_channel] on the [SDL Slack][sdl_slack]. Proposals under current review will be given an issue on the [sdl_evolution repository][sdl_evolution_repo]. Before posting a review, please read "What goes into a review?" below.

The SDLC is currently responsible for the strategic direction of SDL and will have the final say on the result of a proposal. In order to best prepare to make a decision on each proposal, all SDLC members should review and provide feedback during the designated review period.  Once a decision has been made, a rationale will always be posted along with the result of the review of a proposal.

## What goes into a review?
The goal of the review process is to improve the proposal under review through constructive criticism and, eventually, determine the direction of SDL. When writing your review, here are some questions you might want to answer in your review:

* What is your evaluation of the proposal?
* Is the problem being addressed significant enough to warrant a change to SDL?
* Does this proposal fit well with the feel and direction of SDL?
* If you have used competitors with a similar feature, how do you feel that this proposal compares to those?
* How much effort did you put into your review? A glance, a quick reading, or an in-depth study?

Please state explicitly whether you believe that the proposal should be accepted into SDL.

A review should be written as a comment on the GitHub issue opened for the proposal.

## How to propose a change
* **Check prior proposals**: many ideas come up frequently, and may either be in active discussion, or may have been discussed already and accepted or rejected.  Please check the [SDL Evolution Proposal Status page][sdl_evolution_proposal_status_page] for context before proposing something new.
* **Socialize the idea**: if you're still working through the concept of your proposal, propose a rough sketch of the idea on the [#sdl_evolution channel][sdl_evolution_channel] of the [SDL Slack][sdl_slack], the problems it solves, what the solution looks like, etc., to gauge interest from the community.
* **Develop the proposal**: expand the rough sketch into a complete proposal, using the [proposal template](0000-template.md). The scope of the proposal should focus on a singluar feature. Prototyping an implementation and its uses along with the proposal is encouraged, because it helps ensure both technical feasibility of the proposal as well as validating that the proposal solves the problems it is meant to solve.
* **Request a review**: initiate a pull request to the [sdl_evolution repository][sdl_evolution_repo] and follow the instructions in the [pull request template](https://github.com/smartdevicelink/sdl_evolution/blob/master/.github/PULL_REQUEST_TEMPLATE.md) to indicate that you would like the proposal to be reviewed. When the proposal is sufficiently detailed and clear, and addresses feedback from earlier discussions of the idea, a `review ready` label will be added to the pull request. Once the SDLC Steering Committee has voted to bring the proposal into review, it will be assigned a proposal number and an issue will be opened specifically for the review of the proposal.
* **Address feedback**: in general, and especially during the review period, be responsive to questions and feedback about the proposal.  It is the proposal author's burden to advocate for their idea and be open to suggestions from the SDL community.

## Review process
The review process for a particular proposal begins when the SDLC Steering Committee decides to accept a pull request of a new or updated proposal into the [sdl_evolution repository][sdl_evolution_repo]. The proposal is assigned a proposal number (if it is a new proposal), and a review issue is created on GitHub.

The SDLC Steering Committee will review up to six (6) proposals each week.  This number can be reduced based on the complexity and/or context of the proposals. Reviews will last at least one week, but can run longer for particularly large or complex proposals.

When a review issue is created for a proposal, it is also shared on the [#sdl_evolution channel][sdl_evolution_channel] of the [SDL Slack][sdl_slack]. The issue will have the subject "[In Review]" followed by the proposal title. The status of proposals are tracked in the [proposals.xml document][sdl_proposals_xml]. All feedback on the proposal should be addressed in the associated GitHub issue. To avoid delays, it is important that the proposal author(s) be available to answer questions, address feedback, and clarify their intent during the review period.

After the review has completed, the SDLC Steering Committee will make a decision on the proposal.  The decision will be reported on the GitHub issue for the proposal review. The proposal's state will be updated in the [sdl_evolution repository][sdl_evolution_repo] to reflect the decision, and the related issue will be closed and locked. Possible decisions include: Accepted, Accepted with Revisions, Rejected, Returned for Revisions, Withdrawn, and Deferred.

### Proposal Decision Types
- **Accepted**: Proposal has been approved, and issues will be entered in respective repositories for implementation to commence.
- **Accepted with Revisions**: Proposal has been approved, pending the (minor) revisions included in the SDLC Steering Committee's decision comment on the associated review issue.  Issues will be entered in respective repositories for implementation once the proposal file has been revised to incorporate the requested revisions from the SDLC Steering Committee.
- **Rejected**: Proposal was not approved due to the rationale provided in the SDLC Steering Committee's decision comment on the associated review issue.
- **Withdrawn**: Author of proposal has requested that it no longer be considered for review.  This will only be applicable to proposals that have not yet been accepted or rejected.  After a proposal is withdrawn, any interested parties are able to become the author of the proposal to see it through further reviews and be voted upon by the SDLC Steering Committee.
- **Returned for Revisions**: Proposal has been returned to the author to make significant revisions, as described in the SDLC Steering Committee's decision comment on the associated review issue.  The author will submit a pull request against the original proposal and notify the Project Maintainer once revisions are ready to be merged into the original proposal for another SDLC Steering Committee review.  After 2 weeks of inactivity on a proposal that has been returned for revisions, the proposal issue will be closed.  It will be reopened once the author has notified the Project Maintainer that revisions have been submitted.
- **Deferred**: Proposal has been deemed not ready to be voted upon by the SDLC Steering Committee.  Proposals can be deferred if the SDLC plans to meet separately to discuss the proposal/feature in greater detail, or if the proposal is dependent on another proposal being submitted and/or accepted.  With the exception of deferring a proposal for plans to meet separately to discuss, after 2 weeks of inactivity on a proposal that has been deferred, the proposal issue will be closed.  When action is ready to be taken again on the deferred proposal, the issue will be reopened and brought back into review.

Proposals can also remain in review if the SDLC Steering Committee needs more time to review and discuss on the associated review issue.  Closing for after 2 weeks of inactivity applies to these proposals as well.


## Review announcement
When a proposal enters review, a GitHub issue using the following template will be created in the sdl_evolution repository, and the issue will be shared on the [#sdl_evolution channel][sdl_evolution_channel] of the [SDL Slack][sdl_slack]:

---

Hello SDL community,

The review of "\<\<PROPOSAL NAME>>" begins now and runs through \<\<REVIEW
END DATE>>. The proposal is available here:

> <https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/NNNN-proposal.md>

Reviews are an important part of the SDL evolution process. All reviews
should be sent to the associated Github issue at:

> <https://github.com/smartdevicelink/sdl_evolution/issues/NNNN_proposal_name/>

##### What goes into a review?
The goal of the review process is to improve the proposal under review through constructive criticism and, eventually, determine the direction of SDL. When writing your review, here are some questions you might want to answer in your review:

* Is the problem being addressed significant enough to warrant a change to SDL?
* Does this proposal fit well with the feel and direction of SDL?
* If you have used competitors with a similar feature, how do you feel that this proposal compares to those?
* How much effort did you put into your review? A glance, a quick reading, or an in-depth study?

Please state explicitly whether you believe that the proposal should be accepted into SDL.

More information about the SDL evolution process is available at:

> <https://github.com/smartdevicelink/sdl_evolution/blob/master/process.md>

Thank you,

---


## Additional SDL Evolution Process Details

### Revising Previously Accepted Proposals
If it's determined that a previously accepted, but not yet implemented proposal requires revisions, a pull request will need to be entered to revise the original proposal. This can happen upon implementing a feature or reviewing the implementation for a feature.

The pull request will be reviewed in the same way as a proposal.  Therefore, the pull request description should follow the format of the [proposal template](https://github.com/smartdevicelink/sdl_evolution/blob/master/0000-template.md).

Please see an example of how to format this type of pull request [here](https://github.com/smartdevicelink/sdl_evolution/pull/775).

### Making Significant Changes to a Proposal

If you are requesting to change a proposal in review, and the solution in your proposal needs to be changed so significantly that it does not match the original solution, a new proposal should be submitted, and a request to reject or withdraw your original proposal should be brought to the Steering Committee.


###Timing
In general, actions taken on proposals should be limited to one per week.  Please see example situations below:

- If the Steering Committee votes to return a proposal for revisions, bringing the revised proposal back into review cannot happen until the following week.  This allows for adequate time to ensure the Steering Committee's agreed upon revisions have been made.  
- A proposal cannot be brought into review and voted upon in the same week, as Steering Committee representatives would not have sufficient time to review the proposal prior to voting.

###For Consideration
The SDL Community is a global community, and so it can be expected that comments will be made on review issues at various times.  For this reason, we do not have a "cutoff" time for leaving comments on review issues.  While this may sometimes result in a proposal needing to be kept in review an additional week to allow the author or commenter time to respond, we appreciate the understanding of the community to allow such global discussions to take place.

##Implementation Responsibility

The general rule of thumb is that the author of an SDL Evolution proposal is the person or company who intends to contribute code for a feature. SDLC Member contributions should encompass all projects impacted by the feature (including documentation).

You can find more information about proposal implementations and release planning [here][sdl_releases].

[sdl_evolution_repo]: https://github.com/smartdevicelink/sdl_evolution "SDL evolution repository"
[sdl_slack]: http://slack.smartdevicelink.com "SDL slack"
[sdl_evolution_channel]: https://smartdevicelink.slack.com/messages/sdl_evolution/ "#sdl_evolution slack channel"
[sdl_evolution_report_channel]: https://smartdevicelink.slack.com/messages/sdl_evolution_report/ "#sdl_evolution_report slack channel"
[sdl_mailing_list]: https://lists.genivi.org/mailman/listinfo/genivi-smartdevicelink "SDL mailing list"
[sdl_proposals_xml]: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals.xml "SDL Proposals XML"
[sdl_evolution_proposal_status_page]: https://smartdevicelink.github.io/sdl_evolution/ "SDL Evolution Proposal Status Page"
[proposals_versus_issues]: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals_versus_issues.md "Proposals versus Issues"
[sdl_releases]: https://github.com/smartdevicelink/sdl_evolution/blob/master/sdl_releases.md "SDL Releases"