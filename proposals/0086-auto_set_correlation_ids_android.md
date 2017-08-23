# Auto Set Correlation ID (Android)

* Proposal: [SDL-0086](0086-auto_set_correlation_ids_android.md)
* Author: [Joey Grover](https://github.com/joeygrover)
* Status: **In Review**
* Impacted Platforms: [Android]

## Introduction
Every RPC request sent from the mobile proxy needs to have a Correlation ID set. The proxy will reject sending any RPC that does not have one. It was originally used to track responses using the monolithic `IProxyListenerALM` interface callback methods. Since then we have introduced RPC callback listeners that can be set to the request so there is less of a need for developers to specifically know the correlation ID set to a request.

## Motivation
The current proxy forces developers to manually set a correlation ID to each request RPC they wish to send. This can be somewhat hacked together to automatically happen via an abstraction to the `proxy.sendRPC()` method that would check for a correlation ID, and create a new one if it doesn't exist. However, that forces the developer to create that code.


## Proposed solution
The proposed solution will be to automatically set the correlation ID during a get request if one doesn't exist. This will prevent developers from having to manually create/set one. The ID could still be overwritten by the developer if they wish. 


###### RpcRequest.java
```java
public class RPCRequest extends RPCMessage {


	public Integer getCorrelationID() {
	//---- Proposal changes
		//First we check to see if a correlation ID is set. If not, create one.
		if(!function.containsKey(RPCMessage.KEY_CORRELATION_ID)){
			setCorrelationID(CorrelationIdGenerator.generateId());
		}
	//End of changes
		return (Integer)function.get(RPCMessage.KEY_CORRELATION_ID);
	}

	public void setCorrelationID(Integer correlationID) {
		if (correlationID != null) {
            function.put(RPCMessage.KEY_CORRELATION_ID, correlationID );
        } else {
        	function.remove(RPCMessage.KEY_CORRELATION_ID);
        }
	}

}
```

## Potential downsides
- None that could be observed.

## Impact on existing code
-The `RPCRequest.java` class would only need a minor change to add this functionality. By adding a simple key check during the `getCorrelationID()` method call, we can ensure there is always a correlation ID set.

## Alternatives considered
- Setting the correlation ID in the constructer. However, this seemed a waste of a call to the `CorrelationIdGenerator` if users were manually setting their IDs currently. The proposal's approach keeps the calls more efficient.
- Setting the correlation ID during internal proxy checks. This could have worked as well, but the change seemed better scoped for the RPCRequest itself.

