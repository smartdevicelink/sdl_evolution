# RPC design refactoring

* Proposal: [SDL-NNNN](nnnn-rpc-design-refactoring.md)
* Author: [Alexander Kutsan](https://github.com/LuxoftAKutsan)
* Status: **Awaiting review**
* Impacted Platforms: [Core]

## Introduction

This proposal is to rework design of application manager layer in order to:
 - Reduce coupling between components
 - Reduce responsibility of ApplicationManager class
 - Provide plugin architecture for easy adding additional functionality and RPC groups   

## Motivation

SDL core project is actively implementing new features and new functionality.  
To keep project on track and to reduce risks of regression during implementation
refactoring of application manager layer should be done.  

Currently, extending SDL functionality may require code duplication. 
RC module, in fact, duplicates logic of application_manager layer, there is separate request controller, separate mechanism to call  polcies checks, and RPC's processing. So any common logic that should be implemented in application_manager layer should be duplicated in request controller, it results in bugs, and requires more time for implementation. 

The following steps will provide ability to keep RC enough encapsulated, without duplicating SDL code :

## Proposed solution
#### Reduce coupling between components and use dependency injection practice

Now Application manager is a service locator and should to be passed to each component
even if component does not need application manager, but need some other classes that owned by application manager.
During construction components should explicitly receive all dependencies. 
It will prevent from unwanted access and improve encapsulation. 


#### Reduce responsibility of ApplicationManager class 
Currently application manager class has too many responsibilities:
 - Service location
 - Mobile/HMI RPC processing 
 - Mobile/HMI RPC sending 
 - Registration and managing mobile applications
 - Handle different states of SDL (low voltage/ video streaming / audio_path_throw ...) 
 
 The purpose of this refactoring is to extract handling/sending RPC's to separate module.  
 Many SDL commands require application manager only for sending RPC's and do not need to know anything related to other application manager responsibility. 
 Also, extracting RPC processing to separate module will reduce regression risk of changing any functionality that now in ApplicationManager.
 
#### Provide plugin architecture for easy adding additional functionality and RPC groups   

SDL RPC's can be splitted to some groups or RPC's related to certain functionality (for example RC or video streaming).  
Usually these RPC's work with some functionality that is not required for other RPC's, so should not be exposed. 

Adding new RPC or group of RPC's is now very complicated process, but it is also not very obvious. 
If OEM vendors need to introduce in their custom SDL forks new functionality, they need to change SDL code, 
add new classes and modify existing factories. 

The best solution would be plugin approach of adding new RPC's.
So if some vendors need to implement code of new RPC's it would be enough to implement certain interfaces and provide them to SDL as shared library.


## Detailed design

### Use dependency injection for commands 

Commands should be accepted as list of services that they require. And Mobile factory should be responsible for providing this list of dependencies.  

#### Current Approach 
```cpp

SomeCommand::SomeCommand(app_mngr);

void SomeCommand::Run() {
  application_manager->protocol_handler().do_staff();
  application_manager->state_controller().do_staff();
  application_manager->PolicyHandler().do_staff();
  application_manager->resume_controller().do_staff();
  
}
```

#### New Approach 
```cpp

SomeCommand::SomeCommand(protocol_handler, state_controller, policy_handler, resume_controller);

void SomeCommand::Run() {
  protocol_handler_.do_staff();
  state_controller_.do_staff();
  protocol_handler_.do_staff();
  protocol_handler_.do_staff();
}
```
This will simplify code and provide possibility to add a new component to certain commands without affecting other commands.
And factory will create command with all required parameters, so existing code will not be complicated.  
RC component contains class ResourceAllocationManager. And non-RC commands should have no access to this class, so it should be passed only to RC commands. 

### Reduce responsibility of ApplicationManager class 

Logic of handling and sending RPC's should be extracted from ApplicationManager to separate components `RPCHandler`, `RPCService`.

### RPCHandler
RPCHandler class should implement interfaces ```HMIMessageObserver```, ```ProtocolObserver```, handle incoming RPC's from HMI or mobile 
and process them. 

RPCHandler responsibilities:
 - Handle HMI/Mobile RPC's in message loop
 - Class checking policies on each RPC
 - Creating command from message with Command Factories
 - Send command for execution to Request Controller
 
 ### RPCService

RPCService should provide interface for sending messages to Mobile/HMI.  
RPCService should be passed to commands for Sending RPC's using dependency injection approach.

RPCService responsibilities:
 - SendMessage to HMI/Mobile
 - Call checking policies if message is allowed to send
 - Provide Request Controller information of any incoming request should be terminated.  

### Provide plugin architecture for easy adding extra functionality and RPC groups   

Create **PluginManager** class that will be responsible for searching and loading rpc plugins.
All commands logic should be stored in rpc plugins. 

Each RPC plugin should implement following interfaces:
 - Command Interface :
 - CommandFactory Interface : 

#### Plugins responsibilities:
 - Provide list of supported commands
 - Create commands from smart object
 - Contain command logic

SDL will provide to *Plugin* interfaces of all services on application manager layer:
 - RPCService
 - PolicyHander
 - StateController
 - ApplicationManager
 - RequestController
 - ResumeController
 - etc ...

RPC Handler will use PluginManager to get plugins that is able to process required RPC. 
RPC Handler will use Command Factory from plugin to create Command for further processing.

![New design approach](../assets/proposals/nnnn-rpc-design-refactoring/new_design.png)

## Potential downsides
This change requires major changes of application manager layer. 
## Impact on existing code

## Alternatives considered
The only alternatives is to following existing approach, duplicating logic of application_manager layer. 
