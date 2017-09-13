# Mobile API versioning

* Proposal: [SDL 0089](0089-mobile-api-versioning.md)
* Author: [Kujtim Shala](https://github.com/kshala-ford)
* Status: **In Review**
* Impacted Platforms: [ RPC ]

## Introduction

This proposal is about extending the mobile API to provide version related information about features about when they are added, deprecated or removed.

## Motivation

Working on new features (e.g. play/pause button, locale support, manual only choice-sets) it was seen that changes to the mobile API are difficult especially when it comes to a connection session between an app and a head unit of different versions. In practice version mismatch is happening most of the time and in most of the cases it would work properly. Under some certain conditions it can happen that an app is using an API which is not supported by core and vice versa. Following proposals are very difficult to specify and implement as they may cause a breaking change to the API:

- `PLAY_PAUSE` Button taking over the play/pause toggle from the `OK` button. Some infotainment systems provide a play/pause toggle and an OK button. Media apps should use `PLAY_PAUSE` instead of or in addition to `OK` but they still need to subscribe to `OK` whenever they are connected to an older head unit in order to use the play/pause toggle.
- `Choice.vrCommands` to be optional instead of mandatory. Some apps want to perform an interaction in manual mode only. Today they still need to add a VR command to each choice. The proposal is about making it possible to omit VR commands but they still need to provide a VR command placeholder when they are connected to an older head unit.

## Proposed solution

The proposal is not about solving the issue of a version mismatch but rather add version related information to the elements of the mobile API. These version related information can be used as the foundation to improve versioning and the behavior of version mismatch. The version information can be added to the mobile API by using additional XML attributes.

### XML attributes

Following XML attributes should be used to add version information to the mobile API.

#### Attribute `minVersion`

The attribute `minVersion` should be used by the `interface` element to mention the minimum version number which is supported by the mobile API. The minimum version should be as low as possible (1.0) but it allows to remove support for obsolete SDL versions.

Example for the mobile API 4.5.0 which supports SDL starting from 1.0

```xml
<interface name="Ford Sync RAPI" version="4.5.0" minVersion="1.0" ...>
```

#### Attribute `since`

The attribute `since` should be used for any element (`enum`, `element`, `function`, `struct`, `param`) in the mobile API whenever an element is added to the API. It should also be used within the `history` element to describe since what version a change is applied.

Following example about video streaming capabilities which is added to 4.5.0:

```xml
<struct name="HMICapabilities">
  :
  <param name="videoStreaming" type="Boolean" mandatory="false" since="4.5.0" />
</struct>
:
<enum name="VideoStreamingProtocol" since="4.5.0">
  :
</enum>
```

If an element (`enum`, `function` or `struct`) contains the `since` attribute every sub-element (`param` for `function` or `struct`, `element` for `enum`) implicitly inherits the attribute and value. Otherwise the element was added with version 1.0.

#### Attribute `deprecated`

The attribute `deprecated` should be used for any element (`enum`, `element`, `function`, `struct`, `param`) in the mobile API whenever an element is about to be removed to the API.

Following example about locale support which should be deprecated in 4.5.0:

```xml
<enum name="Language" deprecated="4.5.0">
  :
</enum>

<function name="RegisterAppInterface" ...>
  :
  <param name="languageDesired" type="Language" mandatory="true" deprecated="4.5.0" />
  <param name="localeDesired" type="String" mandatory="true" since="4.5.0" />
</function
```

If an element (`enum`, `function` or `struct`) contains the `deprecated` attribute every sub-element (`param` for `function` or `struct`, `element` for `enum`) implicitly inherits the attribute and value.

#### Attribute  `removed`

The attribute `removed` should be used for any element (`enum`, `element`, `function`, `struct`, `param`) whenever an element is removed but can be used by an older version which is still supported by the mobile API.

Following parameter can be taken as an example of a removed element:

```xml
<function name="Show" ...>
  :
  <param name="mediaClock" type="String" minlength="0" maxlength="500" mandatory="false" removed="2.0" />
</function>
```

This attribute should only be used if the element can be used in an older version of SDL which is still supported. As an example if the mobile API minimum version is set to "2.0" the parameter `mediaClock` should be completely removed from the API and the proxies.

### Attribute changes (aka parameter element signature)

The elements `param` and `element` and all the attributes including `name` define a parameter signature. Changes to an existing parameter would produce a new signature which replaces the old parameter. The existing parameter element should be moved into a sub-element called `history` and the new parameter element should be added.

Note: The `type` attribute of a `param` element should not be changed. This would always cause a breaking change and would lead to an API which is not backward compatible. Instead a new parameter should be invented which replaces the existing one. As an exception the type can be changed if the SDL libraries can safely manage different parameter types.

As an example changing `Choice.vrCommands` to be optional starting with version 4.5.0 would look like as followed:

```xml
<struct name="Choice">
  <param name="vrCommands" type="String" minsize="1" maxsize="100" maxlength="99" array="true" mandatory="false" since="4.5.0" /> <!-- explicitly optional since 4.5 -->
  <history>
    <param name="vrCommands" type="String" minsize="1" maxsize="100" maxlength="99" array="true" removed="4.5.0" /> <!-- implicitly mandatory from v1.0 to v4.5-->
  </history>
</struct>
```

Another example shows how play/pause should be properly defined in the mobile API:

```xml
<enum name="ButtonName">
  <element name="OK" since="4.5.0">
    <description>
      The button name for the physical OK button. 
      It is not related to the Play/Pause button. 
      Please use the physical `PLAY_PAUSE` button.
    </description>
    <history>
      <element name="OK" removed="4.5.0">
        <description>
          The button name for the Play/Pause 
          toggle that can be used by media apps.
        </description>
      </element>
    </history>
  </element>
  <element name="PLAY_PAUSE" since="4.5.0">
    <description>
      The button name for the physical Play/Pause
      toggle that can be used by media apps.
    </description>
    <warning>
      Please use the physical OK button in order to
      use a Play/Pause toggle for versions &lt; 4.5.0.
    </warning>
  </element>
</enum>
```

It's using a warning element; please read "Warning element" section for details

### Warning element

It should be possible to add a warning element to any XML element. The warning element should contain a human readable message which helps developers to understand:

- That a new feature is added and not supported in older head units. If possible the warning should give advice how to deliver a similar experience for older head units. Example: PLAY_PAUSE button is not supported in head units <4.5. Use OK button instead for older head units.
- That a feature is deprecated (or even fully removed) and should not be used anymore. If possible the warning should give an advice if the feature is replaced by a successor. Example: Language enum should not be used with 4.5. Use locale parameters instead.

The warning element should be added in the mobile API and in the inline documentation. Additionally the warning can be written into the apps logs which would help validating an app on various head unit versions. The warning should appear in the logs when using a new feature on older head units and should appear when using deprecated or removed APIs on more recent versions. However this would require a library change.

## Potential downsides

The proposal requires more information to be maintained within the mobile API. It will cause more effort to properly maintain the API and it may produce a more complex API with regards to readability. 

## Impact on existing code

Existing code is not affected. The proposal would only add elements and attributes to the mobile API.

## Alternatives considered

Every enum `element` and every `param` element has to explicitly specify the newly added attributes appropriately (every element have to have the `added` attribute but only affected elements should have `deprecated` or `removed` attributes). However it is recommended to inherit the attributes from the parent element (`enum`, `struct` or `function`) if possible to avoid unnecessary duplicates.
