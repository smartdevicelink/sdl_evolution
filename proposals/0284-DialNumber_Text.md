# DialNumber Text

* Proposal: [SDL-0284](0284-DialNumber_Text.md)
* Author: [Michael Crimando](https://github.com/MichaelCrimando)
* Status: **Accepted with Revisions**
* Impacted Platforms: [Core / iOS / Java Suite / JavaScript Suite / RPC]

## Introduction

This proposal adds a text string to `DialNumber` so that apps can be more descriptive or user friendly with it.
## Motivation

Currently when an app sends a DialNumber, the app is stuck with whatever text the HMI has baked in with it.
To enable some more user friendly experiences with DialNumber, we'd like to add a text string to it so that we can provide a friendlier message.

### Current
All apps have to use the same message when dialing a phone number:

<img src="../assets/proposals/0284-DialNumber_Text/Current Dial Number.png" alt="Current Dial Number" class="inline" height= "50%" width= "50%" /> 

### Future
Apps can use a different message based on the use case:

<img src="../assets/proposals/0284-DialNumber_Text/Future Dial Number.png" alt="Future Dial Number" class="inline" height= "50%" width= "50%" /> 


## Proposed solution
Add a text field to DialNumber in the MOBILE_API and HMI_API. 
The HMI would still need to display the phone number and a call button so that the user understands that a call is about to be placed. If the app doesn't send a message, the HMI would just display the standard string that they currently do for `DialNumber`.

Add to the `MOBILE_API`:
```xml
<function name="DialNumber" functionID="DialNumberID" messagetype="request" since="3.0">
    .
    .
    .
    <param name="promptText" type="Common.TextFieldStruct" mandatory="false" since="X.X">
        <description>Body of text to display to the user.</description>
    </param>
</function>
```

And `HMI_API`:
```xml
<function name="DialNumber" messagetype="request">
    .
    .
    .
    <param name="promptText" type="TextField" mandatory="false" since="X.X">
        <description>Body of text to display to the user.</description>
    </param>
</function>
```

In the `MOBILE_API` and `HMI_API` add to the `TextFieldName` enum 
```xml
<enum name="TextFieldName" since="1.0">
     .
     .
     .
    <element name="dialNumberPromptText" since="X.X">
        <description> Line of text for DialNumber</description>
    </element>    

</enum>
```

## Potential downsides

Added complexity to the HMI

## Impact on existing code

The additional parameter would be ignored on older headunits, so nothing needs to be done.

## Alternatives considered

None
