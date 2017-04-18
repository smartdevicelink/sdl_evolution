# iOS Library Proxy Layer Should Not Be Public

* Proposal: [SDL-0019](0019-ios-protocol-layer-nonpublic.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Accepted**
* Impacted Platforms: iOS

## Introduction
This proposal is to make major changes by shifting all code on the proxy layer to be non-public. This would leave the new manager-based layer as the developer's primary interaction point.

## Motivation
Since we shifted to the new developer API in SDL iOS 4.3.0, we have provided two primary interaction points, `SDLManager` and `SDLProxy`. `SDLProxy` was deprecated in 4.3.0 as an incentive for developers to shift over to using `SDLManager` and kin. We should use a major update to make breaking changes that remove `SDLProxy.h` from being public and make `SDLManager` the sole interaction point. This change will remove any confusion that may result from having two primary interaction points (and duplicated APIs) and allow SDL developers to refactor `SDLProxy` and kin to make sense as the backing marshalling layer for `SDLManager` without worrying about making breaking changes.

## Proposed solution
Currently, the following classes of the protocol layer are public:
* `SDLProxy.h`
* `SDLProxyListener.h`
* `SDLProxyFactory.h`

These classes should be shifted to `project` instead of `public` and all public API references to them should be removed.

## Detailed Updates Required
In order to use SDL v5.0, the developer would be required to make changes to their project to no longer use `SDLProxy` and friends and instead use `SDLManager`. These changes are outlined below.

#### Instead of creating and managing an `SDLProxy`, they create an `SDLManager`
###### Old
```objc
- (void)setupProxy {
   if ([self proxy] == nil) {
       [self resetProperties];
       // Create a proxy object by simply using the factory class.
       [self setProxy:[SDLProxyFactory buildSDLProxyWithListener:self]];
   }
}

- (void)teardownProxy {
   if ([self proxy] != nil) {
       [[self proxy] dispose];
       [self setProxy:nil];
   }
}

- (void)onProxyClosed {
   [[NSNotificationCenter defaultCenter]
    removeObserver:self
              name:MobileWeatherDataUpdatedNotification
            object:nil];

   [[NSNotificationCenter defaultCenter]
    removeObserver:self
              name:MobileWeatherUnitChangedNotification
            object:nil];

   [self teardownProxy];
   [self setupProxy];
}

- (void)onProxyOpened {
   [[NSNotificationCenter defaultCenter]
    addObserver:self
       selector:@selector(handleWeatherDataUpdate:)
           name:MobileWeatherDataUpdatedNotification
         object:nil];

   [[NSNotificationCenter defaultCenter]
    addObserver:self
       selector:@selector(repeatWeatherInformation)
           name:MobileWeatherUnitChangedNotification
         object:nil];

   [self registerApplicationInterface];
}

- (void)registerApplicationInterface {
   SDLRegisterAppInterface *request = [[SDLRegisterAppInterface alloc] init];
   [request setAppName:@"MobileWeather"];
   [request setAppID:@"330533107"];
   [request setIsMediaApplication:@(NO)];
   [request setLanguageDesired:[SDLLanguage EN_US]];
   [request setHmiDisplayLanguageDesired:[SDLLanguage EN_US]];
   [request setTtsName:[SDLTTSChunkFactory buildTTSChunksFromSimple:NSLocalizedString(@"app.tts-name", nil)]];
   [request setVrSynonyms:[NSMutableArray arrayWithObject:NSLocalizedString(@"app.vr-synonym", nil)]];
   SDLSyncMsgVersion *version = [[SDLSyncMsgVersion alloc] init];
   [version setMajorVersion:@(1)];
   [version setMinorVersion:@(0)];
   [request setSyncMsgVersion:version];

   [self sendRequest:request];
}
```

###### New
This is replaced by creating an SDLManager and setting the configuration:

```objc
SDLLifecycleConfiguration *lifecycleConfig = [SDLLifecycleConfiguration debugConfigurationWithAppName:@"MobileWeather" appId:@"330533107" ipAddress:@"192.168.1.249" port:2776];
lifecycleConfig.ttsName = [SDLTTSChunkFactory buildTTSChunksFromSimple:NSLocalizedString(@"app.tts-name", nil)];
lifecycleConfig.voiceRecognitionCommandNames = @[NSLocalizedString(@"app.vr-synonym", nil)];
lifecycleConfig.appIcon = [SDLArtwork persistentArtworkWithImage:[UIImage imageNamed:@"AppIcon60x60@2x"] name:@"AppIcon" asImageFormat:SDLArtworkImageFormatPNG];
lifecycleConfig.logFlags = SDLLogOutputConsole;

SDLConfiguration *config = [SDLConfiguration configurationWithLifecycle:lifecycleConfig lockScreen:[SDLLockScreenConfiguration enabledConfiguration]];

self.manager = [[SDLManager alloc] initWithConfiguration:config delegate:self];

[self.manager startWithReadyHandler:^(BOOL success, NSError * _Nullable error) {
}
```

#### Sending RPCs
###### Old
```objc
[[self proxy] sendRPC:request];
```

###### New
```objc
[[self manager] sendRequest:request];
```

#### RPC responses
###### Old
In the old system, you had to implement delegate methods. For example:
```objc
-(void)onDeleteFileResponse:(SDLDeleteFileResponse*) response {
   [self handleSequentialRequestsForResponse:response];

   NSString *filename = [[self currentFilesPending] objectForKey:[response correlationID]];

   if (filename) {
       [[self currentFilesPending] removeObjectForKey:[response correlationID]];
       if ([[SDLResult SUCCESS] isEqual:[response resultCode]]) {
           [[self currentFiles] removeObject:filename];
       }
   }
}
```

###### New
This is made significantly better in the new framework through button handlers and RPC response handlers, but the most basic changes that can be made is simply to switch these delegate methods with notification handlers.
```objc
// Somewhere at the start of your class
[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDeleteFileResponse:) name:SDLDidReceiveDeleteFileResponse object:nil];

// To replace the delegate method
- (void)onDeleteFileResponse:(NSNotification *)notification {
   SDLDeleteFileResponse *response = notifiction[SDLNotificationUserInfoObject];

   // Same as before
}
```

Obviously, this isn't perfectly ideal, but since it's the backup method to using RPC response handlers and button handlers, it's not meant to be. This does have the advantage of being available in any class rather than restricted to a single one.

#### Putfiles
###### Old
With the removal of `SDLProxy`, the following method would also be removed.
```objc
- (void)putFileStream:(NSInputStream *)inputStream withRequest:(SDLPutFile *)putFileRPCRequest;
```

The impact of this removal will vary. For example, the MobileWeather example application does not use it at all and rolls its own putfile handling. For some, therefore, this will be no great loss. However, if this method is used, then the developer may either roll their own putfile handling (as MobileWeather does), or use the new file manager APIs to handle this in a much easier, more automated way.

###### New
To do file management using the file manager, the developer would have to implement something like the following:
```objc
SDLArtwork *image = [SDLArtwork artworkWithImage:[[ImageProcessor sharedProcessor] imageFromConditionImage:filename] name:filename asImageFormat:SDLArtworkImageFormatPNG];
[self.manager.fileManager uploadFile:image completionHandler:^(BOOL success, NSUInteger bytesAvailable, NSError * _Nullable error) {
   // Whatever you need to do
}];
```

## Impact on existing code
This is a major change, but it would not affect anyone if they are using the iOS 4.3.0 APIs. Anyone continuing to use deprecated `SDLProxy` methods will have to switch to using the `SDLManager` based API.

### Proxy Public Method Replacements

#### Properties
* `SDLAbstractProtocol protocol` -> Will not be replaced
* `SDLAbstractTransport transport` -> Will not be replaced
* `NSSet<NSObject<NSProxyListener> *> proxyListeners` -> Will not be replaced
* `SDLTimer startSessionTimer` -> Will not be replaced
* `NSString debugConsoleGroupName` -> Will not be replaced, the debug system should be replaced
* `NSString proxyVersion` -> Will not be replaced, is accessible by default in dynamic frameworks through their public header
* `SDLStreamingMediaManager streamingMediaManager` -> Replaced on `SDLManager`

#### Methods
* `- (id)initWithTransport:(SDLAbstractTransport *)transport protocol:(SDLAbstractProtocol *)protocol delegate:(NSObject<SDLProxyListener> *)delegate;` -> Replaced by setting up `SDLManager` with `SDLConfiguration`
* `- (void)dispose;` -> Will not be replaced
* `- (void)addDelegate:(NSObject<SDLProxyListener> *)delegate;` -> Replaced by using NSNotifications, see above
* `- (void)removeDelegate:(NSObject<SDLProxyListener> *)delegate;` -> Replaced by using NSNotifications, see above
* `- (void)sendRPC:(SDLRPCMessage *)message;` -> Replaced by `SDLManager`'s `sendRPC:` method, see above
* `- (void)handleRPCDictionary:(NSDictionary<NSString *, id> *)dictionary;` -> Will not be replaced, now handled internally by SDL
* `- (void)handleProtocolMessage:(SDLProtocolMessage *)msgData;` -> Will not be replaced, now handled internally by SDL
* `- (void)addSecurityManagers:(NSArray<Class> *)securityManagerClasses forAppId:(NSString *)appId;` -> Replaced by a property `NSArray<Class<SDLSecurityType>> *securityManagers;` on `SDLLifecycleConfiguration`
* `- (void)putFileStream:(NSInputStream *)inputStream withRequest:(SDLPutFile *)putFileRPCRequest;` -> Will be replaced on `SDLFileManager` with a forthcoming proposal.

## Alternatives considered
It should be noted that the impact of this change is somewhat lessened by the impact of previous changes. Because we have hidden the transport and protocol layers (SDL-0016, SDL-0017), the setup for the `SDLProxy` class would have to change in a significant way anyway. Several public APIs on `SDLProxy` would have to change as well, for example, removing the `protocol` and `transport` properties. So, our only alternative to hiding it is to make major, breaking changes to the class.

Because SDL iOS 5.0 is a major change, we should take the opportunity to make as many good changes as possible, and take as many clean breaks as possible (since this isn't a minor change where we are just breaking one API, 5.0 is breaking hundreds already). Furthermore, since our only alternative is to make breaking changes to a class, a bad class that should not be public, that would restrict SDL developers' ability to make needed changes, that may require future breaking changes that ought not be necessary, the alternative of leaving this class (and family) public is deemed problematic and a poor alternative.
