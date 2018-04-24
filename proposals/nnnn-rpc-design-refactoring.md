# RPC design refactoring

* Proposal: [SDL-NNNN](nnnn-rpc-design-refactoring.md)
* Author: [Alexander Kutsan](https://github.com/LuxoftAKutsan)
* Status: **Awaiting review**
* Impacted Platforms: [Core]

## Introduction

Rework design of application manager layer to:
 - Reduce coupling bewteen components
 - Reduce responcibility of ApplicationManager class
 - Provide plugin arhitecture for easy adding additional functionality and RPC groups   

## Motivation

SDL core project is actively implements new features and new funcionality. 
To keep project on track and reduce rick of regression during implementation
some refactoring of application manager layer should be done. 

### Reduce coupling bewteen components and use dependency injection practice

Now Application manager is service locator and need to passed in each component
even if component does not need application manager, but need some other classes that owned by applicatin manager.
During construction componets should explicitely receive all dependencies. 
It will prevent unwanted access and improove incapsulation. 


### Reduce responcibility of ApplicationManager class 
Not application manager class have to many responcibilities:
 - Service location
 - Mobile/HMI RPC processing 
 - Mobile/HMI RPC sending 
 - Registration and managing mobile applications
 - Handle different states of SDL (low voltage/ video streaming / audio_path_throw ...) 
 
 Purpose of this refactring is to extract handling/sending RPC's to separate module. 
 Many SDL commands require application manager only for sending RPC's and do not need to 
 know anything related to other application manager responcibility. 
 Also exctacting RPC processing to separate module will reduce regressin risk of chenging any functionality that now in ApplicationManager.
 
### Provide plugin arhitecture for easy adding additional functionality and RPC groups   

SDL RPS's can be splitted to some groups of RPC's related so certain functionality (for example RC or video streaming).
Ussualy this RPCs works with some scope functinality that not required for other RPC's so should not be exposed. 

Adding new RPC of group of RPCs is now very complicated process, but it is also not very obvious. 
If OEM vendors need to introuce in their custom SDL forks new functionality ther need to change SDL code, 
add new classes and modify existing factories. 

Better solution would be plugin approcah of adding new RPCs.
So if some vendor will need to implement could of new RPC's it would be enough to implement certain interfaces and provide it to SDL as shared library.


## Proposed solution

Describe your solution to the problem. Provide examples and describe how they work. Show how your solution is better than current workarounds: is it cleaner, safer, or more efficient? Use subsections if necessary.

Describe the design of the solution in detail. Use subsections to describe various details. If it involves new protocol changes or RPC changes, show the full XML of all changes and how they changed. Show documentation comments detailing what it does. Show how it might be implemented on the Mobile Library and Core. The detail in this section should be sufficient for someone who is *not* one of the authors to be able to reasonably implement the feature and future [smartdevicelink.com](https://www.smartdevicelink.com) guides.

## Potential downsides

Describe any potential downsides or known objections to the course of action presented in this proposal, then provide counter-arguments to these objections. You should anticipate possible objections that may come up in review and provide an initial response here. Explain why the positives of the proposal outweigh the downsides, or why the downside under discussion is not a large enough issue to prevent the proposal from being accepted.

## Impact on existing code

Describe the impact that this change will have on existing code. Will some SDL integrations stop compiling due to this change? Will applications still compile but produce different behavior than they used to? Is it possible to migrate existing SDL code to use a new feature or API automatically?

## Alternatives considered

Describe alternative approaches to addressing the same problem, and why you chose this approach instead.
