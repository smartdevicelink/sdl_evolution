# Policy validation of RPCs referenced in multiple functional groupings

* Proposal: [SDL-0107](0107-Policy-validation-of-RPCs-referenced-in-multiple-functional-groupings.md)
* Author: [Andrey Byzhynar](https://github.com/abyzhynar)
* Status: **In Review**
* Impacted Platforms: [Core]

## Introduction
Current SDL implementation of PRCs policy check includes the following simple flow. Application could have several functional groupings assigned to it and RPC could be a member of several groupings. Moreover, in each grouping RPC could have different sets of parameters allowed to be processed. In case of user disallows some grouping, it will add restrictions for processing RPC with allowed parameters if request contains also some disallowed.

A new idea is to implement extended policy check for the case when some RPC is included into different functional groupings and such groupings have different user permissions. 

## Motivation

Mobile applications need to know which RPC parameters are allowed and can be processed. 

SDL core has policy mechanism which is the part of RPC processing. It regulates RPC permissions based on groups of RPCs that are allowed to the application. 
Any RPC can belong to different functional groupings with different set of parameters for this RPC. SDL core must handle such cases when this RPC is being sent from mobile application. SDL must calculate final permissions for incoming RPC based on permissions of functional groupings assigned to application where this RPC is present.


## Proposed solution

SDL should re-transfer allowed portion of RPC request to HMI. 
In case when application sends some RPC request and this RPC is present in several functional groupins and these groupings have different parameters - SDL should consider incoming RPC parameters as allowed if these parameters are present 
in functional groupinging assigned to application and not disallowed by user(therefore allowed). If parameters which are present in incoming RPC request are absent in functional groupings assigned to application or this functional grouping is explicitly disallowed by user - these parameters are considered to be disallowed and should not be processed within request to HMI. 

Pre-condition: 

RPC exists at:
*<functional_groupinging_1>* with *<param_1>*, *<param_2>*
*<functional_groupinging_2>* with *<param_3>*, *<param_4>*
and *<functional_groupinging_1>* is disallowed by user

Sample state diagram:

* application -> SDL: RPC with `<param_1>`, `<param_2>`, `<param_3>`, `<param_4>`

* SDL checks groupingings permissions assigned to application 

* SDL -> HMI: RPC with `<param_3>`, `<param_4>` ONLY

* HMI processes this RPC

* HMI -> SDL: RPC (some result code) 

* SDL -> application: RPC response with <received_resultCode_from_HMI> + `"info: <param_1>, <param_2> are disallowed by user"` (only in case of successfull reponse from HMI)


*NOTE*: in case of SendLocation RPC with disallowed `"deliveryMode"` SDL must add to info also: `"default value of <deliveryMode> will be used"` 
  
## Potential downsides
None.

## Impact on existing code

SDL core changes:
- New RPC permissions calculation support by Policy Manager

## Alternatives considered
None.
