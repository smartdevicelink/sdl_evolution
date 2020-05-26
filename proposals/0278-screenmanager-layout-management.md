# Screen Manager Layout Management

* Proposal: [SDL-0278](0278-screenmanager-layout-management.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Accepted**
* Impacted Platforms: [iOS / Java Suite / JavaScript Suite]

## Introduction
Adds a screen manager method for changing the current layout to a new layout.

## Motivation
The manager layer should be able to handle most tasks that used to be handled by RPCs, and the Screen Manager in particular should be able to handle manipulating the screen and templates without requiring the developer to fall back to RPCs in any cases.

One big area that it is currently missing is the ability to manage changing templates, currently done with the `SetDisplayLayout` RPC (on RPC spec <v6.0) and `Show` RPC (on RPC spec v6.0+). This proposal adds a way to change the layout while taking care of backward compatibility concerns.

## Proposed solution
We will add a new screen manager method for changing the current layout to a new layout. This also includes updating the template's night and day color schemes on RPC v5.0+ systems. If the template update is batched with text, graphic updates on v6.0+ then all updates will be sent with one `Show` RPC (if buttons are also batched in the update, it will currently require a another `Show` request - this implementation detail could changein the future). On systems <v6.0, the `Show` request will be sent after  the `SetDisplayLayout`. If the layout update fails while batching, then the text, graphics, buttons or template title will also not be updated.

### iOS APIs
```objc
@interface SDLScreenManager : NSObject

/// Change the current layout to a new layout and optionally update the layout's night and day color schemes. The values set for the text, graphics, buttons and template title persist between layout changes. To update the text, graphics, buttons and template title at the same time as the template, batch all the updates between `beginUpdates` and `endUpdates`. If the layout update fails while batching, then the updated text, graphics, buttons or template title will also not be updated.
- (void)changeLayout:(SDLTemplateConfiguration *)templateConfiguration withCompletionHandler:(nullable SDLScreenManagerUpdateCompletionHandler)handler;

@end
```

### Java APIs
```java
abstract class BaseScreenManager extends BaseSubManager {
    /*
     * Change the current layout to a new layout and optionally update the layout's night and day color schemes. The values set for the text, graphics, buttons and template title persist between layout changes. To update the text, graphics, buttons and template title at the same time as the template, batch all the updates between `beginTransaction` and `commit`. If the layout update fails while batching, then the updated text, graphics, buttons or template title will also not be updated.
     */   
    public void changeLayout(TemplateConfiguration templateConfiguration, CompletionListener listener)
}
```

### JavaScript APIs
The JavaScript APIs will be set up in a similar way to the Obj-C / Java APIs above. All changes will be at the discretion of the Project Maintainer. However larger changes that would impact the Objective-C code above (such as adding or removing a method) will require proposal revisions.

### Additional Implementation Notes
1. When connected to systems running RPC v6.0+, the `ScreenManager` will send `Show` request to change the template. If the template update is batched with other updates, the  `ScreenManager` will upload the graphics before sending a single `Show` request with the template, text, and graphic information. The current implementation of the sub-managers will require the soft buttons to be sent after the rest of the template update in a separate `Show` request, but that implementation detail could change in the future. 
1. When connected to systems running RPC <v6.0, the screen manager will send a `SetDisplayLayout` to change the template. If the template update is batched with other updates, on receipt of a successful `SetDisplayLayout` response, the graphics will first be uploaded and then a `Show` request will be sent by the `ScreenManager` to update the text, graphic, and button information. If the `SetDisplayLayout` request fails, then the graphics and the `Show` request will not be sent in order to make sure that the behavior of the screen manager on RPC <v6.0 is consistent with RPC v6.0+. The current implementation of the sub-managers will require the soft buttons to be sent in a separate `Show` request after the rest of the template update (assuming the template update succeeds), but that implementation detail could change in the future.
1. If the system is running RPC v5.0+ but less than v6.0, the template's day and night color schemes will be updated via the  `SetDisplayLayout` request. If the system is running RPC v6.0+, the template's day and night color schemes will be updated via the `Show` request's `templateConfiguration`. 

## Potential downsides
The author can think of no downsides.

## Impact on existing code
This would be a minor version update to all libraries implementing a screen manager, namely, the iOS, Java, and JavaScript app libraries.

## Alternatives considered
1. A previous version of this proposal supported separating out SDL code by layout. We could return to that style of update instead.
