# Remove QT HMI from SDL Core

* Proposal: [SDL-NNNN](NNNN-remove-qt-hmi-from-sdl-core.md)
* Author: [Jacob Keeler](https://github.com/jacobkeeler)
* Status: **Awaiting review**
* Impacted Platforms: [Core]

## Introduction

This proposal is for the removal of the QT HMI from the SDL Core repository.

## Motivation

The QT HMI has not been supported with any important updates since prior to SmartDeviceLink becoming open-source, and the existence of this component appears to just be a remnant from when the project was solely maintained by Ford. Because of this, build and runtime issues tied to this HMI have cropped up with every SDL Core release, but no time was devoted to fixing these issues since this HMI was unmaintained. 

Leaving this as a build option in the SDL Core repository is confusing for any newcomers to the project, as the HMI has not being in a working state for several releases. As it stands, the QT HMI has received no significant updates since prior to SDL Core 4.0.0. As such, the QT HMI cannot be left in the SDL Core repository in it's current state.

## Proposed Solution

The proposed solution to this issue is to remove this HMI from the repository entirely. It does not appear to be well integrated into the project at the moment, and the amount of work to maintain another sample HMI would be quite significant. Removing it entirely would require the least amount of work by far of the potential solutions to this issue.

This HMI has a few questionable design decisions tied to it, such as the inclusion of a separate `QT_HMI_API` and the forced installation of an outdated version of `dbus` (1.7.8). In addition, it appears that this HMI is heavily related to the HMI used by Ford in production head units, so it's functionality may be too specific for general use.

## Potential Downsides

Several developers outside of the SDLC have stated that they wish to use the QT HMI, but are unable to because of it's outdated state. The argument for keeping this HMI is that it is far easier to integrate a QT-based HMI into an embedded system than a Web-based HMI. Removing this HMI might make the project less appealing to those looking to integrate SDL into their Head Unit.

The Generic HMI might be able to address some of the complications that normally arise with Web-based HMIs, since it can be run in practically any browser. 

If it is determined that it would be worthwhile to maintain a separate QT HMI, one of the potential solutions in the `Alternatives Considered` section could be implemented in place of this proposal.

## Impact on Existing Code

The following changes would need to be made in the Core repository to accomplish this:

1. The CMake files would be edited to remove the QT HMI build option
    1. The `HMI2` option would be removed, as well as anything related to the dbus `HMI_ADAPTER_OPTION` or the qt `HMI_TYPE_OPTION`
    2. The `dbus-1.7.8` library would be removed from the `3rd_party` section
    3. Any references to the `QT_HMI` macro would be removed (the only use I see in the codebase is in `main.cc`) 
2. The `QT_HMI_API` would be removed from the `interfaces` component
3. The `DBusMessageAdapter` class would be removed from the `hmi_message_handler` component
4. The `qt_hmi` component would be removed entirely

There should be no changes to other existing build options as a result of this proposal.

## Alternatives Considered

Alternative 1: Update and maintain the QT HMI in a separate repository

This would require quite a bit more work to accomplish, and would require that the SDLC maintain this project in the future. Research would need to be done on how difficult it would be to separate the current QT HMI out from the Core project, as the `dbus-1.7.8` library is specifically included for communicating with the QT HMI. Work may need to be done to genericize the HMI so that it could be used as a sample.

Alternative 2: Create and maintain a new QT-based sample HMI

This would require the most work of the potential solutions, as it would require the construction and maintentenance of an entirely new project, but it would sidestep some of the complications with the previous alternative.

Alternative 3: Separate the QT HMI into a separate repository for archival purposes

Similar to alternative 1, but there would be no resources dedicated to maintaining the HMI after it is separated from the Core repository and brought to a working state.
