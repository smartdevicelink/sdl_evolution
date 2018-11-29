

# Porting SDL to QNX700 and Automotive Grade Linux (AGL) x64 platforms

* Proposal: [SDL-NNNN](nnnn-sdl_on_qnx_700.md)
* Author: [Alexander Kutsan](https://github.com/LuxoftAKutsan)
* Status: **Awaiting review**
* Impacted Platforms: [Core, ATF]

## Introduction

This proposal is about expanding the list of officially certified platforms by SDL with the following operation systems:

 - QNX 7.0 (x64)
 - Automotive Grade Linux (AGL) Flounder 6.0.2 (x64)

The next part of this proposal is an approach for cross-platform testing automation.

SDL source code should be compilable on the following platforms:

 - Ubuntu - 16.04 (x64) default
 - QNX - 7.0 (x64)
 - Automotive Grade Linux - Flounder 6.0.2 (x64)

The following conditions must be matched: 
- Platform specific code should be isolated and should not contain any business logic. 
- SDL sources should not contain code duplication for specific platform.
- SDL should not contain special pre-compiled binaries for specific platform.

## Motivation

**QNX 6.5** (currently supported by SDL) is already out of date. New version of QNX released is QNX7.0.  

**QNX 7.0** is widely used by OEM manufactures, so SDL should be ready to certify QNX7.0 for working on it. 

**Automotive Grade Linux (AGL)** is modern and popular Linux platform for the Automotive industry. It is already used by many car manufacturers. 
  SDL should also be ready to certify using this platform and to be tested on it. 

## Proposed solution

Provide readiness for open source SDL compilation and certification by SDL Steering Committee for 3 platforms:

 - Ubuntu 16.04 x64 (or higher) native 
 - QNX 7.0 x64 (Using SDL on virtual workstation)
 - Automotive Grade Linux x64 (Using SDL on virtual workstation)
 
Within continuous integration each change (Pull Request to develop) to SDL Core should be tested (in automated mode) for Ubuntu, QNX, AGL. 
It is the Project Maintainer responsibility to certify solution for all referenced platforms.

### Versions of platforms

This proposal is about certifying of the current stable releases of Ubuntu, QNX, AGL for SDL to work on these platforms. 

Current stable releases at the moment of proposal creation are: 
 - Ubuntu - 16.04 (x64) default
 - QNX - 7.0 (x64)
 - Automotive Grade Linux - Flounder 6.0.2 (x64)
 
Future releases of referenced platforms will require new SDL-evolution proposal.

### SDL compilation process:

#### Compilation for QNX 7.0

Compilation for QNX 7.0 requires pre-installed QXN7.0 SDP on developer workstation.

SDL will contain QNX 7.0 toolchain file that should be used for compilation.  
Before compilation suggested to setup `THIRD_PARTY_LIBRARY_PATH` variable to avoid instalation of qnx libraries to host system

Example:  
```$ export THIRD_PARTY_LIBRARY_PATH=<third_party_path>```  
```$ cmake -DCMAKE_TOOLCHAIN_FILE=<sdl_core>/toolchains/Toolchain_QNX700_x86.cmake <sdl_core>```  
```$ make install```

Then all binaries and libraries required for SDL run on QNX will be created in `<build_dir>/bin` and <third_party_path>. 

##### Compilation in docker container

SDL will contain Docker file with environment ready for qnx compilation. This environment will not contain QNX SDP.
Before compilation developer should provide path to SDP with directory mounted to container.

Example of compilation with docker: 
```
$ docker build -t  qnx_sdl_compile .
$ docker run -v <sdl_core>:/home/developer/sdl \
             -v <path_to_qnx_sdp>:/opt/qnx700 \
             qnx_sdl_compile
```
Then all binaries and libraries, which are required for running SDL Core on the QNX platform will be stored in `<sdl_core>/build/bin` 

#### Compilation for AGL 

Compilation for AGL requires pre-installed AGL SDK on the developer platform. 
Compilation for AGL is not cross-platform compilation, but specific versions of libraries should be guaranteed.

SDL will contain Docker file with environment ready for SDL compilation on **AGL Flounder 6.0.2**.
Before running compilation in container developer should specify source directory of SDL Core code.

Compilation of SDL code for AGL will be done by using docker file(default way)
```
$ docker build -t agl_compile .
$ docker run -v <sdl_core>:/home/developer/sdl agl_compile
```
Then all binaries and libraries, which are required for running SDL Core on the AGL platform will be stored in `<sdl_core>/build/bin`

### SDL runtime dependencies

SDL has the following runtime dependencies:
 - libpthread;
 - libdl;
 - libcrypto.so;
 - libssl.so;
 - libcrypt.so;
 - libstdc++.so;
 - libc.so;
 - libgcc_s.so;
 - libudev.so;
 - libsqlite3.so;
 - librt.so.

These libraries should be ported and pre-installed on the distributed target platform before running SDL.

#### Modification in Utils component

Utils component will be affected by modification of SDL Core providing ability to pass SDLC certification. 
Utils component provides all SDL layers platform agnostic interface for communication with the operation system:
 - file system operations;
 - threads and sync primitives;
 - timers;
 - logging;
 - system resource collecting.

### Provide ability for automated testing 

Existing automated testing tool [sdl_atf](https://github.com/smartdevicelink/sdl_atf) and 
[scripts](https://github.com/smartdevicelink/sdl_atf_test_scripts)
should be used for checking SDL functionality on the new platforms.

#### Modifications in ATF

sdl_atf tool should be executed on host workstation, but SDL will be run on remote virtual workstation. 

For support of SDL remote automated testing, the following proposal should be implemented: https://github.com/LuxoftAKutsan/sdl_evolution/blob/remote_atf_proxy/proposals/nnnn-remote_atf_testing.md

#### Modifications in the test scripts

Some scripts should be modified to use SDL on remote workstation.  
All operations with SDL files ( hmi_capabilities, preloaded_pt, etc ...) should be covered with wrappers that support either local or remote execution. 

## Testing Approach

The following items should be checked for all these platforms:
 
 - Compilation;
 - Unit tests;
 - Automated smoke tests;
 - Existing features automated test cases (in case if feature is applicable on the virtual workstation).  

SDL can be tested on virtual workstation for each mentioned platform.  
**Only** Transmission Control Protocol (TCP) transport will be used for communication with mobile.  
TCP/WebSockets transport will be used for communication with HMI.

All mentioned platforms (Ubuntu, AGL, QNX) will share codebase for communication with mobile and HMI.  

#### Manual testing

Manual testing will be performed using WebHMI https://github.com/smartdevicelink/sdl_hmi  
No changes in WebHMI are expected, and WebHMI will be executed on the real developer workstation.

Mobile application may be connected to SDL Core via TCP.

### Automated testing

SDL Core can be tested automatically on all 3 platforms with some changes in ATF test framework and existing scripts. 

The same test scripts will be executed for the following platforms: 
 - Ubuntu;
 - AGL;
 - QNX.
 
Test coverage will include:
  - smoke testing of SDL Core (basic SDL scenarios and 3 policy flows (HTTP, PROPRIETARY, EXTERNAL_PROPRIETARY)); 
  - all delivered features which are applicable for cross-platform testing.
  
Each further delivered feature should be tested on all mentioned platforms.

#### Missed functionality on AGL and QNX

Open source SDL will not implement platform specific functionality on all mentioned systems.
It is OEM's responsibility to implement and check platform specific layer of SDL - OEM Adapter. 

This layer includes:
 - USB transport;
 - Bluetooth transport;
 - Multiple transports support.


## Potential downsides

* Compilation for additional platforms requires tricky changes in configuration and build files.
* Further changes of configuration or build files may break the ability to build SDL for QNX or AGL. 

## Impact on existing code

SDL core will be modified in the platform specific places.
All components that use **utils** will be affected and need to be retested on the target platform.
 
## Alternatives considered

#### Refactor cmake files structure for easy multiple platforms support 
Current approach for creating cmake files and managing dependencies have the following problems : 

1. Existing cmake structure does not allow easy and seamless integration to other operating systems.
2. Existing cmake structure has no unified management system of 3rd party libraries.
3. Existing cmake structure does not allow flexible and clear dependencies resolution between components and libraries.

Unification of 3rd party libraries management and internal dependencies management would reduce OEM efforts to integrate SDL into the custom OEM environment. 

#### Using real hardware with QNX and AGL

SDL may not be tested on virtual workstation, but on real hardware with QNX, Ubuntu and AGL.

Pros: 
 - Real USB, Bluetooth transports may be used for testing.

Cons:
 - This approach will introduce additional efforts for resolving hardware specific problems. 
 - Each OEM supplier has its own hardware, and hardware specific code will be partially not actual.
 - SDL contributor will need to have real hardware (same as certified by SDL) to test their fixes and implementation.
 - Exhausted process of automation for transport-specific testing. Automation pipelines should use real hardware that requires additional efforts for tuning.
