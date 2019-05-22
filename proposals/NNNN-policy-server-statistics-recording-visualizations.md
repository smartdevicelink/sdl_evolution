# SDL Server Statistics Recording & Visualizations

* Proposal: [SDL-NNNN](NNNN-policy-server-statistics-recording-visualizations.md)
* Author: [Nick Schwab](https://github.com/nickschwab), [Cameron Kachur](https://github.com/ckachur)
* Status: **Awaiting review**
* Impacted Platforms: [SDL Server, Core]

## Introduction

The goal of this proposal is to add statistics recording and reporting functionality for policy table updates sent from Core to an SDL Server. Some statistics are already recorded by Core and sent to the associated SDL Server depending on its build configuration, but these statistics are not currently used or utilized by the SDL Server for analysis.

## Motivation

Currently, OEMs using the open-source SDL Server have no insight into the usage patterns of their server(s) and policy table updates. With the introduction of statistics recording and reporting, OEMs would gain the ability to understand which smartphone models are commonly connected to their vehicles, which SDL-enabled applications are the most popular amongst their customers, the distribution of policy table update triggers, and more.

## Proposed solution

### Overview
The proposed solution is to store the statistics data sent from Core to the SDL Server into the SDL Server's Postgres database on a categorical opt-in basis, including the following items:

* Timestamp of the policy table update request (PTU)
* Count of ignition cycles since last PTU
* Odometer reading at the time of the PTU
* A list of enabled SDL apps
* Number of times each app was opened by the user (requires Core update for `PROPRIETARY` mode)
* Number of times each app has made rejected RPC requests (requires Core update for `PROPRIETARY` mode)
* Duration of each app in each HMI level (requires Core update for `PROPRIETARY` mode)
* Device carrier (requires Core update for `PROPRIETARY` mode)
* Device connection type (requires Core update for `PROPRIETARY` mode)
* Device hardware model (requires Core update for `PROPRIETARY` mode)
* Device operating system (requires Core update for `PROPRIETARY` mode)
* Device operating system version (requires Core update for `PROPRIETARY` mode)

Most of these data items are currently only available when Core is running in `EXTERNAL_PROPRIETARY` mode. Therefore, a change in Core is required to support the sending of these attributes - when available - while running in `PROPRIETARY` mode. SDL Server will only record this data if the OEM has enabled the statistics and reporting feature and if the data is present in the policy table update request payload.

The following is an example of data attributes sent by Core in a policy table update request while in `EXTERNAL_PROPRIETARY` mode which must be added to `PROPRIETARY` mode in order to support this proposal:

#### usage_and_error_counts
```
{
  "app_level": {
    "2aa52453-dec2-415f-bacc-2908557e003a": {
      "count_of_user_selections": 0,
      "count_of_rejected_rpc_calls":0,
      "minutes_in_hmi_background": 0,
      "minutes_in_hmi_full": 0,
      "minutes_in_hmi_limited": 0,
      "minutes_in_hmi_none": 0
    }
  }
}
```

#### device_data
```
{
  "1280e3a858d9ab45ed129c2205abb7443eb6797e3fc23f38180879b5090c731f": {
    "carrier": "",
    "connection_type": "BTMAC",
    "hardware": "Pixel",
    "os": "Android",
    "os_version": "8.1.0"
  }
}
```

### Data Storage and Retention
Statistics data will be stored in the SDL Server's existing Postgres database (owned by the OEM) and retained for a period set in the OEM's SDL Server configuration. A daily process will purge statistics older than the defined threshold.

The following SDL Server environment variable configuration options will be available for an OEM to set the data collection and retention:

* `STATISTICS_ENABLED`: (Boolean) Whether or not to record statistics and to render information on the "Statistics" page of SDL Server. Default `false`.
* `STATISTICS_RETENTION_DAYS`: (Integer) The number of days to keep statistics data before purging it from the database. Default `30`.
* `STATISTICS_APPS_ENABLED`: (Boolean) Whether or not to record statistics regarding app usage (data in `usage_and_error_counts` of policy table update). Default `false`.
* `STATISTICS_DEVICE_ENABLED`: (Boolean) Whether or not to record statistics regarding connected user devices (data in `device_data` of policy table update). Default `false`.

### Reporting Interface
A "Statistics" reporting page will be added to the SDL Server user interface containing the following graphs/charts/tables of the analyzed data:

* Number of daily PTUs during the retention period, stacked by the triggering event (miles, days, ignition cycles)
* Percent of PTUs during the retention period caused by miles, days, ignition cycles
* Top device models over the retention period
* Distribution of device operating systems during the retention period
* Distribution of device operating system versions during the retention period
* Top device carriers during the retention period

Additionally, a statistics sub-section will be added to the application review/details page, subject to data availability, to include information such as:

* Aggregate minutes the app is in each HMI level, over the retention period
* Aggregate times the app has been opened by users, over the retention period
* Aggregate count of rejected RPCs, over the retention period

### Default Behavior (opt-in to enable)
By default, statistics recording will be turned off in order to limit I/O throughput to the database. While disabled, the reporting interface will show a "disabled" state. Statistics recording may be turned on via the setting of an SDL Server environment variable.

## Potential downsides
The amount of data collected for statistics may dramatically increase the size of the SDL Server’s Postgres database as well as the I/O throughput depending on the frequency of PTU requests. In consideration of this, statistics recording will be disabled by default to prevent any unexpected load. Additionally, statistics will be purged on a rolling basis - as defined by the OEM in their SDL Server configuration - to limit the maximum amount of disk space consumed by the extra data.

## Impact on existing code

### SDL Server
This change would have no direct impact to existing functionality due to the statistics properties in a Policy Table Update being optional and the parsing of such data would occur without alterations to the PTU response payload. New API endpoints and database tables would be created to accommodate the storage and retrieval of the data to be rendered on the SDL Server dashboard and would have no direct association with existing API endpoints.

### Core
Since the statistics data is already available in `EXTERNAL_PROPRIETARY` mode, there would be minimal impact on existing code to support this functionality while in `PROPRIETARY` mode. The presence of these new data attributes is optional and has no direct impact to existing Core functionality.

## Alternatives considered
In recognition of the additional database load which collecting these statistics may cause, a two-layered system was considered, composed of an in-memory database solution to collect statistics throughout the day and accompanied by a nightly process to write the aggregate statistics to the existing Postgres database. While this would reduce the additional overhead of the primary Postgres database, it would create additional architectural complexity, introduce the risk of data loss in the event of an in-memory storage failure, and result in the loss of granular data records for flexible insights.


