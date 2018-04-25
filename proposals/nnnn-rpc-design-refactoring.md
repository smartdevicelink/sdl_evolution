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

### Use dependency injection for commands 

Commands should accept as list of services that they reuire. And Mobile factory should be responcible for providing this list of dependencies.  

#### Old Approach 
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
It will simplify code and provide poccibility to add new component to certain commands without affecting other commands.
And factory will create command with all required parameters, so existing code will not be complicated.
For RC component contains class ResourceAllocationManager. And not RC commands should not have access to this class, so it should be passsed only to RC commands. 

### Reduce responcibility of ApplicationManager class 

Logic of handling and seding RPC's should be extracted from ApplicationManager to separate components `RPCHandler`, `RPCService`.

### RPCHandler
RPCHandler class should implement interfaces ```HMIMessageObserver```, ```ProtocolObserver``` handle incomming RPC's from HMI or mobile 
and process it. 

RPCHandler responcibilities:
 - Handle HMI/Mobile RPC's in message loop
 - Class checking policies on each RPC
 - Creating command from message with CommandFactories
 - Send command for execution to RequestController
 
 ### RPCService

RPCService should provide interface of sending messages to Mobile/HMI. 
RPCService should be passed to commands for Sending RPC's using dependency injection approach.

RPCService responsibilities:
 - SendMessage to HMI/Mobile
 - Call checking policies if message is allowed to send
 - Provide Requst Controller information of any inciming request shuld be terminated.  

### Provide plugin arhitecture for easy adding additional functionality and RPC groups   

Create **PluginManager** class that will be responcible for seraching and loaging rpc plugins.
All commands logic should be stored in rpc plugins. 

Each RPC plugin should implement folowing interfaces:
 - Command Interface :
 - CommandFactory Interface : 

#### Plugins responcibilities:
 - Provide list of supported commands
 - Create commans from smart object
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
RPC Handler will use Command Factory from plugin to create Command for futher procesing.

![New design approach](assets/nnnn-rpc-design-refactoring/new_design.png)

## Potential downsides
Major required change of application manager layeer design public
## Impact on existing code

## Alternatives considered
