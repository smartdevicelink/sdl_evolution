# SDL JavaScript library

* Proposal: [SDL-0235](0235-sdl-js-library.md)
* Author: [Kujtim Shala](https://github.com/kshala-ford), [Mauricio Juarez](https://github.com/mjuarez-ford)
* Status: **Accepted with Revisions**
* Impacted Platforms: [ JavaScript ]

## Introduction

This proposal is about adding a new SDL library for applications developed in JavaScript.

## Motivation

With the increased popularity and the availability of JavaScript there are requests to support SmartDeviceLink for JavaScript developers. 

## Proposed solution

The solution is to create a common JavaScript library that offers a public proxy object to send and receive RPCs. The library also requires implementations of all the other layers required to package and frame the data and send it over a defined transport.

### SDL library layers

Looking into the existing libraries, developed in Java and Objective-C, they contain the following superset of layers:

1. The **High Level Interface** is a work-in-progress developer friendly API with the purpose to provide a programming interface similar to mobile frameworks.
2. The **Manager layer** is the current programming interface that abstracts the heavy load of dealing with application lifecycle, screen, dealing with RPCs and many more.
3. The **Proxy layer** also known as RPC layer, is the lower level interface with the purpose of managing the connection to the remote endpoint and sending and receiving RPCs. The [RPC specification](https://github.com/smartdevicelink/rpc_spec) of the mobile API is implemented in this layer.
4. The **SDL Session layer** is responsible for the lifecycle of service sessions for e.g. RPC/Bulk, video and audio. It packages application data and sends it to the protocol layer. 
5. The **SDL protocol layer** is responsible for organizing the sending and receiving of frames as per the [Protocol specification](https://github.com/smartdevicelink/protocol_spec)
6. The **transport layer** is the root level of SmartDeviceLink and therefore the most critical layer as it is responsible for the foundation of data transmission. 

It is not realistic to develop a new SDL library that can provide the same set of features as the Android and iOS library all at once. Therefore it is important to focus on a "milestone 1" which includes the following fundamental elements:

#### Included tasks in this proposal

**1. Proxy layer** 

Provide a Proxy class and implementations of all RPCs according to the [RPC specification v5.1](https://github.com/smartdevicelink/rpc_spec/tree/5.1.0). As this specification is XML structured it makes sense to develop a code generator to export all the RPCs, structs and enums to usable code.

**2. SDL Session layer and Protocol layer**

In the first milestone the JavaScript library should support the RPC and Bulk service types for communication. Media and projection applications may not be supported in the first release.

An open source BSON libray developed in JavaScript should be used by the SDL JavaScript library. If there is no suitable 3rd party BSON library available, a new BSON library will be created according to the specification of [bsonspec.org](http://bsonspec.org/#/specification).

**3. Transport layer**

The first release should come with a base/abstract definition of the transport layer. Based on this definition a WebSocket Server transport described in [Cloud App Transport Adapter](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0158-cloud-app-transport-adapter.md) should be implemented with this proposal. Additionally a TCP socket client transport should be implemented for development purposes. Both transports should be implemented for Node.js runtime.

#### Manager layer

The first managers that should be introduced in future proposals should be a lifecycle manager and the file manager. Other managers (screen manager etc.) should be added in future releases.

This proposal does not include a manager layer. Managers will be introduced via new proposals.

### Promise based development

Just as the other existing libraries, the JavaScript library requires possibilities to perform async operations. JavaScript is very well capable of serving this task especially with using the Promise pattern. 

There are many sources describing the Promise pattern with JavaScript and how it is used already in the native API and other libraries and frameworks. See [Mozilla: Promise](https://developer.mozilla.org/de/docs/Web/JavaScript/Reference/Global_Objects/Promise) and [You Don't Know JS - Promises](https://github.com/getify/You-Dont-Know-JS/blob/master/async%20%26%20performance/ch3.md)

### Project management

The JavaScript library will be open source and stored in a new smartdevicelink repository on GitHub called sdl_javascript_suite. The project maintainers will be responsible for maintaining and reviewing the code and the project.

The development should be done in JavaScript (not TypeScript) following ECMA-Script 2017. All the base source code should be developed using [JavaScript standard built-in objects](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects). 

The transport related source code for Node.js can use Node specific libraries needed (like socket.io). This code should be stored in a separate folder from the base source code in the repository.

## Potential downsides

The downside of having another SDL library is the increase of SDL maintenance. The project maintainers may need to assign individuals who are responsible for managing issues, projects and releases, and reviewing pull requests. The SDLC has to decide on the benefits of having a JavaScript library compared to the effort maintaining it.

## Impact on existing code

There is no impact to existing code. This proposal is about creating a new implementation of the SDL specs.

## Alternatives considered

No alternatives known. 
