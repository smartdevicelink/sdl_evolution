# Haptic Projection

* Proposal: [SDL-NNNN](NNNN-haptic-projection.md)
* Author: [Drew Dobson](https://github.com/drewd)
* Status: **Awaiting review**
* Impacted Platforms: [Android]

## Introduction

The SendHapticData RPC allows video projection apps to inform SDL Core where their controls are 
located. This will allow projection apps to either automatically or manually set their projection
 view's haptic information.
 
## Motivation

App developers must manually call the SendHapticData RPC. The automatic haptic data calculation 
will insure more apps will support haptic touches. Manual haptic data allows OpenGL projection to
 set their data properly.
 
## Proposed solution

Enhance the `VirtualDisplayEncoder.SdlPresentation` class to traverse it's view hierarchy looking
 if each view `View#isFocusable()`.

Examples of required changes:

```java
class RPCRequestFactory {
    public static SendHapticData buildSendHapticData(List<HapticRect> hapticRectData, 
            Integer correlationID) {
        SendHapticData msg = new SendHapticData();
        msg.setCorrelationID(correlationID);
        msg.setHapticRectData(hapticRectData);
        return msg;
    }
}
```
```java
class SdlProxyBase {
    	public void sendHapticData(List<HapticRect> hapticRectData) throws SdlException {
    	    final SendHapticData msg = RPCRequestFactory.buildSendHapticData(hapticRectData, 200);
    	    sendRPCRequest(msg);
    	}
}
```
```java
class VirtualDisplayEncoder {
    class SdlPresentation extends Presentation {
        
        private List<HapticRect> userSpecifiedHaptics;
        
        @Override
        protected void onCreate(Bundle savedInstanceState) {
            ...
            setOnShowListener(new OnShowListener() {
               @Override
               public void onShow(DialogInterface dialog) {
                   // If the developer manually sets the haptics, do not automatically calculate
                   if (userSpecifiedHaptics != null)
                       refreshHapticData();
               } 
            });
        }
        
        /**
         * Automatically figure out the HapticRects for this Presentation
         */
        public final void refreshHapticData() {
            List<HapticRect> list = new ArrayList<>();
            findHapticRects(w.getDecorView(), list);
            try {
                proxy.sendHapticData(list);
            } catch (SdlException e) {
                e.printStackTrace();
            }
        }
        
        /**
         * Walks the view hierarchy to find focusable views 
         */
        private static void findHapticRects(View view, final List<HapticRect> list) {
            if (view.isFocusable()) {
                // Create HapticRect and add it to the list
            }
            if (view instanceof ViewGroup) {
                // Recursively check children 
            }
        }
        
        /**
         * The developer can manually call this to override the default view traversal
         */
        public final void setHapticData(List<HapticRect> hapticData) {
            userSpecifiedHaptics = hapticData;
            try {
                proxy.sendHapticData(hapticData);
            } catch (SdlException e) {
                e.printStackTrace();
            }
        }
    }
} 
```
## Potential downsides

1. This does not monitor changes in the view hierarchy (i.e. adding/removing a view, visibility 
changes nor enable/disable). Any runtime changes will need to be manually calculated by the 
developer or `SdlPresentation#refreshHapticData()` will need to be invoked again.
2. This does not take into consideration layout overrides described [here](https://developer
.android.com/reference/android/view/View.html#FocusHandling).
3. How do apps with focusable ViewGroups handle having focusable views inside them?

## Impact on existing code

- New code added to existing class will enhance them and not break backwards compatibility.
- `SdlPresentation` will need save the `SdlProxyALM` instance passed to 
`VirtualDisplayEncoder#init(Context, SDlProxyALM, Class)`

## Alternatives considered

1. Let Android's native focus handling do all of this work for us by sending the "arrow" keys 
from SDLCore to the Android device and injecting the proper d-pad key presses into the view's 
hierarchy. This would be similar to OnTouchEvent already implemented.

