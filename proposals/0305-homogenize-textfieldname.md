# Homogenize TextFieldName

* Proposal: [SDL-0305](0305-homogenize-textfieldname.md)
* Author: [Collin McQueen](https://github.com/iCollin)
* Status: **Accepted with Revisions**
* Impacted Platforms: Core, HMI, iOS, Java Suite, JavaScript Suite, RPC

## Introduction

This proposal is to homogenize the enum `TextFieldName` in [`MOBILE_API.xml`](https://github.com/smartdevicelink/rpc_spec/blob/RPC-Generator/MOBILE_API.xml#L753) and [`HMI_API.xml`](https://github.com/smartdevicelink/sdl_core/blob/6.1.1/src/components/interfaces/HMI_API.xml#L539).

## Motivation

Having an enum defined differently in either API file is an inherent problem. This will cause undefined behavior in communication between parties using different API definitions.

## Background

All fields that currently exist only in the `HMI_API.xml` used to also exist in the `MOBILE_API.xml` up until the `sdl_core` 4.0 release. They were removed in sdl_core commit `a91f49224cf94614f1753433ad96473fd4572207`.

## Proposed solution

#### MOBILE_API.xml

```xml
<enum name="TextFieldName" since="1.0">
...
        <element name="phoneNumber" since="4.0">
            <description> Optional hone number of intended location / establishment (if applicable) for SendLocation.</description>
        </element>
+
+       <element name="timeToDestination" since="X.X">
+           <description>Optional time to destination field for navigationTexts parameter in ShowConstantTBT</description>
+       </element>
+
+       <element name="turnText" since="X.X"/>
+           <description>Turn text for turnList parameter of UpdateTurnList</description>
+       </element>
+
+       <element name="navigationText" since="X.X">
+           <description>Navigation text for turnList parameter of UpdateTurnList</description>
+       </element>
    </enum>
```

`timeToDestination` is added because it exists in the [`HMI_API.xml`](https://github.com/smartdevicelink/sdl_core/blob/6.1.1/src/components/interfaces/HMI_API.xml#L627) and can be used in the [`ShowConstantTBT` RPC](https://smartdevicelink.com/en/docs/hmi/master/navigation/showconstanttbt/).

`turnText` is added because it exists in the [`HMI_API.xml`](https://github.com/smartdevicelink/sdl_core/blob/6.1.1/src/components/interfaces/HMI_API.xml#L629) and can be used in the [`UpdateTurnList` RPC](https://smartdevicelink.com/en/docs/hmi/master/navigation/updateturnlist/).

`navigationText` is added because it exists in the [`HMI_API.xml`](https://github.com/smartdevicelink/sdl_core/blob/6.1.1/src/components/interfaces/HMI_API.xml#L630) and can be used in the [`UpdateTurnList` RPC](https://smartdevicelink.com/en/docs/hmi/master/navigation/updateturnlist/).

#### HMI_API.xml

```xml
 <enum name="TextFieldName">
...
   <element name="phoneNumber">
     <description> Optional hone number of intended location / establishment (if applicable) for SendLocation.</description>
   </element>
-   <element name="timeToDestination"/>
+   <element name="timeToDestination">
+     <description>Optional time to destination field for ShowConstantTBT</description>
+   </element>
-    <!-- TO DO to be removed -->
-   <element name="turnText"/>
+   <element name="turnText">
+     <description>Turn text for turnList parameter of UpdateTurnList</description>
+   </element>
   <element name="navigationText">
     <description>Navigation text for turnList parameter of UpdateTurnList</description>
   </element>
-  <element name="notificationText">
-    <description>Text of notification to be displayed on screen.</description>
-  </element>
 </enum>
```

`notificationText` is removed because it does not exist in the `MOBILE_API.xml` and is not used currently.

The comment `<!-- TO DO to be removed -->` is removed because it is no longer relevant.

Descriptions are added to both `timeToDestination` and `turnText`.

## Potential downsides

The author doesn't know of any downsides to this proposal.

## Impact on existing code

The `MOBILE_API.xml` changes will have no impact on existing code as only additions are made.

The `HMI_API.xml` changes will require updates to HMIs to remove `notificationText` from their capabilities and an update to Core to remove the processing of the `notificationText` `TextFieldName` capability.

## Alternatives considered

The author considered making no changes to the spec but this would be confusing to developers and would cause problems when another element is added to the `TextFieldName` enum.

The author considered not removing `notificationText` but this solution would also cause problems when another element is added to the `TextFieldName` enum.
