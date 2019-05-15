# SDL Server Version Tracking

* Proposal: [SDL-0229](0229-sdl-server-version-tracking.md)
* Author: [Nick Schwab](https://github.com/nickschwab)
* Status: **Accepted**
* Impacted Platforms: [SDL Server, SHAID]

## Introduction

The goal of this proposal is enable the SDLC and Project Maintainer to track which SDL Server versions are in use by OEMs.

## Motivation

With the knowledge of which SDL Server versions are being used by OEM partners, the Project Maintainer can provide faster, more accurate product support. Additionally, tracking SDL Server versions will allow the SDLC to better understand the frequency of which OEMs update their SDL Server installations, and identify deprecation opportunities with minimal OEM impact.

## Proposed solution

The proposed solution is to add a new HTTP header attribute to each API call to SHAID from SDL Server containing the version of the SDL Server installation.

### SDL Server Changes

A new HTTP header attribute sent with each API call to SHAID.

`sdl_server_version`: String representing the SDL Server version, e.g. "2.6.1"

### SHAID Changes

Add a new column to SHAID's `request_log` database table to store the incoming SDL Server version header string. Write this value to the database asynchronously when an API request is fulfilled.

New column:

`sdl_server_version`: VARCHAR(12) DEFAULT NULL


## Impact on Existing Code
The proposed solution has minimal impact on existing code, as some header attributes are already sent in API requests from SDL Server to SHAID for authentication purposes and SHAID's existing API request logging already occurs in an asynchronous fashion. There would be no direct impact to API calls or user interfaces.

## Potential Downsides

* Nominal increase in database storage consumption

## Alternatives Considered

### SDL Server Version Setting
This alternative would be to add an "SDL Server Version" dropdown to the "Company Info" tab on [smartdevicelink.com](https://smartdevicelink.com). Using this dropdown, OEMs could select which version of SDL Server they are using and the selection would be saved to their company's profile.

Downsides to this alternative include:

* Requires direct action by an OEM rather than an automated approach
* OEM users may select the wrong version
* OEM users may not update the selection after they upgrade their SDL Server installation
* Requires supporting UI, UX, and API changes
