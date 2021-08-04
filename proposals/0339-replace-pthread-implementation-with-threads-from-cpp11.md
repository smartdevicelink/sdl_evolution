# Replace `thread::Thread` implementation with `std::thread` from C++11

* Proposal: [SDL-0339](0339-replace-pthread-implementation-with-threads-from-cpp11.md)
* Author: [Vadym Luchko](https://github.com/VadymLuchko)
* Status: **Returned for Revisions**
* Impacted Platforms: [Core]

## Introduction

The proposal's main idea is to remove the platform-specific threads functionality covered by the C++11 standard threads from SDL Core.

## Motivation

The latest version of SDL Core utilizes the pthread library to manage threads.

This code and library was introduced due to the limitation of the C++ standard at that period of time. The currently supported version of the C++ standard in SDL Core is C++11, which contains similar functionality to manage the threads in a common way for most of the platforms.

At the same time, the approaches defined in the C++11 standard are well known for most developers around the world.

The main idea for this proposal is to replace the 3rd party libraries and the list of wrappers for the thread management with the approaches defined in the C++11 standard. The mentioned changes shouldn't affect the functionality of SDL Core, should improve portability in general, simplify the support of the project due to the standard approaches, and minimize the list of dependencies.


## Proposed solution

As mentioned in the previous section, the changes introduced to the project shouldn't affect the functionality. They should mostly be done to replace the non-standard functionally, as in the example below.

The current implementation is represented with the current class `UsbHandler`:

```
class UsbHandler {
public:
  UsbHandler::UsbHandler() {
    thread_ = threads::CreateThread("UsbHandler", new UsbHandlerDelegate(this));
  }
	
private:

  void DoSomething() {...}

  class UsbHandlerDelegate : public threads::ThreadDelegate {
  public:
    void threadMain() {
      handler_->DoSomething();
    }
    void exitThreadMain() OVERRIDE;

  private:
    UsbHandler* handler_;
  };

  threads::Thread* thread_;
};
```
As the result of the changes, the same class should be changed to the class with the same functionality but with a simpler structure without delegate classes, raw pointers, complicated callbacks, and any 3rd party dependencies:

```
class UsbHandler {
public:
  UsbHandler::UsbHandler() {
    thread = std::thread([](){DoSomething();});
  }
	
private:
  void DoSomething() {...}

  std::thread thread_;
};
```


## Potential downsides

C++11 provides no equivalent to `pthread_cancel(pthread_t thread)`.
As an option to resolve this issue, we can add some `cancellation_token` to thread attributes which contains a sign that the thread has been cancelled.


Here is an simplified example of how SDL Сore will implement stopping threads:
```
/*   Cancellation Token Class  */

class CancellationToken {
public:
  CancellationToken() : _cancelled(false) {}
  operator bool() const { return !_cancelled; }
  void cancel() { _cancelled = true; }
private:
  std::atomic<bool> _cancelled;
};

/*  Thread Wrapper Class */

class ThreadWrapper {
protected:
  std::thread _thread;
  CancellationToken _token;

  void Reset() {
    if (!_thread.joinable())
      return;

    _token.cancel();
    _thread.join();
  }

public:
  ThreadWrapper() = default;

  template <typename Delegate, typename... Args>
  void Start(Delegate &&delegate, Args... args) {
    _thread = std::thread(delegate, args..., std::ref(_token));
  }

  void Stop() {
    Reset();
  }

  ~ThreadWrapper() { Reset(); }
};

/*    Test Class Using Thread Wrapper  */

class UsbHandler : public ThreadWrapper {
public:
  void Init() {
    Start([](CancellationToken &token) {
      while (token) {
        ....
      }
    });
  }
};

/*    Usage   */
void Test() {
  UsbHandler uh;
  uh.Init();

  std::this_thread::sleep_for(std::chrono::seconds(5));
  uh.Stop();
}
```

Pthreads provides control over the size of the stack of created threads; C++11 standard threads does not address this issue.
However in SDL Core we don't need to specify a stack size since the default stack size meets SDL Core requirements.


## Impact on existing code
The thread approach of SDL Core will be impacted. Removing the current thread implementation, delegate classes, and public methods will be done. Therefore, a major version change of SDL Core is required.


## Alternatives considered
Alternatively, we can use platform-specific approaches (pthread on POSIX and win thread on Windows) or numerous wrappers like Boost.Thread, Dlib, OpenMP, OpenThreads etc.
