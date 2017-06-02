# Use boost library. Technical part.

* Proposal: [SDL-NNNN](NNNN-use-boost-library-technical-part.md)
* Author: [Aleksandr Galiuzov](https://github.com/AGaliuzov)
* Status: **Awaiting review**
* Impacted Platforms: [Core]

## Introduction
This proposal is the technical continuation for the proposal [#44](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0044-use-Boost-library.md). It supposed to demonstrate in practice the Boost library advantages over the hand-written algorithms.

## Motivation
The Boost library allows to switch attention to the development of the business logic rather then concentrate on writing
certain helping utilities. To demonstrate the boost advantages over the hand-written function the `FilesSystem` class from SDL has been choosen. The proposal doesn't address all the functions from the class, but it shows how the biggest functions could be reworked to simplify the readability, reduce the code amount and make the code portable without any additional efforts.

## Detailed design
There are two massive functions in SDL's `FileSystem` class: `DirectorySize` and `ListFiles`. Find bellow the current implementation.


#### Code without Boost library
``` c++ using namespace boost::filesystem;
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

There are numbers of possible problems:
1. Manual heap allocation could lead to the memory leaks.
2. Some differences in code for QNX and Linux.(Usage of `#ifdef`s). It could be even more differences in case of porting, for example, to Windows.
3. Hand-made recursive algorithm to iterate through the directories. Usually such algorithms could be the sources of the hard identified bugs.

#### Code using the boost library
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

## Alternatives
No alternatives considered.
