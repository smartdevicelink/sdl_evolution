# iOS Library Use Nullability Annotations
* Proposal: [SDL-0018](0018-ios-use-nullability-annotations.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **In Review**
* Impacted Platforms: iOS

## Introduction
This proposal is to make major changes to the iOS library to support using nullability annotations in every file. After this proposal is implemented, every file in the project should have nullability information. In addition, we should make improvements in order to have as few `nullable` properties as possible.

## Motivation
The primary reason to add nullability annotations is to make it easier to reason about what could be nil and what cannot be nil. For example, a method we provide could require a parameter to be passed if it's required instead of asserting if it is not passed. Additionally, this would make our code more modern and integrated with Swift since any non-annotated property comes out as an implicitly unwrapped optional. Further, this would make testing easier because we can make more guarantees and about what will and will not be nil.

## Proposed Solution
The proposal is to add the `NS_ASSUME_NONNULL` and its ending counterpart to every .h and .m file and to explicitly declare any property that can be null as `nullable` (they will be null at some point). In addition, we should do dual part cleanup. The first part is to do non-breaking changes that allow as many properties and instance variables to be labelled `nonnull` (that is, they will never be null) as possible. Second, we should make breaking changes to keep as many public properties as possible as `nonnull`. For example, some classes contain `dispose` methods which set properties to nil. These are not necessary as when the class goes to nil, it will set those properties to nil. To preserve those properties as `nonnull` and for general clarity, it may make sense to remove those `dispose` methods.

The largest portion of classes to be changed will be RPC classes. For these, we could set any mandatory properties as `nonnull` as long as they have proper initializers so that the properties will not be null before they are set for the first time. This would help developers by not allowing them to send errant RPCs accidentally. We should therefore create proper initializers, or have good defaults for these mandatory properties.

## Potential Downsides
Marking every file with `NS_ASSUME_NONNULL` and marking all properties that will be `nil` as `nullable` should have no ramifications. Neither should doing non-breaking changes to allow as many properties and instance variables to be nonnull as possible.

The second part of this proposal, making breaking changes such as altering `dispose` methods would require some care to be sure we do not introduce new bugs.

Finally, changing RPC classes to employ `nonnull` for mandatory properties could have the downside of additional work needed by us of creating good defaults and initializers, and of the developer to make sure they use those initializers.

## Impact on existing code
This would be a breaking change. Developers may have to change how they build RPCs to use intializers that set mandatory properties. Depending on how much work is needed to make properties `nonnull` this could have a significant impact.

## Alternatives considered
We could implement part of this proposal. We should, at the very least, implement `NS_ASSUME_NONNULL` in every class and mark down what is and is not `nullable` even if we make no changes at all to help keep properties and method parameters `nonnull`. However, since we are doing a major change anyway, we should make improvements to guarantee as many things `nonnull` as make sense.
