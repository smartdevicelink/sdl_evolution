# Use Taskmaster To Handle Queuing Operations in Managers

* Proposal: [SDL-NNNN](nnnn-Use-Taskmaster-To-Handle-Queuing-Operations-In-Managers.md)
* Author: [Joey Grover](https://github.com/joeygrover), [Bilal Alsharifi](https://github.com/bilal-alsharifi)
* Status: **Awaiting review**
* Impacted Platforms: [Java Suite]

## Introduction

This proposal is to include a new third party dependency called [`TaskMaster`](https://github.com/livio/Taskmaster) and start using it in the SDL Java Suite library. [`TaskMaster`](https://github.com/livio/Taskmaster) provides a queue oriented thread management solution to improve how managers handle queueing operations and make their logic easier to maintain and more efficient. This will allow the Java Suite library to better align with the iOS library that natively has this functionality through the OS.

## Motivation

The SDL Java Suite library currently uses `ThreadPoolExecutor` in `ChoiceSetManager` to manage queuing operations and executing them sequentially using one or multiple threads. The `ThreadPoolExecutor` solution is an improvement over the manual way of handling queuing using flags and endless callbacks. However, the `ThreadPoolExecutor` cannot be easily extended to be used in conjunction with other managers simultaneously. Doing so will require each manager to have its own `ThreadPoolExecutor` instance which means each manager will require at least one thread of its own. This may be okay if we have one or two managers that require the ability to queue tasks. However, as the number of managers in the library keeps growing as well as the need for better thread management, the library should have a more scalable solution. This proposal intends to include a third party dependency called `TaskMaster` created by the SDL project maintainer to have a central management for queues and threads for all managers in the SDL Java Suite library. This will allow for a single point of thread management for all the SDL managers.

## Proposed solution

The proposal suggests using [`TaskMaster`](https://github.com/livio/Taskmaster) in SDL Java Suite to create serial queues of operations that need to be executed in order. `ChoiceSetManager`, currently, uses `ThreadPoolExecutor` to queue operations and run them in order. For example, it uses a queue to submit `CheckChoiceVROptionalOperation` then `PresentChoiceSetOperation` to make sure that manager doesn't start presenting choices before knowing whether VR is optional or not on the target head unit. This queuing approach is much better than manually tracking if there is something queued (as the library currently still does  that in `SoftButtonManager` for example). However, the `ThreadPoolExecutor` solution falls short when we need to extend that solution to more managers because each manager and potentially submanagers will be forced to create new threads.

[`TaskMaster`](https://github.com/livio/Taskmaster) is queue oriented thread management solution developed by the SDL project maintainer to solve aforementioned issue. It is designed in a way that allows each manager to have its own queue of operations but still run all queues on a fixed number of threads. This gets rid of the thread-per-queue restriction that the `ThreadPoolExecutor` solution suffers. SDL iOS already uses `NSOperationQueue` to manage queuing operations in the managers which is a similar solution but it handles threads at the OS level.

The proposal suggests adding an API called `getTaskmaster()` to the `Isdl` interface which allows all managers to access the same `Taskmaster` instance:

```
public interface ISdl {
    ...

    Taskmaster getTaskmaster();
}
```    

Each manager that uses queues can create its own queue using the `Taskmaster` instance and add operations to the queue to be executed it order:

```
class ChoiceSetManager {
    Queue operationQueue;

    ChoiceSetManager (){
        operationQueue = internalInterface.getTaskmaster().createQueue("operationQueue", 1, false);
        ...
    }

    void preloadChoices(@NonNull List<ChoiceCell> choices, @Nullable final CompletionListener listener) {
        ...
        PreloadChoicesOperation preloadChoicesOperation = new PreloadChoicesOperation("preloadChoicesOperation");
        operationQueue.add(preloadChoicesOperation, false);
        ...
    }
}
```

Each operation can extend `Task` class from [`TaskMaster`](https://github.com/livio/Taskmaster) and implement the operation logic in the `onExecute()` callback. [`TaskMaster`](https://github.com/livio/Taskmaster) will take care of running that logic when it finishes running all previous operations in the queue:

```
class PreloadChoicesOperation extends Task {
    @Override
    public void onExecute() {
        // Do work here
    }
}
```

## Potential downsides

This proposal will add a dependency to the SDL Java Suite library. However, because the dependency is created and managed by the SDL Project maintainer, any updates or compatibility issues should be made as needed.

## Impact on existing code

Changes to SDL Java Suite:

* Add [`TaskMaster`](https://github.com/livio/Taskmaster) as a dependency in the SDL Java Suite library
* Start using [`TaskMaster`](https://github.com/livio/Taskmaster) to replace the current queuing implementation in `ChoiceSetManager`
* Update `SoftButtonManager` to use queues to simplify its logic and align with iOS

Those changes should not be breaking because they will be only modifying internal logic in the mangers. No public APIs should be modified.

## Alternatives considered

* Keep using `ThreadPoolExecutor` in `ChoiceSetManager` and start using it in a similar way in other managers. This will make each manager have its own thread which is not going to be efficient as the number of managers keep growing
* Avoid using queues in managers. This makes the managers logic more complex when it comes to handle multiple operations that need to run in order. That will also make SDL iOS and SDL Java Suite not aligned as the iOS library is already using queues in multiple managers