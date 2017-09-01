# Mark public deprecated methods

* Proposal: [SDL NNN](NNNN-NNNN-Deprecated-interfaces-markup.md)
* Author: Alexander Kutsan
* Status: **Awaiting review**
* Impacted Platforms: Core

## Introduction
Public methods is part of SDL interface. New features may use some existing interfaces and expect some behavior. 
Sometimes some features use interfaces that planed to be removed. And after removing interfaces feature can't be released due to conflicts in code.

## Motivation
Marking method as deprecated should trigger a compile time warning, but should not block project assemble.
Reverse feature support plugins that can be created by 3rd party developers.
Each public method should work to handle backward capabilities with other developers plugins code.
Also some classes also can be deprecated and creating instances of this classes should cause compile time warnings also.

## Proposed Solution
Deprecating methods should enough explicit in code and in documentation. 
Each deprecated method should be marked such in documentation page and if this method is used in code, it should trigger compile time warning.
SDL use doxygen for documentation public interfaces, and doxygen support [@deprecated](https://www.stack.nl/~dimitri/doxygen/manual/commands.html#cmddeprecated) command.
In code deprecated metods should be done with macro that will use c++14 [ [[deprecated]] ] (http://en.cppreference.com/w/cpp/language/attributes)
atribute or other featured depends from used compiler and c++ version. 

## Detailed Design

For supporting compile time warning while using deprecated functions can be used such macro :

```cpp
#if __cplusplus > 201103L
#define DEPRECATED [[deprecated]]
#else 
#ifdef __GNUC__
#define DEPRECATED __attribute__((deprecated))
#define DEPRECATED_CLASS __attribute__((deprecated))
#elif defined(_MSC_VER)
#define DEPRECATED __declspec(deprecated)
#else
#pragma message("WARNING: You need to implement DEPRECATED for this compiler")
#define DEPRECATED
#endif
#endif
```

It will generate compile time warning in with c++98 or c++11 or c++14.

### Usage : 

#### C++ Code :
```cpp
DEPRECATED void bar() {}
int main() {
  bar();
}
```

#### Compilers output : 

##### G++ :
```bash
$ g++ --std=c++11 -Werror -Wno-error=deprecated-declarations ./main.cc                            
./main.cc: In function ‘int main()’:
./main.cc:85:5: warning: ‘void bar()’ is deprecated (declared at ./main.cc:19) [-Wdeprecated-declarations]
     bar();
     ^
./main.cc:85:9: warning: ‘void bar()’ is deprecated (declared at ./main.cc:19) [-Wdeprecated-declarations]
     bar();

$  g++ --std=c++98 -Werror -Wno-error=deprecated-declarations ./main.cc 
./main.cc: In function ‘int main()’:
./main.cc:85:5: warning: ‘void bar()’ is deprecated (declared at ./main.cc:19) [-Wdeprecated-declarations]
     bar();
     ^
./main.cc:85:9: warning: ‘void bar()’ is deprecated (declared at ./main.cc:19) [-Wdeprecated-declarations]
     bar();
         ^
```

##### Clang : 
```bash
$ clang --std=c++98 -Werror -Wno-error=deprecated-declarations ./main.cc  
./main.cc:23:5: warning: 'bar' is deprecated [-Wdeprecated-declarations]
    bar();
    ^
./main.cc:19:17: note: 'bar' has been explicitly marked deprecated here
DEPRECATED void bar() {}
                ^
1 warning generated.

$ clang --std=c++11 -Werror -Wno-error=deprecated-declarations ./main.cc  
./main.cc:23:5: warning: 'bar' is deprecated [-Wdeprecated-declarations]
    bar();
    ^
./main.cc:19:17: note: 'bar' has been explicitly marked deprecated here
DEPRECATED void bar() {}
                ^
1 warning generated.
```

Full usage example is available https://github.com/alexkutsan/RnD_fun/blob/master/deprecated/main.cc 

Also doxygen `@deprecated` command should be used for documentation:
```cpp
/**
 * @brief The Y class containt one actual and one deprecated method
 */
class Y {

public:

    /**
     * @brief foo not deprecated function of not deprecated class
     */
    void foo(){}

    /**
     * @brief bar deprecated function of not deprecated class
     * @deprecated
     */
    DEPRECATED int bar(){}
};
```

![Doxygen result](http://i.imgur.com/dFUDtSu.png)                                                                                                                                                                                                                                                    

## Impact on existing code
No changes in behaviour should be introduced. 
In some SDL core methods should be marked as deprecated and using this methods will cause compile time warning

## Alternatives
As alternative it is possible to remove deprecated methods, but it will breake backwardd capablity 
of 3rd party developers code with newer versions of SDL.
$ 
