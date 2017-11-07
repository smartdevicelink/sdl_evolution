# Change ATF test reports folder structure

* Proposal: [SDL-NNNN](NNNN-Change_ATF_test_reports_folder_structure.md)
* Author: [Irina Getmanets](https://github.com/GetmanetsIrina)
* Status: **Awaiting review**
* Impacted Platforms: ATF

## Introduction

For now ATF reports folder has inconvenient nested structure. ATF creates structure of folders from relative path to script, e.g. runned script fom test_scripts/API/Navidation/Subscriptions/.
With current implementation will be created the next structure
<pre><code>
TestingReports
  ->ATF_timestamp
    ->test_scripts
      ->API
      	->Navigation
	  ->Subscriptions
  ->SDL_timestamp
    ->test_scripts
      ->API
      	->Navigation
	  ->Subscriptions
  ->Reports_timestamp
    ->test_scripts
      ->API
      	->Navigation
	  ->Subscriptions
</pre></code>

## Motivation

Create more convenient reports structure, less nested.

## Proposed solution

The solution is to create new structure:
<pre><code>TestingReports
	-> ScriptName_timestamp
		-> ATF
		-> SDL</pre></code>
Subfolder ATF will contain ATF logs and report.
Subfolder SDL will contain SDL logs.

## Potential downsides

n/a

## Impact on existing code

Impact on ATF reporting functionality.

## Alternatives considered

n/a
