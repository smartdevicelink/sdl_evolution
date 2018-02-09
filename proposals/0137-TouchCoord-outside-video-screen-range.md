# TouchCoord outside video screen range

* Proposal: [SDL-0137](0137-TouchCoord-outside-video-screen-range.md)
* Author: [Masato Ogawa](https://github.com/masatoogawa)
* Status: **In Review**
* Impacted Platforms: [Core / RPC]

## Introduction

Updates `TouchCoord` for gesture recognition across the SDL Video screen and the Native screen

## Motivation

We have use cases for keeping gesture recognition from the SDL Video screen to the Native screen. Since the current `TouchCoord` does not support negative values, SDL applications cannot recognize some gestures for upward or leftward direction.

![pic1](../assets/proposals/0137-TouchCoord-outside-video-screen-range/0137-TouchCoord-outside-video-screen-range-pic1.png)

We also have a use case for multi-touch recognition on the Haptic device. The screen cursor position becomes the 1st touch coordinate, and the 2nd touch coordinate becomes the 1st touch relative coordinates. Therefore, depending on the position of the screen cursor, 2nd touch becomes coordinates outside the screen area, the SDL application can not recognize the coordinates of upward and leftward direction.

![pic2](../assets/proposals/0137-TouchCoord-outside-video-screen-range/0137-TouchCoord-outside-video-screen-range-pic2.png)

## Proposed solution

Remove the range limitation of "x" and "y" of `TouchCoord`, so that negative values can be conveyed to apps.

## Detailed design

### Additions to Mobile_API

```
 <struct name="TouchCoord">
-    <param name="x" type="Integer" mandatory="true" minvalue="0" maxvalue="10000">
+    <param name="x" type="Integer" mandatory="true">
         <description>The x coordinate of the touch.</description>
     </param>
-    <param name="y" type="Integer" mandatory="true" minvalue="0" maxvalue="10000">
+    <param name="y" type="Integer" mandatory="true">
         <description>The y coordinate of the touch.</description>
     </param>
 </struct>
```

### Additions to HMI_API

```
 <struct name="TouchCoord">
-  <param name="x" type="Integer" mandatory="true" minvalue="0" maxvalue="10000">
+  <param name="x" type="Integer" mandatory="true">
     <description>The x coordinate of the touch.</description>
   </param>
-  <param name="y" type="Integer" mandatory="true" minvalue="0" maxvalue="10000">
+  <param name="y" type="Integer" mandatory="true">
     <description>The y coordinate of the touch.</description>
   </param>
 </struct>
```

## Potential downsides

Current iOS and Android SDL Proxy do not have implementation of checking minvalue and maxvalue. An old SDL application that receives a value outside the range may cause unexpected behavior.

## Impact on existing code

The impact on Core and Proxy codes should be small.
* Core doesn't have any logic that uses touch coordinates, thus no code change is required. Only the interface files are updated.
* Currently Proxy doesn't have implementation of checking minvalue and maxvalue, therefore no code change is required.

SDL applications might want to add range checking since they will receive negative coordinate values after this change.

## Alternatives considered

1) Add negative values to "x" and "y" of `TouchCoord`.

```
 <struct name="TouchCoord">
-    <param name="x" type="Integer" mandatory="true" minvalue="0" maxvalue="10000">
+    <param name="x" type="Integer" mandatory="true" minvalue="-10000" maxvalue="10000">
         <description>The x coordinate of the touch.</description>
     </param>
-    <param name="y" type="Integer" mandatory="true" minvalue="0" maxvalue="10000">
+    <param name="y" type="Integer" mandatory="true" minvalue="-10000" maxvalue="10000">
         <description>The y coordinate of the touch.</description>
     </param>
 </struct>
```

### Additions to HMI_API

```
 <struct name="TouchCoord">
-  <param name="x" type="Integer" mandatory="true" minvalue="0" maxvalue="10000">
+  <param name="x" type="Integer" mandatory="true" minvalue="-10000" maxvalue="10000">
     <description>The x coordinate of the touch.</description>
   </param>
-  <param name="y" type="Integer" mandatory="true" minvalue="0" maxvalue="10000">
+  <param name="y" type="Integer" mandatory="true" minvalue="-10000" maxvalue="10000">
     <description>The y coordinate of the touch.</description>
   </param>
 </struct>
```

2) Add new parameters such as "offsetx", "offsety" and keep current parameters "x" and "y". This has a compatibility issue since HMI cannot know whether SDL Proxy understands the offset parameters.

