# Change ATF test reports folder structure

* Proposal: [SDL-NNNN](NNNN-Change_ATF_test_reports_folder_structure.md)
* Author: [Irina Getmanets](https://github.com/GetmanetsIrina)
* Status: **Awaiting review**
* Impacted Platforms: ATF

## Introduction

Main output of ATF is test reports.
ATF provide such reports:
* Console logs
* SDL logs
* Transport logs
* Detailed report

This proposal is about creating clear and useful structure of test scripts reports.

## Motivation

Create more convenient reports structure, less nested. Multiple running of test script should not override old reports. Structure of reports should be clear for easy searching certain report.

## Proposed solution

The solution is to create new structure:
```
TestingReports
	-> ScriptName_YYYYMMDDHHMMSS
		-> ATF
		-> SDL 
```
Subfolder ATF will contain ATF logs and report.
Subfolder SDL will contain SDL logs.

## Potential downsides

n/a

## Impact on existing code

Impact on ATF reporting functionality.

## Alternatives considered

Leave as is.
