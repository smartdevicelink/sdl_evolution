# Retry Failed File Uploads

* Proposal: [SDL-NNNN](nnnn-retry-failed-file-uploads.md)
* Author: [NicoleYarroch](https://github.com/NicoleYarroch)
* Status: **Awaiting review**
* Impacted Platforms: [iOS]

## Introduction
This proposal is to implement retry attempts when a file upload fails.

## Motivation
Currently the file manager only attempts to upload a file to Core once. If a developer wants to retry sending a failed upload, it is up to them to implement this feature. This can make it frustrating to handle transport failures. 

## Proposed solution

1. Create a new configuration, `SDLFileManagerConfiguration`, to be added to the `SDLConfiguration` class. The new configuration will allow the developer to set the number of retry attempts for two types of files: `SDLArtwork` files, which are images to be displayed in the UI, and general files, which can be any non-artwork files such audio and text files. A default configuration will set the retry attempts to 1. Setting the retry attempts to 0 will disable the retry feature.

    ```objc
    // SDLFileManagerConfiguration.h
    @property (strong, nonatomic, nullable) NSNumber<SDLUInt> *artworkRetryCount;
    @property (strong, nonatomic, nullable) NSNumber<SDLUInt> *fileRetryCount;

    + (instancetype)defaultConfiguration;
    - (instancetype)initWithArtworkRetryCount:(UInt8)artworkRetryCount fileRetryCount:(UInt8)fileRetryCount;
    ```

2. Add the retry logic to the existing `SDLFileManager` class. When the file fails to upload, the manager will check the number of failed upload attempts for the file's name, and retry the upload if allowed. A dictionary will be used to track the failed upload count for files. The dictionary will be emptied when the app is disconnected from Core.    

    ```objc
    // SDLFileManager.m
    @property (strong, nonatomic) NSMutableDictionary<SDLFileName *, NSNumber<SDLUInt> *> *failedFileUploadsCount;
    ```

## Potential downsides
None. 

## Impact on existing code
This is a minor version change. A new configuration, `SDLFileManagerConfiguration`, will be added to the `SDLConfiguration` class. The `SDLFileManager`'s `sdl_uploadFile:completionHandler:` method will be updated to handle retry attempts.

## Alternatives considered
 1. Add a retry attempt count to the `SDLFileManager`'s `uploadFiles:` and `uploadArtworks:` methods. The developer would have to set the desired retry attempt count every time they upload a file, which could be tedious. This would also require deprecating 6 existing methods and replacing them with new methods that include the retry attempts parameter.

 