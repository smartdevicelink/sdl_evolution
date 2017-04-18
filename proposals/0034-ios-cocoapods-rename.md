# Rename Cocoapods Project to "SmartDeviceLink"

* Proposal: [SDL-0034](0034-ios-cocoapods-rename.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Accepted**
* Impacted Platforms: iOS

## Introduction

In order to properly support Swift into the future, this proposal is to deprecate the current Cocoapods podspec "SmartDeviceLink-iOS" in favor of a new one "SmartDeviceLink".

## Motivation

Currently, if you get the iOS library project via download or from Carthage, the project will be a framework known as "SmartDeviceLink". This means that when the developer imports the project using Swift, they import it as `import SmartDeviceLink`. However, if the library is retrieved via Cocoapods, because the podspec names the project "SmartDeviceLink-iOS", the developer would have to import it as `import SmartDeviceLink-iOS`. This is obviously not ideal, but not a large issue. However, now that we have a Swift helper project that hooks into the main Obj-C project, this causes an incompatibility. The Swift files must import the SmartDeviceLink project in some way, but because there are two different possible import statements, when retrieving the library, either Cocoapods or a normal retrieve will not be compilable.

## Proposed solution

The proposed solution is to use the built in "deprecate in favor of" [feature of Cocoapods](http://stackoverflow.com/a/36928723/1221798). We would create a new podspec, `smartdevicelink.podspec`. This new podspec would support the subspec for Swift, whereas the old (current) one would not, because the Swift module would not compile under the current podspec. As noted in the above link, we would then run:

```
pod trunk deprecate OLD_SPEC --in-favor-of=NEW_SPEC
```

This would notify anyone who's using the old podspec that they need to update to use the new one, which is a one word change in their podfile, simply to change "SmartDeviceLink-iOS" to "SmartDeviceLink".

## Potential downsides

The main potential downside is that we would have to support both podspecs for a little while, until the next major version. We would be able to get stats on how many people are using our old podspec based on the number of monthly downloads using it. This is not a big deal, we will just have to make sure people are aware of the correct podspec to use, and Cocoapods helps us here.

## Impact on existing code

As mentioned in potential downsides, all developers using Cocoapods as their dependency manager will have to update their podfile from saying "SmartDeviceLink-iOS" to say "SmartDeviceLink", they will be notified by Cocoapods whenever they update their dependencies that they need to make this change.

## Alternatives considered

The only alternative is to not allow Cocoapods users to use the Swift helper library, but this is deemed not an allowable solution.
