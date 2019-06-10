# Proxy Library RPC Generation

* Proposal: [SDL-0234](0234-proxy-rpc-generation.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Accepted with Revisions**
* Impacted Platforms: [iOS / Java Suite]

## Introduction
This proposal adds automatic RPC generation for iOS and Java from the XML spec via a python script.

## Motivation
Adding RPCs is currently difficult. Every RPC to be added requires handwriting each parameter, then review, and then unit testing. This makes large RPC changes very difficult, and at times, error-prone. Beyond that, alterations to the RPC classes require an enormous amount of work due to the number of RPCs that already exist – in addition to the problems of code duplication. This does not happen often, but it does happen.

## Proposed solution
The proposed solution is to create python scripts that auto-generate Objective-C and Android code based on a given SDL MOBILE_API XML spec. This allows us to generate new Obj-C and Android classes whenever the XML spec changes, and to update the script whenever the classes themselves need to change.

The script should take a `MOBILE_API` XML spec as input and a location to output. The script will then output the RPC files at that location.

### Implementation Notes
1. The spec is not currently housed within the library. Therefore the `rpc_spec` repository will be pulled into each library repository as a submodule. The `MOBILE_API` in the `rpc_spec` submodule will be the version used by the script to output the RPC files.
2. This proposal is left intentionally ambiguous regarding implementation details of the scripts. I wish to leave implementation details up to the author(s) of the scripts. However, the command-line switches should be identical between implementations.
3. The different platform scripts should be very similar outside of the actual code that's generated (e.g. file system code and XML parsing code should be nearly identical).
4. The author(s) of these scripts should use the `rpc_spec` markdown generator as a base.

## Potential downsides
1. Creating the generator scripts may take longer than simply handwriting, reviewing, and unit testing any particular RPC change. However, in the long run, the time savings will be significant.
2. We would still need to handwrite unit tests for the generated RPC classes.
3. The generator could produce bad RPC classes, however, the library authors will ensure that this is not the case and that the first version of the generated code matches what already exists, and the unit tests will continue to pass.

## Impact on existing code
There should be no API changes. 

## Alternatives considered
1. The author considered other scripting languages, but chose Python because the RPC Spec Markdown parser and generator is written in Python (and therefore we should already have a starting point), and because Python is a general purpose language that comes pre-installed on many operating systems.
