# Supported Character Sets

* Proposal: [SDL-0202](0202-character-sets.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Accepted**
* Impacted Platforms: [Core / iOS / Android / RPC]

## Introduction

This proposal introduces the ability for mobile apps to know what characters are supported by a head unit.

## Motivation

It can be a significant pain point for mobile developers to send a string in, for example, a `Show` RPC, only to have that RPC rejected due to the string containing unsupported characters. There is currently a [`CharacterSet` RPC enum](https://github.com/smartdevicelink/rpc_spec#characterset), however, the enum's values appear to be OEM specific and do not correlate to anything I could find on the internet. We should have generic character sets that correspond to open standards.

## Proposed solution

The proposed solution is to deprecate existing enum values and to add new enum values that correlate to open standards.

```xml
<enum name="CharacterSet" since="1.0">
    <description>The list of potential character sets</description>
    <element name="TYPE2SET" deprecated="true" since="X.X">
        <history>
            <element name="TYPE2SET" since="1.0" until="X.X">
        </history>
    </element>
    <element name="TYPE5SET" deprecated="true" since="X.X">
        <history>
            <element name="TYPE5SET" since="1.0" until="X.X">
        </history>
    </element>
    <element name="CID1SET" deprecated="true" since="X.X">
        <history>
            <element name="CID1SET" since="1.0" until="X.X">
        </history>
    </element>
    <element name="CID2SET" deprecated="true" since="X.X">
        <history>
            <element name="CID2SET" since="1.0" until="X.X">
        </history>
    </element>
    <element name="ASCII" since="X.X">
        <description>ASCII as defined in https://en.wikipedia.org/wiki/ASCII as defined in codes 0-127. Non-printable characters such as tabs and back spaces are ignored.</description>
    </element>
    <element name="ISO_8859_1" since="X.X">
        <description>Latin-1, as defined in https://en.wikipedia.org/wiki/ISO/IEC_8859-1</description>
    </element>
    <element name="UTF_8" since="X.X">
        <description>The UTF-8 character set that uses variable bytes per code point. See https://en.wikipedia.org/wiki/UTF-8 for more details. This is the preferred character set.</description>
    </element>
</enum>
```

These character sets were chosen because they are the most widely supported character sets and are supported on all Android and iOS devices. As noted in the document, UTF-8 is the preferred character set.

Additionally, we will update the description documentation of the `characterSet` in the `TextField` struct as follows.

```xml
<struct name="TextField" since="1.0">
    ...
    <param name="characterSet" type="CharacterSet" mandatory="true">
        <description>The set of characters that are supported by this text field. All text is sent in UTF-8 format, but not all systems may support all of the characters expressed by UTF-8. All systems will support at least ASCII, but they may support more, either the LATIN-1 character set, or the full UTF-8 character set.</description>
    </param>
    ...
</struct>
```

## Potential downsides

Infotainment systems will be required to implement the entirety of a character set or there may be issues with apps using uncommon characters. Character sets outside of these will be unsupported.

## Impact on existing code

This will be a minor version change due to additions and deprecations.

## Alternatives considered

One alternative considered was to have a string with supported characters passed from the head unit to the mobile device. However, for several reasons, this was rejected.

1. Character sets also affect encoding, and the head unit sending characters in an unknown encoding will never work correctly.
2. The number of supported characters in a set may be very large, resulting in the string being passed being enormous.
3. We should use standard instead of non-standard implementations.
