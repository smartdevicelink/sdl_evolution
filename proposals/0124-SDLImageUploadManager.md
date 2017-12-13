# SDLImageUploadManager

* Proposal: [SDL-0124](0124-SDLImageUploadManager.md)
* Author: [Brandon Salahat](https://www.github.com/Toyota-BSalahat)
* Status: **In Review**
* Impacted Platforms: [iOS]

## Introduction
Currently the logic SDL applications must implement to manage image uploads is tedious and error prone. The typical implementation is rewriting images using the same filename any time the image needs to be shown, or uploads all images at launch and never verifies their existence before calling a Show request. This proposal aims to centralize image management logic, optimize uploads with a local cache when possible, and generally move all image management responsibilities into the proxy.

## Motivation

Currently app integrations must handle all image upload logic via the FileManager or using Putfile directly. This leads to a lot of tedious logic to properly optimize image uploads, cover all edge cases, and update show requests once the images are uploaded. It would be easier for app developers if the proxy handled most of this logic, and they just specified the image they want to send to the head unit.

Workflows:
In all cases after the final step, the app must generate a SDLImage object and not rely on UI.Show displaying the image until the upload operation is complete. This often means sending an additional Show request just to bring the uploaded image on-screen. If the image was already present on the head unit, this step can be skipped and the Show request can be called with the SDLImage immediately.

Current workflow (iOS)
1. App gets UIImage object
2. App must check if image already exists using ListFile/RemoteFileNames
3. App must generate image name and SDLArtwork object
4. App must upload SDLArtwork using FileManager
5. In FileManager callback, app must handle possible errors and success case

Common app developer integration (1)
1. App is launched, SDL connects
2. App uses putfile/filemanager to upload all static images
3. If images are no longer present on the head unit between step 2 and when the show request is generated, images no longer display

Common app developer integration (2)
1. App is launched, SDL connects
2. App downloads/generates image dynamically
3. App uploads image using putfile/filemanager using static filename with overwrite always enabled (ie "appname.jpg")
4. App never knows for sure what image is displayed. Often the wrong image can be displayed on the head unit.

Many integration issues stem from workflows that fall somewhere between integration (1) and (2). App developers are not having the time/understanding of SDL to properly manage the current image upload workflows.

## Proposed solution

The SDL proxy provides an ImageUploadManager class that handles all of the SDL-specific image upload logic. Its interface accepts the standard UIImage object, and it either returns the ID of the uploaded image immediately, or once the upload operation is complete. This class can optimize image uploads to prevent constant overwrites of the same file name and can reduce RPC chatter by tracking what images the app has already uploaded. This will help app partners by reducing how much SDL logic they must handle, and by moving the logic into the proxy they will not have to worry about most of the edge cases.

Proposed workflow
1. App has UIImage from static or generated/dynamic image asset
2. App passes UIImage to ImageUploadManager class
3. ImageUploadManager takes UIImage and determines if the image already exists on the head unit via its local image cache/remotefilenames RPC
4. If the image is already uploaded, ImageUploadManager immediately returns the image id/name of the uploaded image for app developer to use in current Show request.
5. If image is not uploaded, ImageUploadManager generates a unique image name, uses FileManager to upload the generated SDLArtwork object, handles any error on behalf of the app, and returns the image ID of the completed upload to the app.
6. App receives id/name of uploaded image. Dispatches show request accordingly. In this case almost all implementation details of the previous workflows are handled by the ImageUploadManager within the Proxy.


Proposed Interface

````swift
class SDLImageUploadManager {
    static let sharedInstance: SDLImageUploadManager = SDLImageUploadManager()
    func uploadImage(image: UIImage?, overwrite: Bool, completion: ((String?) ->())?)  -> String?
}
````

Proposed Usage (assuming app is in process of sending initial Show request for a template)

````swift
//existingShowRequest has already been initialized and populated

let imageId = SDLImageUploadManager.sharedInstance.uploadImage(image: imageview, overwrite: false, completion: { (newImageID) in
                let imageShow = SDLShow()
                imageShow?.graphic = SDLImage(name: newImageID, of: SDLImageType.dynamic())
                //send show request to update template now that image is available
            })
            
if imageId != nil {
    //generate SDLImage and set it on existingShowRequest
}
````

Under the hood the ImageUploadManager class will generate file names, track previously uploaded images with a basic image cache system, sync with the remote file list when necessary, etc.

## Potential downsides

1. Apps that already implement SDL may not adopt the new interface immediately (or at all)
2. It is technically possible that the cache mechanism could fall out of sync with the remote, though this can be mitigated with strategies that use remoteFileList to sync when errors are detected, etc.
3. Complexity and error handling are added to the proxy (but abstracted out of app implementations)

## Impact on existing code

- Impact to existing code should be minimal if implemented as a new class. However since FileManager already exists, this could also be added there as additional functionality

## Alternatives considered

1. Modifying FileManager to perform some of these capabilities on behalf of SDL applications
2. Leaving the image upload workflow as-is. Future implementations will need to use Putfile or FileManager
3. Implementing functionality similar to as-described in this proposal, but only expose it through the SDL graphical interface (ie, image uploads would only be optimized when images are sent using something like proposal [268](https://github.com/smartdevicelink/sdl_evolution/pull/268)


## Out of Scope
This proposal mainly discusses the iOS proxy, however this functionality would also be beneficial for Android.
