# JavaScript Suite SDL Manager

* Proposal: [SDL-NNNN](NNNN-js-suite-managers.md)
* Author: [Chris Rokita](https://github.com/crokita)
* Status: **Awaiting review**
* Impacted Platforms: JavaScript Suite

## Introduction

In a similar vein to [this proposal](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0171-android-manager-apis.md), the goal is to introduce a manager layer to the JavaScript suite, closely matching the Android and iOS manager APIs. These manager classes are designed to abstract out complex flows and state for common tasks, such as file handling and displaying information to the screen. 

## Motivation

Boilerplate code that developers will have to write in order to effectively use the library's features is time that doesn't need to be spent. In addition, having developers write their own abstractions to common tasks introduces the possibility of bugs that will slow down the process of using the library. Having a set of built in classes that are designed to remove setup work means more time saved for every developer that uses the project and less error-prone implementations for future apps.

## Proposed solution

A set of submanager classes will be created, with each one designated to a particular responsibility to simplify using the library. These submanagers will be controlled by an encompassing class named `SdlManager`, which is for the developer's convenience. These classes will match closely to existing manager layers to allow for easy adoption for those already familiar with the Android or iOS libraries. In addition, unique features of JavaScript can be utilized to further ease the pain of dealing with asynchronous logic, such as using Promises and the yielding async/await syntax. 

### Managers

Specifically, these are the following manager classes that existing libraries already use, and thus will need to be implemented in the JavaScript suite:
* BaseSubManager (The class that submanagers will extend)
* SdlManager (Publically-facing manager that allows access to the submanagers below)
    * LockscreenManager (Handles lockscreens and customization)
    * ScreenManager (Handles the process of displaying and managing items on the head unit)
        * MenuManager (Handles menus and submenus)
        * VoiceCommandManager (Keeps track of voice commands)
        * ChoiceSetManager (Handles interactive choice sets)
        * SoftButtonManager (Handles softbutton state)
        * TextAndGraphicManager (Handles text and images)
    * AudioStreamManager (Helps with transcoding audio files and streaming them)
    * VideoStreamingManager (Helps with streaming video content)
    * FileManager (Handles file uploading and deletion)
        * SdlFile (Handles the construction of files- not a submanager)
        * SdlArtwork (Extends SdlFile and is specifically for images)
    * PermissionManager (Keeps track of what is allowed for the app)
    * LifecycleManager (Handles SDL session logic and sending RPCs)
    * SystemCapabilityManager (Keeps track of system capabilities)

### Promises

JavaScript allows for asynchronous code to be in the written the same way as typical synchronous code. This means that nested callback functions can be avoided and the code can be read simply from top to bottom. The following is an example of how one can make a helper function to abstract out the work needed for the LifecycleManager to send and receive an RPC:

```js
asyncSendRpcRequest (request) {
    return new Promise((resolve, reject) => {
        const functionId = SDL.rpc.enums.FunctionID.valueForString(request.getFunctionName());
        let correlationIdRequest;
        let listener;

        listener = new SDL.rpc.RpcListener().setOnRpcMessage(rpcMessage => {
            const correlationIdResponse = rpcMessage.getCorrelationId();
            // ensure the correlation ids match
            if (correlationIdRequest === correlationIdResponse) {
                // remove the listener once the correct response is received
                this._manager.removeRpcListener(functionId, listener);
                resolve(rpcMessage); // the response is returned here
            }
        });

        this._manager.addRpcListener(functionId, listener);
        this._manager.sendRpcMessage(request);

        correlationIdRequest = request.getCorrelationId();
    });
}
```

And here is how it can be used in practice:

```js
const putFile = new SDL.rpc.messages.PutFile()
        .setFileName(fileName)
        .setFileType('GRAPHIC_PNG')
        .setPersistentFile(true)
        .setFileData(fileBinary);

const putFileResponse = await asyncSendRpcRequest(putFile); // execution is paused here until the response comes back
console.log(putFileResponse); 
```

For sending batches of RPCs simultaneously, all the Promises can be stored into an array and execution can halt until all have been resolved, via `await Promise.all(array)`. The async/await syntax, as well as Promises, are available as of ECMA-Script 2017. These features will greatly reduce the code complexity of future apps.

## Potential downsides

A lot of code will need to be written and tested, placing the burden of boilerplate on the project maintainers instead of the developers. But, the time saved in the long run for future developers will be much larger than the time taken to write the managers out now. 

## Impact on existing code

The code changes required are additive and will not impact existing code.

## Alternatives considered

Deviating from the existing manager layers' APIs is an option, but it comes at the cost of being a different set of APIs, and so a developer migrating from the Android or iOS libraries would have to learn and understand the manager layer all over again.

