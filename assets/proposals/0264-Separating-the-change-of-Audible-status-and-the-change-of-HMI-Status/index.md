## OnEventChanged

##### PHONE_CALL

!!! MUST
1. Change audioStreamingState to NOT_AUDIBLE for all apps (keep hmiLevel) when active call on HMI has been started.

2. Send notification with appropriate parameter value when the event ends.
!!!

!!! NOTE
- SDL does not send BC.ActivateApp or BC.OnResumeAudioSource to HMI after the phone call is ended.

- If HU wants to switch the screen (HMIStatus) during PHONE_CALL, they can use API `BC.OnAppDeactivated (AppID)` and `BC.OnAppActivated (AppID)`.
!!!

Upon receiving `OnEventChanged(PHONE_CALL)`, SDL will:

|isActive|Result|
|:-------|:-----|
|true|Keep the HMI state of all applications but change audible state of all applications to NOT_AUDIBLE|
|false|Return applications to the same HMI state they had prior to the event|
