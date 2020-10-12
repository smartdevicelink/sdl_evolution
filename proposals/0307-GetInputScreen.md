# Get Input Screen

* Proposal: [SDL-0307](0307-GetInputScreen.md)
* Author: [Michael Crimando](https://github.com/MichaelCrimando)
* Status: **In Review**
* Impacted Platforms: [HMI / Core / iOS / Java Suite / JavaScript / RPC]

## Introduction

This proposal adds an Form screen for apps. This enables a way for the user to sign in, put in their credit card information, put in their address and more. This is particularly focused on embedded/cloud apps because the app lives in the car and the user will still need a way to enter information without having the ability to do so on their phone.

## Motivation

With current SDL, apps live on the phone and connect to the car. So, the user can enter information for things like their login, address and credit card information via their phone and then connect the app to their car. With embedded/cloud apps, the app no longer lives in the phone - it lives in the car.  Users will need a way to do all of this functionality still.

Here's an example from an overall plan

<img src="../assets/proposals/0307-GetInput/GetInput Overview.PNG" alt="Login Screen" class="inline" height= "100%" width= "100%" /> 

Here's more specific potential screens

<img src="../assets/proposals/0307-GetInput/GetInput-1.PNG" alt="Login Screen" class="inline" height= "50%" width= "50%" /> 
<img src="../assets/proposals/0307-GetInput/GetInput-1-1.PNG" alt="Login Screen with Error" class="inline" height= "50%" width= "50%" /> 
<img src="../assets/proposals/0307-GetInput/GetInput-1-2.PNG" alt="Login Screen with Error Template" class="inline" height= "50%" width= "50%" /> 
<img src="../assets/proposals/0307-GetInput/GetInput-2.PNG" alt="Address Screen" class="inline" height= "50%" width= "50%" /> 
<img src="../assets/proposals/0307-GetInput/GetInput-3.PNG" alt="Credit Card Screen" class="inline" height= "50%" width= "50%" />
<img src="../assets/proposals/0307-GetInput/GetInput-3-1.PNG" alt="Credit Card Screen with Error" class="inline" height= "50%" width= "50%" />
<img src="../assets/proposals/0307-GetInput/GetInput-3-2.PNG" alt="Credit Card Screen with Error Template" class="inline" height= "50%" width= "50%" />

## Proposed solution
Add a new RPC for an input screen. This screen would use RPC encryption which is handled by policies.
It contains a title, and an array of `InputLines`

Here's the `MOBILE_API`:
```xml
<function name="DisplayForm" functionID="DisplayFormID" messagetype="request" since="X.X">
  <param name="initialText" type="String" maxlength="500"  mandatory="true">
    <description>
      Text to be displayed first.
    </description>
  </param>
  <param name="errorMessage" maxlength="500" type="String" mandatory="false">
    <description>
      If there's a problem with the input fields, this can be used to display information.
    </description>
  </param>
  <param name="fields" type="Field" array="true" minsize="1" maxsize="100" mandatory="true">\
  </param>
    <param name="softButtons" type="SoftButton" minsize="1" maxsize="8" array="true" mandatory="false">
    <description>
      App defined SoftButtons for cancel, edit, submit, etc.
    </description>
  </param>
</function>
```
and the `HMI_API`:
```xml
<function name="UI.DisplayForm" functionID="DisplayFormID" messagetype="request">
  <param name="initialText" type="String" maxlength="500"  mandatory="true">
    <description>
      Text to be displayed first.
    </description>
  </param>
  <param name="errorMessage" maxlength="500" type="String" mandatory="false">
    <description>
      If there's a problem with the input fields, this can be used to display information.
    </description>
  </param>
  <param name="fields" type="Common.Field" array="true" minsize="1" maxsize="100" mandatory="true">\
  </param>
    <param name="softButtons" type="Common.SoftButton" minsize="1" maxsize="8" array="true" mandatory="false">
    <description>
      App defined SoftButtons for cancel, edit, submit, etc.
    </description>
  </param>
</function>
```



Add a new struct called `Field` and an enum called `FieldType` to get user input in the DisplayForm screen.
This enables text input fields, numeric input fields and combo box input fields.  Text and numeric input fields would bring up a keyboard or numpad. Combo box input would bring up a drop down list of items. If a combo box is requested, and the user doesn't pick anything, the HMI will send back the field.text and then it's up to the app on what to do.

Here's the MOBILE_API:
```xml
<struct name="Field">
  <description>
    A single field for data input
  </description>
  <param name="type" type="FieldType" mandatory="true">
  </param>
  <param name="label" maxlength="500" type="String" mandatory="true">
  </param>
  <param name="image" type="Image" mandatory="false">
    <description>
      An image icon for the input field
    </description>
  </param>
  <param name="text" maxlength="500" type="String" mandatory="false">
    <description>
      The text that is already present in the input field
    </description>
  </param>
  <param name="format" maxlength="500" type="String" mandatory="false">
    <description>
      A text string used to format the input text to a certain style. Any characters except underscore will remain in the field with no way to type over them. The underscore character will represent a space that the user can type in.  E.g. A format string for phone number would be +_(___)___-____
    </description>
  </param>
  <param name="additionalInfo" maxlength="500" type="String" mandatory="false">
    <description>
      More information that is shown by the input field
    </description>
  </param>
  <param name="error" type="Boolean" mandatory="false">
    <description>
      If set to true, then the field has some problem with it and the HMI should highlight it in red.
    </description>
  </param>
  <param name="comboBoxChoices" type="String" maxlength="500" array="true" minsize="1" maxsize="200" mandatory="false">
    <description>
      List of choices if the type is COMBO_BOX. Otherwise ignored.
    </description>
  </param>
  <param name="inputMask" type="KeyboardInputMask" mandatory="false">
    <description>
      Used to cover up personal information like credit card number. Defaults to "DISABLE_INPUT_KEY_MASK"
    </description>
  </param>
</struct>
```

Plus the headunit can note that it supports form field text and images through `TextFieldName` and `ImageFieldName` in the `MOBILE_API`
```xml
   <enum name="TextFieldName" since="1.0">
     .
     .
     .
        <element name="formFieldLabel">
            <description>If this is not present, the app may assume that DisplayForm is unsupported. If it is present, it is assumed that all features other than image are supported.
        </element>
   </enum>
```
```xml
  <enum name="ImageFieldName" since="3.0">
    <element name="formFieldImage">
      <description>An image icon for the input field</description>
    </element>
  </enum>
```

```xml
  <enum name="FieldType" since="X.X">
    <description>The type of input field</description>
    <element name="COMBO_BOX" />
    <element name="TEXT" />
    <element name="NUMBER" />
      <description>
        This is a notice for the HMI to bring up a keypad
      </description>
  </enum>
```

and the `HMI_API`:
```xml
<struct name="Field">
  <description>
    A single field for data input
  </description>
  <param name="type" type="Common.FieldType" mandatory="true">
  </param>
  <param name="label" maxlength="500" type="String" mandatory="true">
  </param>
  <param name="image" type="Image" mandatory="false">
    <description>
      An image icon for the input field
    </description>
  </param>
  <param name="text" maxlength="500" type="String" mandatory="false">
    <description>
      The text that is already present in the input field
    </description>
  </param>
  <param name="format" maxlength="500" type="String" mandatory="false">
    <description>
      A text string used to format the input text to a certain style. Any characters except underscore will remain in the field with no way to type over them. The underscore character will represent a space that the user can type in.  E.g. A format string for phone number would be +_(___)___-____
    </description>
  </param>
  <param name="additionalInfo" maxlength="500" type="String" mandatory="false">
    <description>
      More information that is shown by the input field
    </description>
  </param>
  <param name="error" type="Boolean" mandatory="false">
    <description>
      If set to true, then the field has some problem with it and the HMI should highlight it in red.
    </description>
  </param>
  <param name="comboBoxChoices" type="String" maxlength="500" array="true" minsize="1" maxsize="200" mandatory="false">
    <description>
      List of choices if the type is COMBO_BOX. Otherwise ignored.
    </description>
  </param>
  <param name="inputMask" type="Common.KeyboardInputMask" mandatory="false">
    <description>
      Used to cover up personal information like credit card number. Defaults to "DISABLE_INPUT_KEY_MASK"
    </description>
  </param>
</struct>
```
```xml
  <enum name="FieldType">
    <description>The type of input field</description>
    <element name="COMBO_BOX" />
    <element name="TEXT" />
    <element name="NUMBER" />
      <description>
        This is a notice for the HMI to bring up a keypad.
      </description>
  </enum>
```

Regarding the response which would be sent when the user presses a softbutton, this would use RPC encryption which is handled by policies.
There would be one string response for each field. If a field was left empty, the associated string would be blank.
This requires the following updates to the `MOBILE_API`:
```xml
<function name="DisplayForm" messagetype="response">
  
  <param name="success" type="Boolean" platform="documentation" mandatory="true">
    <description> true if successful; false, if failed.</description>
  </param>

  <param name="resultCode" type="Result" platform="documentation" mandatory="true">
    <description>See Result</description>
    <element name="SUCCESS"/>
    <element name="REJECTED"/>
    <element name="INVALID_DATA"/>
    <element name="INVALID_ID"/>
    <element name="DUPLICATE_NAME"/>
    <element name="DISALLOWED"/>
    <element name="OUT_OF_MEMORY"/>
    <element name="TOO_MANY_PENDING_REQUESTS"/>
    <element name="APPLICATION_NOT_REGISTERED"/>
    <element name="GENERIC_ERROR"/>
  </param>
  
  <param name="info" type="String" maxlength="1000" mandatory="false" platform="documentation">
    <description>Provides additional human readable info regarding the result.</description>
  </param>
  
  <param name="fields" type="Field" maxlength="500" array="true" minsize="1" maxsize="100" mandatory="true">
    <description>
      This will return an array of Fields that have the same type and label as requested, but with the text field populated.
    </description>
  </param>
  
</function>
```

We can use the `maskInputCharacters` parameter from [0238-Keyboard-Enhancements](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0238-Keyboard-Enhancements.md) for password or other sensitive data input. The main goal of this is to leverage an existing enum to help us out. `maskInputCharacters` mask will override `KeyboardProperties.maskInputCharacters` in `SetGlobalProperties`. All other keyboard-related items in `SetGlobalProperties` will work normally.

### Error Flow
To clarify the error flow a bit, heres a sequence diagram

<img src="../assets/proposals/0307-GetInput/GetInput-ErrorFlow.PNG" alt="Login Screen" class="inline" /> 


## Potential downsides

1. This adds complexity to Mobile Libraries, JavaScript Library, Core and the HMI.
2. This form process does not support OAuth logins (like Google, Apple, or Facebook).
3. This proposal doesn't include any manager changes, which would be useful for helping app partners use this feature.

## Impact on existing code

It's a new parameter so this would not affect older SDL versions.
It would be a minor version change for affected mobile libraries. 
This is dependent on [0238-Keyboard-Enhancements](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0238-Keyboard-Enhancements.md)

## Alternatives considered

If an app desires, they can give the user a PIN number via an on-screen alert instead and have the user go to their website and enter the PIN there as a login.
