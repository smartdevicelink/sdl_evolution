# Start Video Stream With OnTouchEvent Permission

* Proposal: [SDL-0304](0304-stream-ontouchevent.md)
* Author: [Kujtim Shala](https://github.com/kshala-ford)
* Status: **Returned for Revisions**
* Impacted Platforms: [ iOS / Java ]

## Introduction

This proposal is changing the behavior for how the streaming video manager should include `OnTouchEvent` permission in the starting conditions for head units that run SDL prior to https://github.com/smartdevicelink/sdl_evolution/issues/1140.

## Motivation

SDL navigation applications stream the UI as a video to the vehicle head unit. Head units with Video Service set to protected will require a certificate for encryption. However, for apps that connect for the first time, the app ID is unknown and the head unit may not have a certificate for that app for encryption.

The head unit will request the policy backend for policy data of the unknown ID and the response may contain information to permitted RPCs such as the permission to receive `OnTouchEvent` and a certificate for encrypting the Video Service. Until the response is received, the app should not attempt to start a Video Service session. If the HMI state is the only condition, the head unit will not acknowledge starting a Video Service sessions without a certificate.

At this time, all navigation applications require touch input from the IVI touch screen. `OnTouchEvent` permission is not granted by default but is given to all navigation applications.

The `OnTouchEvent` permission is granted to every navigation application and the permission update happens at the same time with the injection of the required certificate. Therefore, the app can expect the head unit to be ready for encryption.

## Proposed solution

Holding the app back from starting the Video Service session should only happen to existing head units prior to systems with the same SDL API that implements `encryptionReady` and only if the app has a matching security manager for the connected head unit. Otherwise this proposal should not apply.

The library should wait to send the start service request until all conditions are met. The solution is to check the existence of `OnTouchEvent` in the latest `OnPermissionsChange` notification by leveraging the PermissionManager's APIs. The existence of `OnTouchEvent` should be stored in a member variable within the Streaming Manager. The value of this member variable should be an additional condition to start the Video Service.

This way, at every event that changes one of the conditions, the Streaming Manager will start the Video Service session if all conditions are met including the existence of `OnTouchEvent` permission.


### Android

```java
// check if the permission for OnTouchEvent is already set
boolean allowed = sdlManager.getPermissionManager().isRPCAllowed(FunctionID.ON_TOUCH_EVENT);

if (!allowed) {
    List<PermissionElement> permissionElements = new ArrayList<>();
    permissionElements.add(new PermissionElement(FunctionID.ON_TOUCH_EVENT, null));
    UUID listenerId = sdlManager.getPermissionManager().addListener(permissionElements, PermissionManager.PERMISSION_GROUP_TYPE_ANY, new OnPermissionChangeListener() {
    @Override
    public void onPermissionsChange(@NonNull Map<FunctionID, PermissionStatus> updatedPermissionStatuses, @NonNull int updatedGroupStatus) {
        if (updatedPermissionStatuses.get(FunctionID.ON_TOUCH_EVENT).getIsRPCAllowed()) {
            // GetVehicleData RPC is allowed
            allowed = true;
            example_call_to_attempt_to_start_the_video_service();
        }
    }
});
}
```

### iOS

```objc
// check if the permission for OnTouchEvent is already set
BOOL isAllowed = [self.sdlManager.permissionManager isRPCNameAllowed:SDLRPCFunctionNameOnTouchEvent];

SDLPermissionElement *permissionElement = [[SDLPermissionElement alloc] initWithRPCName:SDLRPCFunctionNameOnTouchEvent parameterPermissions:nil];
SDLPermissionObserverIdentifier subscriptionId = [self.sdlManager.permissionManager subscribeToRPCPermissions:@[permissionElement] groupType:SDLPermissionGroupTypeAny withHandler:^(NSDictionary<SDLRPCFunctionName, SDLRPCPermissionStatus *> *_Nonnull updatedPermissionStatuses, SDLPermissionGroupStatus updatedGroupStatus) {
    if (updatedPermissionStatuses[SDLRPCFunctionNameGetVehicleData].isRPCAllowed) {
        // GetVehicleData RPC is allowed
        isAllowed = YES;
        example_call_to_attempt_to_start_the_video_service();
    }
}];
```

## Potential downsides

This change should not have an impact to head units without encryption due to the condition that a security manager must exist for the connected head unit. Other head units without touch capability will not be affected either. The only scenario where this change would have a negative impact is to navigation apps that purely work without touch permissions. Those would not need `OnTouchEvent` to be in the policy set. In order to run on the affected head units (which are existing head units that require encryption and have a security manager), the app would need `OnTouchEvent` anyways.

Navigation applications' startup time should not be delayed because the app will not be able to start the video stream anyways before the head unit has received the certificate. 

## Impact on existing code

Only the video streaming manager is in focus. Ideas to allow navigation applications without streaming shouldn't be affected as they wouldn't start the streaming managers.

## Alternatives considered

 Other proposals addressed this issue for future head units but would require a software update. This proposal targets a very specific group of existing head units that are affected by the described issue. No other alternatives are considered for these affected head units.
