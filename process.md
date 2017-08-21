# SDL Evolution Process
The SmartDeviceLink Consortium (SDLC) seeks the help of the community to help guide and shape how SDL changes. To do that effectively, we outline in this document a process for introducing ideas to SDL and how the SDLC Steering Committee will guide those ideas through the review process.

## Scope
Any changes to the [SDL RPC spec](https://github.com/smartdevicelink/rpc_spec), the [SDL protocol](https://github.com/smartdevicelink/protocol_spec), enhancements or major API changes to the SDL [iOS](https://github.com/smartdevicelink/sdl_ios) or [Android](https://github.com/smartdevicelink/sdl_android) SDKs, and [SDL Core](https://github.com/smartdevicelink/sdl_core) must go through the SDL evolution proposal and review process. An enhancement is defined as changing any behavior in a way that is different from the original definition of the behavior.  Please reference the [Proposals versus Issues document][proposals_versus_issues] for more information on what constitutes an Evolution Proposal versus a bug fix.  Major changes are defined according to [semantic versioning](http://www.semver.org).

Bug fixes should go through the normal contribution process, for example, [this is the iOS repository's process](https://github.com/smartdevicelink/sdl_ios/blob/master/.github/CONTRIBUTING.md).

If you have questions about if a particular case should be an Evolution Proposal or bug fix, please ask on [SDL slack][sdl_slack].

## Participation
Everyone is welcome to discuss and propose new changes to SDL on the [#sdl_evolution channel][sdl_evolution_channel] on the [SDL slack][sdl_slack]. Proposals under current review will be given an issue on the [sdl_evolution repository][sdl_evolution_repo]. Before posting a review, please read "What goes into a review?" below.

The SDLC is currently responsible for the strategic direction of SDL and will have the final say on the result of a proposal. A rationale will always be posted along with the result of the review of a proposal.

## What goes into a review?
The goal of the review process is to improve the proposal under review through constructive criticism and, eventually, determine the direction of SDL. When writing your review, here are some questions you might want to answer in your review:

* What is your evaluation of the proposal?
* Is the problem being addressed significant enough to warrant a change to SDL?
* Does this proposal fit well with the feel and direction of SDL?
* If you have used competitors with a similar feature, how do you feel that this proposal compares to those?
* How much effort did you put into your review? A glance, a quick reading, or an in-depth study?

Please state explicitly whether you believe that the proposal should be accepted into SDL.

A review should be written as a comment on the Github issue of the proposal created by the review manager.

## How to propose a change
* **Check prior proposals**: many ideas come up frequently, and may either be in active discussion, or may have been discussed already and accepted or rejected.  Please check the [SDL Evolution Proposal Status page][sdl_evolution_proposal_status_page] for context before proposing something new.
* **Socialize the idea**: if you're still working through the concept of your proposal, propose a rough sketch of the idea on the [#sdl_evolution channel][sdl_evolution_channel] of the [SDL Slack][sdl_slack], the problems it solves, what the solution looks like, etc., to gauge interest from the community.
* **Develop the proposal**: expand the rough sketch into a complete proposal, using the [proposal template](0000-template.md), and continue to refine the proposal on the evolution slack channel. Prototyping an implementation and its uses along with the proposal is encouraged, because it helps ensure both technical feasibility of the proposal as well as validating that the proposal solves the problems it is meant to solve.
* **Request a review**: initiate a pull request to the [sdl_evolution repository][sdl_evolution_repo] to indicate to the maintainers that you would like the proposal to be reviewed. When the proposal is sufficiently detailed and clear, and addresses feedback from earlier discussions of the idea, the pull request will be accepted. The proposal will be assigned a proposal number as well as a maintainer to manage the review. In addition, an issue will be opened specifically for the review and attached to the proposal.
* **Address feedback**: in general, and especially [during the review period](#review), be responsive to questions and feedback about the proposal.

## Review process
The review process for a particular proposal begins when the SDLC Steering Committee decides to accept a pull request of a new or updated proposal into the [sdl_evolution repository][sdl_evolution_repo]. The proposal is assigned a proposal number (if it is a new proposal), then enters the review queue.

The SDLC Steering Committee will work with the author to assess when the proposal is ready for review. Reviews usually last a single week, but can run longer for particularly large or complex proposals.

When the scheduled review period arrives, the review manager will post the proposal to the [#sdl_evolution slack channel][sdl_evolution_channel], the [genivi-smartdevicelink mailing list][sdl_mailing_list], and create a Github issue for the actual review, which will additionally be attached to the proposal. They will have the subject "[In Review]" followed by the proposal title. The Review Manager will be responsible for tracking the status of the proposal in the [proposal XML document][sdl_proposals_xml]. All feedback on the proposal should be addressed in the associated Github issue or to the review manager directly via email or Slack. To avoid delays, it is important that the proposal authors be available to answer questions, address feedback, and clarify their intent during the review period.

After the review has completed, the SDLC Steering Committee will make a decision on the proposal. The review manager is responsible for determining consensus among the SDLC Steering Committee, then reporting their decision to the proposal authors and SDL users. The review manager will update the proposal's state in the [sdl_evolution repository][sdl_evolution_repo] to reflect that decision, then close and lock the related issue. Possible decisions include: Accepted, Accepted with Revisions, Rejected, Returned for Revisions, and Deferred.

### Proposal Decision Types
- **Accepted**: Proposal has been approved, and the SDL maintainer will enter issues in respective repositories for implementation to commence.
- **Accepted with Revisions**: Proposal has been approved, pending the (minor) revisions included in the SDLC Steering Committee's decision comment on the associated review issue.  The SDL project maintainer will enter issues in respective repositories for implementation once the proposal.md file has been revised to incorporate the requested revisions from the SDLC Steering Committee.
- **Rejected**: Proposal was not approved due to the rationale provided in the SDLC Steering Committee's decision comment on the associated review issue.
- **Returned for Revisions**: Proposal has been returned to the author to make significant revisions, as described in the SDLC Steering Committee's decision comment on the associated review issue.  The author will submit a pull request against the original proposal and notify the review manager once revisions are ready to be merged into the original proposal for another SDLC Steering Committee review.
- **Deferred**: Proposal has been deemed not ready to be voted upon by the SDLC Steering Committee.  Proposals can be deferred if the SDLC plans to meet separately to discuss the proposal/feature in greater detail, or if the proposal is dependent on another proposal being submitted and/or accepted.

Proposals can also remain in review if the SDLC Steering Committee needs more time to review and discuss on the associated review issue.

## Review announcement
When a proposal enters review, an email using the following template will be sent to the [#sdl_evolution slack channel][sdl_evolution_channel], the [genivi-smartdevicelink mailing list][sdl_mailing_list], and to a Github issue:

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

\<\<REVIEW MANAGER NAME>>

---

[sdl_evolution_repo]: https://github.com/smartdevicelink/sdl_evolution "SDL evolution repository"
[sdl_slack]: http://slack.smartdevicelink.com "SDL slack"
[sdl_evolution_channel]: https://smartdevicelink.slack.com/messages/sdl_evolution/ "#sdl_evolution slack channel"
[sdl_evolution_report_channel]: https://smartdevicelink.slack.com/messages/sdl_evolution_report/ "#sdl_evolution_report slack channel"
[sdl_mailing_list]: https://lists.genivi.org/mailman/listinfo/genivi-smartdevicelink "SDL mailing list"
[sdl_proposals_xml]: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals.xml "SDL Proposals XML"
[sdl_evolution_proposal_status_page]: https://smartdevicelink.github.io/sdl_evolution/ "SDL Evolution Proposal Status Page"
[proposals_versus_issues]: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals_versus_issues.md "Proposals versus Issues"
