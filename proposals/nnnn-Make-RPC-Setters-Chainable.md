# Make RPC Setters Chainable

* Proposal: [SDL-NNNN](nnnn-Make-RPC-Setters-Chainable.md)
* Author: [Bilal Alsharifi](https://github.com/bilal-alsharifi)
* Status: **Awaiting review**
* Impacted Platforms: [Java Suite]

## Introduction

This proposal is to enhance how the params' setters for the RPC classes work to make creating new RPCs easier. This can be done by making each setter return an instance of the RPC object. By doing that, creating an RPC and setting its params can all be done in one line of code. This reduces the amount of boilerplate code that developers need to write to create RPCs.

## Motivation

The SDL Java Suite library currently has a default constructor for every RPC that takes no params. It also has a constructor that takes all mandatory params. If developers want to create an RPC and set some of the non-mandatory params, they will have to write a line of code to set every param. This is not ideal if the RPC has multiple params. Let's take creating an `Alert` RPC as a simple example:

```
Alert alert = new Alert();
alert.setAlertText1("text1");
alert.setDuration(5000);
alert.setPlayTone(true);
...
```

The case will be more tedious if the developer wants to set more params. This proposal intends to solve the aforementioned issue by allowing developers to chain RPC setter calls to be able to create the RPC and set all params in one-line of code.

## Proposed solution

The proposal suggests enhancing how the current RPC setters work by making each setter return an instance of the object. For example, in the `Alert` RPC setters we can make the following modifications:

```
public class Alert extends RPCRequest {
	...

    public Alert setAlertText1(String alertText1) {
		setParameters(KEY_ALERT_TEXT_1, alertText1);
		return this;
    }

    public Alert setDuration(Integer duration) {
		setParameters(KEY_DURATION, duration);
		return this;
    }

    public Alert setPlayTone(Boolean playTone) {
		setParameters(KEY_PLAY_TONE, playTone);
		return this;
    }
    ...
}
```

By making that change, developers will be able to chain RPC setters calls together to be able to create and set the params in one line of code like the following:

```
Alert alert = new Alert().setAlertText1("text1").setDuration(5000).setPlayTone(true);
```

## Potential downsides

This proposal will modify every RPC setter in the library. However, the change is minimal as shown earlier and it will make creating RPCs much easier for the developer. 

## Impact on existing code

We'll need to update the setters for all RPCs in the SDL Java Suite library to return an instance of the RPC object. Those changes should not cause issues with the existing code written by developers because the RPC setters currently are not returning any value. Making them return an instance of the object will modify the return type for the public setters. However, it will keep the current usages of the setters working with no change needed from the developer's side.

## Alternatives considered

* Keep using the current RPC setters. This will require the developer to write multiple lines of code just to create an RPC and set its params which becomes tedious if the RPC has a lot of params.
* Create more constructors to set the RPC params upon creation. This will make the RPC classes end up with a lot of different variations for the constructors as we keep adding more params to the RPCs. This will be confusing to the library maintainers as well as the developers who use the library in their apps. Also, this means the library will expose more public APIs to the developers that need to be maintained and cannot be easily removed or changed without making breaking changes.
