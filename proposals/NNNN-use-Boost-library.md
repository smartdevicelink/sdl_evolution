# Use Boost library in SDL

* Proposal: [SDL-NNNN](NNNN-use-Boost-library.md)
* Author: [Alexandr Galiuzov](https://github.com/AGaliuzov)
* Status: **Awaiting review**
* Impacted Platforms: [Core]

## Introduction
Writing proper failover code pledge to success. Automotive industry constantly focused on code quality and application performance. Usually development process consists of writing all kind of utilities, helper classes and local frameworks in order to have a good basis for the business logic implementation. A customer is usually cares about certain problem solution rather than whole bunch of helper utilities. But because of lack of ready solutions, developers had to reinvent the wheel over and over again. It certainly leads to increase of the number of errors, makes support harder and production code unstable. So the support becomes more expensive and solutions release rarely fit in time especially on early developments stages.
Unfortunately by default pre `C++11` does not have ready solutions for daily routine i.e file system, threads and memory management. There is a Qt library which has a lot of useful features out of the box but at the same time it is quite hard to adopt this library to the already existed project which uses iso c++ and has significant codebase. Another solution is the Boost library.

## Motivation
From time to time we’re facing with different problems with our [Utils](https://github.com/smartdevicelink/sdl_core/tree/master/src/components/utils/include/utils) module - threads, timers, file system.
* We've faced with different issues during porting to Windows platform because items mentioned above were designed in platform specific manner. We had to refactor existing architectural solutions, invent workarounds to fix platform/compiler specific issues.
* All the time we have to solve customer’s problems very fast and we have no enough time for current utilities adaptation. Usually it much faster to develop necessary functionality from the scratch. But such approach brings us new defects, waste our time to support and improve this functionality. 

## Proposed solution
The porposed solution which has to adress mentioned issues is to use [Boost library](http://www.boost.org/users/history/version_1_62_0.html)
* The way to solve the issue is to use Boost library. It supports dozens of platforms out of the box, even with ancient compilers.
* The Boost license encourages both commercial and non-commercial use. The Boost license permits the creation of derivative works for commercial or non-commercial use with no legal requirement to release your source code. Other differences include Boost not requiring reproduction of 	copyright messages for object code redistribution, and the fact that the Boost license is not "viral": if you distribute your own code along with some Boost code, the Boost license applies only to the Boost code (and modified versions thereof); you are free to license your own code under any terms you like. The GPL is also much longer, and thus may be harder to understand.
* The proposed version of the Boost library is 1.62
##### Benefits
* Boost proves itself as a stable well designed and tested solution. Boost uses iso c++. This library contains dozens of production ready solutions which could be used by developers during their daily routine without any fear to fail a release due to minor error in the hand-written algorithm. Today some of Boost’s utilities became a part of `C++11`: smart pointers, threads, bindings and much more. Although there are a lot of useful utilities which currently accessible only in Boost: filesystem, various algorithms, asynchronous IO, network.
* Boost used by millions developers in the whole world and exactly this fact makes this library stable and well tested. It works on all mainstream platforms which allows to avoid problem with porting and cross platform development.
* Performance - Boost has solid async api framework. We can remove dozens threads which are usually slow down the system’s performance
* Boost helps to avoid wheel reinvention and concentrate mainly on the features implementation instead of proper background for them.
* Boost helps to reduce cost of support: most of hard-to-fix defects are related to all kinds of utilities and platform specific parts.
* Quality. SDL project will utilize library which is developed/tested by hundreds of developers around the world.
* Officially Boost support big number of platforms and compilers 
  * QNX QCC: 4.2.1 - we use this one to build code for PASA delivery
  * Windows(XP, Vista, 7, CE) with Visual C++: 12.0, 11.0, 10.0, 9.0
  * Linux. Clang: 3.0+. GCC: 4.2+
  * OS X Clang: 3.0+
  * Unofficially Boost supports Android: https://svn.boost.org/trac/boost/ticket/7833
  * There is even more information on the [Boost official suite](http://www.boost.org/users/history/version_1_56_0.html)
* Boost library supports `C++11` standard . It enables some useful features/API  if `C++11` is available. And in the same time using the Boost we can prepare good basis for migration to the `C++11` in case of necessity.
* Some Boost’s features which are delivered as header-only libraries and thus have no any additional dependencies could be easily ported to some rare platforms (Solaris, AIX)
* Boost is well known among c++ developers. So usage of it will decrease the entrance threshold for new developers. The ones who have some experience will not have to study project specific tools.

## Potential downsides
This is additional dependency which is out of our control. It's not easy to apply possible customization if required - it has to be accepted by Boost community. In the worst case we might fork the whole library and customize it on our own.

## Impact on existing code
This proposal is not geared to provide any changes to the existed code. It rather allows to share the common idea is how greate to have such library as Boost. Once it will be accepted there some number of separate proposals will be created. One proposal for one improvement using the Boost library.
* Change thread managment in SDL.
* Use the filesystem api from the Boost instead of one developed within SDL.
* Substitute SDL's timers with Boost analog.
* Substitute SDL's `DateTime` with Boost analog 

## Alternatives considered
The one alternative is to continue to implement any utility we need manually.
Another alternative is to use Qt framework, but the drawbacks regarding this approach are mentioned above.
