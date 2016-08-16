# iOS Readonly Properties on RPC Classes
* Proposal: [SE-NNNN](NNNN-filename.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Awaiting review**
* Review manager: TBD
* Impacted Platforms: iOS

## Introduction
This feature is a major change affecting RPC requests, responses, and structs. Currently, RPCs use readwrite properties that allow properties to be altered after the object has been created. This proposal will change that such that properties can no longer be set after an object has been created.

## Motivation
Currently, RPCs are mutable in that all of their properties can be set without the object needing to become a wholly new object. This is generally considered a bad practice in model objects, enough so that when Apple rebuilt Swift, they provided better support for this with Structs. Below is a list of benefits immutable RPCs would grant us:

1. Immutable RPCs would be simpler (though not *necessarily* easier) to construct.
1. Immutable RPCs would be much simpler and easier to test and use.
1. Immutable RPCs would translate better across threads and queues, since they could not be modified and are therefore thread-safe.
1. Immutable RPCs are guaranteed to be side-effect free, therefore no defensive copying is needed and can therefore be faster.
1. Immutable RPCs would avoid unpredictable states since their initialization and setup can be controlled.

In short, immutable objects are simply a best practice all around and would improve the library, at the cost of some convenience when constructing objects.

## Proposed solution
This proposed change is to alter all RPC classes to only use `readonly` properties, instead of the current default, `readwrite`. Since RPCs are essentially model classes, this is a clear best practice.

```objc
@interface SDLAddSubMenu : SDLRPCRequest {
}
- (instancetype)init;
- (instancetype)initWithDictionary:(NSMutableDictionary *)dict;
@property (strong) NSNumber *menuID;
@property (strong) NSNumber *position;
@property (strong) NSString *menuName;

@end
```

would therefore become:

```objc
@interface SDLAddSubMenu : SDLRPCRequest {
}
- (instancetype)init;
- (instancetype)initWithDictionary:(NSMutableDictionary *)dict;
- (instancetype)initWithMenuId:(NSNumber *)menuId position:(NSNumber *)position menuName:(NSString *)menuName;
@property (strong, readonly) NSNumber *menuID;
@property (strong, readonly) NSNumber *position;
@property (strong, readonly) NSString *menuName;

@end
```

As seen above, this would have the side effect of forcing us to build better initializers for RPC classes, since this would be the only method of setting properties.

When it makes sense, we could additionally add initializers or functions that take create a new object of the same class and modify as specified. This is similar to the `mutating func` concept on Swift Structs. For example, the following could be a new method on `SDLAddSubMenu`:

```objc
- (SDLAddSubMenu *)updateWithMenuId:(nullable NSNumber *)menuId position:(nullable NSNumber *)position menuName:(nullable NSString *)menuName {
    SDLAddSubMenu *newSubMenu = [self copy];
    newSubMenu.menuID = menuId ? menuId : self.menuID;
    newSubMenu.position = position ? position : self.position;
    newSubMenu.menuName = menuName ? menuName : self.menuName;
    
    return newSubMenu;
}
```

The above implementation would require the RPCs and structs to conform to the `NSCopying` protocol, however, it could be done by using a separate initializer which receives a passed in object of the same type and updated property values as well.

Additionally, we may remove the `SDLRPCRequestFactory` since it no longer has a use. All of the creation methods would be initializers on the respective RPC classes.

## Potential Downsides
The largest downside would be that everything must be set up at initialization time. Since Objective-C doesn't have default initializers like Swift does, this means that in some cases we may need multiple initializers hand-crafted so they make sense. For example, the `RegisterAppInterface` request would likely have an initializer for all the values, but additional ones removing some values that can be automatically created or are optional. This is the current purpose of the `SDLRPCRequestFactory` which can be removed after this update since it will not longer function.

## Impact on existing code
This would be a breaking change because any developer currently modifying a RPC object outside of initializers will no longer be able to do so. The creation of these RPCs will be able to happen in the initializers instead. The creation of the initializers is another minor change, and the removal of `SDLRPCRequestFactory` is a major change.

## Alternatives considered
The best alternative is a full move to Swift structs, which are fully immutable and copyable by default, while allowing for mutating functions that return a new object after mutation, as well as support for default initializers. However, this is impractical at this time. Perhaps in the future, we can build a Swift RPC layer that connects to the Obj-C core similar to how [Realm](http://www.github.com/realm/realm-cocoa) does it. This is impractical at this point, however, and remains an improvement over the current code.
