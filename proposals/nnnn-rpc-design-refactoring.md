# RPC design refactoring

* Proposal: [SDL-NNNN](nnnn-rpc-design-refactoring.md)
* Author: [Alexander Kutsan](https://github.com/LuxoftAKutsan)
* Status: **Awaiting review**
* Impacted Platforms: [Core]

## Introduction

Rework design of application manager layer to:
 - Reduce coupling between components
 - Reduce responsibility of ApplicationManager class
 - Provide plugin architecture for easy adding additional functionality and RPC groups   

## Motivation

SDL core project is actively implements new features and new functionality. 
To keep project on track and reduce rick of regression during implementation
some refactoring of application manager layer should be done. 

### Reduce coupling between components and use dependency injection practice

Now Application manager is service locator and need to passed in each component
even if component does not need application manager, but need some other classes that owned by application manager.
During construction components should explicitly receive all dependencies. 
It will prevent unwanted access and improve encapsulation. 


### Reduce responsibility of ApplicationManager class 
Not application manager class have to many responsibilities:
 - Service location
 - Mobile/HMI RPC processing 
 - Mobile/HMI RPC sending 
 - Registration and managing mobile applications
 - Handle different states of SDL (low voltage/ video streaming / audio_path_throw ...) 
 
 Purpose of this refactoring is to extract handling/sending RPC's to separate module. 
 Many SDL commands require application manager only for sending RPC's and do not need to 
 know anything related to other application manager responsibility. 
 Also extracting RPC processing to separate module will reduce regression risk of changing any functionality that now in ApplicationManager.
 
### Provide plugin architecture for easy adding additional functionality and RPC groups   

SDL RPC's can be splitted to some groups of RPC's related so certain functionality (for example RC or video streaming).
Usually this RPC's works with some scope functionality that not required for other RPC's so should not be exposed. 

Adding new RPC of group of RPC's is now very complicated process, but it is also not very obvious. 
If OEM vendors need to introduce in their custom SDL forks new functionality their need to change SDL code, 
add new classes and modify existing factories. 

Better solution would be plugin approach of adding new RPC's.
So if some vendor will need to implement could of new RPC's it would be enough to implement certain interfaces and provide it to SDL as shared library.


## Proposed solution

### Use dependency injection for commands 

Commands should accept as list of services that they require. And Mobile factory should be responsible for providing this list of dependencies.  

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
It will simplify code and provide possibility to add new component to certain commands without affecting other commands.
And factory will create command with all required parameters, so existing code will not be complicated.
For RC component contains class ResourceAllocationManager. And not RC commands should not have access to this class, so it should be passed only to RC commands. 

### Reduce responsibility of ApplicationManager class 

Logic of handling and sending RPC's should be extracted from ApplicationManager to separate components `RPCHandler`, `RPCService`.

### RPCHandler
RPCHandler class should implement interfaces ```HMIMessageObserver```, ```ProtocolObserver``` handle incoming RPC's from HMI or mobile 
and process it. 

RPCHandler responsibilities:
 - Handle HMI/Mobile RPC's in message loop
 - Class checking policies on each RPC
 - Creating command from message with Command Factories
 - Send command for execution to Request Controller
 
 ### RPCService

RPCService should provide interface of sending messages to Mobile/HMI. 
RPCService should be passed to commands for Sending RPC's using dependency injection approach.

RPCService responsibilities:
 - SendMessage to HMI/Mobile
 - Call checking policies if message is allowed to send
 - Provide Request Controller information of any incoming request should be terminated.  

### Provide plugin architecture for easy adding additional functionality and RPC groups   

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
Major required change of application manager layer design public
## Impact on existing code

## Alternatives considered
