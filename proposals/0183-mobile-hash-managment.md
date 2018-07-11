# Automatic Mobile Resumption Hash Management

* Proposal: [SDL-0183](0183-mobile-hash-managment.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Returned for Revisions**
* Impacted Platforms: iOS / Android

## Introduction

Add automatic hash management to the manager layer of the libraries. Automatically send the resumption hash upon connection and refill the managers with the data they contained at the time that hash was retrieved.

## Motivation

With the addition of the manager layer, hashes have become significantly more difficult to use. While hashes can be sent and the data will resume on the system, the manager-layer does not know this and cannot restore the data that is currently in use. This may cause bugs or for data to be resent in its entirety that merely needs to be updated.

## Proposed solution

The general proposed solution is to store similar sorts of data that the head unit stores for a hash. When the hash is accepted, the library should auto-restore data into the various managers as well. This will allow the developer to interact with the managers as desired.

This change would affect the sub-screen managers only: the Choice Set, Menu, Text and Graphic, and Soft Button Managers.

### iOS

On iOS, there are two main (native) solutions available: Core Data and `NSKeyedArchiver`, but `NSKeyedArchiver` is determined to be the best fit for our needs. `NSKeyedArchiver` is a system that serializes object models conforming to the `NSCoding` protocol into raw data and saves that to a file. [NSHipster has a good overview](http://nshipster.com/nscoding/) of `NSCoding`.

#### Coding support

`SDLMenuCell`, `SDLChoiceCell`, `SDLSoftButtonObject`, `SDLSoftButtonState`, and the `SDLScreenManager` template data types (such as `SDLMetadataType` and `SDLArtwork`) would be given `NSCoding` support and saved when each manager disconnects, along with the latest hash.

#### SDLScreenManagerDelegate

One significant issue is that blocks will not work with resumption hashes as they cannot be stored. This means the entire structure of response blocks and command blocks will have to change or be updated in some way. The only way to fix this would be a delegate system complementary to the block system and the developer would need to be informed that delegates are the only callback that will fire on resumed sessions. This means that we will have to add a delegate system to the screen managers where it does not already exist.

The Screen Manager would add a new protocol `SDLScreenManagerDelegate`:

```objc
@protocol SDLScreenManagerDelegate <NSObject>

- (void)screenManager:(SDLScreenManager *)screenManager didSelectMenuCell:(SDLMenuCell *)cell atIndexPath:(NSIndexPath *)indexPath;

- (void)screenManager:(SDLScreenManager *)screenManager didSelectVoiceCommand:(SDLVoiceCommand *)voiceCommand atIndexPath:(NSIndexPath *)indexPath;

- (void)screenManager:(SDLScreenManager *)screenManager didSelectSoftButton:(SDLSoftButtonObject *)softButton withState:(SDLSoftButtonState *)state;

- (void)screenManagerDidUpdateScreenState:(SDLScreenManager *)screenManager;

// The choice set is already handled by a delegate

@end
```

Resumed data would **only** fire through this delegate.

### Android

Android will have to make similar changes and updates to the (yet to come) manager layer. Android has SQLite built in, but will likely store a JSON object into SharedPreferences when the managers disconnect and load on connection. A similar delegate-style interface may have to be added to handle restored commands.

## Potential downsides

The primary potential downside is that code blocks cannot be stored and restored this way. This means that we need a new way to call handlers. The only way that will work is through delegates / interfaces. This is a significant downside.

## Impact on existing code

This will be a minor version change. Accounting for corner cases may require significant work.

## Alternatives considered

1. An alternative could be to use a 3rd party solution such as Realm to persist data. Realm is as powerful as Core Data, but nearly as easy to use as `NSKeyedArchiver` and also cross-platform. However, requiring apps to import a third-party library for this purpose is deemed too onerous.
2. The other main iOS solution is to use Core Data. Core Data is based on SQLite (as opposed to `NSKeyedArchiver`'s raw data), is faster, supports automatic migrations of data, and allows querying, however, it is *significantly* more complex to use and was deemed more than is needed.
3. Instead of using a delegate, the developer could be given the opportunity to add new blocks to the resumed data using some sort of resumption delegate.
