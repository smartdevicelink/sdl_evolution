# Use Boost library in SDL

* Proposal: [SDL-0044](0044-use-Boost-library.md)
* Author: [Alexandr Galiuzov](https://github.com/AGaliuzov)
* Status: **Accepted**
* Impacted Platforms: [Core]

## Introduction
Writing proper failover code pledge to success. Automotive industry constantly focused on code quality and application performance. Usually development process consists of writing all kind of utilities, helper classes and local frameworks in order to have a good basis for the business logic implementation. A customer is usually cares about certain problem solution rather than whole bunch of helper utilities. But because of lack of ready solutions, developers had to reinvent the wheel over and over again. It certainly leads to increase of the number of errors, makes support harder and production code unstable. So the support becomes more expensive and solutions release rarely fit in time especially on early developments stages.
Unfortunately by default pre `C++11` does not have ready solutions for daily routine i.e file system, threads and memory management. There is a Qt library which has a lot of useful features out of the box but at the same time it is quite hard to adopt this library to the already existed project which uses iso c++ and has significant codebase. Another solution is the Boost library.

## Motivation
From time to time we’re facing with different problems with our [Utils](https://github.com/smartdevicelink/sdl_core/tree/master/src/components/utils/include/utils) module - threads, timers, file system.
* We've faced with different issues during porting to Windows platform because items mentioned above were designed in platform specific manner. We had to refactor existing architectural solutions, invent workarounds to fix platform/compiler specific issues.
* All the time we have to solve customer’s problems very fast and we have no enough time for current utilities adaptation. Usually it much faster to develop necessary functionality from the scratch. But such approach brings us new defects, waste our time to support and improve this functionality. 

## Proposed solution
The proposed solution which has to address mentioned issues is to use [Boost library v1.56](http://www.boost.org/users/history/version_1_56_0.html)
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
  * QNX QCC: 4.2.1 - default for QNX SDK v6.5
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
Every utility component such as `Thread`, `Filesystem`, `DateTime`, `Timer` should be changed. As the good example of the possible changes propose to start from the `Filesystem` component. Below you can find the current implementation
```c++
size_t file_system::DirectorySize(const std::string& path) {
  size_t size = 0;
  int32_t return_code = 0;
  DIR* directory = NULL;
#ifndef __QNXNTO__
  struct dirent dir_element_;
  struct dirent* dir_element = &dir_element_;
#else
  char* direntbuffer = new char[offsetof(struct dirent, d_name) +
                                pathconf(path.c_str(), _PC_NAME_MAX) + 1];
  struct dirent* dir_element = new (direntbuffer) dirent;
#endif
  struct dirent* result = NULL;
  struct stat file_info = {0};
  directory = opendir(path.c_str());
  if (NULL != directory) {
    return_code = readdir_r(directory, dir_element, &result);
    for (; NULL != result && 0 == return_code;
         return_code = readdir_r(directory, dir_element, &result)) {
      if (0 == strcmp(result->d_name, "..") ||
          0 == strcmp(result->d_name, ".")) {
        continue;
      }
      std::string full_element_path = path + "/" + result->d_name;
      if (file_system::IsDirectory(full_element_path)) {
        size += DirectorySize(full_element_path);
      } else {
        stat(full_element_path.c_str(), &file_info);
        size += file_info.st_size;
      }
    }
  }
  closedir(directory);
#ifdef __QNXNTO__
  delete[] direntbuffer;
#endif
  return size;
}

std::vector<std::string> file_system::ListFiles(
    const std::string& directory_name) {
  std::vector<std::string> listFiles;
  if (!DirectoryExists(directory_name)) {
    return listFiles;
  }

  int32_t return_code = 0;
  DIR* directory = NULL;
#ifndef __QNXNTO__
  struct dirent dir_element_;
  struct dirent* dir_element = &dir_element_;
#else
  char* direntbuffer =
      new char[offsetof(struct dirent, d_name) +
               pathconf(directory_name.c_str(), _PC_NAME_MAX) + 1];
  struct dirent* dir_element = new (direntbuffer) dirent;
#endif
  struct dirent* result = NULL;

  directory = opendir(directory_name.c_str());
  if (NULL != directory) {
    return_code = readdir_r(directory, dir_element, &result);

    for (; NULL != result && 0 == return_code;
         return_code = readdir_r(directory, dir_element, &result)) {
      if (0 == strcmp(result->d_name, "..") ||
          0 == strcmp(result->d_name, ".")) {
        continue;
      }

      listFiles.push_back(std::string(result->d_name));
    }

    closedir(directory);
  }

#ifdef __QNXNTO__
  delete[] direntbuffer;
#endif
  return listFiles;
}
```

There are number of obvious problems in the code above
1. Manual heap allocation could lead to the memory leaks.
2. Some differences in code for QNX and Linux.(Usage of `#ifdef`'s). It could be even more differences in case of porting, for example, to Windows.
3. Hand-made recursive algorithm to iterate through the directories. Usually such algorithms could be the sources of the hard identified bugs.

With the Boost library the code could be significantly simplified. See the snipet below
```c++
using boost::filesystem;
int directory_size(const std::string& path) {
  int size = 0;
  for (auto& entry : boost::make_iterator_range(recursive_directory_iterator(path), {})) {
    boost::system::error_code error;
    size += file_size(entry.path(), error);
  }
  return size;
}

std::vector<std::string> ListFiles(const std::string& path) {
  std::vector<std::string> files;
  recursive_directory_iterator end;
  std::transform(recursive_directory_iterator(path), end, std::back_inserter(files),
                 [](const directory_entry& dir_entry) {
                   return dir_entry.path().c_str();
                 });

  return files;
}
```

The advantages are quite obvious:

1. There is just a couple of lines
2. No hand-made algorithms reduce the possibility to have the hard identified bugs.
3. Work with all platforms supporting by Boost (Linux, Windows, QNX, etc.)

## Alternatives considered
The one alternative is to continue to implement any utility we need manually.
Another alternative is to use Qt framework, but the drawbacks regarding this approach are mentioned above.
