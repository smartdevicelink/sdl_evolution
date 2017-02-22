# Multiple File Manager Transactions

* Proposal: [SDL-0029](0029-ios-multiple-file-manager-transactions.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Deferred**
* Impacted Platforms: iOS

## Introduction
This proposal seeks to add APIs that allow developers to make multiple file manager transactions simultaneously. For example, a developer should be able to delete or upload multiple files simultaneously and have the completion block only be fired when all have completed.

## Motivation
It is common that developers will want to upload multiple files or images simultaneously and want to be notified when all are completed; for example, when the app has first connected. However, there are currently only two ways to do this. The first way is to use the file manager and upload the files one at a time, keeping track of which have completed manually. This way gives you the advantages of file manager, with its completion block and tracking, but takes up a lot of code. The second way is to manually create `SDLPutFile` instances and send them all manually. This way has less code, but also less safety and does not give you much help. There is a hole in our API to send multiple files in a way that the manager system can monitor and provide the developer back good and useful information.

## Proposed Solution
While this proposal is suggesting a design (see Detailed Design below), the final implementation may look slightly different based on implementation details. The suggested solution is to add two new methods to `SDLFileManager`. The first, to delete multiple files on the remote system simultaneously, allows the developer to pass an array of file names to be deleted and to be notified when all the requests have finished processing on the remote system. Second, to upload multiple files to the remote system simultaneously, allows the developer to pass an array of `SDLFile` instances. The developer will then be notified as the data is uploaded, as well as when all the requests and data have finished being uploaded to the remote system.

## Detailed Design
The proposed solution is to add two new methods to `SDLFileManager`:

```objc
- (void)deleteRemoteFilesWithNames:(NSArray<SDLFileName *> *)names completionHandler:(nullable SDLFileManagerMultiDeleteCompletionHandler)completionHandler;

- (void)uploadFiles:(NSArray<SDLFile *> *)files progressHandler:(nullable SDLFileManagerMultiUploadProgressHandler)progressHandler completionHandler:(nullable SDLFileManagerMultiUploadCompletionHandler)completionHandler;
```

### Deleting Multiple Remote files
Deleting multiple remote files is a much simpler problem than uploading multiple files because there isn't as large of a need to worry about data transfer. There will not be a "progress" handler because the operation should happen relatively quickly. These deletes may fail however, for example if the file does not exist on the remote system and cannot be deleted. We may, therefore, have a mixture of successful deletes and failed deletes. The completion handler will have to handle this mixed case.

As noted above, the method to do multiple deletes will be defined as the following:
```objc
- (void)deleteRemoteFilesWithNames:(NSArray<SDLFileName *> *)names completionHandler:(nullable SDLFileManagerMultiDeleteCompletionHandler)completionHandler;
```

The completion handler for the new multiple delete will look like this:
```objc
typedef void(^SDLFileManagerMultiTransactionCompletionHandler)(nullable NSError *error);
```
* `error` - This will provide an error code and domain if any of the deletes fail. The `userInfo` dictionary property will contain type `<SDLFileName: NSError>`. The key is the file name that did not delete properly, the value is an error describing what went wrong on that particular delete attempt.

### Uploading Multiple Files
Uploading multiple files is a considerably more difficult problem, as there are many more failure points and it is a very complex operation that may take a significant amount of time. Because of this, a progress handler will exist to keep the developer updated on the status of each upload and the multi-file upload as a whole. We may, at the end of the multi-file upload, have a mixture of successful and failed uploads. The final completion handler will have to handle this mixed case.

As noted above, the method to do multiple uploads will be defined as the following:
```objc
- (void)uploadFiles:(NSArray<SDLFile *> *)files progressHandler:(nullable SDLFileManagerUploadProgressHandler)progressHandler completionHandler:(nullable SDLFileManagerMultiUploadCompletionHandler)completionHandler;
- (void)uploadFiles:(NSArray<SDLFile *> *)files completionHandler:(nullable SDLFileManagerMultiUploadCompletionHandler)completionHandler;
```

The progress handler will be fired after each file within the array is uploaded or fails. It will look like this:
```objc
typedef void(^SDLFileManagerMultiUploadProgressHandler)(SDLFileName fileName, float uploadPercentage, Bool *cancel, nullable NSError *error);
```

* `fileName` - The name of the last file that had an upload attempt.
* `uploadPercentage` - This percentage is a decimal number between 0.0 - 1.0. It is calculated by dividing the total number of bytes in files successfully or unsuccessfully uploaded by the total number of bytes in all files passed to the `uploadFiles:progressHandler:completionHandler` method.
* `cancel` - If the developer sets this Bool to YES within the progress block, the file manager will cancel all remaining uploads.
* `error` - This will provide an error code and domain if the file failed to upload.

The completion handler will be fired after all files within the array are uploaded or fail. It will look like this (same as the deletion completion handler, above):
```objc
typedef void(^SDLFileManagerMultiTransactionCompletionHandler)(nullable NSError *error);
```
* `error` - This will provide an error code and domain. The `userInfo` dictionary property will contain type `<SDLFileName: NSError>`. The key is the file name that did not delete properly, the value is an error describing what went wrong on that particular upload attempt.

### SDLFile Updates
To account for the calculation of bytes taking place in `uploadFiles:progressHandler:completionHandler:` ([see above](#Uploading Multiple Files)), and API addition will be made to `SDLFile`:

```objc
@property (assign, nonatomic, readonly) NSUInteger numberOfBytes;
```

This property will return the number of bytes of data in the file, whether it is stored on disk or in memory. This is a readonly, computed property; `numberOfBytes` will be calculated when it is called by inspecting the file it is holding (whether in memory or on disk). If this computation is expensive, it may be cached.

## Potential Downsides
The primary potential downside of this proposal is that the APIs being added will be among the most complicated to implement in SDL. It wraps what is already a fairly complex API to upload files and provide completion blocks and will have to track those completion blocks and provide progress updates. Due to it also providing the number of bytes uploaded and to be uploaded, it will have to track those uploads in a bit more detail than the file manager currently does.

A second potential downside is that this new API makes no attempt to prevent developers from uploading files while the app is in state `NONE`. However, this restriction is not currently an SDL restriction, it is a restriction implemented by Ford. Until the SDL Committee decides to ratify this type of restriction into SDL, the SDL mobile library should not make an attempt to prevent the developer from performing a legitimate operation. Ford should provide good error messaging if they create restrictions above and beyond SDL's restrictions. Furthermore, this problem can be partially alleviated with good API method documentation.

## Impact on existing code
This is a minor version change; it will only add new API surface. This will drastically simplify developers' attempts to upload multiple files at once.

## Alternatives considered
The only alternatives considered are different or less complex APIs for the same thing. For example, altering how progress is calculated to, instead of the file manager calculating out how many bytes have been sent and total bytes, simply giving the developer how many uploaded files have completed and how many remain.
