# JavaScript Suite SDL Manager

* Proposal: [SDL-0272](0272-sdl-javascript-manager-layer.md)
* Author: [Chris Rokita](https://github.com/crokita)
* Status: **Accepted with Revisions**
* Impacted Platforms: JavaScript Suite

## Introduction

In a similar vein to [this proposal](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0171-android-manager-apis.md), the goal is to introduce a manager layer to the JavaScript Suite, closely matching the Java Suite and iOS manager APIs. These manager classes are designed to abstract out complex flows and states for common tasks, such as file handling and displaying information to the screen. 

## Motivation

Boilerplate code that developers will have to write in order to effectively use the library's features is time that doesn't need to be spent. In addition, having developers write their own abstractions to common tasks introduces the possibility of bugs that will slow down the process of using the library. Having a set of built in classes that are designed to remove setup work means more time saved for every developer that uses the project and less error-prone implementations for future apps.

## Proposed solution

A set of submanager classes will be created, with each one designated to a particular responsibility to simplify using the library. These submanagers will be controlled by an encompassing class named `SdlManager`, which is for the developer's convenience. These classes will match closely to existing manager layers to allow for easy adoption for those already familiar with the Java Suite or iOS libraries. In addition, unique features of JavaScript can be utilized to further ease the pain of dealing with asynchronous logic, such as using Promises and the yielding async/await syntax. 

### Managers

Specifically, these are the following manager classes that existing libraries already use, and thus will need to be implemented in the JavaScript suite:
* SubManagerBase (The class that submanagers will extend)
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

class SubManagerBase {
    /**
     * @param {LifecycleManager} lifecycleManager - An instance of a LifecycleManager
     * @constructor
     */
    constructor (lifecycleManager)

    /**
     * Starts up a SubManagerBase, and resolves the returned Promise when SubManagerBase is done setting up or failed setup.
     * @return {Promise} Resolves true when in READY or LIMITED state, or false when in ERROR state.
     */
    async start ()

    /**
     * Called when manager is being torn down.
     */
    dispose ()

    /**
     * Returns the current state.
     * @return {Number}
     */
    getState ()
}

class SdlManagerBase {
    /**
    * @param {AppConfig} appConfig - An instance of AppConfig describing the application's metadata and desired transport
    * @param {ManagerListener} managerListener - An instance of ManagerListener to be used to listen for manager events
    * @constructor
    */
    constructor (appConfig = null, managerListener = null)

    /**
    * Retrieves the stored AppConfig instance
    * @return {AppConfig|null}
    */
    getAppConfig ()

    /**
    * Sets the AppConfig instance
    * @param {AppConfig} appConfig
    * @return {SdlManagerBase}
    */
    setAppConfig (appConfig)

    /**
    * Retrieves the stored ManagerListener
    * @return {SdlManagerListener|null}
    */
    getManagerListener ()

    /**
    * Sets the ManagerListener instance
    * @param {ManagerListener} managerListener
    * @return {SdlManagerBase}
    */
    setManagerListener (managerListener)

    /**
    * Retrieves the state of the manager
    * @return {Number}
    */
    getState ()

    /**
    * Checks the manager's state and provides a silent log if it's not ready for use
    * @return {SdlManagerBase}
    */
    checkSdlManagerState ()

    /**
    * Set up the notification queue
    * @return {SdlManagerBase}
    */
    initNotificationQueue ()

    /**
    * @abstract
    * @return {SdlManagerBase}
    */
    addRpcListener (functionId, listener)

    /**
    * @abstract
    * @return {SdlManagerBase}
    */
    removeRpcListener (functionId, listener)

    /**
    * @abstract
    * @return {SdlManagerBase}
    */
    checkState ()

    /**
    * @abstract
    * @return {Promise}
    */
    initialize ()

    /**
    * @abstract
    * @return {SdlManagerBase}
    */
    start ()

    /**
    * @abstract
    * @return {SdlManagerBase}
    */
    dispose ()

    /**
    * Sends a single RPC
    * @abstract
    * @param {RpcMessage} message
    * @return {Promise}
    */
    sendRpc (message)

    /**
    * Sends multiple RPCs asynchronously
    * @abstract
    * @param {RpcMessage[]} messages
    * @return {Promise}
    */
    sendRpcs (messages)

    /**
    * Sends multiple RPCs synchronously
    * @abstract
    * @param {RpcMessage[]} messages
    * @return {Promise}
    */
    sendSequentialRpcs (messages)

    /**
    * Retreives the RAI response from the LifecycleManager
    * @return {RegisterAppInterfaceResponse|null}
    * @abstract
    */
    getRegisterAppInterfaceResponse ()

    /**
    * Retrieves the current HMI status from the LifecycleManager
    * @return {OnHmiStatus|null}
    * @abstract
    */
    getCurrentHmiStatus ()

    /**
    * Retrieves the Auth Token from the LifecycleManager
    * @return {string|null}
    * @abstract
    */
    getAuthToken ()


}

class SdlManager extends SdlManagerBase {
    /**
    * @param {AppConfig} appConfig - An instance of AppConfig describing the application's metadata and desired transport
    * @param {ManagerListener} managerListener - An instance of ManagerListener to be used to listen for manager events
    * @constructor
    */
    constructor (appConfig = null, managerListener = null)
    
    /**
    * Add a listener for a given FunctionID
    * @param {Number} functionId - A Function ID from the RPC Spec
    * @param {function} listener - A callback function(RpcMessage)
    */
    addRpcListener (functionId, listener)
    
    /**
    * Remove a listener for a given FunctionID
    * @param {Number} functionId - A Function ID from the RPC Spec
    * @param {function} listener - A callback function(RpcMessage)
    */
    removeRpcListener (functionId, listener)
    
    /**
    * Checks the state of sub-managers
    * @return {SdlManager}
    */
    checkState ()
    
    /**
    * Initializes sub-managers
    * @return {Promise}
    */
    initialize ()
    
    /**
    * Retrieves a reference to the PermissionManager, if ready
    * @return {PermissionManager|null}
    */
    getPermissionManager ()
    
    /**
    * Retrieves a reference to the FileManager, if ready
    * @return {FileManager|null}
    */
    getFileManager ()
    
    /**
    * Retrieves a reference to the ScreenManager, if ready
    * @return {ScreenManager|null}
    */
    getScreenManager ()
    
    /**
    * Retrieves a reference to the SystemCapabilityManager
    * @return {SystemCapabilityManager}
    */
    getSystemCapabilityManager ()
    
    /**
    * Initializes the LifecycleManager using the AppConfig and starts the transport
    * @return {SdlManager}
    */
    start ()
    
    /**
    * Gracefully disposes the managers and alerts and destroys the ManagerListener
    * @return {SdlManager}
    */
    dispose ()
    
    /**
    * Sends a single RPC
    * @param {RpcMessage} message
    * @return {Promise} - A Promise which resolves if the RPC response is SUCCESS, otherwise rejects
    */
    async sendRpc (message)
    
    /**
    * Sends multiple RPCs asynchronously
    * @param {RpcMessage[]} messages - An array of RpcMessages
    * @return {Promise} - A Promise which resolves if all RPCs respond with SUCCESS, otherwise rejects with the first failure
    */
    async sendRpcs (messages)
    
    /**
    * Sends multiple RPCs synchronously (in order)
    * @param {RpcMessage[]} messages
    * @return {Promise} - A Promise which resolves with the last RPC response if all RPCs respond with SUCCESS, otherwise rejects with the first failure
    */
    async sendSequentialRpcs (messages)
    
    /**
    * Retreives the RAI response from the LifecycleManager
    * @return {RegisterAppInterfaceResponse|null}
    */
    getRegisterAppInterfaceResponse ()
    
    /**
    * Retrieves the current HMI status from the LifecycleManager
    * @return {OnHmiStatus|null}
    */
    getCurrentHmiStatus ()
    
    /**
    * Retrieves the Auth Token from the LifecycleManager
    * @return {string|null}
    */
    getAuthToken ()
    
}


class ScreenManagerBase extends SubManagerBase {
    /**
     * @param {LifecycleManager} lifecycleManager
     * @param {FileManager} fileManager
    */
    constructor (lifecycleManager, fileManager = null)

    /**
     * @return {Promise}
    */
    async start ()

    /**
     * Called when manager is being torn down
    */
    dispose ()

    /**
     * Set the textField1 on the head unit screen
     * Sending an empty String "" will clear the field
     * @param {String} textField1 - value represents the textField1
     * @return {BaseScreenManager}
     */
    setTextField1 (textField1)

    /**
     * Get the current textField1 value
     * @return {String} - value represents the current textField1 value
     */
    getTextField1 ()

    /**
     * Set the textField2 on the head unit screen
     * Sending an empty String "" will clear the field
     * @param {String} textField2 - value represents the textField1
     * @return {BaseScreenManager}
     */
    setTextField2 (textField2)

    /**
     * Get the current textField2 value
     * @return {String} - value represents the current textField2 value
     */
    getTextField2 ()

    /**
     * Set the textField3 on the head unit screen
     * Sending an empty String "" will clear the field
     * @param {String} textField3 - value represents the textField1
     * @return {BaseScreenManager}
     */
    setTextField3 (textField3)

    /**
     * Get the current textField3 value
     * @return {String} - value represents the current textField3 value
     */
    getTextField3 ()

    /**
     * Set the textField4 on the head unit screen
     * Sending an empty String "" will clear the field
     * @param {String} textField4 - value represents the textField1
     * @return {BaseScreenManager}
     */
    setTextField4 (textField4)

    /**
     * Get the current textField4 value
     * @return {String} - value represents the current textField4 value
     */
    getTextField4 ()

    /**
     * Set the mediaTrackTextField on the head unit screen
     * @param {String} mediaTrackTextField - value represents the mediaTrackTextField
     * @return {BaseScreenManager}
     */
    setMediaTrackTextField (mediaTrackTextField)

    /**
     * Get the current mediaTrackTextField value
     * @return {String} - value represents the current mediaTrackTextField
     */
    getMediaTrackTextField ()

    /**
     * Set the primaryGraphic on the head unit screen
     * @param {SdlArtwork} primaryGraphic - an SdlArtwork object represents the primaryGraphic
     * @return {BaseScreenManager}
     */
    setPrimaryGraphic (primaryGraphic)

    /**
     * Get the current primaryGraphic value
     * @return {SdlArtwork} - object represents the current primaryGraphic
     */
    getPrimaryGraphic ()

    /**
     * Set the secondaryGraphic on the head unit screen
     * @param {SdlArtwork} secondaryGraphic - an SdlArtwork object represents the secondaryGraphic
     * @return {BaseScreenManager}
     */
    setSecondaryGraphic (secondaryGraphic)

    /**
     * Get the current secondaryGraphic value
     * @return {SdlArtwork} - object represents the current secondaryGraphic
     */
    getSecondaryGraphic ()

    /**
     * Set the alignment for the text fields
     * @param {TextAlignment} textAlignment - TextAlignment value represents the alignment for the text fields
     * @return {BaseScreenManager}
     */
    setTextAlignment (textAlignment)

    /**
     * Get the alignment for the text fields
     * @return {TextAlignment} - value represents the alignment for the text fields
     */
    getTextAlignment ()

    /**
     * Set the metadata type for the textField1
     * @param {MetadataType} textField1Type - a MetadataType value represents the metadata for textField1
     * @return {BaseScreenManager}
     */
    setTextField1Type (textField1Type)

    /**
     * Get the metadata type for textField1
     * @return {MetadataType} - value represents the metadata for textField1
     */
    getTextField1Type ()

    /**
     * Set the metadata type for the textField2
     * @param {MetadataType} textField2Type - a MetadataType value represents the metadata for textField2
     * @return {BaseScreenManager}
     */
    setTextField2Type (textField2Type)

    /**
     * Get the metadata type for textField2
     * @return {MetadataType} - value represents the metadata for textField2
     */
    getTextField2Type ()

    /**
     * Set the metadata type for the textField3
     * @param {MetadataType} textField3Type - a MetadataType value represents the metadata for textField3
     * @return {BaseScreenManager}
     */
    setTextField3Type (textField3Type)

    /**
     * Get the metadata type for textField3
     * @return {MetadataType} - value represents the metadata for textField3
     */
    getTextField3Type ()

    /**
     * Set the metadata type for the textField4
     * @param {MetadataType} textField4Type - a MetadataType value represents the metadata for textField4
     * @return {BaseScreenManager}
     */
    setTextField4Type (textField4Type)

    /**
     * Get the metadata type for textField4
     * @return {MetadataType} - value represents the metadata for textField4
     */
    getTextField4Type ()

    /**
     * Sets the title of the new template that will be displayed.
     * Sending an empty String "" will clear the field
     * @param {String} title - the title of the new template that will be displayed. Maxlength: 100.
     * @return {BaseScreenManager}
     */
    setTitle (title)

    /**
     * Gets the title of the new template that will be displayed
     * @return title - String value that represents the title of the new template that will be displayed
     */
    getTitle ()

    /**
     * Set softButtonObjects list and upload the images to the head unit
     * @param {SoftButtonObject[]} softButtonObjects - the list of the SoftButtonObject values that should be displayed on the head unit
     * @return {Promise} - returns BaseScreenManager when finished
     */
    async setSoftButtonObjects (softButtonObjects)

    /**
     * Get the soft button objects list
     * @return {SoftButtonObject[]}
     */
    getSoftButtonObjects ()

    /**
     * Get the SoftButtonObject that has the provided name
     * @param {String} name - a String value that represents the name
     * @return {SoftButtonObject}
     */
    getSoftButtonObjectByName (name)

    /**
     * Get the SoftButtonObject that has the provided buttonId
     * @param {Number} buttonId - an int value that represents the ID of the button
     * @return {SoftButtonObject}
     */
    getSoftButtonObjectById (buttonId)

    /**
     * Get the currently set voice commands
     * @return {VoiceCommand[]} - a List of Voice Command objects
     */
    getVoiceCommands ()

    /**
     * Set voice commands
     * @param {VoiceCommand[]} voiceCommands - the voice commands to be sent to the head unit
     * @return {Promise}
     */
    async setVoiceCommands (voiceCommands)

    /**
     * The list of currently set menu cells
     * @return {MenuCell[]} - a List of the currently set menu cells
     */
    getMenu ()

    /**
     * Creates and sends all associated Menu RPCs
     * Note: the manager will store a deep copy the menuCells internally to be able to handle future updates correctly
     * @param {MenuCell[]} menuCells - the menu cells that are to be sent to the head unit, including their sub-cells.
     * @return {BaseScreenManager}
     */
    setMenu (menuCells)

    /**
     * Sets the behavior of how menus are updated. For explanations of the differences, see {@link DynamicMenuUpdatesMode}
     * @param {DynamicMenuUpdatesMode} value - the update mode
     * @return {BaseScreenManager}
     */
    setDynamicMenuUpdatesMode (value)

    /**
     * @return {DynamicMenuUpdatesMode} - The currently set DynamicMenuUpdatesMode. It defaults to ON_WITH_COMPAT_MODE if not set.
     */
    getDynamicMenuUpdatesMode ()

    /**
     * Requires SDL RPC Version 6.0.0 or greater
     * Opens the Main Menu.
     * @return {Boolean} success / failure - whether the request was able to be sent
     */
    openMenu ()

    /**
     * Requires SDL RPC Version 6.0.0 or greater
     * Opens a subMenu. The cell you pass in must be constructed with {@link MenuCell(String,SdlArtwork,List)}
     * @param {MenuCell} cell - A <Strong>SubMenu</Strong> cell whose sub menu you wish to open
     * @return {Boolean} success / failure - whether the request was able to be sent
     */
    openSubMenu (cell)

    /**
     * The main menu layout. See available menu layouts on WindowCapability.menuLayoutsAvailable.
     * @param {MenuConfiguration} menuConfiguration - The default menuConfiguration
     * @return {BaseScreenManager}
     */
    setMenuConfiguration (menuConfiguration)

    /**
     * The main menu layout. See available menu layouts on WindowCapability.menuLayoutsAvailable.
     * @return {MenuConfiguration} - the currently set MenuConfiguration
     */
    getMenuConfiguration ()

    /**
     * Deletes choices that were sent previously
     * @param {ChoiceCell[]} choices - A list of ChoiceCell objects
     */
    deleteChoices (choices)

    /**
     * Preload choices to improve performance while presenting a choice set at a later time
     * @param {ChoiceCell[]} choices - a list of ChoiceCell objects that will be part of a choice set later
     * @return {Promise}
     */
    async preloadChoices (choices)

    /**
     * Presents a searchable choice set
     * @param {ChoiceSet} choiceSet - The choice set to be presented. This can include Choice Cells that were preloaded or not
     * @param {InteractionMode} mode - The intended interaction mode
     * @param {KeyboardListener} keyboardListener - A keyboard listener to capture user input
     */
    presentSearchableChoiceSet (choiceSet, mode, keyboardListener)

    /**
     * Presents a choice set
     * @param {ChoiceSet} choiceSet - The choice set to be presented. This can include Choice Cells that were preloaded or not
     * @param {InteractionMode} mode - The intended interaction mode
     */
    presentChoiceSet (choiceSet, mode)

    /**
     * Presents a keyboard on the head unit to capture user input
     * @param {String} initialText - The initial text that is used as a placeholder text. It might not work on some head units.
     * @param {KeyboardProperties} customKeyboardProperties - the custom keyboard configuration to be used when the keyboard is displayed
     * @param {KeyboardListener} keyboardListener - A keyboard listener to capture user input
     * @return {Number} - A unique cancelID that can be used to cancel this keyboard. If `null`, no keyboard was created.
     */
    presentKeyboard (initialText, customKeyboardProperties, keyboardListener)

    /**
     * Set a custom keyboard configuration for this session. If set to null, it will reset to default keyboard configuration.
     * @param {KeyboardProperties} keyboardConfiguration - the custom keyboard configuration to be used when the keyboard is displayed
     * @return {BaseScreenManager}
     */
    setKeyboardConfiguration (keyboardConfiguration)

    /**
     * @return {Set.<ChoiceCell>} - A set of choice cells that have been preloaded to the head unit
     */
    getPreloadedChoices ()

    /**
     * Dismisses a currently presented keyboard with the associated ID. Canceling a keyboard only works when connected to SDL Core v.6.0+. When connected to older versions of SDL Core the keyboard will not be dismissed.
     * @param {Number} cancelID - The unique ID assigned to the keyboard
     */
    dismissKeyboard (cancelID)

    /**
     * Begin a multiple updates transaction. The updates will be applied when commit() is called<br>
     * Note: if we don't use beginTransaction & commit, every update will be sent individually.
     */
    beginTransaction ()

    /**
     * Send the updates that were started after beginning the transaction
     */
    commit () 
}


class MenuManagerBase extends SubManagerBase {
    /**
     * @constructor
     * @param {LifecycleManager} lifecycleManager
     * @param {FileManager} fileManager
    */
    constructor (lifecycleManager, fileManager)

    /**
     * @return {Promise}
    */
    async start ()

    /**
     * @param {DynamicMenuUpdatesMode} value
    */
    setDynamicUpdatesMode (value)

    /**
     * Creates and sends all associated Menu RPCs
     * @param {MenuCell[]} cells - the menu cells that are to be sent to the head unit, including their sub-cells.
    */
    setMenuCells (cells)

    /**
     * Returns current list of menu cells
     * @return {MenuCell[]} - a List of Currently set menu cells
    */
    getMenuCells ()

    /**
     * @return {DynamicMenuUpdatesMode} - The currently set DynamicMenuUpdatesMode. It defaults to ON_WITH_COMPAT_MODE
    */
    getDynamicMenuUpdatesMode ()

    /**
     * Opens the Main Menu
     * @return {Boolean}
    */
    openMenu ()

    /**
     * Opens a subMenu. The cell you pass in must be constructed with {@link MenuCell(String,SdlArtwork,List)}
     * @param {MenuCell} cell - A <Strong>SubMenu</Strong> cell whose sub menu you wish to open
     * @return {Boolean}
    */
    openSubMenu (cell)

    /**
     * This method is called via the screen manager to set the menuConfiguration.
     * This will be used when a menu item with sub-cells has a null value for menuConfiguration
     * @param {MenuConfiguration} menuConfiguration - The default menuConfiguration
    */
    setMenuConfiguration (menuConfiguration)

    /**
     * @return {MenuConfiguration}
    */
    getMenuConfiguration ()

}


class VoiceCommandManagerBase extends SubManagerBase {
    /**
     * Sets up variables and the listeners
     * @param {LifecycleManager} lifecycleManager
    */
    constructor (lifecycleManager)

    /**
     * After this method finishes, the manager is ready
     * @return {Promise}
    */
    async start ()

    /**
     * Stores the voice commands to send later. Will get overwritten by additional invocations of this method
     * @param {VoiceCommand[]} voiceCommands
     * @return {Promise} - returns after old commands are deleted and new ones are added
    */
    async setVoiceCommands (voiceCommands)

    /**
     * Gets all the voice commands currently set
     * @return {VoiceCommand[]}
    */
    getVoiceCommands ()

}


class ChoiceSetManagerBase extends SubManagerBase {
    /**
     * @param {LifecycleManager} lifecycleManager
     * @param {FileManager} fileManager
    */
    constructor (lifecycleManager, fileManager)
    
    /**
     * @return {Promise}
    */
    async start ()
    
    dispose ()
    
    /**
     * Preload choices to improve performance while presenting a choice set at a later time
     * @param {ChoiceCell[]} choices - a list of ChoiceCell objects that will be part of a choice set later
     * @return {Promise}
    */
    async preloadChoices (choices)
    
    /**
     * Deletes choices that were sent previously
     * @param {ChoiceCell[]} choices - A list of ChoiceCell objects
    */
    deleteChoices (choices)
    
    /**
     * Presents a choice set
     * @param {ChoiceSet} choiceSet - The choice set to be presented. This can include Choice Cells that were preloaded or not
     * @param {InteractionMode} mode - The intended interaction mode
     * @param {KeyboardListener} keyboardListener - A keyboard listener to capture user input
    */
    presentChoiceSet (choiceSet, mode, keyboardListener)
    
    /**
     * Presents a keyboard on the head unit to capture user input
     * @param {String} initialText - The initial text that is used as placeholder text. It might not work on some head units.
     * @param {KeyboardProperties} customKeyboardConfig - the custom keyboard configuration to be used when the keyboard is displayed
     * @param {KeyboardListener} listener - A keyboard listener to capture user input
     * @return {Number} - A unique ID that can be used to cancel this keyboard. If `null`, no keyboard was created.
    */
    presentKeyboard (initialText, customKeyboardConfig, listener)
    
    /**
     * Cancels the keyboard-only interface if it is currently showing. If the keyboard has not yet been sent to Core, it will not be sent.
     * This will only dismiss an already presented keyboard if connected to head units running SDL 6.0+.
     * @param {Number} cancelID - The unique ID assigned to the keyboard, passed as the return value from `presentKeyboard`
    */
    dismissKeyboard (cancelID)
    
    /**
     * Set a custom keyboard configuration for this session. If set to null, it will reset to default keyboard configuration.
     * @param {KeyboardProperties} keyboardConfiguration - the custom keyboard configuration to be used when the keyboard is displayed
    */
    setKeyboardConfiguration (keyboardConfiguration)
    
    /**
     * @return {Set.<ChoiceCell>} A set of choice cells that have been preloaded to the head unit
    */
    getPreloadedChoices ()

}


class SoftButtonManagerBase extends SubManagerBase {
    /**
     * constructor
     * @param {LifecycleManager} lifecycleManager
     * @param {FileManager} fileManager
    */
    constructor (lifecycleManager, fileManager)

    /**
     * After this method finishes, the manager is ready
     * @return {Promise}
    */
    async start ()

    /**
     * Teardown method
    */
    dispose ()

    /**
     * Get the SoftButtonObject that has the provided name
     * @param {String} name - a String value that represents the name
     * @return {SoftButtonObject|null} - a SoftButtonObject, or null if none is found
    */
    getSoftButtonObjectByName (name)

    /**
     * Get the SoftButtonObject that has the provided buttonId
     * @param {Number} buttonId - an int value that represents the ID of the button
     * @return {SoftButtonObject|null} - a SoftButtonObject, or null if none is found
    */
    getSoftButtonObjectById (buttonId)

    /**
     * Get the soft button objects list
     * @return {SoftButtonObject[]} - a List<SoftButtonObject>
    */
    getSoftButtonObjects ()

    /**
     * Set softButtonObjects list and upload the images to the head unit
     * @param {SoftButtonObject[]} list - the list of the SoftButtonObject values that should be displayed on the head unit
     * @return {Promise} - Resolves to BaseSoftButtonManager when done
    */
    async setSoftButtonObjects (list)

    /**
     * Get the current String associated with MainField1
     * @return {String} - the string that is currently used for MainField1
    */
    getCurrentMainField1 ()

    /**
     * Sets the String to be associated with MainField1
     * @param {String} currentMainField1 - the String that will be set to TextField1 on the current template
     * @return {BaseSoftButtonManager}
    */
    setCurrentMainField1 (currentMainField1)

    /**
     * Sets the batchUpdates flag that represents whether the manager should wait until commit() is called to send the updated show RPC
     * @param {Boolean} - batchUpdates Set true if the manager should batch updates together, or false if it should send them as soon as they happen
     * @return {BaseSoftButtonManager}
    */
    setBatchUpdates (batchUpdates)
    
}


class TextAndGraphicManagerBase extends SubManagerBase {
    /**
     * @constructor
     * @param {LifecycleManager} lifecycleManager
     * @param {FileManager} fileManager
     * @param {SoftButtonManager} softButtonManager
    */
    constructor (lifecycleManager, fileManager = null, softButtonManager = null) 

    /**
     * After this method finishes, the manager is ready
     * @return {Promise}
    */
    async start () 

    /**
     * Teardown method
    */
    dispose () 

    /**
     * @param {TextAlignment} textAlignment
     * @return {BaseTextAndGraphicManager}
    */
    setTextAlignment (textAlignment) 

    /**
     * @return {TextAlignment}
    */
    getTextAlignment () 

    /**
     * @param {String} mediaTrackTextField
     * @return {BaseTextAndGraphicManager}
    */
    setMediaTrackTextField (mediaTrackTextField) 

    /**
     * @return {String}
    */
    getMediaTrackTextField () 

    /**
     * @param {String} textField1
     * @return {BaseTextAndGraphicManager}
    */
    setTextField1 (textField1) 

    /**
     * @return {String}
    */
    getTextField1 () 

    /**
     * @param {String} textField2
     * @return {BaseTextAndGraphicManager}
    */
    setTextField2 (textField2) 

    /**
     * @return {String}
    */
    getTextField2 () 

    /**
     * @param {String} textField3
     * @return {BaseTextAndGraphicManager}
    */
    setTextField3 (textField3) 

    /**
     * @return {String}
    */
    getTextField3 () 

    /**
     * @param {String} textField4
     * @return {BaseTextAndGraphicManager}
    */
    setTextField4 (textField4) 

    /**
     * @return {String}
    */
    getTextField4 () 

    /**
     * @param {MetadataType} textField1Type
     * @return {BaseTextAndGraphicManager}
    */
    setTextField1Type (textField1Type) 

    /**
     * @return {MetadataType}
    */
    getTextField1Type () 

    /**
     * @param {MetadataType} textField2Type
     * @return {BaseTextAndGraphicManager}
    */
    setTextField2Type (textField2Type) 

    /**
     * @return {MetadataType}
    */
    getTextField2Type () 

    /**
     * @param {MetadataType} textField3Type
     * @return {BaseTextAndGraphicManager}
    */
    setTextField3Type (textField3Type) 

    /**
     * @return {MetadataType}
    */
    getTextField3Type () 

    /**
     * @param {MetadataType} textField4Type
     * @return {BaseTextAndGraphicManager}
    */
    setTextField4Type (textField4Type) 

    /**
     * @return {MetadataType}
    */
    getTextField4Type () 

    /**
     * @param {String} title
     * @return {BaseTextAndGraphicManager}
    */
    setTitle (title) 

    /**
     * @return {String}
    */
    getTitle () 

    /**
     * @param {SdlArtwork} primaryGraphic
     * @return {BaseTextAndGraphicManager}
    */
    setPrimaryGraphic (primaryGraphic) 

    /**
     * @return {SdlArtwork}
    */
    getPrimaryGraphic () 

    /**
     * @param {SdlArtwork} secondaryGraphic
     * @return {BaseTextAndGraphicManager}
    */
    setSecondaryGraphic (secondaryGraphic) 

    /**
     * @return {SdlArtwork}
    */
    getSecondaryGraphic () 

    /**
     * @param {Boolean} batching
     * @return {BaseTextAndGraphicManager}
    */
    setBatchUpdates (batching) 
    
}


class FileManagerBase extends SubManagerBase {
    /**
     * @constructor
     * @param {LifecycleManager} lifecycleManager
     */
    constructor (lifecycleManager) 
    
    /**
     * Returns a list of file names currently residing on core.
     * @return {Array<String>} - List of remote file names
     */
    getRemoteFileNames () 
    
    /**
     * Get the number of bytes still available for files for this app.
     * @return {Number} - Number of bytes still available
     */
    getBytesAvailable () 
    
    /**
     * Attempts to delete the desired file from core
     * @param {String} fileName - name of file to be deleted
     * @return {Promise} - Resolves to Boolean - whether the operation was successful
     */
    async deleteRemoteFileWithName (fileName) 
    
    /**
     * Attempts to delete a list of files from core
     * @param {String[]} fileNames - list of file names to be deleted
     * @return {Promise} - Resolves to Boolean[] - whether the operations were successful
     */
    async deleteRemoteFilesWithNames (fileNames) 
    
    /**
     * Creates and returns a PutFile request that would upload a given SdlFile
     * @param {SdlFile} sdlFile - SdlFile with fileName and one of A) fileData, B) Uri, or C) resourceID set
     * @return {Promise} - Resolves to PutFile - a valid PutFile request if SdlFile contained a fileName and sufficient data
     */
    async createPutFile (sdlFile) 
    
    /**
     * @param {SdlFile} sdlFile - SdlFile with file name and one of A) fileData, B) Uri, or C) resourceID set
     * @return {Promise} - Resolves to Boolean - whether the operation was successful
     */
    async uploadFile (sdlFile) 
    
    /**
     * Attempts to upload a list of SdlFiles to core
     * @param {SdlFile[]} sdlFiles - list of SdlFiles with file name and one of A) fileData, B) Uri, or C) resourceID set
     * @return {Promise} - Resolves to Boolean[] - whether the operations were successful
     */
    async uploadFiles (sdlFiles) 
    
    /**
     * Attempts to upload SdlArtwork to core
     * @param {SdlArtwork} sdlArtwork - SdlArtwork with file name and one of A) fileData, B) Uri, or C) resourceID set
     * @return {Promise} - Resolves to Boolean - whether the operation was successful
     */
    async uploadArtwork (sdlArtwork) 
    
    /**
     * Attempts to upload a list of SdlArtwork to core
     * @param {SdlArtwork} sdlArtworks - list of SdlArtworks with file name and one of A) fileData, B) Uri, or C) resourceID set
     * @return {Promise} - Resolves to Boolean[] - whether the operations were successful
     */
    async uploadArtworks (sdlArtworks) 
    
    /**
     * Check if an SdlFile has been uploaded to core
     * @param {SdlFile} sdlFile - SdlFile with file name and one of A) fileData, B) Uri, or C) resourceID set
     * @return {Boolean} that tells whether file has been uploaded to core (true) or not (false)
     */
    hasUploadedFile (sdlFile) 
}


class PermissionManagerBase extends SubManagerBase {
    /**
     * @constructor
    */
    constructor (lifecycleManager) 
    
    /**
     * @return {Promise}
    */
    async start () 
    
    /**
     * Checks if an RPC requires encryption
     *
     * @param {Number} functionId - the RPC's FunctionID to check
     * @return {Boolean} - true if the given RPC requires encryption; false, otherwise
     */
    getRpcRequiresEncryption (functionId) 
    
    /**
     * Gets the encryption requirement
     * @return {Boolean} - true if encryption is required; false otherwise
     */
    getRequiresEncryption () 
    
    /**
     * Determine if an individual RPC is allowed in the context of the current HMI level and permissions
     * @param {Number} functionId - FunctionID value that represents the ID of the RPC
     * @return {Boolean} whether the RPC is allowed or not
     */
    isRpcAllowed (functionId) 
    
    /**
     * Determine if an individual permission parameter is allowed in the context of the current HMI level and permissions
     * @param {FunctionID} functionId - The ID of the RPC
     * @param {String} parameter - A parameter for the RPC. Ex: "rpm" or "speed" for GetVehicleData
     * @return {Boolean} boolean represents whether the permission parameter is allowed or not
     */
    isPermissionParameterAllowed (functionId, parameter) 
    
    /**
     * Clean up everything after the manager is no longer needed
     * @return {PermissionManagerBase}
     */
    dispose () 
    
    /**
     * Determine if a group of permissions is allowed for the current HMI level
     * @param {PermissionElement[]} permissionElements - An array of PermissionElement that represents the RPC names and their parameters
     * @return {Number} An integer value that gives an overall view whether the permissions are allowed or not
     */
    getGroupStatusOfPermissions (permissionElements) 
    
    /**
     * Determine if a group of permissions is allowed for the current HMI level
     * @param {PermissionElement[]} permissionElements - An array of PermissionElement that represents the RPC names and their parameters
     * @return {Object} A key-value map with RPC IDs as keys and a PermissionStatus object (or null) as the value
     */
    getStatusOfPermissions (permissionElements) 
    
    /**
     * Add a listener to be called when there is permissions change
     * @param {PermissionElement[]} permissionElements - An array of PermissionElement that represents the RPC IDs and their parameters
     * @param {Number} groupType PermissionGroupType int value represents whether we need the listener to be called when there is any permissions change or only when all permissions become allowed
     * @param {function} listener - A function to be invoked upon permission change: function(Object<FunctionID, PermissionStatus>, PermissionGroupStatus)
     * @return {String} A UUID for the Permission Filter listener. It can be used to remove the listener later.
     */
    addListener (permissionElements, groupType, listener) 
    
    /**
     * Removes specific listener
     * @param {String} filterUuid - The UUID of the listener to be removed
     * @return {PermissionManagerBase}
     */
    removeListener (filterUuid) 
}

class LifecycleManager {
    /**
     * @param {AppConfig} sdlConfig
     * @param {LifecycleListener} lifecycleListener
     * @constructor
    */
    constructor (appConfig, lifecycleListener) 

    /**
     * After this method finishes, the manager is ready
     * @return {LifecycleManager}
    */
    start () 

    /**
     * Teardown method
    */
    stop () 

    /**
     * Gets the system capability manager
     * @param {SdlManager} sdlManager - A reference to an instance of SdlManager
     * @return {SystemCapabilityManager|null}
    */
    getSystemCapabilityManager (sdlManager) 

    /**
     * Determine whether or not the SDL Session is connected
     * @return {Boolean} isConnected
    */
    isConnected () 

    /**
     * Add a listener for a specific RPC
     * @param {Number} functionId
     * @param {function} callback
    */
    addRpcListener (functionId, callback) 

    /**
     * Remove a listener for a specific RPC
     * @param {Number} functionId
     * @param {function} callback
    */
    removeRpcListener (functionId, callback) 

    /**
     * Handles the logic of sending a message and listening for a response for requests
     * @param {RpcMessage} rpcMessage
     * @param {function} callback - callback(RpcResponse)
     * @return {Promise} - Resolves if the RPC response is SUCCESS, otherwise rejects
    */
    sendRpcMessage (rpcMessage = null) 

    /**
     * Gets the register app interface response
     * @return {RegisterAppInterfaceResponse}
    */
    getRegisterAppInterfaceResponse () 

    /**
     * Gets the HMI status
     * @return {OnHmiStatus}
    */
    getCurrentHmiStatus () 

    /**
     * Gets the auth token
     * @return {string}
    */
    getAuthToken () 

    /**
     * Gets the SDL message version
     * @return {SdlMsgVersion}
    */
    getSdlMsgVersion () 

    /**
     * Adds a listener for a system capability
     * @param {SystemCapabilityType} systemCapabilityType
     * @param {function} listener
    */
    addOnSystemCapabilityListener (systemCapabilityType, listener) 

    /**
     * Removes a listener for a system capability
     * @param {SystemCapabilityType} systemCapabilityType
     * @param {function} listener
     * @return {Boolean}
    */
    removeOnSystemCapabilityListener (systemCapabilityType, listener) 

}


class SystemCapabilityManager {
    /**
     * @constructor
     * @param {LifecycleManager} lifecycleManager
    */
    constructor (lifecycleManager = null) 

    /**
     * Gets the window capability given a window ID
     * @param {Number} windowId
     * @return {WindowCapability|null}
    */
    getWindowCapability (windowId) 

    /**
     * Returns the default main window capability
     * @return {WindowCapability|null}
    */
    getDefaultMainWindowCapability () 

    /**
     * Takes in a RAIR and stores its information
     * @param {RegisterAppInterfaceResponse} response
    */
    parseRaiResponse (response) 

    /**
     * @param {SystemCapabilityType} systemCapabilityType
     * @param {Object} capability
    */
    setCapability (systemCapabilityType, capability) 

    /**
     * Ability to see if the connected module supports the given capability. Useful to check before attempting to query for capabilities that require asynchronous calls to initialize.
     * @param {SystemCapabilityType} type - the SystemCapabilityType that is to be checked
     * @return {Boolean} - if that capability is supported with the current, connected module
     */
    isCapabilitySupported (type) 

    /**
     * Tries to find a capability in the cache
     * @param {SystemCapabilityType} systemCapabilityType
     * @return {Object|null} - returns null if a capability can't be returned
    */
    getCapability (systemCapabilityType) 

    /**
     * Sends a request to core for the capability, instead of only checking cached capabilities
     * @param {SystemCapabilityType} systemCapabilityType
     * @return {Promise} - Promise returning either the capability Object or null if not found
    */
    async queryCapability (systemCapabilityType) 

    /**
     * @param {SystemCapabilityType} systemCapabilityType
     * @param {function} listener
    */
    addOnSystemCapabilityListener (systemCapabilityType, listener) 

    /**
     * @param {SystemCapabilityType} systemCapabilityType
     * @param {function} listener
     * @return {Boolean}
    */
    removeOnSystemCapabilityListener (systemCapabilityType, listener) 


}
```

## Potential downsides

A lot of code will need to be written and tested, placing the burden of boilerplate on the project maintainers instead of the developers. But, the time saved in the long run for future developers will be much larger than the time taken to write the managers out now. 

## Impact on existing code

The code changes required are additive and will not impact existing code.

## Alternatives considered

Deviating from the existing manager layers' APIs is an option, but it comes at the cost of being a different set of APIs, and so a developer migrating from the Java Suite or iOS libraries would have to learn and understand the manager layer all over again.
