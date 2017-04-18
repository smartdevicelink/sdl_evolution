# Move to the new C++11 standard.

* Proposal: [SDL-0043](0043-upgrade-c++-standard.md)
* Author: [Alexandr Galiuzov](https://github.com/AGaliuzov)
* Status: **In Review**
* Impacted Platforms: [Core]

## Introduction
This proposal is geared to upgrade currently used `C++98` standard to `C++11` as the latter one has much more useful features and significant improvements from the performance point of view. Also it became more safe in runtime and allows to catch a lot of issues during the compilation stage.

## Motivation
* Reinventing the wheel:
  * own implementations for synchronization primitives, thread handling, atomics, smart pointers and various utilities
* Code bloating:
  * poor support of principle "write once - use many times"
  * usage of multiple functors and helper classes
  * lack of algorithms in old version of standard library force to write own implementation
* Performance constraints:
  * wasting more time and system resources for object copying
* Risk of resource leaks:
  * unhandy initialization of containers
  * absence of shared pointers support and presence of dangerous auto pointers
* Safety risks:
  * no strictly defined null pointer
  * using of ifdefs and various macroses
  * no strongly typed enums
* Portability issues:
  * no standardized multithreading support
* Complexity growth:
  * absence of variadic templates support, template aliases and other related features forces to write more complex intricated code

## Proposed solution
In order to be able to develop stable, reliable and high-performance solutions automotive industry needs to use appropriate environment and try to follow modern standards in software development area and in particular updated `C++11` standard. New `C++11` standard is aimed to resolve or minimize multiple problems we have currently.
The minimal version of gcc compiler should be 4.8.1 as this one implements all of the major features of the `C++11`.
The details could be found [here](https://gcc.gnu.org/gcc-4.8/cxx0x_status.html).

## Potential downsides
* Not all the compilers are fully supports the `C++11` standard. `GCC` partially supports it starting from version 4.4.
* There is no backward compatibility with currently used `c++98`
* Some OEM are still using old software development environment i.e. QNX SDK 6.5 which is quite obsolete and uses `GCC` 4.4. With new standard they have to upgrade own environment

## Impact on existing code
All the SDL is the impact area. However it should not be changed at once. The upgrading could be done step-by-step without any kind of regression.
* Change utility classes such as hand written [`SharedPtr`](https://github.com/smartdevicelink/sdl_core/blob/master/src/components/include/utils/shared_ptr.h)
* Use lambda function instead of heavy functors
* Use `auto` variables and `default` constructions etc.

In general this movement could be done transparently for SDL users.

## Alternatives considered
The only alternative is to continue to use obsolete `c++98`
