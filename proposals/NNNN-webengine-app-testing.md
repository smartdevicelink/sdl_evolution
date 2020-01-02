# WebEngine App Testing

* Proposal: [SDL-NNNN](NNNN-webengine-app-testing.md)
* Author: [Nick Schwab](https://github.com/nickschwab), [Chris Rokita](https://github.com/crokita)
* Status: **Awaiting review**
* Impacted Platforms: [Manticore]

## Introduction

 To provide true production-like testing of WebEngine apps, this proposal introduces the ability for developers to upload their compressed WebEngine app bundle (zip file) to Manticore and have their application automatically establish a connection to Core's WebSocket Server.

## Motivation

According to [SDL-0240: WebEngine support for SDL JavaScript](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0240-sdl-js-pwa.md), WebEngine app developers will be able to test their applications using a direct connection by exposing Core's WebSocket server connection details on the Manticore interface. While direct connections are ideal for testing during active development, this method does not provide a true testing scenario for how WebEngine applications will be loaded and executed in production environments.

## Proposed solution

The proposed solution is to add a "Add WebEngine App" option to the Manticore UI under the "Connect Apps" menu. This button would navigate to a sub-section to allow the developer to select their zip file from their computer and submit it for processing by Manticore.

Once the zip file is submitted, Manticore will unzip the file contents to the Manticore instance's filesystem using a Node.js server and return the fully qualified path of the WebEngine application's HTML entry point. The Manticore front-end will render the returned URL in a hidden iFrame for containerization, which will connect to Core's WebSocket Server and execute the application's logic in accordance to [SDL-0240](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0240-sdl-js-pwa.md).

When a WebEngine app is running, the app's name (or App ID, depending on availability) will appear in the "Connected Apps" menu. When clicked, the Manticore user will be presented with the option to terminate the application (and therefore remove it from the HMI and purge the application's data on the filesystem).

## Potential downsides

One potentially-perceived downside to the proposed solution is the security of writing user-uploaded files to Manticore's filesystem. However, user files are already written to the filesystem via PutFile RPCs, and the filesystem is containerized for each Manticore instance to prevent malicious content from affecting other Manticore instances.

Another potential downside is the performance of the proposed iFrames. Like the Generic HMI, the iFrames used to render and execute the app developer's WebEngine app are powered by the developer's browser rather than using cloud-based resources. However, modern-day computers (and even low-end devices like the Raspberry Pi) contain sufficient resources to run these basic HTML and JavaScript files unless put under stress by other unrelated processes.

## Impact on existing code

The proposed solution does not introduce any breaking changes, but simply adds to Manticore's features. The changes required to Manticore's front-end will be minimal, as many existing UI components can be re-used to achieve the proposed solution. Similarly, the changes required to Manticore's back-end to act as a basic file server are fairly trivial and can utilize existing code/practices.

## Alternatives considered

One alternative considered was to run the decompressed WebEngine package in a headless browser using Manticore's cloud resources rather than the client's browser. This alternative would offer no noticeable performance improvements over client-side iFrames in most cases, and would result in additional hosting costs to the SDLC since it would reduce the amount of Manticore instances capable of running on each Manticore server.

Another alternative considered was to store the decompressed WebEngine package on a publicly-accessible auto-purging Amazon S3 bucket instead of Manticore's ephemeral filesystem. Since Manticore's filesystem has sufficient storage available for WebEngine apps and is automatically purged when a developer stops their Manticore instance, utilizing Amazon S3 would result in higher operational costs without any added benefit.

Finally, a third alternative considered was to make significant changes to Generic HMI to act as a web server rather than static HTML, CSS, and JavaScript in order to support the ability to store, decompress, and serve WebEngine apps. Since Manticore already has the ability to act in such a fashion, this alternative was deemed unnecessary.