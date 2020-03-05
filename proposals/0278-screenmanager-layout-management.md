# Screen Manager Layout Management

* Proposal: [SDL-0278](0278-screenmanager-layout-management.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **In Review**
* Impacted Platforms: [iOS / Java Suite / JavaScript Suite]

## Introduction
Adds a screen manager method for changing the current layout to a new layout.

## Motivation
The manager layer should be able to handle most tasks that used to be handled by RPCs, and the Screen Manager in particular should be able to handle manipulating the screen and templates without requiring the developer to fall back to RPCs in any cases.

One big area that it is currently missing is the ability to manage changing templates, currently done with the `SetDisplayLayout` RPC (on RPC spec <6.0) and `Show` RPC (on RPC spec >6.0). This proposal adds a way to change the layout while taking care of backward compatibility concerns.

## Proposed solution
We will add a new screen manager method for changing the current layout to a new layout.

### iOS APIs
```objc
@interface SDLScreenManager : NSObject

/// Change the current layout to a new layout. You can get a list of SDL-defined layout strings in SDLPredefinedLayout.
- (void)changeLayout:(NSString *)newLayout withCompletionHandler:(SDLScreenManagerUpdateCompletionHandler)handler;

@end
```

### Java APIs
```java
abstract class BaseScreenManager extends BaseSubManager {
    public void changeLayout(String newLayout, CompletionListener listener);
}
```

### JavaScript APIs
The JavaScript APIs will be set up in a similar way to the Obj-C / Java APIs above. All changes will be at the discretion of the Project Maintainer. However larger changes that would impact the Objective-C code above (such as adding or removing a method) will require proposal revisions.

### Additional Implementation Notes
1. When connected to systems running RPC <6.0, the screen manager should send `SetDisplayLayout` to change the template, and on systems running RPC >6.0, the screen manager should send `Show` to change the template.

## Potential downsides
The author can think of no downsides.

## Impact on existing code
This would be a minor version update to all libraries implementing a screen manager, namely, the iOS, Java, and JavaScript app libraries.

## Alternatives considered
1. A previous version of this proposal supported separating out SDL code by layout. We could return to that style of update instead.
