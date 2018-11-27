

# Porting SDL to QNX700 and Automotive Grade Linux (AGL) x64 platforms

* Proposal: [SDL-NNNN](nnnn-sdl_on_qnx_700.md)
* Author: [Alexander Kutsan](https://github.com/LuxoftAKutsan)
* Status: **Awaiting review**
* Impacted Platforms: [Core, ATF]

## Introduction

This proposal is about expanding the list of officially certified platforms by SDL with the following the operation systems:

 - QNX 7.0 (x64)
 - Automotive Grade Linux (AGL) Flounder 6.0.2 (x64)

And approach for cross-platform testing automation.

SDL source code should be compilable for the following platforms:

 - Ubuntu - 16.04 (x64) default
 - QNX - 7.0 (x64)
 - Automotive Grade Linux - Flounder 6.0.2 (x64)

Platform specific code should be isolated and should not contain any business logic. SDL sources should not contain code duplication for specific platform. SDL should not contain special pre-compiled binaries for specific platform.

## Motivation

**QNX 6.5** (currently supported by SDL) is already out of date. New version of QNX released is QNX7.0.  

**QNX 7.0** is widely used by OEM manufactures, so SDL should be ready to be certified for working on QNX7.0. 

**Automotive Grade Linux (AGL)** is modern and popular Linux platform for the Automotive industry, and it is already used by many car manufacturers. SDL should also be ready to be certified for using this platform and tested on it. 

## Proposed solution

Provide readiness for open source SDL compilation and certification by SDL Steering Committee for 3 platforms :

 - Ubuntu 16.04 x64 (or higher) native. 
 - QNX 7.0 x64 (Using SDL on virtual workstation).
 - Automotive Grade Linux x64 (Using SDL on virtual workstation).
 
Within continuous integration each change (Pull Request to develop) for SDL Core should be tested (in automated mode) for Ubuntu, QNX, AGL. It is the Project Maintainer responsibility to certify solution for all referenced platforms.

### Versions of platforms

This proposal is about certifying SDL for the latest releases of Ubuntu, QNX, AGL. 
Future releases of referenced platforms will require new SDL-evolution proposal.

### SDL compilation process:

#### Compilation for QNX 7.0

Compilation for QNX 7.0 required pre-installed QXN7.0 SDP on developer workstation.

SDL will contains QNX 7.0 toolchain file that should be used for compilation. 
Example : 

```$ cmake -DCMAKE_TOOLCHAIN_FILE=<sdl_core>/toolchains/Toolchain_QNX700_x86.cmake <sdl_core>```
```$ make install```

Then all binaries and libraries required for running SDL on QNX will be in `<build_dir>/bin`

#### Compilation for AGL 

Compilation for AGL required pre-installed AGL SDK on the developer platform. 
Compilation for AGL is not cross platform compilation, but specific versions of libraries should be guaranteed.

SDL will contains Docker file with environment ready for compilation for **AGL Flounder 6.0.2**.
Default command for this Docker file will be `cmake && make install` commands that will compile SDL Core code.
Before running compilation in container developer should specify source directory of SDL Core code.

Compilation of SDL code for AGL will be done by using docker file.
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

Utils component will be affected by modification of SDL Core to providing ability to pass SDLC certification. 
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

sdl_atf tool should be executed on host workstation, but SDL will be ran on remote virtual workstation. 

For support remote automated testing of SDL, the following proposal should be implemented: https://github.com/LuxoftAKutsan/sdl_evolution/blob/remote_atf_proxy/proposals/nnnn-remote_atf_testing.md

#### Modifications in the test scripts

Some scripts should be modified to use SDL on remote workstation.  
All operations with SDL files ( hmi_capabilities, preloaded_pt, etc ...) should be covered with wrappers that support either local or remote execution. 

## Testing Approach

The following items should be checked for all these platforms:
 
 - Compilation;
 - Unit tests;
 - Automated smoke;
 - Existing features automated test cases (in case if feature is applicable on the virtual workstation).  

SDL could be tested on virtual workstation for each mentioned platform. 
For communication with mobile will be used **only**  Transmission Control Protocol (TCP) transport.
For communication with HMI will be used TCP/WebSockets transport.

All mentioned platforms (Ubuntu, AGL, QNX) will share codebase for communication with mobile and HMI.  

#### Manual testing

Manual testing will be performed using WebHMI https://github.com/smartdevicelink/sdl_hmi
No changes in WebHMI are expected, and WebHMI will be executed on the real developer workstation.

Mobile application may be connected to SDL Core via TCP.

### Automated testing.

With some changes in ATF test framework and existing scripts SDL Core could be tested automatically on all 3 platforms. 

The same test scripts will be executed for: 
 - Ubuntu;
 - AGL;
 - QNX.
 
Test coverage will include:
  - smoke testing of SDL Core (basic SDL scenarios and 3 policy flows (HTTP, PROPRIETARY, EXTERNAL_PROPRIETARY)); 
  - all delivered features that are applicable for cross platform testing.
  
Each further delivered feature should be tested on all mentioned platforms.

#### Missed functionality on AGL and QNX

Open source SDL will no implement platform specific functionality on all mentioned systems.
It is OEM's responsibility to implement and check platform specific layer of SDL - OEM Adapter. 

This layer includes:
 - USB transport;
 - Bluetooth transport;
 - Multiple transports support.


## Potential downsides

N/A

## Impact on existing code

SDL core will be modified in the platform specific places.
All components that use **utils** will be affected and need to be retested on the target platform.
 
## Alternatives considered


#### Additional transport support on AGL, QNX virtual workstation

Add USB and Bluetooth transport support for virtualized QNX and AGL platforms.
These transport adapters will not be used for real OEMs, the only place to use them will be virtual workstations.
Also communication via this transport adapters actually will be emulated by virtual workstation.
Supporting of additional transports on the virtual workstation is exhausted. There is no valuable reason to keep supporting of many transports on multiple platforms. One exception might be applied - as best practice example for OEM suppliers. 

Pros: 
 - Testing may be done via additional transports.

Cons:
- Big efforts for automation of transport testing. 
- Big efforts for supporting many transports on multiple platform.
- Transport specific code will not be actual for OEM suppliers.
- Transport testing will be executed through virtualisation layer.

#### Using real hardware with QNX and AGL

SDL may not be tested on virtual workstation, but on real hardware with QNX, Ubuntu and AGL.

Pros: 
 - Real USB, Bluetooth transports may be used for testing.

Cons:
 - This approach will introduce additional efforts for resolving hardware specific problems. 
 - Each OEM supplier has its own hardware, and hardware specific code will be partially not actual.
 - SDL contributor will need to have real hardware (same as certified by SDL) to test their fixes and implementation.
 - Exhausted process of automation for transport-specific testing. Automation pipelines should use real hardware that requires additional efforts for tuning.
