
# Android RPC Refactor

* Proposal: [SDL-NNNN](nnnn-android_rpc_refactor.md)
* Author: [Austin Kirk](https://github.com/askirk), [Joey Grover](https://github.com/joeygrover)
* Status: **Awaiting review**
* Impacted Platforms: Android

## Introduction

This proposal is to modify the `RPCMessage` class to include generalized getter and setter methods. This would allow for the refactoring of `RPCRequests` and other RPC classes to use these methods rather than continuing to duplicate code that achieves the same result. 

## Motivation

`RPCRequests`, for instance: AddCommand, DeleteCommand, AddSubMenu, DeleteSubMenu, each have their own similar getter and setter methods. These functions are spread throughout the library creating unnecessary duplication of code. This proposal aims to reduce this duplicated code and create standard getter and setter functions that can be utilized throughout the library.

Many of these getters and setters are practically identical:

AddCommand & DeleteCommand use:

```java
public void setCmdID(Integer cmdID) {
	if (cmdID != null) {
    	parameters.put(KEY_CMD_ID, cmdID);
	} else {
    	parameters.remove(KEY_CMD_ID);
	}
}  

public Integer getCmdID() {
    return (Integer) parameters.get(KEY_CMD_ID);
}  	
```

Whereas AddSubMenu & DeleteSubMenu use: 

```java
public void setMenuID( Integer menuID ) {
    if (menuID != null) {
        parameters.put(KEY_MENU_ID, menuID );
    } else {
        parameters.remove(KEY_MENU_ID);
    }
}

public Integer getMenuID() {
    return (Integer) parameters.get( KEY_MENU_ID );
}
```

This duplicated code decentralizes possible errors and makes it much harder to make updates in the future.

## Proposed solution

Instead, it might be more useful to have a set of a general getter/setter methods in a base class e.g. `RPCMessage` that can be inherited and used by each of the individual RPC classes.

```
public class RPCMessage extends RPCStruct  {
	public void setObject(String functionName, Object value);
	public Object getObject(Class tClass, String key);
	public Object getObjectArray(Class tClass, String key);
	public String getString(String key);
	public Integer getInteger(String key);
	...
}
```

### Generic Setter Method
RPC Request classes almost exclusively use setter methods in the following fashion:

```
String KEY_STRING = "SOMETHING";
public void setSomething(Object obj) {
	if (obj != null) {
    	parameters.put(KEY_STRING, obj);
	} else {
    	parameters.remove(KEY_STRING);
	}
}
```

A generalized setter method should be available for these custom setter methods to use. It could resemble the following:

```
public void setObject(String key, Object value) {
	if (value != null) {
		parameters.put(key, value);
	} else {
		parameters.remove(key);
	}
}
``` 

### Generic Getter Methods
Unlike the setter methods, RPC Request classes use getter methods in multiple ways:

1. Query the `parameters` Hashtable for an `obj` (Object) for a certain key.
2. Then do one of the following:

 * A) If `obj` is an instance of a certain class, cast the object and return it
 * B) If `obj` is an instance of a Hashtable, construct an object of a certain class from the Hashtable
 * C) If `obj` is an instance of a List, cast to a list of objects of a certain class or construct a list of objects from a list of Hashtables

 And return the object or List.

3. If none of the prior conditions were true, return a null object.

Based of this pattern, the following are two proposed general getter methods:

```
// Case A
public Object getObject(Class tClass, String key) {
	Object obj = parameters.get(key);
	if(tClass.isInstance(obj)) {
		return tClass.cast(obj);
	}
	return null;
}

// Case B & C
public Object getObjectArray(Class tClass, String key){
	Object obj = parameters.get(key);
	if (obj instanceof Hashtable) {
		try {
			Constructor constructor = tClass.getConstructor(Hashtable.class);
			return constructor.newInstance((Hashtable<String, Object>) obj);
		} catch (Exception e) {
			e.printStackTrace();
		}
	}else if (obj instanceof List<?>) {
		List<?> list = (List<?>)parameters.get(key);
		if (list != null && list.size() > 0) {
			Object item = list.get(0);
			if (tClass.isInstance(item)) {
				return (tClass.cast(list));
			} else if (item instanceof Hashtable) {
				List<Object> newList = new ArrayList<Object>();
				for (Object hashObj : list) {
					try {
						Constructor constructor = tClass.getConstructor(Hashtable.class);
						newList.add(constructor.newInstance((Hashtable<String, Object>)hashObj));
					} catch (Exception e) {
						e.printStackTrace();
					}
				}
				return newList;
			}
		}
	}
	return null;
}
```

Getters for common known object types can also be implemented in a centralized method within the `RPCMessage` class:

```
public String getString(String key) {
	return (String) parameters.get(key);
}

public Integer getInteger(String key) {
	return (Integer) parameters.get(key);
}

...
```

Additional implementations of getter methods include:

 * If `obj` is an instance of a String, use a method like `valueForString` to cast the object to a certain class. This use could still be accounted for using the new getter methods:

 ```
 String VN_KEY = "VN_KEY";
 public VehicleNotification getNotificationStatus(){
 		Object obj = getObject(VehicleNotification.class, VN_KEY);
 		if(obj == null){
 			obj = VehicleNotification.valueForString(getString(VN_KEY));
 		}
 		return obj;
 }
 ```

## Potential downsides

The main downside is that it would require a major rework of many RPCs in the Android Sdl Library. This could take some time, and will require sufficient testing.

## Impact on existing code

As stated above, many RPCs would need to be re-written to use the generalized methods. It would only impact the Android Sdl library.

## Alternatives considered

An alternative is to just leave the code as is. However, this proposals purpose is to clean up existing code and make it more readable and reusable for future changes and use. 
