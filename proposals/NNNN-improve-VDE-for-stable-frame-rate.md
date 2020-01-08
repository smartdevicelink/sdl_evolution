# Improve VirtualDisplayEncoder for stable frame rate

* Proposal: [SDL-NNNN](NNNN-improve-VDE-for-stable-frame-rate.md)
* Author: [Shinichi Watanabe](https://github.com/shiniwat)
* Status: **Awaiting review**
* Impacted Platforms: [Java Suite]

## Introduction

This proposal improve the quality of video projection when using Android `VirtualDisplay` and `MediaEncoder`, as Android `MediaEncoder` does not produce consistent frame rate for rendering `VirtualDisplay's` surface.

## Motivation

A part of sdl_java_suite library utilizes `VirtualDisplay` and `MediaEncoder` to produce the video projection stream.
Actually, frame rate of video stream depends on how often `MediaCodec.Callback` gets called.
The component structure is illustrated as follows:

![virtualdisplay_unstable_rate](../assets/proposals/NNNN-improve-VDE-for-stable-frame-rate/vd_mc_unstable.png)

**Fig. 1: VirtualDisplay's surface produces unstable frame rate**

For instance, 
- if an app's content in `VirtualDisplay` is updated quite often, the `MediaEncoder` associated with `VirtualDisplay's` surface produces 60 frames per second.
- if an app's content in `VirtualDisplay` is not updated very frequently, its surface produces rather few frames (e.g. 20 frames) per second.

Most HUs would be designed for consistent video frame rate, so it may cause some negative effect if video frame rate goes up and down.

This proposal addresses this Android specific issue as it tightly related with how Android `VirtualDisplay` works.

## Proposed solution

Because the issue comes from the fact where `VirtualDisplay's` surface emits output buffer in variable rate, the idea is:

- Give the intermediate surface to `VirtualDisplay`.
- When `VirtualDisplay` sends frames, the intermediate surface can determine whether or not to forward them into `MediaCodec's` input surface.

The approach is introduced at http://stackoverflow.com/questions/31527134/controlling-frame-rate-of-virtualdisplay, i.e.

- Create a `SurfaceTexture`, construct a Surface from it, and give it to `VirtualDisplay`.
- When `SurfaceTexture` fires `onFrameAvailable` callback, we can buffer the frame, and render the texture onto `MediaCodec's` input surface by using GLES.

The idea is illustrated as follows:
  
![virtualdisplay_w_intermediate_surface](../assets/proposals/NNNN-improve-VDE-for-stable-frame-rate/vd_w_intermediate_surface.png)

**Fig. 2: VirtualDisplay with intermediate Surface**

### Detailed design

1. Setup intermediate surface and surface texture.
We need to add following components, which includes some of [Grafika](https://github.com/google/grafika), into `VirtualDisplayEncoder` class.

- `EglCore` (com.android.grafika.gles.EglCore)
- `OffscreenSurface` (com.android.grafika.gles.OffscreenSurface)
- `TextureId`, which can be created by `FullFrameRect.createTextureObject()`
- `SurfaceTexture` with above `TextureId`
- Surface with above `SurfaceTexture` (let's call this to IntermediateSurface)
- `WindowSurface` (com.android.grafika.gles.WindowSurface)

2. create `VirtualDisplay` with IntermediateSurface
Instead of inputSurface, we use IntermediateSurface for `VirtualDisplay`, so that we can control update timing of the IntermediateSurface.

3. create capture thread
In capture thread, we periodically update surface texture, so that we can capture the surface in constant rate.

The pseudo code of CaptureThread looks as follows:

```java
 import android.os.Looper;private final class CaptureThread extends Thread implements SurfaceTexture.OnFrameAvailableListener {
    long frameInterval; // this is given as the paramter
    static final int MSG_TICK = 1;
    static final int MSG_UPDATE_SURFACE = 2;

    private Handler handler;
    private SurfaceTexture surfaceTexture;
    private int textureId;
    private WindowSurface windowSurface;
    private FullFrameRect fullFrameRect;
    private long frameIntervalInNano = 1000000000 / fps; // fps should be specified by HU.
    private long nextTime;
    private final float[] matrix = new float[16];

    ...
    public void run() {
        Looper.prepare();
        // we use a Handler for this thread
        handler = new Handler() {
                public void handleMessage(Message msg) {
                    switch(msg.what) {
                        case MSG_TICK:
                            // we can draw the image in Surface Texture here, something like
                            long now = System.nanoTime();
                            if (now > nextTime) {
                                try {
                                    windowSurface.makeCurrent();
                                    GLES20.glViewport(0, 0, width, height);
                                    fullFrameRect.drawFrame(textureId, matrix);
                                } catch(RuntimeException e) {
                                    ...
                                }
                                nextTime += frameIntervalInNano;
                            }
                            long delayTime = // adjust delaytime..
                            handler.sendMessageDelayed(handler.obtainMessage(MSG_TICK), delayTime);
                            break;
                        case MSG_UPDATE_SURFACE:
                            // update the surface here.
                            updateSurface();
                    }
                }
         }
    }

    private void updateSurface() {
        try {
            windowSurface.makeCurrent()
        } catch(RuntimeException e) {
            ...
        }
        surfacetexture.updateTexImage();
        surfaceTexture.getTransformMatrix(matrix);
    }

    /**
    * this is where we update the surface
    * @param surfaceTexture
    */
    public void onFrameAvailable(SurfaceTexture surfaceTexture) {
        // here, we can do update surfaceTexture
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            updateSurface();
        } else {
            // note that API level is lower than 21 (LOLLIPOP), setOnFrameAvailableListener(listener) is used,
            // and most likely, OnFrameAvailableListener gets called in main thread.
            // In that case, we have to call updateSurface in CaptureThread instead.
            handler.sendMessage(handler.obtainMessafge(MSG_UPDATE_SURFACE));
        }

        // when the first time this gets called, start the loop
        // by mHandler.sendMessage()
        if (nextTime == 0) {
            nextTime = System.nanoTime();
            handler.sendMessage(handler.obtainMessage(MSG_TICK));
        }
    }
 }
```

## Potential downsides

No downside, as it will be implemented in Proxy, and there should be no performance overhead.
One thing to note is that this proposal includes the usage of `Grafika` component, which is under [Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0).

sdl_java_suite already uses some component under Apache License 2.0 (e.g. `JSON`), so adding another open source component won't cause any issues.

## Impact on existing code

Because this approach does not change existing API, and changes are inside of `VirtualDisplayEncoder` class, there's no impact to developers who use `VirtualDisplayEncoder`.

## Alternatives considered

This is pure improvement for existing `VistualDisplayEncoder`. So there're no alternatives, but this proposal adds the ability to specify the desired FPS on Proxy end.
This proposal should be combined with "Add preferred FPS to VideoStreamingCapability" proposal, so that we can respect for preferred FPS value, which is specified by HU.
