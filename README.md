# SDL Evolution

**Do not submit a proposal without reading this roadmap document.** Ideas should be discussed on the [SDL Slack][sdl_slack] [#sdl_evolution][sdl_evolution_channel] open channel before a proposal is created here.

For more information about SDL, go to [www.smartdevicelink.com](https://www.smartdevicelink.com).

This process and document is based on Apple's excellent [Swift Evolution](https://github.com/apple/swift-evolution) process.

This document tracks the ongoing evolution of SDL. Proposals should be made for any public API surface change, that is, any change that would necessitate a minor or major version change in any SDL mobile library. If a protocol or RPC change does not change any API surface, they must still be brought through the proposal process. In sum, the following changes must be proposed:

* Changes necessitating minor or major version updates to the mobile libraries according to [semantic versioning](http://www.semver.org), except those that are caused by a misspelling.
* Major changes (Definition TBD) to SDL Core.
* **Any** change to the SDL Protocol.
* **Any** change to the SDL RPC spec.

Important documents:

* Goals for upcoming SDL releases – this document.
* The [SDL evolution proposal review schedule](https://smartdevicelink.github.io/sdl_evolution/) to see upcoming SDL evolution proposal reviews.
* The [SDL evolution review process](process.md) to see how to propose and review proposals.
* The [proposals versus issues document](proposals_versus_issues.md) to understand the differences between an SDL Evolution Proposal and an SDL Issue.

## SDL Protocol Version Next: X.X
Expected Release Date: N/A

The goal of the upcoming release is...
You can see a detailed list of accepted and implemented proposals on the [proposal status page][proposal-status].

## SDL RPC Spec Version Next: X.X
Expected Release Date: N/A

The goal of the upcoming release is...
You can see a detailed list of accepted and implemented proposals on the [proposal status page][proposal-status].

## Core Version Next: X.X
Expected Release Date: N/A

The goal of the upcoming release is...
You can see a detailed list of accepted and implemented proposals on the [proposal status page][proposal-status].

## iOS SDK Version Next: 5.0
Expected Release Date: N/A

The goal of this release is to rebuild and restructure the lower-level components of SDL iOS. Many of the lower-level protocol components are poorly designed and untestable. Many are unfortunately public classes when they should not be; these must be made private. RPCs, RPC Structs, and Enums are all difficult to update and add to, and unfortunately poorly designed (for example, enums are largely global, RPC properties are largely atomic, no nullability or generics). Code generation should be leveraged to make these easier to update in the future and for better compatibility with Swift.
You can see a detailed list of accepted and implemented proposals on the [proposal status page][proposal-status].

## Android SDK Version Next: X.X
Expected Release Date: N/A

The goal of the upcoming release is...
You can see a detailed list of accepted and implemented proposals on the [proposal status page][proposal-status].

[sdl_slack]: http://slack.smartdevicelink.com "SDL Slack"
[sdl_evolution_channel]: https://smartdevicelink.slack.com/messages/sdl_evolution/ "sdl_evolution slack channel"
[proposal-status]: https://smartdevicelink.github.io/sdl_evolution/
