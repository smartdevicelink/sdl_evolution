

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

### Rework of SDL code 

Cmake toolchain mechanism should be used for changing target platforms.

 **Example** :
  - Compilation for QNX : `cmake -DCMAKE_TOOLCHAIN_FILE=<sdl_core>/toolchains/Toolchain_QNX700_x86.cmake <sdl_core>` 
  - Compilation for AGL : `cmake -DCMAKE_TOOLCHAIN_FILE=<sdl_core>/toolchains/Toolchain_AGL_x86.cmake <sdl_core>` 

#### Refactoring of cmake structure


##### CMake modern approach

SDL may use modern cmake approach for targets creation. It will simplify porting SDL to any platform.  

###### Use CMake name spaces 

Propose to use cmake with name spaces for all SDL components and dependencies. 
This best practice of cmake allow:
 - To make clear components dependencies;
 - To avoid dependency gaps (required for multi-threading compilation);
 - To keep components independent;
 - To understand components interface;
 - To unify external dependencies management.
 
Here are the drawbacks of the current structure of cmake usage:
1. Existing cmake structure does not allow easy and seamless integration to other operating systems.
2. Existing cmake structure has no unified management system of 3rd party libraries.
3. With existing cmake structure we have problems with components and libraries dependencies, and the modern approach should resolve it.
4. This new approach will make cmake files more clear and lightweight.


###### target_<link_libraries,include_directiries>

SDL CMake files should avoid using global cmake commands for adding compiler flags, include directories, linkage libraries, etc ...

This functions pollute the project compilation structure, adds hidden dependencies between components, and make cmake files unclear and confusing.

SDL CMake files should explicitly specify include directories, link libraries, compiler options for entire target that it compiles.

#### 3rd party libraries for new platforms

File .cmake should be created for each 3rd party library used by SDL. This file will expose the library as cmake_library.

The following 3rd party libraries which were compiled within SDL, should be configured for QNX7 and AGL x86 platforms:
  - boost;
  - libapr;
  - libaprutils;
  - liblog4cxx;
  - bson-clib;
  - json.

#### New Cmake approach detailed design 

##### SDL core repository structure:

 - `/CMakeLists.txt`: contains common build configs for all projects, include directories with some builds utils and helpers;
 - `/src/`: contains all sources of the project;
 - `/src/components`: contains sources of SDL Core components;
 - `/src/3rd_party`: contains sources of 3rd party components;
 - `/src/appMain`: contains sources of SDL Core main executable and config files for runtime;
 - `/src/docs/`: contains doxygen template for Software Detailed Design (SDD) document generation;
 - `/src/tools/`: contains tools for work with repository, helpers, formatters, git hooks, etc;
 - `/cmake`: contains additional cmake files with common code across components;
 - `/cmake/toolchains`: contains compilation toolchains for different platforms;
 - `/cmake/helpers`: contains cmake helpers with common code across components;
 - `/cmake/dependencies`: contains cmake file for finding certain dependency on the system.

Each folder should contain a README file with descriptions of contents and examples of usage if applicable.

##### 3rd party libraries managment:

By default build system should not install to the system any additional libraries during compilation. 

If required version of certain dependency is available on the system, build system should use it.

If required version of certain dependency missed on the system, it build system should compile it and keep in `<build>` folder within `make` command.


**External dependencies** - dependencies that build system should download from official sources during cmake run.
**3rd_party dependencies** - dependencies that build system should keep as sources in `src/3rd_party` directory.

SDL is responsible for 3rd_party dependencies code and fixes that may also be applied to this code.

List of SDL dependencies : 
  - boost : **external dependency**, if it was not found on the system, build system should download sources from oficial sources during `cmake` command run and compile within project during `make` command run.
  - libapr : **3rd_party dependency**, if it was not found on the system, build system should take sources from `src/3rd_party/` and compile within project during `make` command run.
  - libaprutils : **3rd_party dependency**, if it was not found on the system, build system should take sources from `src/3rd_party/` and compile within project during `make` command run.
  - liblog4cxx : **3rd_party dependency**, if it was not found on the system, build system should take sources from `src/3rd_party/` and compile within project during `make` command run.
  - bson-clib : **external dependency**, if it was not found on the system, build system should download sources from oficial sources during `cmake` command run and compile within project during `make` command run.
  - json : **3rd_party dependency**, if it was not found on the system, build system should take sources from `src/3rd_party/` and compile within project during `make` command run.


######  3rd party libraries instalation rules

Compilation of libraries should not trigger their instalation to the system by default.

Propose to use special CMAKE variable if user desires to install 3rd party libraries to the system: `THIRD_PARTY_INSTALL_PREFIX`.

If this variable is empty, SDL should install 3rd party and external dependencies libraries to `{BUILD_DIR}`/compile_dependencies

During `make install` SDL should copy all files required for SDL RUN to `{BUILD_DIR}`/bin, and libraries required for sdl run to `{BUILD_DIR}`/bin/lib.


#### SDL runtime dependencies

SDL has the following runtime dependencies:
```
$ ldd smartDeviceLink
    linux-vdso.so.1 (0x00007ffdbf543000)
    libpthread.so.0 => /lib/x86_64-linux-gnu/libpthread.so.0 (0x00007fb77f45f000)
    libdl.so.2 => /lib/x86_64-linux-gnu/libdl.so.2 (0x00007fb77f25b000)
    libbluetooth.so.3 => /usr/lib/x86_64-linux-gnu/libbluetooth.so.3 (0x00007fb77f038000)
    libusb-1.0.so.0 => /lib/x86_64-linux-gnu/libusb-1.0.so.0 (0x00007fb77ee20000)
    libPolicy.so (0x00007fb77e062000)
    libcrypto.so.1.0.0 => /usr/lib/x86_64-linux-gnu/libcrypto.so.1.0.0 (0x00007fb77dc1f000)
    libssl.so.1.0.0 => /usr/lib/x86_64-linux-gnu/libssl.so.1.0.0 (0x00007fb77d9b7000)
    libstdc++.so.6 => /usr/lib/x86_64-linux-gnu/libstdc++.so.6 (0x00007fb77d1ed000)
    libgcc_s.so.1 => /lib/x86_64-linux-gnu/libgcc_s.so.1 (0x00007fb77cfd5000)
    libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007fb77cbe4000)
    /lib64/ld-linux-x86-64.so.2 (0x00007fb78220b000)
    libudev.so.1 => /lib/x86_64-linux-gnu/libudev.so.1 (0x00007fb77c9c6000)
    libsqlite3.so.0 => /usr/lib/x86_64-linux-gnu/libsqlite3.so.0 (0x00007fb77c294000)
    libm.so.6 => /lib/x86_64-linux-gnu/libm.so.6 (0x00007fb77bef6000)
    librt.so.1 => /lib/x86_64-linux-gnu/librt.so.1 (0x00007fb77bcee000)
    libcrypt.so.1 => /lib/x86_64-linux-gnu/libcrypt.so.1 (0x00007fb77b882000)
```
These libraries should be ported and pre-installed on the distribution of the target platform before running SDL.

#### Modify Utils component

Utils component will be affected with porting SDL to new platforms. 
Utils component provides all SDL layers platform agnostic interface for communication with the operation system:
 - file system operations
 - threads and sync primitives
 - timers
 - logging
 - system resource collecting
 - ... 
 
### Provide Ability for automated testing 

Existing automated testing tool [sdl_atf](https://github.com/smartdevicelink/sdl_atf) and 
[scripts](https://github.com/smartdevicelink/sdl_atf_test_scripts)
should be used for checking SDL functionality on the new platform.

#### Modification in sdl_atf

sdl_atf tool should be executed on host workstation, but SDL will be executed on remote virtual workstation. 

For support remote automated testing of SDL, the following proposal should be implemented: https://github.com/LuxoftAKutsan/sdl_evolution/blob/remote_atf_proxy/proposals/nnnn-remote_atf_testing.md

#### Modification in test scripts

Some scripts should be modified to use SDL on remote workstation.  
All operations with SDL files ( hmi_capabilities, preloaded_pt, etc ...) should be covered with wrappers that support either local or remote execution. 


## Testing Approach

The following items should be checked for all these platforms :
 
 - Compilation
 - Unit tests
 - Automated smoke
 - Existing features automated test cases (in case if feature is applicable on the virtual workstation)  

SDL will be tested on virtual workstation for each supported platform. 
For communication with mobile will be used **only** TCP transport.
For communication with HMI will be used TCP/WebSockets transport.

All supported platforms (Ubuntu, AGL, QNX) will share codebase for communication with mobile and HMI.  

#### Manual testing

Manual testing will be performed using WebHMI https://github.com/smartdevicelink/sdl_hmi
No changes in WebHMI are expected, and WebHMI will be executed on a real developer workstation.

Mobile application may be connected to SDL via TCP.

### Automated testing.

With some changes in ATF test framework and existing scripts SDL will be tested automatically on all 3 platforms. 

The same test scripts will be executed for : 
 - Ubuntu 
 - AGL
 - QNX
 
Test coverage will include:
  - smoke testing of SDL (basic SDL scenarios and 3 policy flows) 
  - all delivered features that are applicable for cross platform testing.
  
Each further delivered feature should be tested on all supported platforms.

#### Missed functionality on AGL and QNX

Open source SDL will no implement platform specific functionality on all supported systems.
It is OEM's responcibility to implement and check platform specific layer of SDL - OEM Adapter. 

This layer includes :
 - USB transport
 - Bluetooth transport
 - Multiple transports support.


## Potential downsides

N/A

## Impact on existing code

SDL core will be modified in platform specific places.
All components that use **utils** will be affected and need to be retested on target platform.
 
## Alternatives considered


#### Additional transport support on AGL, QNX virtual workstation

Add USB and Bluetooth transport support for virtualized QNX and AGL platforms.
These transport adapters will not be used for real OEMs, the only place to use them will be virtual workstations.
Also communication via this transport adapters actually will be emulated by virtual workstation.
Supporting of additional transports on virtual workstation is exhausted. There is no valuable reason to keep supporting many transports on multiple platforms except as best practice example for OEM suppliers. 

Pros : 
 - Testing may be done via additional transports

Cons:
- Big efforts for automation of transport testing 
- Big efforts for supporting many transports on multiple platform
- Transport specific code will not be actual for OEM suppliers
- Transport testing will be executed through virtualisation layer.

#### Using real hardware with QNX and AGL

SDL may not be tested on virtual workstation, but on real hardware with QNX, Ubuntu and AGL.

Pros : 
 - Real USB, Bluetooth transports may be used for testing.

Cons :
 - This approach will introduce additional efforts for resolving hardware specific problems. 
 - Each OEM supplier has its own hardware, and hardware specific code will be partially not actual.
 - SDL contributor will need to have real hardware (same as certified by SDL) to test their fixes and implementation.
 - Exhausted automation of transport testing. Automation pipelines should use real hardware that requires additional efforts for tuning.
