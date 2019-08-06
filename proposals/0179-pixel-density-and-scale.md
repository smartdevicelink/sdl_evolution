# Pixel density and Scale

* Proposal: [SDL-0179](0179-pixel-density-and-scale.md)
* Author: [Michael Crimando](https://github.com/MichaelCrimando) [Kujtim Shala](https://github.com/kshala-ford)
* Status: **Accepted**
* Impacted Platforms: [Core / iOS / Android / RPC]

## Introduction

This proposal is about adding parameters to `VideoStreamingCapabilities` for pixel density and scale.

## Motivation

Today navigation app developers create a video stream using the screen resolution in pixel without knowing the screen size/pixel density. This can result into different behaviors on screens with the same size but different resolutions.

## Proposed solution

The idea is to include
- *Diagonal screen size* of the screen
- *Pixel per inch (PPI)* of the screen
- *Scale value* to determine how the app should scale the captured view

Main goal is to align different screens and use a common range of "points per inch". This will allow showing assets with a similar size on different screen resolutions.

Below you will find examples of three screens of different sizes and resolutions:
- `scale` is coming from the head unit.
- `Viewport of the head unit` is the accepted resolution coming from StartServiceACK
- `Viewport of the apps view` means the size set to the view used for capturing
- `Pixels per inch` is coming from the head unit
- `Points per inch` is the result of using the scale

Example 1: 8” screen (800x480 pixels)
- scale (1x)
- viewport of the head unit (800x354 pixels)
- viewport of the apps view (800x354 points)
- pixel per inch (117 ppi)
- *points per inch (117 ppi)*

Example 2: 10” screen (1280x768 pixels)
- scale (1.25x)
- viewport of the head unit (1280x569 pixels)
- viewport of the apps view (1024x455 points)
- pixels per inch (149 ppi)
- *points per inch (119 ppi)*

Example 3: 8” screen (1280x768 pixels)
- scale (1.5x)
- viewport of the head unit (1280x569 pixels)
- viewport of the apps view (853x379 points)
- pixels per inch (186 ppi)
- *points per inch (124 ppi)*

Another example: Size of a button (50x50 points) on the screens with and without scale:

| screen    | without scale | with scale   |
| --------- | ------------: | -----------: |
| Example 1 |  0.42735 inch | 0.42735 inch |
| Example 2 |   0.3356 inch |  0.4202 inch |
| Example 3 |   0.2688 inch |  0.4032 inch |

The examples show how different the actual button size would be without scale. 

Recommendations for deciding on a scale value: Whenever possible the scale value should result to 120 points per inch and should be an absolute number to avoid issues with blurry pixel mesh when scaling (2x = 1 point are 2 pixels). That would be too restrictive to OEMs and unrealistic as a requirement for all screens. Therefore also half (1.5x  = 2 points are 3 pixels) or at minimum quarter values should be considered (1.25x = 4 points are 5 pixels). A bad scale would be 1.3x (10 points are 13 pixels) as it would cause a blurry scale therefore should not be used.

The font sizes would also benefit from scale as they are set to height of x/72 inch (see [Point (typography) - Wikipedia](https://en.wikipedia.org/wiki/Point_(typography) and [Convert points to inches](https://www.labelvalue.com/blog/custom-label-information/font-size-guide-convert-points-to-inches.html)). Once the pixel density and scale is known the backgrounding string’s font size can be set in real inches not in pixels. 


### Mobile & HMI API changes

Change the VideoStreamingCapability struct in both API's to include the additional parameters: 
```xml
<struct name="VideoStreamingCapability">
: 
<param name="diagonalScreenSize" type="Float" mandatory="false">
 <description>The diagonal screen size in inches.</description>
</param>
<param name="pixelPerInch" type="Float" mandatory="false">
 <description>PPI is the diagonal resolution in pixels divided by the diagonal screen size in inches.</description>
</param>
<param name="scale" type="Float" mandatory="false">
  <description>The scaling factor the app should use to change the size of the projecting view.</description>
</param>
</struct>
```

### iOS changes

The media streaming manager should still use the screen params for the video stream size. Changes are necessary to `SDLCarWindow`. The view controller's view size should be set to the accepted video resolution (see [Video: StartService ACK](https://github.com/smartdevicelink/protocol_spec#31342-start-service-ack)) divided by the scale. 

```objc
- (void)sdl_didReceiveVideoStreamStarted:(NSNotification *)notification {
    self.videoStreamStarted = true;

    dispatch_async(dispatch_get_main_queue(), ^{
        CGFloat scale = self.sdlManager.videoStreamCapability.scale; // pseudo code
        self.rootViewController.view.frame = CGRectMake(0, 0, self.streamManager.screenSize.width / scale, self.streamManager.screenSize.height / scale);
		...
```

When capturing the screen, the image context should be set to the video resolution

```objc
- (void)syncFrame {
...
    CGRect bounds = CGRectMake(0, 0, self.streamManager.screenSize.width, self.streamManager.screenSize.height);
...
}
```

This will create an image context with the size of the video stream.

### Android changes

When the remote display is started, the VideoStreamingManager should continue to receive its VideoStreamingParameters via the onCapabilityRetrieved method.  Changes are necessary to the update method of the VideoStreamingParameters class to calculate the best ImageResolution based on the values returned in the VideoStreamingCapability struct divided by the scale.  A sample update method implementation is shown below for illustration purposes.

```java
public void startRemoteDisplayStream(Context context, final Class<? extends SdlRemoteDisplay> remoteDisplay, final VideoStreamingParameters parameters, final boolean encrypted){
   if(getWiProVersion() >= 5 && !_systemCapabilityManager.isCapabilitySupported(SystemCapabilityType.VIDEO_STREAMING)){
      Log.e(TAG, "Video streaming not supported on this module");
      return;
   }
   //Create streaming manager
   if(manager == null){
      manager = new VideoStreamingManager(context,this._internalInterface);
   }

   if(parameters == null){
      if(getWiProVersion() >= 5) {
         _systemCapabilityManager.getCapability(SystemCapabilityType.VIDEO_STREAMING, new OnSystemCapabilityListener() {
            @Override
            public void onCapabilityRetrieved(Object capability) {
               VideoStreamingParameters params = new VideoStreamingParameters();
               params.update((VideoStreamingCapability)capability);   //Streaming parameters are ready time to stream
               sdlSession.setDesiredVideoParams(params);
               manager.startVideoStreaming(remoteDisplay, params, encrypted);
            }
	    ...
```
```java
public void update(VideoStreamingCapability capability){
    if(capability.getMaxBitrate()!=null){ this.bitrate = capability.getMaxBitrate(); }
    ImageResolution resolution = capability.getPreferredResolution();
    if(resolution!=null){
        if(resolution.getResolutionHeight()!=null && resolution.getResolutionHeight() > 0){ this.resolution.setResolutionHeight(resolution.getResolutionHeight()/scale); }
        if(resolution.getResolutionWidth()!=null && resolution.getResolutionWidth() > 0){ this.resolution.setResolutionWidth(resolution.getResolutionWidth()/scale); }
    }
    List<VideoStreamingFormat> formats = capability.getSupportedFormats();
    if(formats != null && formats.size()>0){
        this.format = formats.get(0);
    }
}

```

### Changes to touch events & haptic hit

Changing the size of the underlying view will break the correlation between touch coordinates and touchable view items. In order to fix this issue the touch managers of Android and iOS need to calculate the correct coordinates by dividing the incoming coords with the scale.

## Potential downsides

It is considered and accepted that up/down scaling can reduce quality. [Android](https://developer.android.com/training/multiscreen/screendensities) and 
[iOS](https://developer.apple.com/library/content/documentation/DeviceInformation/Reference/iOSDeviceCompatibility/Displays/Displays.html) are working in a similar way to solve the issue. 
First this issue only affects images which don't exist in the desired scale. Second it's expected that majority of the used phones work with higher resolutions compared to the head unit, therefore the apps would always down-scale which is much less problematic than up-scale.

## Impact on existing code

The proposed changes are no breaking changes and would only cause a minor version bump. 

The [protocol spec](https://github.com/smartdevicelink/protocol_spec#3134-video-service) for video was reviewed to identify if it's affected. The proposed parameters are all static and unmodifiable. Therefore the protocol layer is not affected.

## Alternatives considered

Alternatively modify `ScreenParams` struct used by `RegisterAppInterfaceResponse.displayCapabilities`

```xml
<struct name="ScreenParams">
:
<param name="diagonalScreenSize" type="Float" mandatory="false">
 <description>The diagonal screen size in inches.</description>
</param>
<param name="pixelPerInch" type="Float" mandatory="false">
 <description>PPI is the diagonal resolution in pixels divided by the diagonal screen size in inches.</description>
</param>
<param name="scale" type="Float" minvalue="1" maxvalue="10" mandatory="false">
  <description>The scaling factor the app should use to change the size of the projecting view.</description>
</param>
</struct>
```
