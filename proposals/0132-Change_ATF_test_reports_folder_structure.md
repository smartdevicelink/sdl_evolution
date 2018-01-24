# Change ATF test reports folder structure

* Proposal: [SDL-0132](0132-Change_ATF_test_reports_folder_structure.md)
* Author: [Irina Getmanets](https://github.com/GetmanetsIrina)
* Status: **In Review**
* Impacted Platforms: Core

## Introduction

Main output of ATF is test reports.
ATF provide such reports:
* Console logs - name of test cases with execution status FAILED/PASSED.
* SDL logs - SDL log received by ATF via telnet logger.
* Transport logs -  all received and sent data from/to SDL. Transport log can have default view - messages on protocol level (except binaries) and full view - log will be expanded with packages: streamings, service messages, heartbeat, json files.   
* Detailed report - all expected and sent massages related to test cases with expected and actual result.Also contains info about test cases: name, time, sequence, status, duration.

This proposal is about creating clear and useful structure of test scripts reports.

## Motivation

Create more convenient reports structure, less nested. Running multiple test scripts should not override old reports. Structure of reports should be clear, so you can easily search for a certain report.

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
