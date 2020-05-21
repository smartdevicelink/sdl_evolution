# Screen Manager Layout Management

* Proposal: [SDL-0278](0278-screenmanager-layout-management.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Accepted**
* Impacted Platforms: [iOS / Java Suite / JavaScript Suite]

## Introduction
Adds a screen manager method for changing the current layout to a new layout.

## Motivation
The manager layer should be able to handle most tasks that used to be handled by RPCs, and the Screen Manager in particular should be able to handle manipulating the screen and templates without requiring the developer to fall back to RPCs in any cases.

One big area that it is currently missing is the ability to manage changing templates, currently done with the `SetDisplayLayout` RPC (on RPC spec <6.0) and `Show` RPC (on RPC spec >=6.0). This proposal adds a way to change the layout while taking care of backward compatibility concerns.

## Proposed solution
We will add a new screen manager method for changing the current layout to a new layout. This also includes updating the template's data immediately on v6.0+ and sequentially on <v6.0, as well as the template's color schemes on RPC v5.0+ systems.

### iOS APIs
```objc
@interface SDLScreenManager : NSObject

/// Change the current layout to a new layout, update the layout's night and day color schemes and update the text, graphics, buttons and template title.
- (void)changeLayout:(SDLTemplateLayout *)templateUpdates withCompletionHandler:(nullable SDLScreenManagerUpdateCompletionHandler)handler;

@end

@interface SDLTemplateLayout : NSObject

@property (copy, nonatomic) NSString *layoutName;
@property (copy, nonatomic, nullable) SDLTemplateColorScheme *dayColorScheme;
@property (copy, nonatomic, nullable) SDLTemplateColorScheme *nightColorScheme;
@property (copy, nonatomic, nullable) NSString *title;
@property (copy, nonatomic, nullable) NSString *textField1;
@property (copy, nonatomic, nullable) NSString *textField2;
@property (copy, nonatomic, nullable) NSString *textField3;
@property (copy, nonatomic, nullable) NSString *textField4;
@property (copy, nonatomic, nullable) NSString *mediaTrackTextField;
@property (copy, nonatomic) SDLTextAlignment textAlignment;
@property (copy, nonatomic, nullable) SDLMetadataType textField1Type;
@property (copy, nonatomic, nullable) SDLMetadataType textField2Type;
@property (copy, nonatomic, nullable) SDLMetadataType textField3Type;
@property (copy, nonatomic, nullable) SDLMetadataType textField4Type;
@property (strong, nonatomic, nullable) SDLArtwork *primaryGraphic;
@property (strong, nonatomic, nullable) SDLArtwork *secondaryGraphic;
@property (copy, nonatomic) NSArray<SDLSoftButtonObject *> *softButtonObjects;

- (instancetype)initWithLayout:(NSString *)layout;

- (instancetype)initWithPredefinedLayout:(SDLPredefinedLayout)predefinedLayout;

- (instancetype)initWithPredefinedLayout:(SDLPredefinedLayout)predefinedLayout title:(nullable NSString *)title textField1:(nullable NSString *)textField1 textField2:(nullable NSString *)textField2 textField3:(nullable NSString *)textField3 textField4:(nullable NSString *)textField4 primaryGraphic:(nullable SDLArtwork *)primaryGraphic secondaryGraphic:(nullable SDLArtwork *)secondaryGraphic softButtonObjects:(nullable NSArray<SDLSoftButtonObject *> *)softButtonObjects;

- (instancetype)initWithPredefinedLayout:(SDLPredefinedLayout)predefinedLayout dayColorScheme:(nullable SDLTemplateColorScheme *)dayColorScheme nightColorScheme:(nullable SDLTemplateColorScheme *)nightColorScheme title:(nullable NSString *)title textField1:(nullable NSString *)textField1 textField2:(nullable NSString *)textField2 textField3:(nullable NSString *)textField3 textField4:(nullable NSString *)textField4 mediaTrackTextField:(nullable NSString *)mediaTrackTextField textAlignment:(nullable SDLTextAlignment)textAlignment textField1Type:(nullable SDLMetadataType)textField1Type textField2Type:(nullable SDLMetadataType)textField2Type textField3Type:(nullable SDLMetadataType)textField3Type textField4Type:(nullable SDLMetadataType)textField4Type  primaryGraphic:(nullable SDLArtwork *)primaryGraphic secondaryGraphic:(nullable SDLArtwork *)secondaryGraphic softButtonObjects:(nullable NSArray<SDLSoftButtonObject *> *)softButtonObjects;

@end
```

### Java APIs
```java
abstract class BaseScreenManager extends BaseSubManager {
    /*
     * Change the current layout to a new layout, update the layout's night and day color schemes and update the text, graphics, buttons and template title.
     */   
    public void changeLayout(TemplateLayout templateUpdates, CompletionListener listener) {}
}

public class TemplateLayout {
    String layoutName;
    TemplateColorScheme dayColorScheme;
    TemplateColorScheme nightColorScheme;
    String title;
    String textField1;
    String textField2;
    String textField3;
    String textField4;
    String mediaTrackTextField;
    TextAlignment textAlignment;
    MetadataType textField1Type;
    MetadataType textField2Type;
    MetadataType textField3Type;
    MetadataType textField4Type;
    SdlArtwork primaryGraphic;
    SdlArtwork secondaryGraphic;
    List<SoftButtonObject> softButtonObjects;

    public TemplateLayout (@NonNull String layout) {}

    public TemplateLayout (@NonNull PredefinedLayout layout) {}

    public TemplateLayout (@NonNull PredefinedLayout layout, String title, String textField1, String textField2, String textField3, String textField4, SdlArtwork primaryGraphic, SdlArtwork secondaryGraphic, List<SoftButtonObject> softButtonObjects) {}

    public TemplateLayout (@NonNull PredefinedLayout layout, TemplateColorScheme dayColorScheme, TemplateColorScheme nightColorScheme, String title, String textField1, String textField2, String textField3, String textField4, String mediaTrackTextField, TextAlignment textAlignment, MetadataType textField1Type, MetadataType textField2Type, MetadataType textField3Type, MetadataType textField4Type, SdlArtwork primaryGraphic, SdlArtwork secondaryGraphic, List<SoftButtonObject> softButtonObjects) {}
}
```

### JavaScript APIs
The JavaScript APIs will be set up in a similar way to the Obj-C / Java APIs above. All changes will be at the discretion of the Project Maintainer. However larger changes that would impact the Objective-C code above (such as adding or removing a method) will require proposal revisions.

### Additional Implementation Notes
1. When connected to systems running RPC <6.0, the screen manager should send `SetDisplayLayout` to change the template. The graphics will be uploaded before sending the `SetDisplayLayout`. On receipt of the `SetDisplayLayout` response, a `Show` will be sent by the `ScreenManager` to update the text, graphic, and button information. The current implementation of the sub-managers will require the soft buttons to be sent after the rest of the template update, but that implementation detail could change in the future.
1. When connected to systems running RPC >=6.0, the screen manager will send `Show` to change the template. The `ScreenManager` will upload the graphics before sending the `Show`. The current implementation of the sub-managers will require the soft buttons to be sent after the rest of the template update, but that implementation detail could change in the future.
1. If the system is running RPC >=5.0 but less than 6.0, update the template's day and night color schemes via the  `SetDisplayLayout` request. If the system is running RPC >=6.0, update the template's day and night color schemes via the `Show` request's `templateConfiguration`. 

## Potential downsides
The author can think of no downsides.

## Impact on existing code
This would be a minor version update to all libraries implementing a screen manager, namely, the iOS, Java, and JavaScript app libraries.

## Alternatives considered
1. A previous version of this proposal supported separating out SDL code by layout. We could return to that style of update instead.
