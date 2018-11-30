# Update Image Data

* Proposal: [SDL-NNNN](nnnn-update-image-data.md)
* Author: [Nicole Yarroch](https://github.com/NicoleYarroch)
* Status: **Awaiting review**
* Impacted Platforms: [Core]

## Introduction

Currently when a developer tries to reuse the same file name for a `PutFile` sending image data, the new image is not shown on the HMI. This is due to Core only sending a notification to the HMI when the `PutFile` is a system file. This proposal is to have Core send a notification to the HMI when it receives any type of `PutFile`.    

## Motivation

Reusing a file name for a `PutFile` is useful for developers because they do not have to come up with unique names for dynamically updated images and it saves them an extra step of having to deleting old image data as the new data overwrites the old data.

## Proposed solution

When Core receives a `PutFile` it should send a notification to the HMI that a new `PutFile` was received. Currently an `OnPutFile` notification is only sent when the `PutFile` is a `systemFile`.

```
<function name="OnPutFile" messagetype="notification" >
<description>
Notification sent to HMI when mobile sends file 
</description>
```

## Potential downsides

No potential downsides.

## Impact on existing code

This is a minor version change.

## Alternatives considered

No alternatives considered.

