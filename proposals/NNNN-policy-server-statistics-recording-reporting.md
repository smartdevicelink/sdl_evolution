# Policy Server Statistics Recording & Reporting

* Proposal: [SDL-NNNN](NNNN-policy-server-statistics-recording-reporting.md)
* Author: [Nick Schwab](https://github.com/nickschwab), [Cameron Kachur](https://github.com/ckachur)
* Status: **Awaiting review**
* Impacted Platforms: [Policy Server]

## Introduction

The goal of this proposal is to add statistics recording and reporting functionality for policy table updates sent from Core to a Policy Server. Some statistics are already recorded by Core and sent to the associated Policy Server depending on its build configuration, but these statistics are not currently processed and recorded by the Policy Server for analysis.

## Motivation

Currently, OEMs using the SDLCs open-source Policy Server have no insight into the usage patterns of their server(s). With the introduction of statistics recording and reporting, OEMs would gain the ability to understand which smartphone models are commonly connected to their vehicles, which SDL-enabled applications are the most popular amongst their customers, the distribution of policy table update triggers, and more.

## Proposed solution

### Overview
The proposed solution is to store the statistics data sent from Core to the Policy Server into a database, including but not limited to the following items:
* Timestamp of the policy table update request (PTU)
* Count of ignition cycles since last PTU
* Odometer reading at the time of the PTU
* A list of SDL-enabled apps found on the connected device
* Number of times each app was opened by the user
* Duration of each app in each HMI level
* Device carrier
* Device connection type
* Device hardware model
* Device operating system
* Device operating system version

It is acknowledged that some of these data items are currently only available when Core is running in `EXTERNAL_PROPRIETARY` mode. For this reason, data will only be recorded if it is available in the policy table update request payload. Another evolution proposal may be opened in the future to expand the modes in which Core gathers and sends statistics data.

### Data Storage and Retention
Statistics data will be stored in the Policy Server's existing Postgres database and retained for a period of 30 days. A daily process will purge statistics older than 30 days.

### Reporting Interface
A "Statistics" reporting page will be added to the Policy Server user interface containing graphs of the analyzed data, including but not limited to:
* Number of daily PTUs over past 30 days, stacked by trigger (miles, days, ignition cycles)
* Percent of PTUs in past 30 days caused by miles, days, ignition cycles
* Top device models in past 30 days
* Distribution of device operating systems in past 30 days
* Distribution of device operating system versions in past 30 days 
* Top device carriers in past 30 days

Additionally, a statistics sub-section will be added to the application review/details page, subject to data availability, to include graphs such as:
* Aggregate minutes per day the app is in each HMI level, over past 30 days
* Aggregate times the app has been opened by users per day, over past 30 days
* Aggregate count of rejected RPCs per day, over past 30 days

### Default Behavior
By default, statistics recording will be turned off in order to limit I/O throughput to the database. While disabled, the reporting interface will show a "disabled" state. Statistics recording may be turned on via the setting of a Policy Server environment variable.

## Potential downsides
The amount of data collected for statistics may dramatically increase the size of the Policy Server’s Postgres database as well as the I/O throughput depending on the frequency of PTU requests. In consideration of this, statistics recording will be disabled by default to prevent any unexpected load. Additionally, statistics will be purged on a rolling 30-day basis to limit the maximum amount of disk space consumed by the extra data.

## Impact on existing code
This change would have no direct impact to existing code due to the new statistics parameters in a Policy Table Update being optional (and in many cases are already present in Core’s requests to Policy Servers). In regard to recording the statistics, this logic would occur during a PTU request but would not have any effect on the PTU response payload by the Policy Server.

## Alternatives considered
In recognition of the additional database load which collecting these statistics may cause, we considered proposing a two-layered system composed of an in-memory database solution to collect statistics throughout the day, accompanied by a nightly process to write the aggregate statistics to the existing Postgres database. While this would reduce the additional overhead of the primary Postgres database, it would create additional architectural complexity, introduce the risk of data loss in the event of an in-memory storage failure, and result in the loss of granular data records for flexible insights.


