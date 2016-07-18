# SDL Evolution Process
The SDL maintainers and stakeholders seek the help of the community to help guide and shape how SDL changes. To do that effectively, we outline in this document a process for introducing ideas to SDL and how the SDL maintainers will guide those ideas through the review process.

## Scope
Any changes to the [SDL RPC spec](https://github.com/smartdevicelink/rpc_spec/blob/master/spec.xml), the [SDL protocol](https://github.com/smartdevicelink/protocol_spec), public API changes to the SDL [iOS](https://github.com/smartdevicelink/sdl_ios) or [Android](https://github.com/smartdevicelink/sdl_android) SDKs, or major changes to [SDL Core](https://github.com/smartdevicelink/sdl_core) must go through the SDL evolution proposal and review process. SDL is versioned using [semantic versioning](http://www.semver.org). Therefore, any public API removal, alteration, or addition is a minor or major version change to the respective spec or library, no matter how small the change. The only minor or major change that does not need to go through this process is a misspelled API name in a mobile SDK. In that case, write an issue against the respective repository. Changes that do not make a spec or public API change should go through the normal contribution process, for example, [this is the iOS repository's process](https://github.com/smartdevicelink/sdl_ios/blob/master/.github/CONTRIBUTING.md).

## Participation
Everyone is welcome to discuss and propose new changes to SDL on the [#sdl_evolution channel][sdl_evolution_channel] on the [SDL slack][sdl_slack]. Proposals under current review will be given an issue on the [sdl_evolution repository][sdl_evolution_repo]. Before posting a review, please read "What goes into a review?" below.

The SDL maintainers and stakeholders are currently responsible for the strategic direction of SDL and will have the final say on the result of a proposal. A rationale will always be posted along with the result of the review of a proposal.

## What goes into a review?
The goal of the review process is to improve the proposal under review through constructive criticism and, eventually, determine the direction of SDL. When writing your review, here are some questions you might want to answer in your review:

* What is your evaluation of the proposal?
* Is the problem being addressed significant enough to warrant a change to SDL?
* Does this proposal fit well with the feel and direction of SDL?
* If you have used competitors with a similar feature, how do you feel that this proposal compares to those?
* How much effort did you put into your review? A glance, a quick reading, or an in-depth study?

Please state explicitly whether you believe that the proposal should be accepted into SDL.

A review should be written as a comment on the Github issue of the proposal created by the review manager. If you wish your review to remain private, email or send a slack to the Review Manager directly.

## How to propose a change
* **Check prior proposals**: many ideas come up frequently, and may either be in active discussion on the mailing list, or may have been discussed already and have joined the [Commonly Rejected Proposals](commonly_proposed.md) list.  Please check the issue archive and this list for context before proposing something new.
* **Socialize the idea**: propose a rough sketch of the idea on the [#sdl_evolution channel][sdl_evolution_channel] of the [SDL Slack][sdl_slack], the problems it solves, what the solution looks like, etc., to gauge interest from the community.
* **Develop the proposal**: expand the rough sketch into a complete proposal, using the [proposal template](0000-template.md), and continue to refine the proposal on the evolution slack channel. Prototyping an implementation and its uses along with the proposal is encouraged, because it helps ensure both technical feasibility of the proposal as well as validating that the proposal solves the problems it is meant to solve.
* **Request a review**: initiate a pull request to the [sdl_evolution repository][sdl_evolution_repo] to indicate to the maintainers that you would like the proposal to be reviewed. When the proposal is sufficiently detailed and clear, and addresses feedback from earlier discussions of the idea, the pull request will be accepted. The proposal will be assigned a proposal number as well as a maintainer to manage the review. In addition, an issue will be opened specifically for the review and attached to the proposal.
* **Address feedback**: in general, and especially [during the review period](#review), be responsive to questions and feedback about the proposal.

## Review process

The review process for a particular proposal begins when a maintainer accepts a pull request of a new or updated proposal into the [sdl_evolution repository][sdl_evolution_repo]. That maintainer becomes the *review manager* for the proposal. The proposal is assigned a proposal number (if it is a new proposal), then enters the review queue.

The review manager will work with the proposal authors to schedule the review. Reviews usually last a single week, but can run longer for particularly large or complex proposals.

When the scheduled review period arrives, the review manager will post the proposal to the [#sdl_evolution slack channel][sdl_evolution_channel], the [#sdl_evolution_announce slack channel][sdl_evolution_announce_channel], the [SDL mailing list][sdl_mailing_list], and create a Github issue for the actual review, which will additionally be attached to the actual review. They will have the subject "[Review]" followed by the proposal title. The Review Manager will update the list of active reviews. All feedback on the proposal should be addressed in the associated Github issue or to the review manager directly via email or Slack. To avoid delays, it is important that the proposal authors be available to answer questions, address feedback, and clarify their intent during the review period.

After the review has completed, the maintainers and stakeholders will make a decision on the proposal. The review manager is responsible for determining consensus among the maintainers and stakeholders, then reporting their decision to the proposal authors and SDL users. The review manager will update the proposal's state in the [sdl_evolution repository][sdl_evolution_repo] to reflect that decision.

## Review announcement

When a proposal enters review, an email using the following template will be sent to the [#sdl_evolution slack channel][sdl_evolution_channel], the [#sdl_evolution_announce channel][sdl_evolution_announce_channel], the [SDL mailing list][sdl_mailing_list], and to a Github issue:

---

Hello SDL community,

The review of "\<\<PROPOSAL NAME>>" begins now and runs through \<\<REVIEW
END DATE>>. The proposal is available here:

> <https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/NNNN-proposal.md>

Reviews are an important part of the SDL evolution process. All reviews
should be sent to the associated Github issue at:

> <https://github.com/smartdevicelink/sdl_evolution/issues/NNNN_proposal_name/>

or, if you would like to keep your feedback private, directly to the
review manager via slack or email:

> Slack: <https://smartdevicelink.slack.com/messages/@[REVIEWER_HANDLE]/>

> Email: <maintainer-email@email.com>

You may sign up for the SDL slack at this link:

> <http://slack.smartdevicelink.com>

##### What goes into a review?

The goal of the review process is to improve the proposal under review through constructive criticism and, eventually, determine the direction of SDL. When writing your review, here are some questions you might want to answer in your review:

* Is the problem being addressed significant enough to warrant a change to SDL?
* Does this proposal fit well with the feel and direction of SDL?
* If you have used competitors with a similar feature, how do you feel that this proposal compares to those?
* How much effort did you put into your review? A glance, a quick reading, or an in-depth study?

More information about the SDL evolution process is available at

> <https://github.com/smartdevicelink/sdl_evolution/blob/master/process.md>

Thank you,

-\<\<REVIEW MANAGER NAME>>

Review Manager

---

[sdl_evolution_repo]: https://github.com/smartdevicelink/sdl_evolution "SDL evolution repository"
[sdl_slack]: http://slack.smartdevicelink.com "SDL slack"
[sdl_evolution_channel]: https://smartdevicelink.slack.com/messages/sdl_evolution/ "#sdl_evolution slack channel"
[sdl_evolution_announce_channel]: https://smartdevicelink.slack.com/messages/sdl_evolution_announce/ "#sdl_evolution_announce slack channel"
[sdl_mailing_list]: https://lists.genivi.org/mailman/listinfo/genivi-smartdevicelink "SDL mailing list"
