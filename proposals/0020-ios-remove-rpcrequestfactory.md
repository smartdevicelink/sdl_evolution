# Remove `SDLRPCRequestFactory`

* Proposal: [SDL-0020](0020-filename.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Accepted**
* Impacted Platforms: iOS

## Introduction
This proposal is to make a major change to remove the `SDLRPCRequestFactory` class and move instead build better initializers onto the RPC classes themselves.

## Motivation
Instead of having a dedicated factory class, we should instead create initializer methods directly on the RPC classes. Currently, the factory methods (which is more of a Java convention anyway) are somewhat hidden on the `SDLRPCRequestFactory` class, and shifting them to the individual RPC classes will make them more visible to developers and easier to find in general. Second, it will help ensure that when RPCs are added that the initializers are also updated. Finally, this will help to ensure that the library is more cohesive. Currently, some RPCs have factory methods, some have lots of factory methods, and many RPCs have none. Moving these methods out of the `SDLRPCRequestFactory` class will help to ensure that we keep the library consistent with good initializers.

## Proposed solution
The proposed solution is simply to remove the `SDLRPCRequestFactory` class entirely and to create initializers on RPC classes where they make sense, some may be similar to how `SDLRPCRequestFactory` already generates them with minor tweaks. For example, the correlation id is now automatically handled by the new dev API, therefore it should not be on any initializers as it is on the RPC factory methods.

## Impact on existing code
This is a major change because we are removing a class and a host of methods. This will be a breaking change for many developers who are using those methods to build their RPC requests. They will have to shift to using the initializers or building them manually.

## Alternatives considered
A few alternatives were considered. First is to leave it as is, only tweaking the RPC factory methods (e.g. removing correlation id parameters). This is judged as a worse option because all the methods would still be clumped together in one class instead of spread out to where they should be, close to their respective RPCs. Second is to remove it without replacing the methods with initializers. This is judged as a worse option because the initializers can be useful and manually building every RPC can be a pain on some of the larger RPCs.
