# Deliver build configuration

* Proposal: [SDL-NNNN](nnnn-deliver-build-configuration.md)
* Author: [Alexander Kutsan](https://github.com/LuxoftAKutsan)
* Status: **Awaiting review**
* Impacted Platforms: [Core]

## Introduction

Add text file with information about SDL build configuration as part of SDL delivery. 

## Motivation

After installation of SDL (`make install`) there are couple of files besides SDL binary:

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


Only these files (except 3rd party libraries) are required for SDL testing.
But there is no information about flags that were used for SDL compiling. 
And there is no way to find out this information from delivered files

Because of that automated scripts should be manually configured for each build options of SDL.
Adding information about build options will add possibility to find out what SDL build type is used
and automatically modify some test steps during script execution. 

SDL build flags that affect SDL behaviour :
 - EXTENDED_POLICY (regulates policy flow)
 - REMOTE_CONTROL (switch on/off remote control functionality)
 - BUILD_BT_SUPPORT (switch on/off Bluetooth support)
 - BUILD_USB_SUPPORT (switch on/off USB support)
 - ENABLE_SECURITY (switch on/off security support)
 - EXTENDED_MEDIA_MODE (switch on/off additional media features)
 - TELEMETRY_MONITOR (share information about CPU/MEM usage and time consumptions for RPC processing) 
 - HMI (used hmi type: Dbus or web HMI)
 
Some of these flags are not supported, but exist, and may affect SDL behavior. 


## Proposed solution
Solution is to create text file `build_options.txt` in format:

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

It should impact only configuration files, no SDL behavior and no SDL code should be changed. 

## Alternatives considered

Copy CMakeCache.txt to bin folder during `make install`, but CMakeCache.txt contains a lot of redundant information. 
