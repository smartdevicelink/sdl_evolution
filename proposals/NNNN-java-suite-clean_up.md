# Java Suite Clean Up

* Proposal: [SDL-NNN](NNN-java-suite-clean-up.md)
* Author: [Joey Grover](https://github.com/joeygrover)
* Status: **Awaiting Review**
* Impacted Platforms: [Java Suite]



## Introduction

The Java Suite (formally Android) repo has progressed without the need for a major version for a while. However, it is time to remove old code from the project and create a more streamlined library. This proposal will go through the necessary changes and hopeful timing to clean up up the Java Suite library.


## Motivation

The Java Suite library has been preparing for a major version change. With the introduction of the Java SE and EE sections of the library. New classes were put in place that will take over for old, deprecated classes. The old classes carry a lot of technical debt with the exorbitant amount of public methods, outdated design patterns, and simply misaligned architecture. The new structure present in the pure Java sections show how much cleaner the SDL stack can be.

There is also a learning curve in trying to understand the current project structure for new developers and even those that have been working on the project in the past. The structure as it is was only meant to be a bridge until we could make a breaking change and with more people contributing to the project, it's important to make it as easy as possible for them to understand and be able to effectively contribute.


## Proposed solution

### Remove requirement for baseAndroid folder

The baseAndroid folder is used with symbolic links to certain source files and folders. This was done in order to reuse as much as possible without causing a breaking change in the Android subproject. It works well on Unix based systems, however, Windows in particular doesn't like the symbolic links and require an extra script to try and create them for the machine in which the library is being compiled. It is a less than ideal process.

As we accept a breaking change, we can move the Android subproject to all the same layers as the Java SE and EE projects. This will then allow the Android subproject to use the same `base` source set folder and remove the symbolic link source set folder currently used.

### Consistent Formating

Over the course of the library some coding standards have been missed or changed. The library should have a formatter ran on it to provide consistent formatting to all files. This will likely touch most files and could be seen as a very large change, however, it will only be superficial. These changes will be added to a coding style guide in the repo itself as well.

1. Copyright should be at the top of all files in a comment block before all code.
2. Spaces not tabs. All tabbed indents will be changed to four spaces.
2. Correct camel case and snake case. 
    1. All methods and local variables should be camel case (sdlManager)
    2. All class names should be snake case (SdlSession, ScreenManager)
    3. All class pacakages should be lower class with no special characters (com.smartdevicelink.managers)
3. Proper spacing between arguments and keywords. For example

Wrong:

```
if(x==y)
{
    z=1;
}
else{
    z=0;
}
``` 

Right:

```
if (x == y) {
    z = 1;
} else {
    z = 0;
}
``` 

### Remove Deprecated Code

Most to all deprecated code will be removed. This will include the all the old layers of SdlConnection, SdlSession(Android version), and WiProProtocol. Since the acceptance and integration of proposal [SDL 0194 - Android Transport Layer Overhaul](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0194-android-transport-overhaul.md), these layers are not needed anymore and only bloat the library while preventing the use of the `base` source set folder.

#### Remove old transports

Since all transports have moved to the router service, the old versions of those transports should be removed. Once the old `SdlProxyALM` code path is removed, the `SdlConnection`  and supporting classes will also be removed resulting in the old transports being unused.

### Update the AndroidX Support

The current support library has been deprecated and needs to be updated. The new library package Android is pushing is AndroidX aka Android Jetpack. The current support library does not function alongside the AndroidX package so app developers are currently forced to use the support library which is now deprecated. 

### Misc

#### Force proper integrations

If the library detects that an integration is incorrect it currently just logs a warning. With this major release an exception should be thrown in those cases so that developers know to make fixes right away. For example if the supplied `SdlRouterService` is from the library and not an extension in their app the library would throw an exception:

```java
if(localRouterClass.getName().equalsIgnoreCase(com.smartdevicelink.transport.SdlRouterService.class.getName())){
    throw new Exception("Can't use default SdlRouterService class, must be extended in your project");
}
```

This should also be done for incorrect implementations of the `meta-data` entries needed for a successful integration. These exceptions should be wrapped with a check to only cause this during debug builds and not production.

#### Add more annotations

Where it is possible to use more annotations, they will be added to help create predictable and error free development. Some of the new annotations we will be adding:

- [@CallSuper](https://developer.android.com/studio/write/annotations#call-super): overridden methods must call super
- [@RestrictTo](https://developer.android.com/studio/write/annotations#restrict): defines the visibility of a method/member variable (ie, subclasses, library, etc)

#### Refactor Package and Class Names

As previously described in the Consistent Formating section, some of the packages and class names don't follow the Java standard. These include package names that have capitol letters in them. Other classes are in packages that don't align well, these would be moved to better fitting packages. For example, `SystemCapabilityManager` is in the proxy package, but should be in the manager package. `SdlSession` is in the `SdlConnection` package but can be moved to another package such as `proxy` or `protocol` where it makes more sense. 


### Implement Accepted Proposals


#### SDL-0203 Cloud App Library - Phase 1 

> #### Implement sdl\_java\_common back into SDL Android Library
>
>After the creation of the common library, the SDL Android library will then need to include the sdl\_java\_common library and make the necessary changes to support it. This is almost guaranteed to be a breaking change so its timing could be pushed from the initial start of the proposal implementation.

This will contain the biggest amount of breaking changes. It will include moving the Android project onto the new manager layer away from the deprecated `proxy` classes and use the new `LifecycleManager`

#### SDL-0193 Update SDL-Android minimum SDK

>With the progression of SDL Android as a library, it has become necessary to update the minimum supported SDK from 8. The proposed minimum SDK will be API 16, Jelly Bean.

This would be the appropriate time to implement this accepted proposal. 

## Potential downsides

- Developers using any of the deprecated classes or integration methods will have to update their integration if they want to update their library version. This includes developers using the old `SdlProxyBase/ALM` integration as those classes will be removed. 


## Impact on existing code

- A lot of code is likely to be refactored to support the usage of the common base source set between the Java SE/EE and Android project. 
- Code will be formatted correctly which is only a cosmetic change.
- Deprecated code will be removed.
- Any usage of the support library will be replaced with the new AndroidX  counterpart.
- Where possible, we will try to restrict the accessibility of methods using annotations; this allows us to make changes to a wider scope of files in the future that won't be considered breaking.


## Alternatives considered

- Continue adding more features without removal of old code. This is becoming more and more of an issue. 
