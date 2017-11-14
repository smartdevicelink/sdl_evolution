# Mobile API versioning revision

* Proposal: [NNNN](NNNN-mobile-api-versioning-revision.md)
* Author: [Kujtim Shala](https://github.com/kshala-ford)
* Status: **Awaiting review**
* Impacted Platforms: [ RPC ]

## Introduction

The proposal to add versioning to the mobile API was accepted with the revision to use the maintainer’s proposal. The suggested code will solve the same problem, while making parsing easier. The suggested code is 

```xml
<enum name="ButtonName">
</element>
  <element name="OK" mandatory="false" deleted="4.6.0">
    <description>
      The button name for the physical OK button.
      It is not related to the Play/Pause button.
      Please use the physical `PLAY_PAUSE` button.
    </description>
    <previousVersions>
      <element name="OK" mandatory="true" since="1.0.0" removed="4.5.0"/>
      <element name="OK" mandatory="false" since="4.5.0" deprecated="4.5.2"/>
      <element name="OK" mandatory="false" deprecated="4.5.2" removed="4.6.0"/>
    </previousVersions>     
  </element>
</enum>
```

With the following comment

> I think this is much more confusing and difficult to write a parser for than the maintainer suggestion above. The maintainer suggestion provides only two version parameters: from and until (though these could be different, such as since). Then, all the other parameters become booleans, including deprecated and removed or deleted (whichever wording is chosen). To me, this seems easy to read and easy to parse. In particular, the mandatory change in the revised version seems very confusing.

This document will show scenarios for the mobile API and how to solve them using the author’s proposal and the maintainer’s proposal. At the end both proposals will be compared:

-	What’s the increase the mobile API?
-	What’s the complexity to read the mobile API as a human?
-	What’s the complexity to read the mobile API as a parser?

To compare the parser complexity the comparison includes xpaths to locate the relevant information including versioning.

## Motivation

After elaborating the maintainers proposal it was seen that it requires more effort to get realized compared to the authors proposal. The XML filesize would increase much more than expected and the risk of potential errors is higher. At the end the effort to get the parser to work with versioning is expected to be higher with the maintainers proposal.

## Scenarios

Below you will find all possible scenarios and comparisons this proposal addresses:
In the examples the following struct SyncMsgVersion will be used 

```xml
<struct name="SyncMsgVersion">
  <description>Specifies the version number of the SYNC V4 protocol, that is supported by the mobile application</description>
  <param name="majorVersion" type="Integer" minvalue="1" maxvalue="10" />
  <param name="minorVersion" type="Integer" minvalue="0" maxvalue="1000" />
  <param name="patchVersion" type="Integer" minvalue="0" maxvalue="1000" mandatory="false" />
</struct>
```

## Scenario 1: Deprecate and remove sub-elements element, param

The parameter `patchVersion` will be deprecated with 4.5

### Author proposal

```xml
<struct name="SyncMsgVersion">
  <description>Specifies the version number of the SYNC V4 protocol, that is supported by the mobile application</description>
  <param name="majorVersion" type="Integer" minvalue="1" maxvalue="10" />
  <param name="minorVersion" type="Integer" minvalue="0" maxvalue="1000" />
  <param name="patchVersion" type="Integer" minvalue="0" maxvalue="1000" mandatory="false" deprecated="4.5" removed="5.0"/>
</struct>
```

#### What’s the increase the mobile API?

Very low. Only two attribute were added (deprecated & removed)

#### What’s the complexity to read the mobile API as a human?

Very easy. The attributes are in the parameter definition.

#### What’s the complexity to read the mobile API as a parser?

Very easy. When the parser reaches the parameter every attribute will be provided automatically with no additional code. The xpath to read parameter information would stay the same. Little effort to the parser to allow generation of version specific code (parse and build for any target version).

#### Xpath
```
/interface/struct[@name=’SyncMsgVersion’]/param[@name=’patchVersion’]
```

### Maintainer proposal

```xml
<struct name="SyncMsgVersion">
  <description>Specifies the version number of the SYNC V4 protocol, that is supported by the mobile application</description>
  <param name="majorVersion" type="Integer" minvalue="1" maxvalue="10" />
  <param name="minorVersion" type="Integer" minvalue="0" maxvalue="1000" />
  <param name="patchVersion" type="Integer" minvalue="0" maxvalue="1000" mandatory="false">
    <previousVersions>
      <param name="patchVersion" since="4.5" deprecated="true" />
      <param name="patchVersion" since="5.0" removed="true" />
    </previousVersions>
  </param>
</struct>
```

#### What’s the increase the mobile API?

High. New elements and multiple attributes are added

#### What’s the complexity to read the mobile API as a human?

High. Much more text (elements and attributes) added into multiple lines. 

#### What’s the complexity to read the mobile API as a parser?

High. When the parser reaches the parameter it must check the whole history for deprecation and removal elements. It requires more effort to the parser to support versioning. Without reading the previous versions it wouldn't know that the parameter is removed.

#### Xpath

```
/interface/struct[@name=’SyncMsgVersion’]/param[@name=’patchVersion’]
/interface/struct[@name=’SyncMsgVersion’]/param[@name=’patchVersion’]/previousVersions/param/[@deprecated=’true’ or @removed=’true’]*
```

## Scenario 2: Deprecate and remove container elements enum, struct, function

The example is about replacing SyncMsgVersion with MsgVersion

### Author proposal

```xml
<struct name="SyncMsgVersion" deprecated="5.0" removed="6.0">
  <description>Specifies the version number of the SYNC V4 protocol, that is supported by the mobile application</description>
  <param name="majorVersion" type="Integer" minvalue="1" maxvalue="10" />
  <param name="minorVersion" type="Integer" minvalue="0" maxvalue="1000" />
  <param name="patchVersion" type="Integer" minvalue="0" maxvalue="1000" mandatory="false" deprecated="4.5" removed="5.0"/>
</struct>

<struct name="MsgVersion" added="5.0">
  <param name="majorVersion" type="Integer" minvalue="1" maxvalue="10" />
  <param name="minorVersion" type="Integer" minvalue="0" maxvalue="1000" />
</struct>
```

#### What’s the increase the mobile API?

Very low. Only additional attributes.

#### What’s the complexity to read the mobile API as a human?

Easy. 

#### What’s the complexity to read the mobile API as a parser?

Very easy. The parser can immediately see that SyncMsgVersion should not be evaluated if the target version is later than the `removed` version.

#### Xpath

```
/interface/struct[@name=’SyncMsgVersion’]
/interface/struct[@name=’MsgVersion’]
```

### Maintainer proposal

```xml
<struct name="SyncMsgVersion">
  <description>Specifies the version number of the SYNC V4 protocol, that is supported by the mobile application</description>
  <param name="majorVersion" type="Integer" minvalue="1" maxvalue="10" />
  <param name="minorVersion" type="Integer" minvalue="0" maxvalue="1000" />
  <param name="patchVersion" type="Integer" minvalue="0" maxvalue="1000" mandatory="false">
    <previousVersions>
      <param name="patchVersion" since="4.5" deprecated="true" />
      <param name="patchVersion" since="5.0" removed="true" />
    </previousVersions>
  </param>
  <previousVersions>
    <struct name="SyncMsgVersion" since="5.0" deprecated="true" />
    <struct name="SyncMsgVersion" since="6.0" removed="true" />
  </previousVersions>
</struct>

<struct name="MsgVersion">
  <param name="majorVersion" type="Integer" minvalue="1" maxvalue="10" />
  <param name="minorVersion" type="Integer" minvalue="0" maxvalue="1000" />
  <previousVersions>
    <struct name="MsgVersion" since="5.0" added="true" />
  </previousVersions>
</struct>
```

#### What’s the increase the mobile API?

Very high. Another `previousVersions` elements would be needed.

#### What’s the complexity to read the mobile API as a human?

Very complicated. Scales badly.

#### What’s the complexity to read the mobile API as a parser?

Very high. When the parser reaches the element it first has to verify it’s validity if it should be used to generate code.

#### Xpath

```
/interface/struct[@name=’SyncMsgVersion’]/previousVersions/struct[@deprecated=’true’ or @removed=´true´]*
/interface/struct[@name=’MsgVersion’]/previousVersions/struct[@added=’true’]*
```

## Scenario 3: Change signature of sub-element param

This example  will increase the maxsize of majorVersion parameter with 5.1

### Author proposal

```xml
<struct name="MsgVersion" added="5.0">
  <param name="majorVersion" type="Integer" minvalue="1" maxvalue="100" added="5.1">
    <history>
      <param name="majorVersion" type="Integer" minvalue="1" maxvalue="10" removed="5.1" />
    </history>
  </param>
  <param name="minorVersion" type="Integer" minvalue="0" maxvalue="1000" />
</struct>
```

#### What’s the increase the mobile API?

High. A whole copy of the previous parameter is stored.

#### What’s the complexity to read the mobile API as a human?

Difficult. It might be confusing to see "clones" of the param element.

#### What’s the complexity to read the mobile API as a parser?

Very easy. Little to no effort for the parser to work. 

#### Xpath

```
/interface/struct[@name=’MsgVersion’]/param[@name=´majorVersion´]
```

### Maintainer proposal

```xml
<struct name="MsgVersion" added="5.0">
  <param name="majorVersion" type="Integer" minvalue="1" maxvalue="100">
    <previousVersions>
      <param name="majorVersion" since="5.0" maxvalue="10" until="5.1" />
    </previousVersions>
  <param name="minorVersion" type="Integer" minvalue="0" maxvalue="1000" />
</struct>
```

#### What’s the increase the mobile API?

High. An element explaining the signature change is necessary.

### What’s the complexity to read the mobile API as a human?

Very difficult. It's not a clone but still lot of additional text. Hard to follow the history of the parameter.

#### What’s the complexity to read the mobile API as a parser?

Very easy. Little to no effort for the parser to work. Extremely complicated and a lot of effort needed if support for specific target version is desired.

#### Xpath

```
/interface/struct[@name=’MsgVersion’]
/interface/struct[@name=’MsgVersion’]/previousVersions*
```

## Scenario 4: Deprecate and remove signature changed sub-element param 

This example will deprecate the majorVersion parameter (it's just an example...).

### Author proposal

```xml
<struct name="MsgVersion" added="5.0">
  <param name="majorVersion" type="Integer" minvalue="1" maxvalue="100" added="5.1" deprecated="5.2" removed="6.0">
    <history>
      <param name="majorVersion" type="Integer" minvalue="1" maxvalue="10" removed="5.1" />
    </history>
  </param>
  <param name="minorVersion" type="Integer" minvalue="0" maxvalue="1000" />
</struct>
```

#### What’s the increase the mobile API?

Very low.

#### What’s the complexity to read the mobile API as a human?

Pretty much easy to read.

#### What’s the complexity to read the mobile API as a parser?

Very easy. Little to no effort for the parser to  support specific target version.

#### Xpath

```
/interface/struct[@name=’MsgVersion’]
```

### Maintainer proposal

```xml
<struct name="MsgVersion" added="5.0">
  <param name="majorVersion" type="Integer" minvalue="1" maxvalue="100">
    <previousVersions>
      <param name="majorVersion" since="6.0" removed="true" />
      <param name="majorVersion" since="5.1" deprecated="true" />
      <param name="majorVersion" since="5.0" maxvalue="10" until="5.1" />
    </ previousVersions>
  </param>
  <param name="minorVersion" type="Integer" minvalue="0" maxvalue="1000" />
</struct>
```

#### What’s the increase the mobile API?

High.

#### What’s the complexity to read the mobile API as a human?

Very difficult. It's not a clone but still lot of additional text. Hard to follow the history of the parameter.

#### What’s the complexity to read the mobile API as a parser?

Very easy. Little to no effort for the parser to work. Extremely complicated and a lot of effort needed if support for specific target version is desired.

#### Xpath

```
/interface/struct[@name=’MsgVersion’]
/interface/struct[@name=’MsgVersion’]/previousVersions*
```

## Proposed solution

The proposed solution is to reconsider the original decision and compare the complexity and benefits of each proposal. It's proposed to accept the original authors proposal (see [0089](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0089-mobile-api-versioning.md) ) instead.

## Potential downside

This paper is about eliminating and avoiding downsides of the selected proposal. The downside of the author's proposal take place.

## Impact on existing code

Existing code is not affected. The proposal would only add elements and attributes to the mobile API. The parser and generator don't require any update to work with the XML additions.

## Alternatives considered

No other alternatives are considered.
