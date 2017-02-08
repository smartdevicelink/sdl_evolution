# Stream File Manager Uploads from Disk

* Proposal: [SDL-NNNN](NNNN-filename.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Awaiting review**
* Impacted Platforms: iOS

## Introduction
This proposal is to make a minor API addition to the SDL iOS library to make possible streaming a file from disk in order to reduce memory usage when uploading a large file to the remote system.

## Motivation
In SDL v5.0, the `SDLProxy` class is likely to be removed, and with it, the only method for streaming a file from disk without pulling the whole file into memory. We should build a method for only pulling required data from an `SDLFile`. Currently we can only pull all of the data at once.

## Proposed solution
The proposed solution is to add a new method onto `SDLFile`: `SDLFile dataAtOffset:length:`. This would only pull the required data from the file on disk or in memory using `NSFileHandle`.

There would be additional changes made to `SDLUploadFileOperation` to handle pulling a specific range of data rather than the whole range, but no public API changes. `SDLUploadFileOperation` will call `SDLFile dataAtOffset:length:`, create a PutFile using that data, and send it. It will wrap this process in `@autoreleasepool` so that the PutFiles can be released as soon as possible. This should free up data when sending a large file.

## Impact on existing code
This will be a minor API change to the iOS library. There will be no additional impact.

## Alternatives considered
An alternative would be to more directly copy the `putFileStream:withRequest` method from `SDLProxy`, however, it really doesn't fit with the rest of the File Manager API.
