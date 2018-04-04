# Mobile Menu Manager

* Proposal: [SDL-0155](0155-mobile-menu-manager.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Accepted**
* Impacted Platforms: [iOS / Android]

## Introduction

This proposal is to create a new sub-manager to the Screen Manager that assists developers in creating menus and sub-menus.

## Motivation

As part of the Screen Manager effort to provide a layer of abstraction over bare RPCs, we should assist developers in creating their menus through a menu manager.

## Proposed solution

Below is an example iOS API. The Android API may be somewhat different, as there is currently no manager layer. However, this iOS API may be considered an example of what the Android API will look like, and assuming that the manager layer exists eventually, it should look quite similar.

### SDLMenuCell

A menu cell is a menu command that appears in the standard SDL menu listing. The title is required, while the icon, voice commands, and subCells are optional.

```objc
NS_ASSUME_NONNULL_BEGIN

typedef void(^SDLMenuCellSelectionHandler)();

@interface SDLMenuCell

@property (copy, nonatomic, readonly) NSString *title;
@property (strong, nonatomic, readonly, nullable) SDLArtwork *icon;
@property (copy, nonatomic, readonly, nullable) NSArray<NSString *> voiceCommands;
@property (copy, nonatomic, readonly, nullable) SDLMenuCellSelectionHandler handler;

// Note that if this is non-nil, the icon and handler will be ignored.
@property (copy, nonatomic, readonly, nullable) NSArray<SDLMenuCell *> subCells;

@end

NS_ASSUME_NONNULL_BEGIN
```

### SDLVoiceCommand

A voice command is the equivalent of an `AddCommand` RPC with only the `vrCommands` field set. This is a "hidden" menu command that responds to voice commands.

```objc
NS_ASSUME_NONNULL_BEGIN

typedef void(^SDLVoiceCommandSelectionHandler)();

@interface SDLVoiceCommand

@property (copy, nonatomic, readonly) NSArray<NSString *> voiceCommands;
@property (copy, nonatomic, readonly, nullable) SDLVoiceCommandSelectionHandler handler;

@end

NS_ASSUME_NONNULL_BEGIN
```

### SDLScreenManager Additions

Two additional properties are added to the screen manager, one for the current menu, and one for the current voice commands. Even though both use the same RPC API, they are conceptually different enough to have different APIs because, for example, you may wish to have constant voice commands available globally, even if your menu items change.

To update the menu, a developer would simply set the menu property with a new set of cells. Initially, this manager will probably be fairly naïve and simply delete all the old commands, followed by adding the new ones. In the future, the manager may be able to determine if it can delete specific cells and add new ones; however, this is complicated by the need to position items properly.

```objc
@interface SDLScreenManager

...

@property (copy, nonatomic) NSArray<SDLMenuCell *> *menu;
@property (copy, nonatomic) NSArray<SDLVoiceCommand> *voiceCommands;

...

@end
```

## Potential downsides

While extremely simple, the API could be more iOS-like by replicating the `UITableView` dataSource / delegate APIs. This could be accomplished in the eventual higher-level UI manager, however, changes may need to be made e.g. to add a delegate callback.

## Impact on existing code

This will be a minor version change.

## Alternatives considered

No alternatives were considered by the author other than that listed in `Potential Downsides`.
