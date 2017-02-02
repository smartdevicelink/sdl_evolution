# Add Potential Downsides to Template

* Proposal: [SDL-NNNN](nnnn-meta-template-potential-downsides.md)
* Author: [SDL Developer](https://github.com/smartdevicelink)
* Status: **Awaiting review**
* Impacted Platforms: Meta

## Introduction
This proposal is to update the sdl_evolution template to include a new section: "Potential downsides." This segment will be allow the author to anticipate and respond to possible objections to his or her proposal. Second, we should remove "Detailed design" as separate major section and combine it with "Proposed solution."

## Motivation
Currently, all discussion of possible objections tends to be done in review, but if the author knows that a potential objection is possible, it would make sense for them to provide counter-arguments, explain why the objection fails, or explain why the objection is valid but the proposal's strengths outweigh its weaknesses.

## Proposed solution
The proposed changes are, first, to combine the Proposed solution and Detailed design sections. So often these two sections are combined anyway, and wording was added that proposal authors ought to use subsections.

The second is to add the "Potential downsides" section in which the author(s) should present possible flaws or objections to this proposal and respond to them.

```markdown
# Feature name

* Proposal: [SDL-NNNN](nnnn-filename.md)
* Author: [SDL Developer](https://github.com/smartdevicelink)
* Status: **Awaiting review**
* Impacted Platforms: [Core / iOS / Android / Web / RPC / Protocol]

## Introduction
A short description of what the feature is. Try to keep it to a single-paragraph "elevator pitch" so the reader understands what problem this proposal is addressing.

## Motivation
Describe the problems that this proposal seeks to address. If the problem is that some common pattern is currently hard to express, show how one can currently get a similar effect and describe its drawbacks. If it's completely new functionality that cannot be emulated, motivate why this new functionality would help SDL mobile developers or OEMs provide users with useful functionality.

## Proposed solution
Describe your solution to the problem. Provide examples and describe how they work. Show how your solution is better than current workarounds: is it cleaner, safer, or more efficient? Use subsections if necessary.

Describe the design of the solution in detail. Use subsections to describe various details. If it involves new protocol changes or RPC changes, show the full XML of all changes and how they changed. Show documentation comments detailing what it does. Show how it might be implemented on the Mobile Library and Core. The detail in this section should be sufficient for someone who is *not* one of the authors to be able to reasonably implement the feature and future [smartdevicelink.com](https://www.smartdevicelink.com) guides.

## Potential downsides
Describe any potential downsides or known objections to the course of action presented in this proposal, then provide counter-arguments to these objections. You should anticipate possible objections that may come up in review and provide an initial response here. Explain why the positives of the proposal outweigh the downsides, or why the downside under discussion is not a large enough issue to prevent the proposal from being accepted.

## Impact on existing code
Describe the impact that this change will have on existing code. Will some SDL integrations stop compiling due to this change? Will applications still compile but produce different behavior than they used to? Is it possible to migrate existing SDL code to use a new feature or API automatically?

## Alternatives considered
Describe alternative approaches to addressing the same problem, and why you chose this approach instead.
```
