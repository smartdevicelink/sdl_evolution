# Remove Unused Utilities From SDL Core

* Proposal: [SDL-NNNN](nnnn-remove-unused-utilities-from-sdl-core.md)
* Author: [Jack Byrne](https://github.com/JackLivio)
* Status: **Awaiting review**
* Impacted Platforms: [Core]

## Introduction

This proposal is to remove some unused utility files in SDL Core.

## Motivation

In an effort to trim the code base of SDL Core the author would like to remove some utility files that are unused by SDL Core.

## Proposed solution

Remove the following files:

- [system.cc](https://github.com/smartdevicelink/sdl_core/blob/master/src/components/utils/src/system.cc)
- [system.h](https://github.com/smartdevicelink/sdl_core/blob/master/src/components/utils/include/utils/system.h)
- [thread_manager.cc](https://github.com/smartdevicelink/sdl_core/blob/master/src/components/utils/src/threads/thread_manager.cc)
- [thread_manager.h](https://github.com/smartdevicelink/sdl_core/blob/master/src/components/utils/include/utils/threads/thread_manager.h)
- [pulse_thread_delegate.cc](https://github.com/smartdevicelink/sdl_core/blob/master/src/components/utils/src/threads/pulse_thread_delegate.cc)
- [pulse_thread_delegate.h](https://github.com/smartdevicelink/sdl_core/blob/master/src/components/utils/include/utils/threads/pulse_thread_delegate.h)

The author searched the source code and determined that these files are not included by any other files in the project. 

## Potential downsides

These files could technically be used by a fork of the project. For this reason, the author suggests waiting to remove these files until a major version change release of SDL Core.

## Impact on existing code

No impact on the main SDL Core project as these files aren't used. This might impact projects that have custom implementations that were made to use these files.

## Alternatives considered

None considered.
