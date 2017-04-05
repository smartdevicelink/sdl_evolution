# Gesture cancellation on video streaming

* Proposal: [SDL-NNNN](NNNN-filename.md)
* Author: Masato Ogawa
* Status: **Awaiting review**
* Impacted Platforms: [Core / iOS / Android / RPC]

## Introduction

This proposal defines a gesture cancellation event to prevent false gesture recognition during an interrupted video stream.

## Motivation

During operation with an SDL application supporting video streaming, a native dialog such as incoming-call may interrupt. If touch events before and after a screen interruption are evaluated as one gesture, an unexpected gesture may be detected.

## Proposed solution

HMI notifies gesture cancellation by OnTouchEvent method of UI component.

## Detailed design

### Additions to Mobile_API

```
 <enum name="TouchType">
   <element name="BEGIN"/>
   <element name="MOVE"/>
   <element name="END"/>
+  <element name="CANCEL"/>
 </enum>
```

### Additions to HMI_API

```
 <enum name="TouchType">
   <element name="BEGIN"/>
   <element name="MOVE"/>
   <element name="END"/>
+  <element name="CANCEL"/>
 </enum>
```

HMI notifies with JSON as below. It passes through Core and is passed to Application. In the case of multi-touch, it is necessary to notify each ID.

```
{
  "jsonrpc" : "2.0",
  "method" : "UI.OnTouchEvent",
  "params" :
  {
    "type" : "CANCEL",
    "event" : [
                {
                  "id":0,
                  "ts":[49013],
                  "c":[{"x":323,"y":259}],
                }
              ]
  }
}
```

## Potential downsides

1) Can it be implemented with currently defined values?

Yes, we can treat TouchType::BEGIN during TouchType::MOVE as a cancellation. However, to avoid misunderstanding, it's good to define a single event rather than defining a sequence. And general mobile OS has an event like this.

## Impact on existing code

This change is only adding TouchType's enum value. It does not stop compilation and does not change the current behavior.

## Alternatives considered

If TouchType::BEGIN is received during TouchType::MOVE, the application cancels gesture recognition.

