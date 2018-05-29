# Android Manager APIs

* Proposal: [SDL-NNNN](NNNN-android-manager-apis.md)
* Author: [Brett McIsaac](https://github.com/brettywhite), [Bilal Alsharifi](https://github.com/bilal-alsharifi), [Joey Grover](https://github.com/joeygrover)
* Status: **Awaiting Review**
* Impacted Platforms: Android

## Introduction

This proposal is for synching up the Android SDL library with the iOS library in terms of developer facing APIs. It accomplishes this by introducing a high level developer interface for the Android library through managers. It handles many complex aspects of SDL development, including managing files and setting information on the screen. It also creates a system in which other managers can be easily added in the future to handle tasks. Many aspects of this system are mirrored from the iOS manager system and are designed to be as close as possible to that API while maintaining common Java and Android paradigms. 

## Motivation

In order to work with SDL, app developers are required to learn a new API that includes low level aspects rather than a familiar, native API. The steps to accomplish this include but are not limited to:

   - Read Android documentation, guides, and best practices 
   - Implement the proxy lifecycle
   - Manually handling the majority of RPC notifications, requests and responses
   - Manually managing concurrent and sequential operations (e.g. image upload before on screen show)

The learning curve for an app developer to understand SDL for Android is high and the knowledge is specific to the platform. Development time becomes increased by the necessary boiler plate logic needed to perform common actions. This also introduces a higher probability of error prone code. This proposal aims to fix that by handling much of the complex logic through managers which exposes simpler, easier to understand APIs.

## Proposed Solution

This proposal is about adding a new manager layer to the SDL Android library. As stated, many of the managers use similar APIs to already implemented iOS APIs. It has been designed to be only a minor version change, and will not modify current public APIs.

The new manager system is managed by a class called `SdlManager`. The `SdlManager` handles the lifecycle logic as well as the instantiation and disposal of submanagers. Submanagers extend `BaseSubManager` which contains mostly lifecycle logic and common methods for now, but could easily be expanded in the future.

##### Intended Goals:
1. Match the iOS library manager API as close as possible
2. Reduce the time that it takes for developers to learn SDL for Android
3. Reduce bad practices in system implementations
4. Create a system that is abstracted from low level API details that will allow for more dynamic changes.

### Managers

##### SdlManager

The SDL manager will be the main, developer facing class that will be instantiated to handle lifecycles, submanagers, and any low level API needs. It contains a builder, an ISdl instantiation, and the proxy bridge interface. All submanagers will be created upon instantiation of this manager and their lifecycle controlled by it. 

```java
public class SdlManager implements ProxyBridge.LifecycleListener {

    public static class Builder {
        SdlManager sdlManager;

        public Builder(){}

        public Builder setAppId(final String appId){}

        public Builder setAppName(final String appName){}

        public Builder setIsMediaApp(final Boolean isMediaApp){}

        public Builder setLanguage(final Language hmiLanguage){}

        public Builder setLockScreenConfig (final LockScreenConfig lockScreenConfig){}

        public Builder setHMITypes(final Vector<AppHMIType> hmiTypes){}

        /**
         * This Object type may change with the transport refactor
         */
        public Builder setTransportType(BaseTransportConfig transport){}

        public Builder setContext(Context context){}

        public SdlManager build() {}
    }

    // MANAGER GETTERS

    public FileManager getFileManager() {}

    public VideoStreamingManager getVideoStreamingManager() {}

    public AudioStreamManager getAudioStreamManager() {}

    public ScreenManager getScreenManager() {}

    public LockscreenManager getLockscreenManager() {}

    public PermissionManager getPermissionManager() {}

    public SystemCapabilityManager getSystemCapabilityManager() {}

    // SENDING REQUESTS

    public void sendRPCRequest(RPCRequest request) throws SdlException {}

    public void sendSequentialRequests(final List<? extends RPCRequest> rpcs, final OnMultipleRequestListener listener) throws SdlException {}

    public void sendRequests(List<? extends RPCRequest> rpcs, final OnMultipleRequestListener listener) throws SdlException {}

    // LIFECYCLE / OTHER

    @Override
    public void onProxyClosed(String info, Exception e, SdlDisconnectedReason reason){}

    @Override
    public void onServiceEnded(OnServiceEnded serviceEnded){}

    @Override
    public void onServiceNACKed(OnServiceNACKed serviceNACKed){}

    @Override
    public void onError(String info, Exception e){}
}
```

#### BaseSubManager

This is an abstract class that contains common lifecycle elements and methods between submanagers. This proposal only intends to include a small amount of code for this class, however, during implementation if logic is found to be common between different managers, it will be moved into this abstract class.

```java
public abstract class BaseSubManager {

	// allows better handling of submanagers by maintaining their states
	public enum ManagerState {
		SETTING_UP,
		READY,
		SHUTDOWN,
		ERROR,;
	}

	protected ISdl internalInterface;
	protected ManagerState state;

	public BaseSubManager(@NonNull ISdl internalInterface){
		this.internalInterface = internalInterface;
		this.state = ManagerState.SETTING_UP;
	}

	/**
	 * <p>Called when manager is being torn down</p>
	 */
	public void dispose(){
		this.state = ManagerState.SHUTDOWN;
	}

	protected void transitionToState(ManagerState state) {
		this.state = state;
	}

	protected ManagerState getState() {
		return state;
	}
}
	
```

#### LockScreenManager (and default lock screen)

The lockscreen manager maintains the same base logic as the previous lockscreen manager, but also adds in key functionality that was missing previously. New items include a default lockscreen (layout and activity) and the ability to customize that default lockscreen layout. Apps are also able to pass in custom layouts or disable it completely and roll their own.

```java
public class LockscreenManager extends BaseSubManager {

    public interface OnLockScreenIconDownloadedListener{
        public void onLockScreenIconDownloaded(Bitmap icon);
        public void onLockScreenIconDownloadError(Exception e);
    }

    public LockscreenManager(LockScreenConfig lockScreenConfig, Context context, ISdl internalInterface){}

    public Bitmap getLockScreenIcon(){}

}
```
##### Lockscreen Config

```java
public class LockScreenConfig {

	public LockScreenConfig(){}

	public void setEnabled(Boolean enableAutomaticLockScreen){}

	public Boolean getEnabled() {}

	public void setBackgroundColor(Color backgroundColor){}

	public Color getBackgroundColor() {}

	public void setAppIcon(int appIconInt) {}

	public int getAppIcon() {}
	
	public void setCustomView(int customLayoutResource) {}

	public int getCustomView() {}
}
```

The lockscreen manager will instantiate and manage the lockscreen activity and set the parameters appropriately depending on the lockscreen configuration provided by the developer. If `setEnabled` is set to `False`, the developer will need to manage their lockscreen manually. 

#### ScreenManager

This manager closely follows the previously accepted and implemented iOS manager proposal for [Show Manager](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0134-ios-show-manager.md), also known as the Screen Manager. It gives the developer the ability to easily manage the items on the screen without having to worry about things such as the special ordering of RPCs needed and reduces a large amount of boiler plate logic.

###### Previous Developer Flow

1. Send `ListFiles` to module. 
2. Wait for `ListFiles` response.
3. If image file is not on module, send `PutFile` of image. 
4. Wait for `PutFile` response.
5. Build `Show` with all fields including image parameter.
6. Send `Show` RPC.

###### New ScreenManager Flow

1. Set field in `ScreenManager`.

```java
public class ScreenManager extends BaseSubManager {
    // Constructors

    public ScreenManager(ISdl internalInterface, FileManager fileManager) {}

    // Setters

    public void setTextField1(String textField1) {}

    public void setTextField2(String textField2) {}

    public void setTextField3(String textField3) {}

    public void setTextField4(String textField4) {}

    public void setMediaTrackTextField(String mediaTrackTextField) {}

    public void setPrimaryGraphic(SDLArtwork primaryGraphic) {}

    public void setSecondaryGraphic(SDLArtwork secondaryGraphic) {}

    public void setTextAlignment(SDLTextAlignment textAlignment) {}

    public void setTextField1Type(MetadataType textField1Type) {}

    public void setTextField2Type(MetadataType textField2Type) {}

    public void setTextField3Type(MetadataType textField3Type) {}

    public void setTextField4Type(MetadataType textField4Type) {}

    public void setSoftButtonObjects(ArrayList<SoftButtonObject> softButtonObjects) {}

    // Getters

    public String getTextField1() {}

    public String getTextField2() {}

    public String getTextField3() {}

    public String getTextField4() {}

    public String getMediaTrackTextField() {}

    public SDLFile getPrimaryGraphic() {}

    public SDLFile getSecondaryGraphic() {}

    public SDLTextAlignment getTextAlignment() {}

    public MetadataType getTextField1Type() {}

    public MetadataType getTextField2Type() {}

    public MetadataType getTextField3Type() {}

    public MetadataType getTextField4Type() {}

    public ArrayList<SoftButtonObject> getSoftButtonObjects() {}

    // Updates

    public void beginUpdates(){}

    public void endUpdates(CompletionListener listener){}

}

```

##### SoftButtonManager

This is a non-developer facing submanager of the screen manager. It maintains the softbuttons for the current template including their states and images needed.

```java
public class SoftButtonManager extends BaseSubManager {

    protected boolean batchUpdates;

    // Constructors

    public SoftButtonManager(ISdl internalInterface, FileManager fileManager) {}

    // Update Methods

    public void update() {}

    // Setters / Getters

    public void setSoftButtonObjects(ArrayList<SoftButtonObject> softButtonObjects){}

    public ArrayList<SoftButtonObject> getSoftButtonObjects() {}
    
    public void setHmiLevel(HMILevel level){}

    public HMILevel getHmiLevel() {}

    public void setCurrentMainField1(String mainField1){}

    public String getCurrentMainField1(){}
}
```

The states of softbuttons allow the developer to not have to manage multiple softbuttons that have very similar functionality. For example, a repeat button in a music app can be thought of as one button with three typical states: repeat off, repeat 1, and repeat on. So the developer really only wants to manage simple states between a single button. We introduce a class that handles these:

```java
public class SoftButtonObject {

    public SoftButtonObject(String name, ArrayList<SoftButtonState> states, String initialStateName) {}

    public SoftButtonObject(String name, SoftButtonState state, String initialStateName) {}

    public Boolean transitionToStateNamed(String stateName){}

    public void transitionToNextState() {}

}
```

The `SoftButtonState` class is a small class that defines an individual state.

```java
class SoftButtonState {

    SoftButtonState(String name, String text, SDLFile artwork) {}

}
```

##### TextAndGraphicManager

This submanager is based off and mimics the previously [accepted proposal](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0134-ios-show-manager.md) and [implementation ](https://github.com/smartdevicelink/sdl_ios/blob/master/SmartDeviceLink/SDLTextAndGraphicManager.m) for iOS. This is very similar to the soft button manager as it is a submanager of the screen manager that intends to be non-developer facing. Its purpose is to handle the logic of setting text and artworks. The text setting is dynamic, just as it is in iOS. The complexity of this seemingly simple problem does warrant a specific manager to help scope the code and responsibilities. The merits for this decision were also laid out in the aforementioned proposal and its review. 

```java
public class TextAndGraphicManager extends BaseSubManager {

    private MetadataTags textField1Type, textField2Type, textField3Type, textField4Type;

    //Constructors

    public TextAndGraphicManager(ISdl internalInterface, FileManager fileManager) {}

    // Upload / Send

    public void update() {}

}
```

#### AudioStreamManager

The `AudioStreamManager` [proposal](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0113-audiostreammanager.md) was already accepted but is included in this proposal as reference to the larger effort towards the high level manager APIs. Currently the manager handles only basic operations, but in time it might be feasible to perform transcoding of audio formats similar to the iOS implementation, but due to the lack of native APIs this is not included. 

```java
public class AudioStreamManager extends BaseSubManager implements ISdlServiceListener{

    boolean didRequestShutdown = false;
    public BlockingQueue<SdlAudio> queue;

    public AudioStreamManager(ISdl internalInterface){}

    // Methods
    public IAudioStreamListener start(boolean isEncrypted, AudioStreamingCodec codec,
                                      AudioStreamingParams params){}

    public void stop(){}

    public void play(SdlAudioStream audioClip, boolean playImmediately){}

    // ISdlServiceListener Overrides

    @Override
    public void onServiceStarted(SdlSession session, SessionType type, boolean isEncrypted) {}

    @Override
    public void onServiceEnded(SdlSession session, SessionType type) {}

    @Override
    public void onServiceError(SdlSession session, SessionType type, String reason) {}

    public static class SdlAudioStream{
        URL url;
        File file;
        int resLocation;
        IStreamCallback callback;


        public interface IStreamCallback{
            void onFinished();
            void onError(String error);
        }
    }
}
```

#### VideoStreamingManager

The Android library has a private manager that currently manages video streaming through a `SdlRemoteDisplay` class. This manager intends to be developer facing and handle both cases of remote display and give the developer the option to stream bytes of their encoding through the video service. 

```java
@TargetApi(19)
public class VideoStreamingManager extends BaseSubManager implements ISdlServiceListener {

    public VideoStreamingManager(Context context,ISdl internalInterface){}

    //Library handled video stream display
    public void startRemoteDisplayStream(final Class<? extends SdlRemoteDisplay> remoteDisplay, final VideoStreamingParameters parameters, final boolean encrypted){}
    
    //Method to receive an interface to write raw video 
    public IVideoStreamListener startVideoStream(VideoStreamingParameters parameters, boolean encrypted){}
    
    private void startVideoStreaming(VideoStreamingParameters parameters, boolean encrypted){}

    public void stopStreaming(){}

	@Override
    public void dispose(){}

    @Override
    public void onServiceStarted(SdlSession session, SessionType type, boolean isEncrypted) {}

    @Override
    public void onServiceEnded(SdlSession session, SessionType type) {}

    @Override
    public void onServiceError(SdlSession session, SessionType type, String reason) {}
}
```

#### FileManager

The `FileManager` handles one of the most error prone SDL tasks, managing files uploads, status, and deletion. It is based on a few previously accepted and [implemented proposals](https://github.com/smartdevicelink/sdl_ios/blob/master/SmartDeviceLink/SDLFileManager.m) for the iOS library. This manager will contain a list of remote files that are retrieved on startup, and contains functions for the creating and deleting of files and artwork. It will also make use of our new `CompletionListener` for many of its functions.

```java
public class FileManager extends BaseSubManager {

    FileManager(ISdl internalInterface, Context context) {}

    // GETTERS

    public ArrayList<String> getRemoteFileNames() {}

    // DELETION

    public void deleteRemoteFileWithName(String fileName, CompletionListener listener){}

    public void deleteRemoteFilesWithNames(ArrayList<String> fileNames, CompletionListener listener){}

    // UPLOAD FILES / ARTWORK

    public void uploadFile(SDLFile file, CompletionListener listener){}

    public void uploadFiles(ArrayList<SDLFile> files, CompletionListener listener){}
    
    // HELPER METHODS
    
    public static Uri resourceToUri(Context context, int resID)

}
```

#### PermissionManager

The `PermissionManager` allows the developer to easily query whether an individual permission is allowed or not. It also allows a listener to be added for a list of permissions so that if they are changed, the developer would then be notified. This manager closely mimics that of its [iOS counterpart](https://github.com/smartdevicelink/sdl_ios/blob/master/SmartDeviceLink/SDLPermissionManager.m). 

```java
 public class PermissionManager extends BaseSubManager{

    // Permission groups status constants
    @IntDef({PERMISSION_GROUP_STATUS_ALLOWED, PERMISSION_GROUP_STATUS_DISALLOWED,
            PERMISSION_GROUP_STATUS_MIXED, PERMISSION_GROUP_STATUS_UNKNOWN})
    @Retention(RetentionPolicy.SOURCE)
    public @interface PermissionGroupStatus {}
    public static final int PERMISSION_GROUP_STATUS_ALLOWED = 0;    // Every permission in the group is currently allowed
    public static final int PERMISSION_GROUP_STATUS_DISALLOWED = 1; // Every permission in the group is currently disallowed
    public static final int PERMISSION_GROUP_STATUS_MIXED = 2;      // Some permissions in the group are allowed and some disallowed
    public static final int PERMISSION_GROUP_STATUS_UNKNOWN = 3;    // The current status of the group is unknown

    // Permission groups type constants
    @IntDef({PERMISSION_GROUP_TYPE_ALL_ALLOWED, PERMISSION_GROUP_TYPE_ANY})
    @Retention(RetentionPolicy.SOURCE)
    public @interface PermissionGroupType {}
    public static final int PERMISSION_GROUP_TYPE_ALL_ALLOWED = 0;  // Be notified when all of the permissions in the group are allowed, or, when they all stop being allowed in some sense, that is, when they were all allowed, and now they are not.
    public static final int PERMISSION_GROUP_TYPE_ANY = 1;          // Be notified when any change in availability occurs among the group


    PermissionManager(ISdl internalInterface){}

    // Determine if an individual RPC is allowed for the current HMI level
    public boolean isRPCAllowed(FunctionID rpcName){}

    public boolean isPermissionParameterAllowed(FunctionID rpcName, String parameter){}

    public void dispose(){}

    // Determine if a group of permissions are allowed for the current HMI level
    public @PermissionGroupStatus int getGroupStatusOfPermissions(List<PermissionElement> permissionElements){}

    // Retrieve a map with keys that are the passed in RPC names specifying if that RPC
    // and its parameter permissions are currently allowed for the current HMI level
    public Map <FunctionID, PermissionStatus> getStatusOfPermissions(List<PermissionElement> permissionElements){}

    public UUID addListener(List<PermissionElement> permissionElements, @PermissionGroupType int groupType, OnPermissionChangeListener listener){}

    // Removes specific listener
    public void removeListener(UUID listenerId){}

    public interface OnPermissionChangeListener {
        void onPermissionsChange(Map <FunctionID, PermissionStatus> allowedPermissions, @PermissionGroupStatus int permissionGroupStatus);
    }

}
```

The `PermissionElement` class holds an RPC name and its parameter permissions.

```java
public class PermissionElement {
    PermissionElement(FunctionID rpcName, List<String> parameters){}

    public FunctionID getRpcName() {}

    public void setRpcName(FunctionID rpcName) {}

    public List<String> getParameters() {}

    public void setParameters(List<String> parameters) {}
}
```

The `PermissionStatus` class is a small class that represents whether an individual RPC and its parameters are allowed or not.

```java
class PermissionStatus {
    public PermissionStatus(FunctionID rpcName, boolean isRPCAllowed, Map<String, Boolean> allowedParameters) {}

    public FunctionID getRpcName() {}

    public boolean getIsRPCAllowed() {}

    public Map<String, Boolean> getAllowedParameters() {}
}
```

The `PermissionFilter` holds all the required information for a specific listener.

```java
class PermissionFilter {
    PermissionFilter(UUID identifier, List<PermissionElement> permissionElements, int groupType, PermissionManager.OnPermissionChangeListener listener) {}

    UUID getIdentifier() {}

    List<PermissionElement> getPermissionElements() {}

    int getGroupType() {}

    PermissionManager.OnPermissionChangeListener getListener() {}
}
```

### Other Additions

#### SDLProxyBridge

The SDLProxyBridge has been implemented to allow the library to bridge from old APIs to new. The `SdlManager` will hold an instantiate of this class that is passed to its proxy object. Using the `SdlProxyBase` as our main interface into the old APIs with this bridge, the manager API change can be added with only a minor version change. Proxy bridge allows the managers to listen for specific RPCs without having to individually implement `IProxyListenerBase` themselves and having to override all of the response methods like what is currently required.

```java
public class ProxyBridge implements IProxyListenerBase{

	public interface OnRPCListener {
		void onRpcReceived(int functionID, RPCMessage message);
	}

	protected interface LifecycleListener{
		void onProxyClosed(String info, Exception e, SdlDisconnectedReason reason);
		void onServiceEnded(OnServiceEnded serviceEnded);
		void onServiceNACKed(OnServiceNACKed serviceNACKed);
		void onError(String info, Exception e);
	}

	public ProxyBridge( LifecycleListener lifecycleListener){}

	public boolean onRPCReceived(final RPCMessage message){}

	protected void addRpcListener(FunctionID id, OnRPCListener listener){}

	public boolean removeOnRPCListener(FunctionID id, OnRPCListener listener){}
	
	.....
	
	// All overridden IProxyListenerBase methods
```

#### SDLFile

SDLFile will be added to further match the API with iOS. It will contain helpers that do some of the work that we required the developer to do before, like automatically setting the file type and assembling the byte array of the file to be sent. For uploading a file, the developer may choose to pass either a resource id, a URI, or the byte array itself. 


```java
public SdlFile{

	public void setName(@NonNull String fileName) 
	public String getName()

	public void setResourceId(int id, Resources resources)
	public void getResourceId()

	public void setUri(URI uri)
	public byte[] getUri()

	public void setFileData(byte[] data)
	public byte[] getFileData()

	public void setType(@NonNull FileType fileType)
	public FileType getType()

	public void setPersistent(boolean persistentFile)
	public boolean isPersistent()
}
```

###### SDLArtwork

`SDLArtwork` will extend `SDLFile` and be specifically for uploading images.


#### CompletionListener

A simple listener with a single method, `onComplete(boolean success)` will be added. Its purpose is simply understand when an asynchronous call in the library was completed, and if it was completed successfully or not. 

```java 
public interface CompletionListener {
	/**
	 * Returns whether a specific operation was successful or not
	 * @param success - success or fail
	 */
	void onComplete(boolean success);
}
```

### Future Manager Alignment

Future managers, like the recently approved [Menu Manager](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0155-mobile-menu-manager.md), and [Choice Set Manager](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0157-mobile-choice-manager.md) will now be able to be easily added with this system in place. This means we should no longer experience a large divergence between the iOS and Android library in terms of developer facing APIs.

### Deprecation and Future Implications

The main goal of this proposal is to create the new developer facing API that is easier to use and understand than the previous version. Once that is established, it will be possible to systematically deprecate and remove or make private old public APIs. Some of the initial classes to be deprecated are listed below.

##### Classes that will be deprecated

1. `SdlProxyALM`
2. `SdlProxyBase`
3. `SdlProxyBuilder`
4. `IProxyListener`

##### Proxy Replacement

The hopes is that after the manager API is in place and old proxy classes are deprecated, a new, simpler, private version of the proxy can be created. This proposal does not intend to flesh out those details, but the idea is mentioned here to understand the goal of introducing this large change.

## Potential Downsides

- This proposal will add a great deal of code to the project itself. While the effect will be large at first, over time it will allow for the removal of old classes and logic that are no longer necessary. It is also worth noting that while the library is expanded, the majority of this code was required for developers to write and contain themselves so the size during implementation is near 1 to 1.
- The manager API for the Android Library does not include the `StreamingMediaManager`. This manager seemed redundant on top of the video and audio streaming managers so it was not included.
- Developers that have focused on the Android platform will have to reacquaint themselves with this new API. However, if they have used the iOS library then this should be a nonissue. 

## Impact on existing code

Since this is additive, there will be minimal impact on existing code. A few additions to `ISdl` will require that the added methods are also overwritten in `SdlProxyBase`. Because of this, it can be implemented as a minor version change.


## Alternatives considered
- Starting from scratch and making most native managers. This was dismissed due to not aligning with iOS would only widen the rift between the platforms.
- Slowly introducing the managers one by one. This was useful when implementing into the iOS library. However, since the managers have been proven out on the iOS platform as well as developers understanding and using them it was decided that matching all the managers at once makes the most sense.
- Skipping the managers and going straight to the template screen APIs that are awaiting proposals. It was apparent that these managers would almost be guaranteed to be necessary to support those layers so it was decided they should be added first.
