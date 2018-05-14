# Make spaceAvailable field non-mandatory

* Proposal: [SDL-0163](0163-make-spaceavailable-field-non-mandatory.md)
* Author: [Jacob Keeler](https://github.com/jacobkeeler)
* Status: **Accepted**
* Impacted Platforms: [RPC]

## Introduction

This proposal is to make the `spaceAvailable` field in the `PutFile`, `DeleteFile`, and `ListFiles` responses non-mandatory in the RPC spec.

## Motivation

No other parameters are mandatory in any of the `response` messages from SDL Core outside of `code` and `success`. This is because the current standard is that SDL Core should not be expected to send anything besides these two fields in the case an error response is returned (and indeed, this is the current behavior of SDL Core). The fact this field is currently mandatory appears to just be the result of omitting the `mandatory` field when it was first implemented, which results in the field being mandatory by default. The `mandatory` field was later made necessary for every field, and this field was changed accordingly at that time. As such, it seems that this was likely done on accident originally.

## Proposed solution

The solution to this issue is to change this field to non-mandatory in the RPC spec.

## Potential downsides

Normally, changing whether a field is mandatory would be considered a breaking change in the RPC spec. However, this standard is primarily meant for incoming messages to SDL Core rather than outgoing messages. No validation is done on messages sent from SDL Core, meaning that this change would act more as a documentation change than a functional one. SDL Core does not currently respect the fact that this parameter should be mandatory, as it does not send this field in the case of an error response. As such, no apps could rely on this field being present in any case.

## Impact on existing code

### RPC Spec

```xml
    <function name="PutFile" functionID="PutFileID" messagetype="response">
        ...
-       <param name="spaceAvailable" type="Integer" minvalue="0" maxvalue="2000000000" mandatory="true">
+       <param name="spaceAvailable" type="Integer" minvalue="0" maxvalue="2000000000" mandatory="false">
            <description>
                Provides the total local space available in SDL Core for the registered app.
                If the transfer has systemFile enabled, then the value will be set to 0 automatically.
            </description>
        </param>
        ...
    </function>
```

```xml
    <function name="DeleteFile" functionID="DeleteFileID" messagetype="response">
        ...
-       <param name="spaceAvailable" type="Integer" minvalue="0" maxvalue="2000000000" mandatory="true">
+       <param name="spaceAvailable" type="Integer" minvalue="0" maxvalue="2000000000" mandatory="false">
            <description>Provides the total local space available on the module for the registered app.</description>
        </param>
        ...
    </function>
```

```xml
    <function name="ListFiles" functionID="ListFilesID" messagetype="response">
        ...
-       <param name="spaceAvailable" type="Integer" minvalue="0" maxvalue="2000000000" mandatory="true">
+       <param name="spaceAvailable" type="Integer" minvalue="0" maxvalue="2000000000" mandatory="false">
            <description>Provides the total local space available on the module for the registered app.</description>
        </param>
        ...
    </function>
```

## Alternatives considered

1. Changing the behavior of SDL Core to match the current spec, always sending `spaceAvailable` even in error responses.

