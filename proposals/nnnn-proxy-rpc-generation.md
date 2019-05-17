# Proxy Library RPC Generation

* Proposal: [SDL-NNNN](NNNN-proxy-rpc-generation.md)
* Author: [SDL Developer](https://github.com/joeljfischer)
* Status: **Awaiting review**
* Impacted Platforms: [iOS / Java Suite]

## Introduction
This proposal adds automatic RPC generation for iOS and Java from the XML spec via a python script.

## Motivation
Adding RPCs is currently difficult. Every RPC to be added requires hand-writing each parameter, then review, and then unit testing. This makes large RPC changes very difficult, and at times, error-prone. Beyond that, alterations to the RPC classes require an enormous amount of work due to the number of RPCs that already exist – in addition to the problems of code duplication. This does not happen often, but it does happen.

## Proposed solution
The proposed solution is to create python scripts that auto-generate Objective-C and Android code based on a given SDL MOBILE_API XML spec. This allows us to generate new Obj-C and Android classes whenever the XML spec changes, and to update the script whenever the classes themselves need to change.

The script should take a `MOBILE_API` XML spec as input. The script should then output a folder of RPC classes.

### Implementation Notes
1. The spec is not currently housed within the library. Therefore the spec will need to be fed into the script (i.e. the spec should not be auto-downloaded or stored in the library repository but should be an input to the script).
2. This proposal is left intentionally ambiguous regarding implementation details of the scripts. I wish to leave implementation details up to the author(s) of the scripts.
3. The different platform scripts should be very similar outside of the actual code that's generated (e.g. file system code and XML parsing code should be nearly identical).

## Potential downsides
1. Creating the generator scripts may take longer than simply handwriting, reviewing, and unit testing any particular RPC change. However, in the long run, the time savings will be significant.
2. We would still need to handwrite unit tests for the generated RPC classes. In the future, another proposal could be written to cover auto-generation of RPC test cases.
3. The generator could produce bad RPC classes, however, the library authors will ensure that this is not the case and that the generated code matches what already exists.

## Impact on existing code
There should be no API changes. 

## Alternatives considered
1. The author considered other scripting languages, but chose Python because the RPC Spec Markdown parser and generator is written in Python (and therefore we should already have a starting point), and because Python is a general purpose language that comes pre-installed on many operating systems.