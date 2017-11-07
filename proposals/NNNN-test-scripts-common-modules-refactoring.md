# Test Scripts - Refactoring of Common modules

* Proposal: [SDL-NNNN](NNNN-test-scripts-common-modules-refactoring.md)
* Author: [Dmytro Boltovskyi](https://github.com/dboltovskyi)
* Status: **Awaiting review**
* Impacted Platforms: [ATF]

## Introduction

ATF Test Scripts use a lot of commonly used functions. Such as:

  - data accessors: file, database
  - functions for tables: print, copy
  - sequences:
    - create mobile session
    - register/activate mobile application
    - perform policy table update
  - etc.

The purpose of this proposal is to clean up these common modules.

## Motivation

Current downsides of common modules are:

  - There is no clear structure
  - Lack of description for huge amount of functions
  - There is no single standard for the functions
  - Some functions are duplicated
  - A lot of outdated and unused code

## Proposed solution

### Leave existing modules as is

By leaving all existing modules currently located in ./user_modules folder as is
it will be possible to use all existing ATF test scripts without changes.

### Design a standard template for functions

Each function in common modules should follow a template. E.g.:

```lua
--[[ @jsonFileToTable: convert .json file to table
--! @parameters:
--! pFileName - input file name
--! @return: table with data
--]]
local function jsonFileToTable(pFileName)
  local f = io.open(pFileName, "r")
  local content = f:read("*all")
  f:close()
  return json.decode(content)
end
```

### Create new folders structure

In test scripts repository create the following folders structure:

```
  ./common_modules/
          utils/
          sequences/
```

  - utils - folder for modules with utility functions (e.g.: data accessors, table functions, data converters, etc.)
  - sequences - folder for modules with common sequences (e.g.: register/activate mobile application, policy update, put file, etc.)

TBD: Names of the module files.

### Transfer most used common functions into a new folder

Most used functions needs to be transferred from existing "user_modules" to a new "common_modules" folder in appropriate module file.
And they also need to be updated according to a new template.
A few functions can be placed in one module file.

TBD: Define module file for each function.

### Follow new approach when developing new ATF test scripts

  - In newly created ATF scripts use only functions from new "common_modules" folder and not from an old "user_modules" one
  - If some utility or common sequence function doesn't exist create it in a new "common_modules" in appropriate module file using standard template

## Potential downsides

Existing ATF test scripts may need to be updated if some function from new common modules is required.

## Impact on existing code

Since new common modules is going to be implemented in a new separate folder there will be no impact on existing code.

## Alternatives considered

Use current approach.

