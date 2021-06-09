# Remove Unused Files From SDL Core

* Proposal: [SDL-0338](0338-remove-unused-files-from-sdl-core.md)
* Author: [Jack Byrne](https://github.com/JackLivio)
* Status: **In Review**
* Impacted Platforms: [Core]

## Introduction

This proposal is to remove some unused utility and RPC files in SDL Core.

## Motivation

In an effort to trim the code base of SDL Core the author would like to remove some files that are unused by SDL Core.

## Proposed solution

Remove the following files:

- [system.cc](https://github.com/smartdevicelink/sdl_core/blob/master/src/components/utils/src/system.cc)
- [system.h](https://github.com/smartdevicelink/sdl_core/blob/master/src/components/utils/include/utils/system.h)
- [thread_manager.cc](https://github.com/smartdevicelink/sdl_core/blob/master/src/components/utils/src/threads/thread_manager.cc)
- [thread_manager.h](https://github.com/smartdevicelink/sdl_core/blob/master/src/components/utils/include/utils/threads/thread_manager.h)
- [pulse_thread_delegate.cc](https://github.com/smartdevicelink/sdl_core/blob/master/src/components/utils/src/threads/pulse_thread_delegate.cc)
- [pulse_thread_delegate.h](https://github.com/smartdevicelink/sdl_core/blob/master/src/components/utils/include/utils/threads/pulse_thread_delegate.h)
- [on_vi_acc_pedal_position_notification.cc](https://github.com/smartdevicelink/sdl_core/blob/master/src/components/application_manager/rpc_plugins/sdl_rpc_plugin/src/commands/hmi/on_vi_acc_pedal_position_notification.cc)
- [on_vi_acc_pedal_position_notification.h](https://github.com/smartdevicelink/sdl_core/blob/master/src/components/application_manager/rpc_plugins/sdl_rpc_plugin/include/sdl_rpc_plugin/commands/hmi/on_vi_acc_pedal_position_notification.h)
- [on_vi_belt_status_notification.cc](https://github.com/smartdevicelink/sdl_core/blob/master/src/components/application_manager/rpc_plugins/sdl_rpc_plugin/src/commands/hmi/on_vi_belt_status_notification.cc)
- [on_vi_belt_status_notification.h](https://github.com/smartdevicelink/sdl_core/blob/master/src/components/application_manager/rpc_plugins/sdl_rpc_plugin/include/sdl_rpc_plugin/commands/hmi/on_vi_belt_status_notification.h)
- [policy_retry_sequence.cc](https://github.com/smartdevicelink/sdl_core/blob/master/src/components/application_manager/src/policies/policy_retry_sequence.cc)
- [policy_retry_sequence.h](https://github.com/smartdevicelink/sdl_core/blob/master/src/components/application_manager/include/application_manager/policies/policy_retry_sequence.h)
- [regular/policy_retry_sequence.h](https://github.com/smartdevicelink/sdl_core/blob/master/src/components/application_manager/include/application_manager/policies/regular/policy_retry_sequence.h)

The author searched the source code and determined that these files are not included by any other files in the project. 

## Potential downsides

These files could technically be used by a fork of the project. For this reason, the author suggests waiting to remove these files until a major version change release of SDL Core.

## Impact on existing code

No impact on the main SDL Core project as these files aren't used. This might impact projects that have custom implementations that were made to use these files.

## Alternatives considered

None considered.
