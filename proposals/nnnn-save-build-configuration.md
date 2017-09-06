# Save build configuration

* Proposal: [SDL-NNNN](nnnn-save-build-configuration.md)
* Author: [Alexander Kutsan](https://github.com/LuxoftAKutsan)
* Status: **Awaiting review**
* Impacted Platforms: [Core]

## Introduction

Adding text file with information of build configuration as part of sdl delivery. 

## Motivation

After instalation of sdl `make install` there are couple of files except sdl binary :

- audio.8bit.wav         
- libPolicy.so        
- mycert.pem  
- sample_policy_manager.py  
- smartDeviceLink.ini
- hmi_capabilities.json  
- libUtils.a          
- mykey.pem   
- sdl_preloaded_pt.json     
- start.sh
- libappenders.so        
- log4cxx.properties  
- plugins     
- smartDeviceLinkCore       


Only this files(expect 3rd party libraries) required for sdl testing.
But there is not information about flags that used for sdl compiling. 
And there is no way to find out it only from delivery files.

Because of that automated scripts should be manualy configured for each build type of SDL.
Adding information about build option will add possibility to find out what SDL build type is using
and autimaticaly modify some test steps during script execution. 

SDL Build flags that affect sdl behaviour :
 - EXTENDED_POLICY (Regulates policy flow)
 - REMOTE_CONTROLL (switch on or switch of remote controll functionality)
 - BUILD_BT_SUPPORT (build SDL with Bluetooth support)
 - BUILD_USB_SUPPORT (build SDL with USB support)
 - ENABLE_SECURITY (build SDL with security  support)
 - EXTENDED_MEDIA_MODE (build SDL with additional media features)
 - TELEMETRY_MONITOR (share informatin about cpu/mem usage and time consuptions for RPC processing) 
 - HMI (hmi type, used : Dbus or web HMI)
 
Some of this flags not supported, but exist, may be regulated and affect sdl behaviour. 


## Proposed solution
Solution is to create text file `build_options.txt` in format :

```ini
 // description of build option
 BUILD_OPTION:TYPE=BUILD_OPTION_VALUE
 
 // description of build option 2
 BUILD_OPTION2:TYPE=BUILD_OPTION2_VALUE
 ... 
```
Syntax is the same as in CMakeCache.txt. 



## Potential downsides

N/A

## Impact on existing code

It should impact only configuration files, no behaviour and no code should be changed. 

## Alternatives considered

Copy CMakeCache.txt to bin folder during `make install`, but CMakeCache.txt contains a lot of redundant information. 
