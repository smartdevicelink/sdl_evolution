# Generic Mobile Extensions

* Proposal: [SDL-NNNN](NNNN-filename.md)
* Author: [Joel Fischer](https://github.com/joeljfischer), [Joey Grover](https://github.com/joeygrover)
* Status: **Awaiting review**
* Impacted Platforms: iOS, Android

## Introduction
This proposal is to make additions to the iOS and Android SDL SDKs to incorporate generic extensions. Generic extensions are functionality and code that are started by the SDL lifecycle, but then allowed to interact with the SDL APIs as a free agent, that is, in the same capacity as an app developer may.

## Motivation
The primary motivation of this is to build a system for OEMs and other content providers to provide a way for apps to build off of their unique platforms without having to build that functionality into open-source SDL, while also providing some level of minimal APIs to tell those extensions when they should start, stop, and other specialized information.

## Proposed solution
The proposed solution is to build an **Extension Manager** into the lifecycle management of the SDL mobile libraries. The developer would add extensions to this extension manager. The SDL mobile library would then be responsible for telling the extensions when they ought to start and stop, and therefore to tell the developer when everything is loaded and ready.

With the current design, the extensions do not have access to internal SDL data, such as raw protocol data. Like the developer, they only have access to RPCs and exposed managers, such as the file manager and permissions manager.

## Detailed solution
### iOS
For iOS, this solution would take advantage of the redesigned v4.3.0 lifecycle changes. In v4.3.0, the `SDLLifecycleManager` makes sure its own internal extensions are loaded, then tells the developer to begin using their integration. The extension manager would change this slightly. The startup sequence would now look like this:

1. Developer declares configuration.
2. Developer declares extensions.
3. Lifecycle Manager detects connection.
4. Lifecycle Manager connects and registers based on configuration.
5. Lifecycle Manager starts internal managers and waits for them to declare they are finished starting.
6. Lifecycle Manager starts external extension managers and waits for them to declare they are finished starting.
7. Lifecycle Manager tells developer they may begin their integration.

Steps 2 and 6 are new with this proposal.

#### Designing the extension
The extension would largely be free to interact with SDL in the same way as the developer, simply by calling methods. However, it's lifecycle would be run by the extension manager, therefore SDL would require the extension to have a class conforming to a protocol.

The protocol would look like this:
```
@protocol SDLExtensionType: NSObject
- (void)startWithCompletionHandler:(void (^)(BOOL success, NSError *error))completionHandler;
- (void)stop;
- (NSString *)extensionInterfaceVersion; // This starts at 1.0 and is semantically versioned. Adding / deprecating methods increases the minor version, while removing / changing methods increases the major version.
@end
```

### Android

## Impact on existing code

## Alternatives considered
