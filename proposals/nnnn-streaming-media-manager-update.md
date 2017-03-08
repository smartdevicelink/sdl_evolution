# Streaming Media Manager 5.0
* Proposal: [SDL-NNNN](NNNN-filename.md)
* Author: [Alex Muller](https://github.com/asm09fsu)
* Status: **Awaiting review**
* Impacted Platforms: iOS / Protocol

## Introduction
This proposal is geared at revamping how the Streaming Media Manager (SMM) class manages audio/video streaming. This revamp will also include lifecycle management for these streams as the overall app/proxy lifecycle changes.


## Motivation
We currently have a SMM which provides the basic functionality for streaming audio and video, however much of the management of this class is still up to the developer, and may vary by implementations. In order to allow developers to deliver high quality mobile navigation experiences, the SMM should be revamped to remove much of the bloat and management of the sessions internally and allow the developers to easily use this class for mobile navigation applications. If you need a real reason for why this should be considered, look at the Detailed Design section for all the possible complexities we expect every developer to implement.


## Proposed solution
#### Current Supported Features:
- Starting/Stopping video session with different encryption flags
- Starting/Stopping audio session with different encryption flags
- Sending video data via `CVImageBufferRef`
- Sending audio data via `NSData` of PCM data
- Ability to interact with `SDLTouchManager`
- Ability to set custom video encoder settings
- Access to the shared `CVPixelBufferPoolRef` provided by the encoder
- Access to the screen size of the connected head unit.

#### New Features
- Management of the video session lifecycle in conjunction with proxy & app state changes
- Management of the audio session lifecycle in conjunction with proxy & app state changes
- Ability to register to a touch manager handler for touch events.

## Detailed design
There are multiple parts of the proxy lifecycle that the SMM would have an impact on.
#### `SDLLifecycleManager`
If the application has an `SDLLifecycleConfiguration` with the `appType` of `NAVIGATION`, then SMM will be started automatically once `SDLLifecycleManager` enters the state `didEnterStateSettingUpManagers`. This would simply start the manager, not the sessions. At this point, SMM is ready and listening to HMI status changes and will internally start/stop protocols.
#### `SDLStreamingMediaManager`
Due to the need to make sure we properly unit test all possible combinations of HMI, app and streaming states, we need to be able to change the state machine at will. This, however, should not be exposed to the developer. Because of this, `SDLStreamingMediaManager` will be a wrapper around `SDLStreamingMediaLifecycleManager`, similar to how `SDLManager` is a wrapper around `SDLLifecycleManager`.

#### `SDLStreamingMediaLifecycleManager`
##### State Machines
There will need to be multiple state machines that need to work together to deal with all the possible scenarios the app can be in on both the phone and head unit. Luckily, HMI states are already provided so we will not be building a new state machine, but will list the possible scenarios for different states below.
###### Phone (new state machine)
1. Resigning Active
	- The app is moving to the background. If the streaming state is **Ready**, and in HMI **Limited or greater**, we should send ~30 frames so that we can alert the user to reopen the app. The streams will remain open. Can move to **Backgrounded**.
2. Backgrounded
	- The app is currently in the background, and cannot use the encoder to send over frames. Regardless of HMI changes, we cannot stream video. The stream should remain open if currently open. If the HMI changes to **Background or less**, we should close the sessions, and the Streaming state will move to **Stopped**. Can move to **Regaining Active**.
3. Regaining Active
	- The app is currently regaining it’s position as the foreground app. If we are currently in HMI **Limited or greater**, and the Streaming state is **Ready**, we will restart the streams by moving to state **Stopped**, and then **Starting**, followed by **Ready**. Can move to **Active**.
4. Active
	- The app is in the foreground. We are able to stream if needed, permitting we are in the proper HMI. Can move to **Resigning Active**.

###### HMI (states already available)
1. None
	* App has not been opened yet, or was closed via the app’s Menu button. If the streaming session is **Ready**, we need to move to **Stopped**.
2. Background
	- App was open, however a new streaming app has been opened, and is taking streaming priority. If the streaming session is **Ready**, we need to move to **Stopped**.
3. Limited
	- App was open, however the user has moved to another screen on the head unit. This app is still the primary streaming app. The Streaming State must not move from **Ready**, however if the Phone State is moving from **Active** to **Resigning Active**, we must send 30 frames.  
4. Full
	- App is open, and is currently in focus. If the Streaming State is currently **Stopped**, we should proceed to **Starting**, so long as the Phone State is not **Resigning Active** or **Backgrounded**. If moving to this state and the Phone State is currently **Regaining Active** or **Active**, and the Streaming State is currently  **Ready**, the Streaming State should be moved to **Stopped** followed by **Starting** (restarting the streams). If moving to this state and the Phone State is currently **Backgrounded**, send an RPC to alert the user to open the app (current suggestion is an Alert with TTS).

###### Streaming (new state machine)
1. Stopped
	- Streaming is stopped, and sessions are closed. Can move to **Starting** only if HMI is **Limited or greater** and Phone State is **Regaining Active** or **Active**.
2. Starting
	- Streaming sessions are being opened, and encoder is being prepared. Can move to **Ready** only if HMI is **Limited or greater** and Phone State is **Regaining Active** or **Active**. If not, move to **Stopped**.
3. Ready
	- Streaming sessions and encoder are ready. This state is only active so long as HMI is **Limited or greater** and Phone State is **Regaining Active** or **Active**. If at this state, and Phone State changes to **Resigning Active**, send ~30 frames. If at this state, and HMI changes to **Background or less**, move to **Stopped**.

###### Video Lifecycle Chart
HMI State   | App State         | Can Open Video Stream | Should Close Video Stream
------------|-------------------|-----------------------|--------------------------
NONE        | Background        | No                    | Yes
NONE        | Regaining Active  | No                    | Yes
NONE        | Foreground        | No                    | Yes
NONE        | Resigning Active  | No                    | Yes
BACKGROUND  | Background        | No                    | Yes
BACKGROUND  | Regaining Active  | No                    | Yes
BACKGROUND  | Foreground        | No                    | Yes
BACKGROUND  | Resigning Active  | No                    | Yes
LIMITED     | Background        | No                    | No
LIMITED     | Regaining Active  | Yes                   | Yes
LIMITED     | Foreground        | Yes                   | No
LIMITED     | Resigning Active  | No                    | No
FULL        | Background        | No                    | No
FULL        | Regaining Active  | Yes                   | Yes
FULL        | Foreground        | Yes                   | No
FULL        | Resigning Active  | No                    | No

###### Audio Stream Lifecycle Chart
Since the app state is irrelevant for audio streaming (because we can do this in the background), the lifecycle chart is a bit simpler than the video lifecycle chart.

HMI State   | Can Open Audio Stream | Should Close Audio Stream
------------|-----------------------|--------------------------
NONE        | No                    | Yes
BACKGROUND  | No                    | Yes
LIMITED     | Yes                   | No
FULL        | Yes                   | No

##### Sending Video Data
The way in which video frames are sent over will not change from the current implementation. This function will require input of a `CVImageBufferRef` for video. It will be up to the developer to decide how to frequently to call this function. The developer will be able to know if the currently connected stream is encrypted with a `BOOL` `isEncrypted`, a `CGSize` `screenSize` to let them know the current Head Unit screen size, and a `CVPixelBufferPoolRef` for using the encoder’s pixel buffer pool, as is currently available in SMM.
There will also be getter `isVideoStreamingPaused` that informs a developer to if sending of video data is not occurring based on circumstances where there’s not a need to send frames. If video streaming moves to a state where streaming cannot occur (i.e. HMI state changes to Limited, or Phone state move to Resigning Active), `isVideoStreamingPaused` will be set to `YES`, and will resume when possible.

The thought for implementation is as follows:
```objc
// Checking if SMM is paused
if (streamingMediaManager.isVideoStreamingPaused) {
	<#pause pulling of frames if running#>
	return;
}

// Sending Video Data
CVPixelBufferPoolRef pixelBufferPool = streamingMediaManager.pixelBufferPool;
CGSize screenSize = streamingMediaManager.screenSize;

CVImageBufferRef frame = <#acquire video frame#>
[streamingMediaManager sendVideoFrame:frame];
```

##### Sending video data when iPhone is moving to background
Since iOS cannot use the encoder when the phone is in the background, to conserve battery and CPU, we must find a solution that will drive the user to reopen the app. The suggested solution is to create a single frame that is generated when SMM’s encoder is initialized, and send that over as the Phone State changes from **Active** to **Resigning Active**. This should be built as a non-customizable screen, so that we can rely on consistent behavior among streaming applications for the time being. The current idea is to have a black screen with the text “Please re-open <#App Name#>”. We have the option to provide translations for all languages that SDL supports, if we wish to go that route. We can also use the app icon, if we wish instead of the app name, as the app name could potentially be quite long.

##### Sending Audio Data
Since audio data is sent sporadically, we will have a function that will send audio data only when necessary.
```objc
// Sending Audio Data
[streamingMediaManager sendAudioData:<#audioData#>];
```

#### `SDLTouchManager`
Currently, the `SDLTouchManager` class allows for developers to use a provided set of callbacks so they do not have to provide logic for determining gesture events such as tap, double tap, pinch, and pan. There are some developers, however, that would still like the ability to use their own. Currently, developers can listen to `SDLOnTouchEvent` notifications, and consume the object themselves, however a proposed solution is to make the internal `SDLTouch` object public, and allow for developers to use a handler on `SDLTouchManager` that will provide this touch object back, along with the `SDLTouchType`, to make it easier to handle and consume `SDLOnTouchEvent`.

We would add a property to `SDLTouchManager` called `touchEventHandler`:
```objc
typedef void(^SDLTouchEventHandler)(SDLTouch *touch, SDLTouchType type);

/**
*  @abstract
*      Returns all OnTouchEvent notifications as SDLTouch and SDLTouchType objects.
*/
@property (copy, nonatomic, nullable) SDLTouchEventHandler touchEventHandler;

```

## Impact on existing code
The impact on SDL is that the previous version of `SDLStreamingMediaManager` and all code associated will no longer work. This will require a developer to adapt to using this new method of streaming, but will greatly improve the efficiency of Mobile Navigation Apps.

## Alternatives considered
The alternative decision of keeping the SMM as is was considered, but it is thought as not ideal because this forces the developer to implement the logic for different states of the application both on device, and also on the head unit. This should be consistent across all apps so we can make sure the experience is ideal and consistent for all users.
