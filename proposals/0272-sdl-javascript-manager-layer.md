# JavaScript Suite SDL Manager

* Proposal: [SDL-0272](0272-sdl-javascript-manager-layer.md)
* Author: [Chris Rokita](https://github.com/crokita)
* Status: **Awaiting review**
* Impacted Platforms: JavaScript Suite

## Introduction

In a similar vein to [this proposal](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0171-android-manager-apis.md), the goal is to introduce a manager layer to the JavaScript Suite, closely matching the Java Suite and iOS manager APIs. These manager classes are designed to abstract out complex flows and states for common tasks, such as file handling and displaying information to the screen. 

## Motivation

Boilerplate code that developers will have to write in order to effectively use the library's features is time that doesn't need to be spent. In addition, having developers write their own abstractions to common tasks introduces the possibility of bugs that will slow down the process of using the library. Having a set of built in classes that are designed to remove setup work means more time saved for every developer that uses the project and less error-prone implementations for future apps.

## Proposed solution

A set of submanager classes will be created, with each one designated to a particular responsibility to simplify using the library. These submanagers will be controlled by an encompassing class named `SdlManager`, which is for the developer's convenience. These classes will match closely to existing manager layers to allow for easy adoption for those already familiar with the Java Suite or iOS libraries. In addition, unique features of JavaScript can be utilized to further ease the pain of dealing with asynchronous logic, such as using Promises and the yielding async/await syntax. 

### Managers

Specifically, these are the following manager classes that existing libraries already use, and thus will need to be implemented in the JavaScript suite:
* BaseSubManager (The class that submanagers will extend)
* SdlManager (Publicly-facing manager that allows access to the submanagers below)
    * ScreenManager (Handles the process of displaying and managing items on the head unit)
        * MenuManager (Handles menus and submenus)
        * VoiceCommandManager (Keeps track of voice commands)
        * ChoiceSetManager (Handles interactive choice sets)
        * SoftButtonManager (Handles softbutton state)
        * TextAndGraphicManager (Handles text and images)
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

### API

```js
/*
NOTE: all methods with a final argument of CompletionListener or MultipleFileCompletionListener have that removed in place of making the method async
    all start methods
    ScreenManager.preloadChoices
    ScreenManager.commit
    ChoiceSetManager.preloadChoices
    FileManager.deleteRemoteFileWithName
    FileManager.deleteRemoteFilesWithNames
    FileManager.uploadFile
    FileManager.uploadFiles
    FileManager.uploadArtwork
    FileManager.uploadArtworks

There is also one replacement for a method with an OnSystemCapabilityListener:
    SystemCapabilityManager.getCapability
*/

class BaseSubManager {
    /**
     * @param ISdl internalInterface
    */
    constructor(internalInterface)
    async start()
    dispose()
    /**
     * @return {Number}
    */
    getState() 
}

class BaseSdlManager {
    /**
     * @return {Number}
    */
    getState()
    async start()
    dispose()

    /**
     * @param RPCMessage message
     * @return {RPCResponse|null} - Returns a response if the message is a request, or null otherwise
    */
    async sendRPC(message)

    /**
     * @param RPCMessage[] rpcs
     * @return {(RPCResponse|null)[]} - Returns responses if the message is a request, or null otherwise
    */
    async sendSequentialRPCs(rpcs)
    /**
     * @param RPCMessage[] rpcs
     * @return {(RPCResponse|null)[]} - Returns responses if the message is a request, or null otherwise
    */
    async sendRPCs(rpcs)


    /**
     * @return {RegisterAppInterfaceResponse}
    */
    getRegisterAppInterfaceResponse()
    /**
     * @return {OnHMIStatus}
    */
    getCurrentHMIStatus()
    /**
     * @return {String}
    */
    getAuthToken()
    /**
     * @param FunctionID notificationId
     * @param OnRPCNotificationListener listener
    */
    addOnRPCNotificationListener(notificationId, listener)
    /**
     * @param FunctionID notificationId
     * @param OnRPCNotificationListener listener
    */
    removeOnRPCNotificationListener(notificationId, listener)
    /**
     * @param FunctionID requestId
     * @param OnRPCRequestListener listener
    */
    addOnRPCRequestListener(requestId, listener)
    /**
     * @param FunctionID requestId
     * @param OnRPCRequestListener listener
    */
    removeOnRPCRequestListener(requestId, listener)
}

class SdlManager extends BaseSdlManager {
    /**
     * @return {PermissionManager}
    */
    getPermissionManager() 
    /**
     * @return {FileManager}
    */
    getFileManager() 
    /**
     * @return {ScreenManager}
    */
    getScreenManager() 
    /**
     * @return {SystemCapabilityManager}
    */
    getSystemCapabilityManager()
    startRPCEncryption()

    static class Builder {
        /**
         * @param String appId
         * @param String appName
         * @param SdlManagerListener listener
        */
        constructor(appId, appName, listener)
        /**
         * @param String appId
         * @return {Builder}
        */
        setAppId(appId)
        /**
         * @param String appName
         * @return {Builder}
        */
        setAppName(appName)
        /**
         * @param String shortAppName
         * @return {Builder}
        */
        setShortAppName(shortAppName) 
        /**
         * @param Version minimumProtocolVersion
         * @return {Builder}
        */
        setMinimumProtocolVersion(minimumProtocolVersion) 
        /**
         * @param Version minimumRPCVersion
         * @return {Builder}
        */
        setMinimumRPCVersion(minimumRPCVersion) 
        /**
         * @param Language hmiLanguage
         * @return {Builder}
        */
        setLanguage(hmiLanguage)
        /**
         * @param TemplateColorScheme dayColorScheme
         * @return {Builder}
        */
        setDayColorScheme(dayColorScheme)
        /**
         * @param TemplateColorScheme nightColorScheme
         * @return {Builder}
        */
        setNightColorScheme(nightColorScheme)
        /**
         * @param SdlArtwork sdlArtwork
         * @return {Builder}
        */
        setAppIcon(sdlArtwork)
        /**
         * @param AppHMIType[] hmiTypes
         * @return {Builder}
        */
        setAppTypes(hmiTypes)
        /**
         * @param String[] vrSynonyms
         * @return {Builder}
        */
        setVrSynonyms(vrSynonyms) 
        /**
         * @param TTSChunk[] ttsChunks
         * @return {Builder}
        */
        setTtsName(ttsChunks) 
        /**
         * @param BaseTransportConfig transport
         * @return {Builder}
        */
        setTransportType(transport)
        /**
         * @param SdlSecurityBase[] secList
         * @param ServiceEncryptionListener listener
        */
        setSdlSecurity(secList, listener) 
        /**
         * @param SdlManagerListener listener
         * @return {Builder}
        */
        setManagerListener(listener)
        /**
         * @param Map<FunctionID, OnRPCNotificationListener> listeners
         * @return {Builder}
        */
        setRPCNotificationListeners(listeners)
        /**
         * @return {SdlManager}
        */
        build() 
    }
}


class BaseScreenManager extends BaseSubManager {
    /**
     * @param ISdl internalInterface
     * @param FileManager fileManager
    */
    constructor(internalInterface, fileManager)
    async start()
    dispose()
    /**
     * @param String textField1
    */
    setTextField1(textField1)
    /**
     * @return {String}
    */
    getTextField1()
    /**
     * @param String textField2
    */
    setTextField2(textField2)
    /**
     * @return {String}
    */
    getTextField2()
    /**
     * @param String textField3
    */
    setTextField3(textField3)
    /**
     * @return {String}
    */
    getTextField3()
    /**
     * @param String textField4
    */
    setTextField4(textField4)
    /**
     * @return {String}
    */
    getTextField4()
    /**
     * @param String mediaTrackTextField
    */
    setMediaTrackTextField(mediaTrackTextField)
    /**
     * @return {String}
    */
    getMediaTrackTextField() 
    /**
     * @param SdlArtwork primaryGraphic
    */
    setPrimaryGraphic(primaryGraphic) 
    /**
     * @return {SdlArtwork}
    */
    getPrimaryGraphic() 
    /**
     * @param SdlArtwork secondaryGraphic
    */
    setSecondaryGraphic(secondaryGraphic) 
    /**
     * @return {SdlArtwork}
    */
    getSecondaryGraphic() 
    /**
     * @param TextAlignment textAlignment
    */
    setTextAlignment(textAlignment)
    /**
     * @return {TextAlignment}
    */ 
    getTextAlignment() 
    /**
     * @param MetadataType textField1Type
    */
    getTextField1Type() 
    /**
     * @param MetadataType textField2Type
    */
    setTextField2Type(textField2Type) 
    /**
     * @return {MetadataType}
    */
    getTextField2Type() 
    /**
     * @param MetadataType textField3Type
    */
    setTextField3Type(textField3Type) 
    /**
     * @return {MetadataType}
    */
    getTextField3Type() 
    /**
     * @param MetadataType textField4Type
    */
    setTextField4Type(textField4Type) 
    /**
     * @return {MetadataType}
    */
    getTextField4Type() 
    /**
     * @param String templateTitle
    */
    setTemplateTitle(templateTitle)
    /**
     * @return {String}
    */
    getTemplateTitle()
    /**
     * @param String templateTitle
    */
    setTitle(templateTitle)
    /**
     * @return {String}
    */
    getTitle()
    /**
     * @param SoftButtonObject[] softButtonObjects
    */
    setSoftButtonObjects(softButtonObjects) 
    /**
     * @return {SoftButtonObject[]}
    */
    getSoftButtonObjects() 
    /**
     * @param String name
     * @return {SoftButtonObject}
    */
    getSoftButtonObjectByName(name)
    /**
     * @param Number buttonId
     * @return {SoftButtonObject}
    */
    getSoftButtonObjectById(buttonId)
    /**
     * @return {VoiceCommand[]}
    */
    getVoiceCommands()
    /**
     * @param VoiceCommand[] voiceCommands
    */
    setVoiceCommands(voiceCommands)
    /**
     * @return {MenuCell[]}
    */
    getMenu()
    /**
     * @param MenuCell[] menuCells
    */
    setMenu(menuCells)
    /**
     * @param DynamicMenuUpdatesMode value
    */
    setDynamicMenuUpdatesMode(value)
    /**
     * @return {DynamicMenuUpdatesMode}
    */
    getDynamicMenuUpdatesMode()
    /**
     * @return {Boolean}
    */
    openMenu()
    /**
     * @param MenuCell cell
     * @return {Boolean}
    */
    openSubMenu(cell)
    /**
     * @param MenuConfiguration menuConfiguration
    */
    setMenuConfiguration(menuConfiguration) 
    /**
     * @return {MenuConfiguration}
    */
    getMenuConfiguration()
    /**
     * @param ChoiceCell[] choices
    */
    deleteChoices(choices)
    /**
     * @param ChoiceCell[] choices
    */
    async preloadChoices(choices)
    /**
     * @param ChoiceSet choices
     * @param InteractionMode mode
     * @param KeyboardListener keyboardListener
    */
    presentSearchableChoiceSet(choiceSet, mode, keyboardListener)
    /**
     * @param ChoiceSet choices
     * @param InteractionMode mode
    */
    presentChoiceSet(choiceSet, mode)
    /**
     * @param String initialText
     * @param KeyboardProperties customKeyboardProperties
     * @param KeyboardListener keyboardListener
     * @return {Number}
    */
    presentKeyboard(initialText, customKeyboardProperties, keyboardListener)
    /**
     * @param KeyboardProperties keyboardConfiguration
    */
    setKeyboardConfiguration(keyboardConfiguration)
    /**
     * @return {Set<ChoiceCell>}
    */
    getPreloadedChoices()
    /**
     * @param Number cancelID
    */
    dismissKeyboard(cancelID) 
    beginTransaction()
    async commit(listener)
}


class BaseMenuManager extends BaseSubManager {
    /**
     * @param ISdl internalInterface
     * @param FileManager fileManager
    */
    constructor(internalInterface, fileManager) 
    async start() 
    dispose()
    /**
     * @param DynamicMenuUpdatesMode value
    */
    setDynamicUpdatesMode(value)
    /**
     * @param MenuCell[] cells
    */
    setMenuCells(cells)
    /**
     * @return {MenuCell[]}
    */
    getMenuCells()
    /**
     * @return {DynamicMenuUpdatesMode}
    */
    getDynamicMenuUpdatesMode() 
    /**
     * @return {Boolean}
    */
    openMenu()
    /**
     * @param MenuCell cell
     * @return {Boolean}
    */
    openSubMenu(cell)
    /**
     * @param MenuConfiguration menuConfiguration
    */
    setMenuConfiguration(menuConfiguration) 
    /**
     * @return {MenuConfiguration}
    */
    getMenuConfiguration()
}


class BaseVoiceCommandManager extends BaseSubManager {
    /**
     * @param ISdl internalInterface
    */
    constructor(internalInterface) 
    async start() 
    dispose()
    /**
     * @param VoiceCommand[] voiceCommands
    */
    setVoiceCommands(voiceCommands)
    /**
     * @return {VoiceCommand[]}
    */
    getVoiceCommands()
}


class BaseChoiceSetManager extends BaseSubManager {
    /**
     * @param ISdl internalInterface
     * @param FileManager fileManager
    */
    constructor(internalInterface, fileManager) 
    async start()
    dispose()
    /**
     * @param ChoiceCell[] choices
    */
    async preloadChoices(choices)
    /**
     * @param ChoiceCell[] choices
    */
    deleteChoices(choices)
    /**
     * @param ChoiceSet choiceSet
     * @param InteractionMode mode
     * @param KeyboardListener keyboardListener
    */
    presentChoiceSet(choiceSet, mode, keyboardListener)
    /**
     * @param String initialText
     * @param KeyboardProperties customKeyboardConfig
     * @param KeyboardListener listener
     * @return {Number}
    */
    presentKeyboard(initialText, customKeyboardConfig, listener)
    /**
     * @param Number cancelID
    */
    dismissKeyboard(cancelID) 
    /**
     * @param KeyboardProperties keyboardConfiguration
    */
    setKeyboardConfiguration(keyboardConfiguration)
    /**
     * @return {Set<ChoiceCell>}
    */
    getPreloadedChoices()
}


class BaseSoftButtonManager extends BaseSubManager {
    /**
     * @param ISdl internalInterface
     * @param FileManager fileManager
    */
    constructor(internalInterface, fileManager) 
    async start() 
    dispose() 
}


class BaseTextAndGraphicManager extends BaseSubManager {
    /**
     * @param ISdl internalInterface
     * @param FileManager fileManager
     * @param SoftButtonManager softButtonManager
    */
    constructor(internalInterface, fileManager, softButtonManager) 
    async start() 
    dispose()
}


class BaseFileManager extends BaseSubManager {
    /**
     * @param ISdl internalInterface
    */
    constructor(internalInterface) 
    async start() 
    /**
     * @return {String[]}
    */
    getRemoteFileNames() 
    /**
     * @return {Number}
    */
    getBytesAvailable()
    /**
     * @param String fileName
    */
    async deleteRemoteFileWithName(fileName)
    /**
     * @param String[] fileNames
    */
    async deleteRemoteFilesWithNames(fileNames)
    /**
     * @param SdlFile file
    */
    async uploadFile(file)
    /**
     * @param SdlFile[] files
    */
    async uploadFiles(files)
    /**
     * @param SdlArtwork file
    */
    async uploadArtwork(file)
    /**
     * @param SdlArtwork[] files
    */
    async uploadArtworks(files)
    /**
     * @param SdlFile file
     * @return {Boolean}
    */
    hasUploadedFile(file)
    /**
     * @static
     * @param Result resultCode
     * @param String info
     * @return {String}
    */
    static buildErrorString(resultCode, info)
}


class BasePermissionManager extends BaseSubManager {
    /**
     * @param ISdl internalInterface
    */
    constructor(internalInterface)
    async start() 
    /**
     * @param FunctionID rpcName
     * @return {Boolean}
    */
    getRPCRequiresEncryption(rpcName)
    /**
     * @return {Boolean}
    */
    getRequiresEncryption()
    /**
     * @param FunctionID rpcName
     * @return {Boolean}
    */
    isRPCAllowed(rpcName)
    /**
     * @param FunctionID rpcName
     * @param String parameter
     * @return {Boolean}
    */
    isPermissionParameterAllowed(rpcName, parameter)
    dispose()
    /**
     * @param PermissionElement[] permissionElements
     * @return {PermissionGroupStatus} - Number value
    */
    getGroupStatusOfPermissions(permissionElements)
    /**
     * @param PermissionElement[] permissionElements
     * @return {Map<FunctionID, PermissionStatus>}
    */
    getStatusOfPermissions(permissionElements)
    /**
     * @param PermissionElement[] permissionElements
     * @param PermissionGroupType groupType - Number value
     * @param OnPermissionChangeListener listener
     * @return {UUID}
    */
    addListener(permissionElements, groupType, listener)
    /**
     * @param UUID listenerId
    */
    removeListener(listenerId)
}

class LifecycleManager {
    /**
     * @param AppConfig appConfig
     * @param BaseTransportConfig config
     * @param LifecycleListener listener
    */
    constructor(appConfig, config, listener)
    async start()
    startRPCEncryption()
    stop()
    /**
     * @param SdlManager sdlManager
     * @return {SystemCapabilityManager}
    */
    getSystemCapabilityManager(sdlManager)
    /**
     * @return {RegisterAppInterfaceResponse}
    */
    getRegisterAppInterfaceResponse()
    /**
     * @return {OnHMIStatus}
    */
    getCurrentHMIStatus() 
    /**
     * @param SdlManager sdlManager
     * @return {ISdl}
    */
    getInternalInterface(sdlManager) 
    /**
     * @return {String}
    */
    getAuthToken()
    /**
     * @param SdlSecurityBase[] secList
     * @param ServiceEncryptionListener listener
    */
    setSdlSecurity(secList, listener) 
}


class SystemCapabilityManager {
    /**
     * @param ISdl callback
    */
    constructor(callback)
    /**
     * @param Number windowID
     * @return {WindowCapability}
    */
    getWindowCapability(windowID)
    /**
     * @return {WindowCapability}
    */
    getDefaultMainWindowCapability() 
    /**
     * @param RegisterAppInterfaceResponse response
    */
    parseRAIResponse(response)
    /**
     * @param SystemCapabilityType systemCapabilityType
     * @param Object capability
    */
    setCapability(systemCapabilityType, capability)
    /**
     * @param SystemCapabilityType type
     * @return {Boolean}
    */
    isCapabilitySupported(type)
    /**
     * @param SystemCapabilityType systemCapabilityType
     * @return {Object}
    */
    async getCapability(systemCapabilityType) {
        
    }
    /**
     * @param SystemCapabilityType systemCapabilityType
     * @param OnSystemCapabilityListener scListener
    */
    addOnSystemCapabilityListener(systemCapabilityType, listener)
    /**
     * @param SystemCapabilityType systemCapabilityType
     * @param OnSystemCapabilityListener scListener
     * @return {Boolean}
    */
    removeOnSystemCapabilityListener(systemCapabilityType, listener)
    /**
     * @static
     * @param Object object
     * @param Function classType - An object of a class
     * @return {Function[]} - An array of objects of a class
    */
    static convertToList(object, classType)
}
```

## Potential downsides

A lot of code will need to be written and tested, placing the burden of boilerplate on the project maintainers instead of the developers. But, the time saved in the long run for future developers will be much larger than the time taken to write the managers out now. 

## Impact on existing code

The code changes required are additive and will not impact existing code.

## Alternatives considered

Deviating from the existing manager layers' APIs is an option, but it comes at the cost of being a different set of APIs, and so a developer migrating from the Java Suite or iOS libraries would have to learn and understand the manager layer all over again.

