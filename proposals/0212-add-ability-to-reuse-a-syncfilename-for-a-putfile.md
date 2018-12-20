# Add Ability to Reuse a SyncFileName for a PutFile

* Proposal: [SDL-0212](0212-add-ability-to-reuse-a-syncfilename-for-a-putfile.md)
* Author: [Nicole Yarroch](https://github.com/NicoleYarroch)
* Status: **Accepted with Revisions**
* Impacted Platforms: [Core]

## Introduction

Currently, when a developer tries to reuse the same `syncFileName` for a `PutFile` with image data, the HMI is not updated to show the new image. This is due to Core only sending a notification to the HMI when the `PutFile` is a system file. To remedy this issue, Core needs to send a notification to the HMI when it receives any type of `PutFile`.    

## Motivation

Reusing a `syncFileName` for a `PutFile` is useful for developers because they do not have to come up with unique names for dynamically updated images, and it saves them the extra step of having to delete the old data as the new data will overwrite the old.

## Proposed solution

When Core receives a `PutFile` it should send a notification to the HMI that a new `PutFile` was received. Currently an `OnPutFile` notification is only sent when the `PutFile` is a `systemFile`. Two new parameters will be added to the `OnPutFile` notification: `isSystemFile`, which will preserve the current task Core performs for system files, and `appID` which will be used to update the correct app's UI.

```
<function name="OnPutFile" messagetype="notification">
    <description>
    Notification sent to HMI when mobile sends file
    </description>
    
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
    
    /* Existing parameters */
    <param name="offset" type="Integer" minvalue="0" maxvalue="100000000000" mandatory="false">
        <description>
        Optional offset in bytes for resuming partial data chunks
        </description>
    </param>
    
    <param name="length" type="Integer" minvalue="0" maxvalue="100000000000" mandatory="false">
        <description>
        Optional length in bytes for resuming partial data chunks
        </description>
    </param>
    
    <param name="fileSize" type="Integer" minvalue="0" maxvalue="100000000000" mandatory="false">
        <description>
        Full Size of file. sends in first OnPutFile notification if file is splited into many PutFiles
        </description>
    </param>
    
    <param name="FileName" type="String" maxlength="255" mandatory="true">
        <description>
        File reference name
        </description>
    </param>
    
    <param name="syncFileName" type="String" maxlength="255" mandatory="true">
        <description>
        File reference name
        </description>
    </param>
    
    <param name="fileType" type="Common.FileType" mandatory="true">
        <description>
        Selected file type
        </description>
    </param>
    
    <param name="persistentFile" type="Boolean" defvalue="false" mandatory="false">
        <description>
        Indicates if the file is meant to persist between sessions / ignition cycles.
        If set to TRUE, then the system will aim to persist this file through session / cycles.
        While files with this designation will have priority over others, they are subject to deletion by the system at any time.
        In the event of automatic deletion by the system, the app will receive a rejection and have to resend the file.
        If omitted, the value will be set to false.
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

