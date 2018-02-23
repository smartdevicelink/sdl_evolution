# SDLImageUploadManager

* Proposal: [SDL-0124](0124-SDLImageUploadManager.md)
* Author: [Brandon Salahat](https://www.github.com/Toyota-BSalahat)
* Status: **Accepted with Revisions**
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

Several targetted enhancements are made to the existing APIs to reduce the burden on app developers.

1. A SDLArtwork init method is added that takes a UIImage and the current required arguments, and generates the image name/id based on a hash of the image.
2. Two SDLImage init methods are added
````objc
[SDLImage initWithName:(NSString *)] and [SDLImage initWithStaticImageValue:(UInt16)]
````

3. A upload function variant is added to the file manager that will return the image arguments name/ID if the file is reported as existing in the remote file list, or will perform the upload and return the name/id in a callback block once uploaded.

Proposed Usage (assuming app is in process of sending initial Show request for a template)

````swift
//existingShowRequest has already been initialized and populated

let sdlImage = SDLArtwork(uiImage) //add a SDLArtwork init that generates the ID from a hash of the image. This could have default arguments for persistence and image type, or could remain verbose as it is currently

let existingImage = fileManager.upload(sdlImage) { newImageId in //Add a upload variant that will return the generated ID if the file is reported as existing in the remote file list, or performs the upload and returns the id in a callback block once uploaded. 
    let show = UIShow()
   show.graphic = SDLImage(newImageId)
  //send show
}.map { existingImageId -> SDLImage in
   return SDLImage(existingImageId)
}

existingShowRequest.graphic = existingImage
````

Under the hood the new SDLArtwork init method would handle the naming of images, and the new upload method would abstract away some of the image upload logic apps currently have to reason through.

## Potential downsides

1. Apps that already implement SDL may not adopt the new interface immediately (or at all)
2. Complexity and error handling are added to the proxy (but abstracted out of app implementations)

## Impact on existing code

FileManager will receive a new upload method, SDLArtwork will receive a new initializer

## Alternatives considered

1. Leaving the image upload workflow as-is. Future implementations will need to use Putfile or FileManager
2. Implementing functionality similar to as-described in this proposal, but only expose it through the SDL graphical interface (ie, image uploads would only be optimized when images are sent using something like proposal [268](https://github.com/smartdevicelink/sdl_evolution/pull/268)


## Out of Scope
This proposal mainly discusses the iOS proxy, however this functionality would also be beneficial for Android.
