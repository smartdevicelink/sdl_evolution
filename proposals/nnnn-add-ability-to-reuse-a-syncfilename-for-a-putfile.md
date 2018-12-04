# Add Ability to Reuse a SyncFileName for a PutFile

* Proposal: [SDL-NNNN](nnnn-add-ability-to-reuse-a-syncfilename-for-a-putfile.md)
* Author: [Nicole Yarroch](https://github.com/NicoleYarroch)
* Status: **Awaiting review**
* Impacted Platforms: [Core]

## Introduction

Currently, when a developer tries to reuse the same `syncFileName` for a `PutFile` with image data the HMI is not updated to show the new image. This is due to Core only sending a notification to the HMI when the `PutFile` is a system file. To remedy this issue, Core needs to send a notification to the HMI when it receives any type of `PutFile`.    

## Motivation

Reusing a `syncFileName` for a `PutFile` is useful for developers because they do not have to come up with unique names for dynamically updated images, and it saves them the extra step of having to deleting the old data as the new data overwrites the old.

## Proposed solution

When Core receives a `PutFile` it should send a notification to the HMI that a new `PutFile` was received. Currently an `OnPutFile` notification is only sent when the `PutFile` is a `systemFile`. Two new parameters will be added to the `OnPutFile` notification: `isSystemFile`, which will preserve the current task Core performs for system files, and `appID` which will be used to update the correct app's UI.

```
<function name="OnPutFile" messagetype="notification">
    <description>
    Notification sent to HMI when mobile sends file
    </description>

    ...
    
    /* New parameters */
    <param name="isSystemFile" type="Boolean" defvalue="false" mandatory="false">
        <description>
        Indicates if the file is meant to be passed thru core to elsewhere on the system. If true the system will pass the data thru as it arrives to a predetermined area outside of core.
        </description>
    </param>

    <param name="appID" type="Integer" mandatory="false">
        <description>
        Unique (during ignition cycle) id of the application. To be used in all RPCs sent by both HU system and SDL
        </description>
    </param>
</function>
```

## Potential downsides

No potential downsides.

## Impact on existing code

This is a minor version change.

## Alternatives considered

No alternatives considered.

