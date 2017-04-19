# Enhance Video Streaming API's for Android

* Proposal:  [SDL-0051](0051-enhance_video_streaming_apis_for_android.md)
* Authors: [Austin Kirk](https://github.com/askirk), [Joey Grover](https://github.com/joeygrover)
* Status: **Accepted**
* Impacted Platforms: Android

## Introduction
This proposal is to add APIs to the current SDL Android library that provide an enhanced ability for developers to stream video through SDL's video streaming capabilities. The new APIs will leverage native OS classes that developers will understand. 

## Motivation
As it currently stands, the video streaming capabilities in the SDL Android library can provide developers with an `OpenGLSurface` or an `OutputStream` to stream video to. Actually taking advantage of these components to stream video often requires significant overhead code that either (a) renders an OpenGL surface or (b) creates a raw H264 video stream. If a developer simply wants to stream an image, Surface, or other display element to the head unit, the current APIs in SDL Android aren't very clear on how to do so.

## Proposed solution
The proposed solution is to add API calls in the SDL Android library that allow developers to:

* Stream their own custom [Presentation](https://developer.android.com/reference/android/app/Presentation.html) class to the head unit
* Respond to touch events on the `Presentation` being streamed on the head unit

## Detailed solution

This solution revolves around adding the following classes to the SDL Android library:

##### SdlPresentation

```
public static class SdlPresentation extends Presentation{}
```
This is a class that developers would extend to display their own layout, set `onClickListeners`, etc. This class can refresh its `View` that is written to the display on the order of milliseconds. The refresh rate could be customizable. An example of how a developer could construct their own class is:

```
public static class MyPresentation extends VirtualDisplayEncoder.SdlPresentation{

        public MyPresentation(Context context, Display display) {
            super(context, display);
        }

        @Override
        protected void onCreate(Bundle savedInstanceState) {
            super.onCreate(savedInstanceState);

            setContentView(R.layout.stream);

            Button black_button = (Button) findViewById(R.id.black_button);

            black_button.setOnClickListener(customOnClickListener);

            Button red_button = (Button) findViewById(R.id.red_button);

            red_button.setOnClickListener(customOnClickListener);
        }

        View.OnClickListener customOnClickListener = new View.OnClickListener() {

            @Override
            public void onClick(View v) {

                int id = v.getId();
                ImageView imageView = (ImageView) mainView.findViewById(R.id.mainImage);

                if(id == R.id.black_button){
                    Log.d(TAG, "Black!");
                    imageView.setImageResource(R.drawable.blackchip);
                }else if(id == R.id.red_button) {
                    Log.d(TAG, "Red!");
                    imageView.setImageResource(R.drawable.redchip);
                }
            }
        };
}
```

##### VirtualDisplayEncoder

This class would allow developers to provide a custom `SdlPresentation` to stream to a head unit, and relay the touch events on the head unit back to it. A developer would be able to initialize and begin streaming video to the head unit as follows:

```
VirtualDisplayEncoder vdEncoder = new VirtualDisplayEncoder();
vdEncoder.initialize(..., MyPresentationClass);
vdEncoder.start();
```

Touch events gathered in an Sdl Service can be relayed to the `VirtualDisplayEncoder` like so:

```
public void onOnTouchEvent(OnTouchEvent notification){
	vdEncoder.handleTouchEvent(notification);
}
```

Finally, developers can shut down the `VirtualDisplayEncoder` and stop streaming to the head unit using a method like `vdEncoder.shutDown();`

## Potential downsides
This would certainly provide more streaming resources for developers than what exists today, but using the `Presentation` approach may not suit every developers needs. 

The `VirtualDisplayEncoder` class requires an API level of at least 21 to use, which some Android phones may not be updated to. Secondly, this proposal requires the compile version of the SDL Android library to be changed to at least 21. The minimum SDK version and target SDK version of the project would not need to change.

## Impact on existing code
Most of this proposal involves the addition of an entirely new class and methods, not directly affecting existing code. That being said, we need to ensure that it doesn't inappropriately alter any of the data structures the developers provide or cause an SDL enabled app or Service to crash. 

## Alternatives considered
A [sample SDL streaming app](https://github.com/livio/sdl_video_streaming_android_sample/tree/7cc01900a8c704f0924ceb2905be6609b54f4583) that streamed an .mp4 video to a head unit was created in Feb 2017. It involved using a lengthy, non-intuitive approach adapted from [CameraToMpegTest.java](http://bigflake.com/mediacodec/CameraToMpegTest.java.txt). In conclusion, it was less practical for developers to use.
