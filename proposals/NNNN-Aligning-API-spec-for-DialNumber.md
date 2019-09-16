# Aligning API spec for DialNumber

* Proposal: [SDL-NNNN](NNNN-Aligning-API-spec-for-DialNumber.md)
* Author: [Ankur Tiwari](https://github.com/atiwari9)
* Status: **Awaiting Review**
* Impacted Platforms: [Core][HMI]

## Introduction

This proposal is to align HMI API spec with MOBILE API spec for `DialNumber`.

## Motivation
HMI API spec is incorrrect for `DialNumber`, this impacts the apps using this RPC. We should correct the HMI API using MOBILE API as reference because MOBILE API is correct.


## Proposed solution

Need to update description for param `number` in HMI API so that it matches with corresponding Mobile API description(`DialNumber` should allow digits 0-9 and * # , ; +)

#### HMI API Ref: (Incorrect)
https://github.com/smartdevicelink/sdl_core/blob/master/src/components/interfaces/HMI_API.xml#L4062

```
<function name="DialNumber" messagetype="request">
	<description>Request from SDL to call a specific number.</description>
	<param name="number" type="String" maxlength="40" mandatory="true">
		<description>The number to dial. Only the character + and numbers are allowed.</description>
	</param>
	<param name="appID" type="Integer" mandatory="true">
		<description>ID of application that concerns this RPC.</description>
	</param>
</function>
```

#### Mobile API Ref: (Correct)
https://github.com/smartdevicelink/sdl_core/blob/develop/src/components/interfaces/MOBILE_API.xml#L7353

```
<function name="DialNumber" functionID="DialNumberID" messagetype="request" since="3.0">
	<description>Dials a phone number and switches to phone application.</description>

	<param name="number" type="String" maxlength="40" mandatory="true">
		<description>
			Phone number is a string, which can be up to 40 chars.
			All characters shall be stripped from string except digits 0-9 and * # , ; +
		</description>
	</param>
</function>
    
```

Please refer to [SDL Core bug](https://github.com/smartdevicelink/sdl_core/issues/2408)

## Potential downsides

None

## Impact on existing code

* SDL Core would need to update the valid value checks.
* HMI may need to updates as well.

## Alternatives considered

None

