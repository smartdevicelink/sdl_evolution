# SDL Releases Overview

## Planning

The SDLC Steering Committee meets toward the end of each year to plan the Roadmap for the following year.  Typically, the release schedule looks like this:

- End of Q1: Mostly bug fixing with minimal RPC and Protocol Spec, all affected projects (see below)
- End of Q2: Proxy (Java Suite and iOS) Libraries
- End of Q3/Beginning of Q4 (largest release): RPC and Protocol Spec, all affected projects (see below)

### Which projects need to be updated?<a id="which-projects-need-to-be-updated?"></a>

Each project will have their own releases and features that only affect their specific platform. Most Core releases will include RPC or Protocol Spec changes; these modifications will affect the widest range of projects.

Changes to RPC and Protocol Specs impact the following projects:

- Core
- Generic HMI
- SDL HMI
- ATF and scripts
- Java Suite (Android, JavaSE, and JavaEE; including hello world samples)
- iOS (including hello world sample)
- RPC Spec (if RPC modification)
- Protocol Spec (if Protocol Spec modification)
- SDL Server
- SHAID (SDLC Proprietary)
- SDL Developer Portal (SDLC Proprietary)
- Manticore
- Documentation
   - App Library Guides
   - HMI Integration Guidelines
   - Core Documentation
   - Core Guides

Changes to Core impact the following projects:

- Core
- Generic HMI (in most cases)
- SDL HMI (in most cases)
- ATF and scripts
- Manticore
- Documentation
   - HMI Integration Guidelines
   - Core Documentation
   - Core Guides
    
Changes to the Java Suite project impact the following projects:

- Java Suite (Android, JavaSE, and JavaEE; including hello world samples)
- Documentation
   - App Library Guides


Changes to the iOS project impact the following projects:

- iOS (including hello world sample)
- Documentation
   - App Library Guides

For additional information see the [SDL Evolution README](https://github.com/smartdevicelink/sdl_evolution/blob/master/README.md).

### Determining Priority and Timing

The Project Maintainer will work with the SDLC Steering Committee to determine priority for the Core releases which include RPC and protocol modifications. After gathering priority from members, the Project Maintainer compiles the information and comes up with a rough estimate on what can be achieved. This will then involve working with SDLC members on their plans to contribute to the SDL project. These contributions will be considered donations. The Project Maintainer will use contribution dates from members and put together a plan for the release that can be followed.

Members who have committed to contributing features will be responsible for meeting the contribution dates in order for that feature to be included in the planned release timeline.

## Code Contributions

### Who codes a feature/proposal?

The general rule of thumb is that the author of an SDL Evolution proposal is the person or company who intends to contribute code for a feature. SDLC Member contributions should encompass all projects impacted by the feature (including documentation).  See the [Which projects need to be updated?](#which-projects-need-to-be-updated?) section for details.  Note that the following projects are exempt from this requirement for SDLC Members: SHAID, SDL Developer Portal, Manticore.


### Project Maintainer Review

The Project Maintainer will perform reviews on all contributions to ensure they are of the highest quality and stability before merging them into one of the mainline branches. 

#### Prerequisites for SDLC Member Contributions

- All contributions should be reviewed and tested before asking for the Project Maintainer to review.  This includes code review and testing with only and all affected open source components; testing with proprietary systems/apps/setups are not acceptable.
    - If a supplier is contributing on behalf of an SDLC member, the SDLC member needs to approve the contribution before requesting Project Maintainer review.
- All contributions should be in working order and should not require "special setup." 
- All code should follow the contribution guidelines contained in the repository in which they are being donated.


### Ready for Review

Once the prerequesites for SDLC Member Contributions are met, and the pull request(s) has/have been submitted, the author or SDLC member contributing the code can tag `@theresalech` asking for the Project Maintainer to review.

After the review request has been made, __no changes should be submitted to a pull request until the review round is over.__

### Review Process

While the contribution is being reviewed by the Project Maintainer, there are a few things to keep in mind:

- Once the review process has started, do not push additional changes until the round of review is completed.
- The Project Maintainer will perform a general code review as well as testing to ensure the pull request works as expected.
- After the Project Maintainer has completed their review, the author should rework the pull request based on the reviewer's comments and concerns and again ensure that the feature/fix still works after the changes.
- The author then pushes those changes into the remote branch and once again can tag the Project Maintainer reviewer to begin the next round of review.
- This process continues until the pull request is approved by the Project Maintainer. 


### When do contributions get reviewed?

Contributions are reviewed based on SDLC priority and the annual SDL Roadmap. The Project Maintainer will work off the originally supplied contribution dates and assign time to review, which might mean there is time between the contribution date and the start of the Project Maintainer review.

If a pull request has not been prioritized by the SDLC or is not part of the SDL Roadmap, there is no specific time table as to when it will be reviewed and merged. It is important to ask the SDLC to prioritize items that are important to you or your organization. 

## Testing and Official Release

Once all planned contributions have been implemented and merged into the respective mainline branch, the Project Maintainer performs end to end testing of the Release Candidate.  If necessary, the Project Maintainer provides the Steering Committee with a Release Candidate for review and approval.  

As outlined in the Project Maintainer Agreement, the Steering Committee is responsible for approving the following releases:

- Major Core Releases
- Minor Core Releases
- Major Proxy (iOS and Java Suite) Releases

For releases requiring Steering Committee approval, there is typically a 1 month Release Candidate review period.  This includes time for the Steering Committee to review and perform testing, and the Project Maintainer to address any found issues.  This timing is subject to change at the Steering Committee's discretion.