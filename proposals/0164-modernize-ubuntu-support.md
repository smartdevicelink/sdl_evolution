# Modernize Ubuntu Support

* Proposal: [SDL-0164](0164-modernize-ubuntu-support.md)
* Author: [Jacob Keeler](https://github.com/jacobkeeler)
* Status: **Accepted**
* Impacted Platforms: [Core]

## Introduction

This proposal is to add official support of the latest Ubuntu LTS Release (version 18.04 as of April 26th, 2018) to SDL Core, as well as update the minimum supported version from Ubuntu 14.04 to Ubuntu 16.04 as the former reaches the end of its support lifetime.

## Motivation

Official support of Ubuntu 14.04 will be dropped in one year (April 2019), meaning that the default build platform of SDL Core should be updated to account for this. In addition, a new LTS release of Ubuntu was very recently released, and SDL Core can be updated to officially support this version.

## Proposed solution

The proposed solution to this is to test SDL Core on the new Ubuntu 18.04 LTS release to verify it fully supports this release. Any compatibility issues with this release found in testing will be fixed before as part of this proposal. Upon resolving these compatibility issues, all relevant documentation will be updated to include 16.04 as the minimum supported version and 18.04 as the recommended version.

## Potential downsides

As always, upgrading the supported version has its own support costs, but considering that the current default OS (Ubuntu 14.04) is close to being no longer supported, this is likely a worthwhile jump.

## Impact on existing code

The exact changes to the codebase needed must be determined after testing the current project on the new release of Ubuntu. Some of known compatibility issues are shown in [this PR](https://github.com/smartdevicelink/sdl_core/pull/924/files) which was originally meant to add support for Ubuntu 16.04 LTS.

The SDL Core [README](https://github.com/smartdevicelink/sdl_core/blob/master/README.md) and [FAQ](https://github.com/smartdevicelink/sdl_core_guides/blob/master/docs/FAQ/index.md) also need to be updated with these version changes.

## Alternatives considered

- Just updating the minimum supported version, adding support for Ubuntu 18.04 LTS at a later time.
