# Proxy Library RPC Generation

* Proposal: [SDL-0234](0234-proxy-rpc-generation.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Accepted with Revisions**
* Impacted Platforms: [ Core / iOS / Java Suite / JavaScript / RPC ]

## Introduction
This proposal adds automatic RPC generation for iOS and Java from the XML spec via a python script.

## Motivation
Adding RPCs is currently difficult. Every RPC to be added requires handwriting each parameter, then review, and then unit testing. This makes large RPC changes very difficult, and at times, error-prone. Beyond that, alterations to the RPC classes require an enormous amount of work due to the number of RPCs that already exist – in addition to the problems of code duplication. This does not happen often, but it does happen.

## Proposed solution
The proposed solution is to create python scripts that auto-generate Markdown, C++, Objective-C, Android/Java and JavaScript code based on a given SDL MOBILE_API XML spec. This allows us to generate new content whenever the XML spec changes, and to update the script whenever the classes themselves need to change.

The script should take a `MOBILE_API` XML spec as input and a location to output. The script will then output the RPC files at that location.

### Implementation Notes
1. The spec is not currently housed within the library. Therefore the `rpc_spec` repository will be pulled into each library repository as a submodule. The `MOBILE_API` in the `rpc_spec` submodule will be the version used by the script to output the RPC files. Following repositories should include `rpc_spec`:

    `sdl_core`, `sdl_java_suite`, `sdl_ios`, `sdl_javascript_suite`

2. This proposal is left intentionally ambiguous regarding implementation details of the scripts. I wish to leave implementation details up to the author(s) of the scripts. However, the command-line switches should be identical between implementations. See "Command-line switches" section for details.
3. The different platform scripts should be very similar outside of the actual code that's generated (e.g. file system code and XML parsing code should be nearly identical).
4. The author(s) of these scripts should use the `sdl_core` [InterfaceGenerator](https://github.com/smartdevicelink/sdl_core/blob/master/tools/InterfaceGenerator) as a base. 

    This base should be refactored with regards to code structure to improve the code quality and readability. Inline documentation should also be added to the scripts.

    The generator scripts of the `InterfaceBuilder` that already creates code for Core should be refactored to use parser scripts from `rpc_spec` instead.
    
5. The generator code that creates the library code should be located in the library repository. 
6. The parser code that parses the `MOBILE_API` should be located in the `rpc_spec` repository. It will be included into the library repositories due to the submodule reference. This should help maintaining the parser code.
7. The `rpc_spec` repository should include generator scripts that can generate the README.md file for the GitHub repository.
8. the `rpc_spec` repository should include an XSD file that defines the MOBILE_API XML file and relationship of the XML elements. _(Note: A PR already exists for the rpc_spec repository which includes a reverse engineered XSD file. see https://github.com/smartdevicelink/rpc_spec/pull/202)_.
9. The parser code that parses the MOBILE_API should use the XSD file to verify the integrity of the XML.
10. The generator scripts are dependent on the parser scripts, therefore the generator scripts should import the parser scripts and call the parser functions.
11. Both, the generator and parser scripts should be versioned with only a major version number. The version number should be stored as a number in a variable. Changes to the scripts should match with the major version, especially when the change impacts the interface of the parser scripts. Patch-like changes like a bugfix should not require a version bump.
12. The generator script should compare the own version number with the version number of the parser script. If the version number does not match, the generator script should print an error message and stop the execution. This increases maintenance time but introduces a security check to make sure both sides are kept up-to-date. Following cases can cause a version mismatch:
    
    The generator script is updated to meet a new MOBILE API feature, but the submodule reference is not updated

    The submodule reference was updated but the parser scripts are not up-to-date

    The submodule reference was updated with more recent parser scripts but the generator scripts are not updated

13. Python 2 support ends in 2020. Therfore, all python scripts should be developed for Python 3. This includes scripts from the InterfaceBuilder that will be refactored.

### Command-line switches

The command-line switches of all generator scripts should be identical. Following list of command-line switches is proposed:

- `<input-file>` - required, should point to `MOBILE_API.xml` and be provided to and used by the parser scripts.
- `<output-directory>` - required, define the place where the generated output should be placed.
- `[<regex-pattern>]` - optional, only elements matched with defined regex pattern will be parsed and generated, if present
- `--help, -h` - print the help information and exit
- `--version, -v` - print the version and exit
- `--verbose` - display additional details like logs etc.
- `--enums, -e, --structs, -s, --functions, -f` - only specified elements will be generated, if present
- `--overwrite, -y` - force overwriting of existing files in the output directory, ignore confirmation message
- `--skip, -n` - skip overwriting of existing files in the output directory, ignore confirmation message



## Potential downsides
1. Creating the generator scripts may take longer than simply handwriting, reviewing, and unit testing any particular RPC change. However, in the long run, the time savings will be significant.
2. We would still need to handwrite unit tests for the generated RPC classes.
3. The generator could produce bad RPC classes, however, the library authors will ensure that this is not the case and that the first version of the generated code matches what already exists, and the unit tests will continue to pass.

## Impact on existing code
There should be no API changes. 

## Alternatives considered
1. The author considered other scripting languages, but chose Python because the RPC Spec Markdown parser and generator is written in Python (and therefore we should already have a starting point), and because Python is a general purpose language that comes pre-installed on many operating systems.
