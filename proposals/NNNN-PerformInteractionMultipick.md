
# Perform Interaction Multipick

* Proposal: [SDL-NNNN](NNNN-PerformInteractionMultipick.md)
* Author: [Michael Crimando](https://github.com/MichaelCrimando)
* Status: **Awaiting review**
* Impacted Platforms: [Core / iOS / Java Suite / RPC ]

## Introduction

For when a user wants to order something from an app, the user may want to pick 1 or more of their favorite items from a list. This would allow that. Currently, perform interaction only accepts 1 input and clears.

## Motivation

As a user, I want to be able to pick multiple things from a list of my favorite orders so that I can order everything I want through the head unit.

Here's an example from an overall plan

<img src="../assets/proposals/NNNN-PerformInteraction-Multipick/PerformInteraction Multipick overview.PNG" alt="Login Screen" class="inline" height= "100%" width= "100%" /> 

## Proposed solution
An app can mark that the `performInteraction` is a multipick type by setting the text of the final confirmation button. That is - the button that the user presses after they are done selecting all their choices.
So, add a field `multiPickConfirmationButtonText`, if this has text in it then the `performInteraction` will be multipick. If the `InteractionMode` is `VR_ONLY` or the displayLayout is `TILES_WITH_SEARCH`, `LIST_WITH_SEARCH`, or `KEYBOARD_ONLY`, then the response will be `INVALID_DATA`. If the `InteractionMode` is `BOTH`, then the VR portion of the `PerformInteraction` will be skipped.


Add `multiPickConfirmationButtonText` to the request in the `MOBILE_API`.
Also, add a return parameter `choiceIDArray` to `PerformInteraction` response. This array allows duplicate choiceIDs so that the HMI can send back the same choiceID multiple times to relay a quantity back to the app:
```xml
    <function name="PerformInteraction" functionID="PerformInteractionID" messagetype="request" since="1.0">
      <description>Triggers an interaction (e.g. "Permit GPS?" - Yes, no, Always Allow).</description>
      .
      .
      .
      <param name="multiPickConfirmationButtonText" type="String" maxlength="500" mandatory="false" since="X.X">
        <description>
          If this parameter is set, then this is a multipick performInteraction. This text will be in the button that a person uses to finish choosing items.
        </description>
      </param>
    </function>
	
    <function name="PerformInteraction" messagetype="response">
    .
    .
    .
      <param name="choiceIDArray" type="Integer" minsize="1" maxsize="100" minvalue="0" maxvalue="2000000000" array="true" mandatory="false" since="X.X">
       <description>
          IDs of the choices that were selected in response to a multipick performInteraction. Allows duplicate choiceIDs so that the HMI can send back the same choiceID multiple times to relay a quantity back to the app.
          Only is valid if general result is "success:true".
       </description>
      </param>	
    </function>	
```

Then do the same for the `HMI_API`:
```xml
<interface name="UI" version="X.X.X" date="X-X-X">
.
.
.
  <function name="PerformInteraction" messagetype="request">
  .
  .
  .
    <param name="multiPickConfirmationButtonText" type="String" maxlength="500" mandatory="false">
      <description>
        If this parameter is set, then this is a multipick performInteraction. This text will be the button that a person uses to finish choosing items.
      </description>
    </param>
  </function>
  
  <function name="PerformInteraction" messagetype="response">
  .
  .
  .
    <param name="choiceIDArray" type="Integer" minsize="1" maxsize="100" minvalue="0" maxvalue="2000000000" array="true" mandatory="false">
      <description>
        IDs of the choices that were selected in response to a multipick performInteraction. Allows duplicate choiceIDs so that the HMI can send back the same choiceID multiple times to relay a quantity back to the app.
        Only is valid if general result is "success:true".
      </description>
    </param>	
  </function>
</interface>
```

The SDL Mobile libraries will do some handling of providing the `choiceID` or `choiceIDArray` response back to the app. 
On older head units, the app might request a multipick `performInteraction` but the head unit would ignore the parameter of `multiPickConfirmationButtonText` and the response would only end up being a single choiceID.  If the `choiceID` and `choiceIDArray` are both present in the response from the HMI, then Mobile libraries will just send back `choiceIDArray`.

If a multipick PI times out, then SDL shall send a response of `TIMED_OUT` with no choices.


## Potential downsides

Adds complexity to Core and HMI. 
On older head units, the user would only be able to pick one thing from the multipick perform interaction.

## Impact on existing code

This adds complexity to Core and the HMI

## Alternatives considered

We could have a layout mode of `PerformInteraction` for multipick. Though this might be limiting on the types on layouts that could be used.
```xml
<enum name="LayoutMode" since="3.0">
.
.
.
  <element name="TILES_WITH_MULTIPICK" >
    <description>
      This mode causes the interaction to display the previous set of choices as icons along with a search field in the HMI.
    </description>
  </element>
  <element name="LIST_WITH_MULTIPICK" >
    <description>
      This mode causes the interaction to display the previous set of choices as a list.
    </description>
  </element>
</enum>			
```

Alternatively, we could create a new RPC of `PerformInteractionMultipick`.
Add to the `MOBILE_API` and `HMI_API` a new RPC `PerformInteractionMultipick`.
The `request` would have most of the same parameters as `PerformInteraction` but with an updated description and a new parameter for the confirmation button and no voice component. The response would also be the same in the `MOBILE_API` and `HMI_API` except the `choiceID` response would be an Array.
Add to the `MOBILE_API`:
```xml
  <function name="PerformInteractionMultipick" functionID="PerformInteractionMultipickID" messagetype="request" since="X.X">
	<description>Triggers an interaction where a user can pick multiple things (e.g. "What do you want to order from this restaurant?").</description>
	
	<param name="initialText" type="String" maxlength="500"  mandatory="true" since="X.X">
	  <description>
		Text to be displayed first.
	  </description>
	</param>
	
	<param name="multiPickConfirmationButtonText" type="String" maxlength="500" mandatory="false" since="X.X">
	  <description>
		This text will be in the button that a person uses to finish choosing items.
	  </description>
	</param>
	
	<param name="initialPrompt" type="TTSChunk" minsize="1" maxsize="100" array="true" mandatory="false" since="X.X">
	  <description>
		This is the initial prompt spoken to the user at the start of an interaction.
		An array of text chunks of type TTSChunk. See TTSChunk.
		The array must have at least one item.
	  </description>
	</param>
	
	<param name="interactionChoiceSetIDList" type="Integer" minsize="0" maxsize="100" minvalue="0" maxvalue="2000000000" array="true" mandatory="true" since="X.X">
	  <description>List of interaction choice set IDs to use with an interaction.</description>
	</param>
	
	<param name="timeout" type="Integer" minvalue="5000" maxvalue="100000" defvalue="10000" mandatory="false" since="X.X">
	  <description>
		Timeout in milliseconds.
		If omitted a standard value of 10000 milliseconds is used.
		Applies only to the menu portion of the interaction. The VR timeout will be handled by the platform.
	  </description>
	</param>

	<param name="interactionLayout" type="LayoutMode" mandatory="false" since="3.0" since="X.X">
	  <description>See LayoutMode.</description>
	</param>

	<param name="cancelID" type="Integer" mandatory="false" since="6.0" since="X.X">
	  <description>
		An ID for this specific PerformInteraction to allow cancellation through the `CancelInteraction` RPC.
	  </description>
	</param>
  </function>
```
```xml
  <function name="PerformInteractionMultipick" functionID="PerformInteractionMultipickID" messagetype="response" since="X.X" since="X.X">
	<param name="success" type="Boolean" platform="documentation" mandatory="true">
	  <description> Triggers an interaction where a user can pick multiple things (e.g. "What do you want to order from this restaurant?"). </description>
	</param>
	
	<param name="resultCode" type="Result" platform="documentation" mandatory="true" since="X.X">
	  <description>See Result</description>
	  <element name="SUCCESS"/>
	  <element name="INVALID_DATA"/>
	  <element name="OUT_OF_MEMORY"/>
	  <element name="TOO_MANY_PENDING_REQUESTS"/>
	  <element name="APPLICATION_NOT_REGISTERED"/>
	  <element name="GENERIC_ERROR"/>
	  <element name="REJECTED"/>
	  <element name="INVALID_ID"/>
	  <element name="DUPLICATE_NAME"/>
	  <element name="TIMED_OUT"/>
	  <element name="ABORTED"/>
	  <element name="UNSUPPORTED_RESOURCE"/>
	  <element name="WARNINGS"/>
	</param>
	
	<param name="info" type="String" maxlength="1000" mandatory="false" platform="documentation" since="X.X">
	  <description>Provides additional human readable info regarding the result.</description>
	</param>
	
	<param name="choiceID" type="Integer" array="true" minlength="0" maxlength="500" minvalue="0" maxvalue="2000000000" mandatory="false" since="X.X">
	  <description>
		ID of the choice that was selected in response to PerformInteraction.
		Only is valid if general result is "success:true".
	  </description>
	</param>
  </function>
```


and `HMI_API`:
```xml
<interface name="UI" version="X.X.X" date="X-X-X">
  <function name="PerformInteractionMultipick" messagetype="request">
    <description>Triggers an interaction where a user can pick multiple things (e.g. "What do you want to order from this restaurant?"). </description>
    <param name="initialText" type="Common.TextFieldStruct" mandatory="false">
      <description>Uses initialInteractionText. See TextFieldStruct.</description>
    </param>
    <param name="multiPickConfirmationButtonText" type="String" maxlength="500" mandatory="false">
      <description>
        This text will be the button that a person uses to finish choosing items.
      </description>
    </param>
    <param name="choiceSet" type="Common.Choice" minsize="1" maxsize="100" array="true" mandatory="false">
      <description>The list of choices to be used for the interaction with the user</description>
    </param>
    <param name="timeout" type="Integer" minvalue="5000" maxvalue="100000" defvalue="10000" mandatory="true">
      <description>Timeout in milliseconds.</description>
    </param>
    <param name="interactionLayout" type="Common.LayoutMode" mandatory="false">
      <description>See LayoutMode.</description>
    </param>
    <param name="appID" type="Integer" mandatory="true">
      <description>ID of application that concerns this RPC.</description>
    </param>
    <param name="cancelID" type="Integer" mandatory="false">
      <description>
        An ID for this specific alert to allow cancellation through the `CancelInteraction` RPC.
      </description>
    </param>
  </function>
</interface>
```
```xml
  <function name="PerformInteractionMultipick" messagetype="response">
    <param name="choiceID" type="Integer" minsize="1" maxsize="100" minvalue="0" maxvalue="2000000000" array="true" mandatory="false">
      <description>IDs of the choices that were selected. Allows duplicate choiceIDs so that the HMI can send back the same choiceID multiple times to relay a quantity back to the app.

          Only is valid if general result is "success:true".</description>
    </param>
  </function>
```
