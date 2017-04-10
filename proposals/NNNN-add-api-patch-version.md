# Add API Patch Version

* Proposal: [SDL-NNNN](NNNN-add-api-patch-version.md)
* Author: [Jacob Keeler](https://github.com/jacobkeeler)
* Status: **Awaiting review**
* Impacted Platforms: Core, iOS, Android

## Introduction

This proposal is for the addition of a patch version into the Mobile and HMI APIs, as well as the `SyncMsgVersion` struct.

## Motivation

With several hotfixes recently made to both the Mobile and HMI APIs, it has been necessary to increase the minor version of each affected interface despite the fact that these changes are not functionality additions, but fixing previously broken/incorrect functionality.

In other words, there is currently no way to present backward-compatible fixes to the API without increasing the minor version of the interface.

In addition, all SDL Projects have been using [semantic versioning](http://semver.org/) as their versioning system, and this is impossible to maintain with the xml API files without a patch version.

## Proposed solution

This proposed solution to these issues is to include an optional `patchVersion` parameter into the `SyncMsgVersion` struct within the Mobile API. In addition, a patch version should be added for each of the interfaces in the HMI API to match this convention.

This parameter needs to be made optional in order to maintain backward compatibility, but it should always be included by Core when sending a RegisterAppInterface response once it is implemented.

## Potential downsides

It may be argued that the addition of this field is unnecessary under the assumption that changes to the spec would be infrequent, and that any changes should actually constitute minor version updates. 

Due to the fact that we have already needed to patch the APIs recently with fairly minor changes, I believe that it is better for us to have this field to simplify the inclusion of these fixes when necessary.

## Impact on existing code

This proposal will require minor code changes for expanding the SyncMsgVersion struct in:

- SDL Core
- Android Library
- iOS Library

###Core

In Core, this proposal would require that functionality be added to the interface generator Python tool to add a patch version to the generated message version file.

####MsgVersionGenerate.py:
```
array = (root.attrib["version"]).split(".")
major_version = array[0]
minor_version = array[1]
patch_version = array[2]
```

The `version` field in the Mobile API would need to be expanded to include this parameter, as well as the `SyncMsgVersion` struct.

####MOBILE_API.xml:
```
<interface name="Ford Sync RAPI" version="4.3.0" date="2017-03-29">
...
  <struct name="SyncMsgVersion">
    <description>Specifies the version number of the SYNC V4 protocol, that is supported by the mobile application</description>

    <param name="majorVersion" type="Integer" minvalue="1" maxvalue="10">
      <description>The major version indicates versions that is not-compatible to previous versions.</description>
    </param>
    <param name="minorVersion" type="Integer" minvalue="0" maxvalue="1000">
      <description>The minor version indicates a change to a previous version that should still allow to be run on an older version (with limited functionality)</description>
    </param>
    <param name="patchVersion" type="Integer" minvalue="0" maxvalue="1000" mandatory=false>
      <description>The minor version indicates a fix to existing functionality in a previous version that should still allow to be run on an older version </description>
    </param>
  </struct>
```

The `syncMsgVersion` field constructed as part of the RegisterAppInterface Response RPC would need to be updated to include the `patchVersion`.

####register_app_interface_request.cc
```
  response_params[strings::sync_msg_version][strings::patch_version] =
      patch_version;  // From generated file interfaces/generated_msg_version.h
```

The `version` field for each interface in the HMI API would need to be expanded to include this parameter. This parameter is not read in by the interface generator, which means the version of these interfaces are not currently available to the HMI. As a result, there are no code changes necessary to add a patch version to the HMI API.

####HMI_API.xml
```
<interface name="Common" version="1.5.0" date="2017-03-29">
...
<interface name="Buttons" version="1.1.0" date="2016-08-18">
...
<interface name="BasicCommunication" version="1.0.0" date="2013-04-12">
...
<interface name="VR" version="1.0.0" date="2013-04-17">
...
<interface name="TTS" version="1.0.0" date="2013-04-18">
...
<interface name="UI" version="1.0.0" date="2013-04-16">
...
<interface name="Navigation" version="1.3.0" date="2017-03-29">
...
<interface name="VehicleInfo" version="1.0.0" date="2013-04-21">
...
<interface name="SDL" version="1.0.0" date="2014-03-12">
```

###Android Library

In the Android Library, this proposal would require the addition of the `patchVersion` field to the `SdlMsgVersion` class.

####SdlMsgVersion.java:

```
    public static final String KEY_MAJOR_VERSION = "majorVersion";
    public static final String KEY_MINOR_VERSION = "minorVersion";
    public static final String KEY_PATCH_VERSION = "patchVersion";
    
    ...
    
    /**
     * Get patch version
     * 					<ul>
     * 					<li>minvalue="0"</li>
     * 				    <li>maxvalue="1000"</li>
     *					</ul>
     * @return the patch version
     */
    public Integer getPatchVersion() {
        return (Integer) store.get( KEY_PATCH_VERSION );
    }
    /**
     * Set patch version
     * 					<ul>
     * 					<li>minvalue="0"</li>
     * 				    <li>maxvalue="1000"</li>
     *					</ul>
     * @param patchVersion min: 0; max: 1000
     */
    public void setPatchVersion( Integer patchVersion ) {
        if (patchVersion != null) {
            store.put(KEY_PATCH_VERSION, patchVersion );
        } else {
            store.remove(KEY_PATCH_VERSION);
        }
    }
```

###iOS Library

In the iOS library, this proposal would require the addition of the `patchVersion` JSON key to `SDLNames.h`.

####SDLNames.h
```
...
#define NAMES_passengerSideAirbagDeployed @"passengerSideAirbagDeployed"
#define NAMES_patchVersion @"patchVersion"
#define NAMES_pdop @"pdop"
...
```

In Addition, the `SDLSyncMsgVersion` class would need to be updated to include the `patchVersion` field.

####SDLSyncMsgVersion.h
```
- (instancetype)initWithMajorVersion:(NSInteger)majorVersion minorVersion:(NSInteger)minorVersion;

- (instancetype)initWithMajorVersion:(NSInteger)majorVersion minorVersion:(NSInteger)minorVersion patchVersion:(NSInteger)patchVersion;

...

/**
 * @abstract The patch version indicates a fix to existing functionality in a previous version that should still allow to be run on an older version
 * 
 * Optional, Integer, 0 - 1000
 */
@property (strong) NSNumber *patchVersion;
```

####SDLSyncMsgVersion.m
```
- (instancetype)initWithMajorVersion:(NSInteger)majorVersion minorVersion:(NSInteger)minorVersion patchVersion:(NSInteger)patchVersion {
    self = [self init];
    if (!self) {
        return nil;
    }

    self.majorVersion = @(majorVersion);
    self.minorVersion = @(minorVersion);
    self.patchVersion = @(patchVersion);

    return self;
}

...

- (void)setPatchVersion:(NSNumber *)patchVersion {
    if (minorVersion != nil) {
        [store setObject:patchVersion forKey:NAMES_patchVersion];
    } else {
        [store removeObjectForKey:NAMES_patchVersion];
    }
}

- (NSNumber *)patchVersion {
    return [store objectForKey:NAMES_patchVersion];
}
```

## Alternatives considered

The only real alternative to this is just to leave the versioning system as is. This means that each modifcation to any of the RPC specs requires at least a minor version change, and would prevent us from using semantic versioning with these specs. 

This fix really has technically only become necessary due to the mistakes made in adding new functionality to the APIs thus far, and these changes were not reviewed by the SDL team before being merged. With this argument, this proposed change could be viewed as unecessary. 

I don't believe that this alternative is a particularly forward-thinking approach to the issue. Mistakes can sometimes be made, and I believe that there could very well be more incorrect functionality in the API which we are not aware of yet.
