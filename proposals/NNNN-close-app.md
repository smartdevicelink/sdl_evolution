# CloseApp RPC

* Proposal: [NNNN](NNNN-close-app.md)
* Author: [Kujtim Shala](https://github.com/kshala-ford)
* Status: **Awaiting review**
* Impacted Platforms: [ Core / iOS / Android / RPC ]

## Introduction

This proposal is about adding a new RPC called `CloseApp` which can be used by an app to send itself into `HMI_NONE`.

## Motivation

In order to close an app the driver can enter the apps menu on the head unit and select "Exit {AppName}". This is working without any issues for template based apps. Users are able to get back control of an app which was started before. Projection apps like mobile-navigation apps are going to add their own menu which follows their own design guideline instead of using `AddCommand`. This leads into a problem of how those apps are closed. Once started on the head unit user won't be able to get back control of the app as Core is auto-resuming apps. 

## Proposed solution

The proposed solution is to add an opaque RPC called `CloseApplication`.

```xml
<function name="CloseApplication" messagetype="Request">
</function>

<function name="CloseApplication" messagetype="Response">
        <param name="success" type="Boolean" platform="documentation">
            <description> true if successful; false, if failed </description>
        </param>
        
        <param name="resultCode" type="Result" platform="documentation">
         <element name="SUCCESS"/>
         <element name="DISALLOWED"/>
         <element name="APPLICATION_NOT_REGISTERED"/>
         <element name="GENERIC_ERROR"/>
         <element name="IGNORED"/>
        </param>
        
        <param name="info" type="String" maxlength="1000" mandatory="false" platform="documentation">
            <description>Provides additional human readable info regarding the result.</description>
        </param>
</function>
```

A registerd application can send this RPC to transit from any HMI level to `HMI_NONE`. The application will receive an `OnHMIStatus` notification which then leads to remove the lock screen from the phone app. Different to unregister or re-register the application stays registered but will not be used as the preferred mobile-nav application anymore.

## Potential downsides

None

## Impact on existing code

None. It's only adding an opaque RPC.

## Alternatives considered

An alternative would be to make the RPC more generic and allow the app to set the own HMI level. The RPC would be called `SetHMILevel` with a parameter called `hmiLevel`

```xml
<function name="SetHMILevel" messagetype="Request">
  <param name="hmiLevel" type="HMILevel" mandatory="true" />
</function>
```

However this RPC would cause a higher complexity regarding policies (not every app should be able to enter HMI_LIMITED or HMI_FULL).
