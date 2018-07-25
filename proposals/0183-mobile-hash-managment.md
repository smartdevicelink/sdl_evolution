# Automatic Mobile Resumption Hash Management

* Proposal: [SDL-0183](0183-mobile-hash-managment.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Accepted**
* Impacted Platforms: iOS / Android

## Introduction

Add automatic hash management to the manager layer of the libraries. Automatically send the resumption hash upon connection and enable the reuse of data the developer sets if it already exists.

## Motivation

With the addition of the manager layer, hashes have become significantly more difficult to use. While hashes can be sent and the data will be resumed on the system, the manager-layer does not know this and cannot restore the data that is currently in use. This may cause bugs or for data to be resent in its entirety that merely needs to be reused.

## Proposed solution

The general proposed solution is to store similar sorts of data that the head unit stores for a hash. When the hash is accepted, data will not be set onto the managers. Instead, the data will be held in a "waiting" state on the new `SDLResumptionManager` manager, though it should be inspectable by the developer. When the developer sets up their menus and soft buttons, if those objects exactly match what has been stored, no RPCs will be sent, but callbacks will be setup for those objects.

A new delegate method will be added to `SDLManagerDelegate` and its Android equivalent.

```objc
- (void)dataDidResumeWithResumptionManager:(SDLResumptionManager *)resumptionManager;
```

The `SDLResumptionManager` will handle archiving and unarchiving data as well as matching and restoring data set by the other managers as appropriate.

```objc
@interface SDLResumptionManager

// Current state of resumption data
@property (copy, nonatomic, nullable) NSString *textField1;
@property (copy, nonatomic, nullable) NSString *textField2;
@property (copy, nonatomic, nullable) NSString *textField3;
@property (copy, nonatomic, nullable) NSString *textField4;
@property (copy, nonatomic, nullable) NSString *mediaTrackTextField;
@property (strong, nonatomic, nullable) SDLArtwork *primaryGraphic;
@property (strong, nonatomic, nullable) SDLArtwork *secondaryGraphic;
@property (copy, nonatomic) SDLTextAlignment textAlignment;
@property (copy, nonatomic, nullable) SDLMetadataType textField1Type;
@property (copy, nonatomic, nullable) SDLMetadataType textField2Type;
@property (copy, nonatomic, nullable) SDLMetadataType textField3Type;
@property (copy, nonatomic, nullable) SDLMetadataType textField4Type;

#pragma mark Soft Buttons

@property (copy, nonatomic) NSArray<SDLSoftButtonObject *> *softButtonObjects;

#pragma mark Menu

@property (copy, nonatomic) NSArray<SDLMenuCell *> *menu;
@property (copy, nonatomic) NSArray<SDLVoiceCommand *> *voiceCommands;

#pragma mark Choice Sets

/**
 Cells will be hashed by their text, image names, and VR command text. When assembling an SDLChoiceSet, you can pull objects from here, or recreate them. The preloaded versions will be used so long as their text, image names, and VR commands are the same.
 */
@property (copy, nonatomic, readonly) NSSet<SDLChoiceCell *> *preloadedChoices;

@end
```

### iOS

On iOS, there are two main (native) solutions available for persisting the data on disk: Core Data and `NSKeyedArchiver`, but `NSKeyedArchiver` is determined to be the best fit for our needs. `NSKeyedArchiver` is a system that serializes object models conforming to the `NSCoding` protocol into raw data and saves that to a file. [NSHipster has a good overview](http://nshipster.com/nscoding/) of `NSCoding`.

#### Coding support

`SDLMenuCell`, `SDLChoiceCell`, `SDLSoftButtonObject`, `SDLSoftButtonState`, and the `SDLScreenManager` template data types (such as `SDLMetadataType` and `SDLArtwork`) would be given `NSCoding` support and saved when each manager disconnects, along with the latest hash.

### Android

Android will have to make similar changes and updates to the (yet to come) manager layer. Android has SQLite built in, but will likely store a JSON object into SharedPreferences when the managers disconnect and load on connection. The `ResumptionManager` will have to exist on Android as well.

## Potential downsides

The primary potential downside is that code blocks cannot be stored and restored this way. This means that we need a new way to call handlers. The only way that will work is through delegates / interfaces. This is a significant downside.

## Impact on existing code

This will be a minor version change. Accounting for corner cases may require significant work.

## Alternatives considered

1. An alternative could be to use a 3rd party solution such as Realm to persist data. Realm is as powerful as Core Data, but nearly as easy to use as `NSKeyedArchiver` and also cross-platform. However, requiring apps to import a third-party library for this purpose is deemed too onerous of a requirement.
2. The other main iOS solution is to use Core Data. Core Data is based on SQLite (as opposed to `NSKeyedArchiver`'s serialized data), is faster, supports automatic migrations of data, and allows querying, however, it is *significantly* more complex to use and was deemed more complex than is needed.
3. Instead of an `SDLResumptionManager`, each manager could store its own resumption data. I actually prefer this approach, but couldn't make the interface work and still expose the current state of the resumed data. We wouldn't want to duplicate items like `textField1` with `resumedTextField1` as that would bloat classes significantly. We could have something like a `resumedData` single property, but then we'd need a multitude of new classes to handle exposing that data. If we decided not to expose the resumed data for developer inspection, this approach would be preferable. It's fairly awkward to expose it all on one manager object as it is, but I deemed the benefit for developers of being able to inspect this data was greater than the awkwardness.

## Previous Approaches

* A previous version of this proposal advocated for an approach of setting all data back into the managers. There was a significant downside that callback blocks could not be stored and resumed, and the mitigating approach fell too far short.
