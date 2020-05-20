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
We will add a new screen manager method for changing the current layout to a new layout. This also includes updating the template's night and day color schemes when the feature is available on systems supporting RPC Spec 5.0.0 or newer. 

### iOS APIs
```objc
@interface SDLScreenManager : NSObject

/// Change the current layout to a new layout. The layout's night and day color schemes will stay the same.
- (void)changeLayout:(SDLPredefinedLayout)newLayout withUpdateCompletionHandler:(SDLScreenManagerUpdateCompletionHandler)handler;

/// Change the current layout to a new layout and update the layout's night and day color schemes.
- (void)changeLayout:(SDLPredefinedLayout)newLayout dayColorScheme:(nullable SDLTemplateColorScheme *)dayColorScheme nightColorScheme:(nullable SDLTemplateColorScheme *)nightColorScheme withUpdateCompletionHandler:(SDLScreenManagerUpdateCompletionHandler)handler;

/// Change the current layout to a new layout, update the layout's night and day color schemes and update the text, graphics, buttons and template title.
- (void)changeLayout:(SDLPredefinedLayout)newLayout dayColorScheme:(nullable SDLTemplateColorScheme *)dayColorScheme nightColorScheme:(nullable SDLTemplateColorScheme *)nightColorScheme textField1:(nullable NSString *)textField1 textField2:(nullable NSString *)textField2 textField3:(nullable NSString *)textField3 textField4:(nullable NSString *)textField4 mediaTrackTextField:(nullable NSString *)mediaTrackTextField textField1Type:(nullable SDLMetadataType)textField1Type textField2Type:(nullable SDLMetadataType)textField2Type textField3Type:(nullable SDLMetadataType)textField3Type textField4Type:(nullable SDLMetadataType)textField4Type textAlignment:(nullable SDLTextAlignment)textAlignment title:(nullable NSString *)title primaryGraphic:(nullable SDLArtwork *)primaryGraphic secondaryGraphic:(nullable SDLArtwork *)secondaryGraphic softButtonObjects:(nullable NSArray<SDLSoftButtonObject *> *)softButtonObjects withUpdateCompletionHandler:(SDLScreenManagerUpdateCompletionHandler)handler;

@end
```

### Java APIs
```java
abstract class BaseScreenManager extends BaseSubManager {

/*
 * Change the current layout to a new layout. The layout's night and day color schemes will stay the same.
 */
public void changeLayout(PredefinedLayout newLayout, CompletionListener listener);
   
/*
 * Change the current layout to a new layout and update the layout's night and day color schemes.
 */    
public void changeLayout(PredefinedLayout newLayout, TemplateColorScheme dayColorScheme, TemplateColorScheme nightColorScheme, CompletionListener listener);

/*
 * Change the current layout to a new layout, update the layout's night and day color schemes and update the text, graphics, buttons and template title.
 */   
public void changeLayout(PredefinedLayout newLayout, TemplateColorScheme dayColorScheme, TemplateColorScheme nightColorScheme, String textField1, String textField2, String textField3, String textField4, String mediaTrackTextField, MetadataType textField1Type, MetadataType textField2Type, MetadataType textField3Type, MetadataType textField4Type,TextAlignment textAlignment, String title, SdlArtwork primaryGraphic, SdlArtwork secondaryGraphic, List<SoftButtonObject> softButtonObjects, CompletionListener listener);
}
```

### JavaScript APIs
The JavaScript APIs will be set up in a similar way to the Obj-C / Java APIs above. All changes will be at the discretion of the Project Maintainer. However larger changes that would impact the Objective-C code above (such as adding or removing a method) will require proposal revisions.

### Additional Implementation Notes
1. When connected to systems running RPC <6.0, the screen manager should send `SetDisplayLayout` to change the template. On receipt of  the `SetDisplayLayout` response, a `Show` will be sent by the existing Text and Graphic Manager and Soft Button Manager to update the text, graphic, and button information. 
1. When connected to systems running RPC >=6.0, the screen manager will send `Show` to change the template. The existing Text and Graphic Manager and Soft Button Managers will be used to send the updated `Show`. The Text and Graphic Manager will be used to upload the primary and secondary graphics and send the `Show` request. On receipt of the `Show` response, the Soft Button Manager will be used to send the updated soft buttons. 
1. If the system is running RPC >=5.0 but less than 6.0, update the template's day and night color schemes via the  `SetDisplayLayout` request. If the system is running RPC >=6.0, update the template's day and night color schemes via the `Show` request's `templateConfiguration`. 

## Potential downsides
The author can think of no downsides.

## Impact on existing code
This would be a minor version update to all libraries implementing a screen manager, namely, the iOS, Java, and JavaScript app libraries.

## Alternatives considered
1. A previous version of this proposal supported separating out SDL code by layout. We could return to that style of update instead.
