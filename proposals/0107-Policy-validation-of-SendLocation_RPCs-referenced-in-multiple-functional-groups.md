# Policy validation of SendLocation RPC referenced in multiple functional groupings

* Proposal: [SDL-0107](0107-Policy-validation-of-SendLocation_RPCs-referenced-in-multiple-functional-groupings.md)
* Author: [Andrey Byzhynar](https://github.com/abyzhynar)
* Status: **In Review**
* Impacted Platforms: [Core]

## Introduction
Current SDL implementation of SendLocation PRC policy check includes the following simple flow. Application could have several functional groupings assigned to it and SendLocation RPC could be a member of several groupings. Moreover, in each grouping SendLocation could have different sets of parameters allowed to be processed. In case of user disallows some grouping, it will add restrictions for processing SendLocation with allowed parameters if request contains also some disallowed.

A new idea is to implement extended policy check for the case when SendLocation RPC is included into different functional groupings and such groupings have different user permissions. 

## Motivation

Mobile applications need to know which RPC parameters are allowed and can be processed. 

SDL core has policy mechanism which is the part of RPC processing. It regulates RPC permissions based on groups of RPCs that are allowed to the application. 
SendLocation RPC can belong to different functional groupings with different set of parameters for this RPC. SDL core must handle such cases when this RPC is being sent from mobile application. SDL must calculate final permissions for incoming RPC based on permissions of functional groupings assigned to application where this RPC is present.


## Proposed solution

SDL should re-transfer allowed portion of SendLocation request to HMI. 
In case when application sends SendLocation request and SendLocation RPC is present in several functional groupins and these groupings have different parameters - SDL should consider incoming RPC parameters as allowed if these parameters are present 
in functional groupinging assigned to application and not disallowed by user(therefore allowed). If parameters which are present in incoming SendLocation request are absent in functional groupings assigned to application or this functional grouping is explicitly disallowed by user - these parameters are considered to be disallowed and should not be processed within request to HMI. 

Pre-condition: 

`SendLocation` RPC exists at:
*<functional_groupinging_1>* with *<param_1>*, *<param_2>*
*<functional_groupinging_2>* with *<param_3>*, *<param_4>*
and *<functional_groupinging_1>* is disallowed by user

Sample state diagram:

* application -> SDL: SendLocation with `<param_1>`, `<param_2>`, `<param_3>`, `<param_4>`

* SDL checks groupingings permissions assigned to application 

* SDL -> HMI: SendLocation with `<param_3>`, `<param_4>` ONLY

* HMI processes this RPC

* HMI -> SDL: SendLocation (some result code) 

* SDL -> application: SendLocation with <received_resultCode_from_HMI> + `"info: <param_1>, <param_2> are disallowed by user"` (only in case of successfull reponse from HMI)


*NOTE*: in case with disallowed `"deliveryMode"` SDL must add to info also: `"default value of <deliveryMode> will be used"` 
  
## Potential downsides
None.

## Impact on existing code

SDL core changes:
- New RPC permissions calculation support by Policy Manager

## Alternatives considered
None.
