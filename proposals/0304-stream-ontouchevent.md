# Start Video Stream With OnTouchEvent Permission

* Proposal: [SDL-0304](0304-stream-ontouchevent.md)
* Author: [Kujtim Shala](https://github.com/kshala-ford)
* Status: **Deferred**
* Impacted Platforms: [ iOS ]

## Introduction

This proposal is changing the behavior for how the streaming video manager should include `OnTouchEvent` permission in the starting conditions.

## Motivation

SDL navigation applications stream the UI as a video to the vehicle head unit. In this case it's quite obvious that touch events are key for such applications to operate. However, for nav apps that connect to a head unit for the first time, the app ID is unknown and therefore it's not clear if the app is allowed to video stream or to receive touch events. Starting the video stream only upon `HMI_FULL` can lead to Core to replying with `NAK` on the start service request.

## Proposed solution

The library should wait to send the start service request until all conditions are met. The solution is to check the existence of `OnTouchEvent` in the latest `OnPermissionsChange` notification.

Below code shows an example implementation in the class `SDLStreamingVideoLifecycleManager`. 

First of all the manager should be able to store the last known permission status of OnTouchEvent in case the permissions were provided before other conditions were met (e.g. permission update during HMI_NONE).

```objc
@property (assign, nonatomic) BOOL videoStreamPermissionGranted;
```

During initialization of the manager, it should add an observer to permission changes. On every change the permission change should be read to identify if OnTouchEvent is granted for HMI_FULL. In this case the permission condition is met and the manager should try to start the video service session.

```objc
- (void)sdl_permissionsChange:(SDLRPCNotificationNotification *)notification {
    SDLOnPermissionsChange *permissions = notification.notification;
    NSArray<SDLPermissionItem *> *items = permissions.permissionItem;

    BOOL touchPermissionGranted = NO;

    for (SDLPermissionItem *item in items) {
        if ([item.rpcName isEqualToString:@"OnTouchEvent"]) {
            if ([item.hmiPermissions.allowed containsObject:SDLHMILevelFull]) {
                touchPermissionGranted = YES;
                break;
            }
        }
    }

    self.videoStreamPermissionGranted = touchPermissionGranted;

    if (self.isHmiStateVideoStreamCapable && self.videoStreamPermissionGranted) {
        [self sdl_startVideoSession];
    } else {
        [self sdl_stopVideoSession];
    }
}
```

With the newly added flag, every other place that starts or stops the video session should be altered as well, including the following:

```objc
- (void)startWithProtocol:(SDLProtocol *)protocol {
     // attempt to start streaming since we may already have necessary conditions met
-    [self sdl_startVideoSession];
+    if (self.isHmiStateVideoStreamCapable && self.videoStreamPermissionGranted) {
+        [self sdl_startVideoSession];
+    } else {
+        [self sdl_stopVideoSession];
+    }
}

- (void)sdl_hmiStatusDidChange:(SDLRPCNotificationNotification *)notification {
    ...
-    if (self.isHmiStateVideoStreamCapable) {
+    if (self.isHmiStateVideoStreamCapable && self.videoStreamPermissionGranted) {
         [self sdl_startVideoSession];
     } else {
         [self sdl_stopVideoSession];
     }
}
```

Note: The example code should not be considered as the only option to implement this proposal. Other solutions that serve the same feature should also be accepted during implementation.  

## Potential downsides

Potentially this code can have an impact on existing head units that would allow navigation apps to start the video stream without touch permissions. Those applications require OnTouchEvent anyway to operate, so they shouldn't see any impact. Navigation applications' startup time could be delayed, however, as head units may return `NAK` in case of an early start service request this proposal should rather be seen as a stability improvement.

## Impact on existing code

Only the video streaming manager is in focus. Ideas to allow navigation applications without streaming shouldn't be affected as they wouldn't start the streaming managers.

## Alternatives considered

The video streamable status notification should provide very similar functionality, however it's not available on all nav app-capable head units and therefore an alternative was considered listening for touch events. Also listening for the video streamable status could be a valid addition to the proposed solution.
