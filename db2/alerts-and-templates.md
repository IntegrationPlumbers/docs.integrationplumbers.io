---
title: Alerts and templates
nav_order: 10
---

# Alerts, thresholds and templates

This page lists every threshold the plug-in ships, how often each metric group collects, and how to change both. It also covers the three monitoring templates, the incident rule set and configuration drift pieces that ship beside the plug-in, and the six runbooks for common Db2 alerts. It is for the Enterprise Manager administrator who decides what raises an incident and who hears about it.

> **Prerequisites for this page**
> - The plug-in deployed to the OMS and to every agent, and at least one target whose `License` metric reports `Active`. See [Troubleshooting](troubleshooting.md#licence-gate).
> - An Enterprise Manager administrator with access to Metric and Collection Settings.
> - For the templates and the incident rule set: EM CLI, logged in (`emcli login`), on a host that can reach the OMS.

**Where to find it:** metric values under **Target menu → Monitoring → All Metrics**; thresholds and schedules under **Target menu → Monitoring → Metric and Collection Settings**; templates under **Enterprise → Monitoring → Monitoring Templates**; rule sets under **Setup → Incidents → Incident Rules**.

**In this page:** How findings become alerts · Default thresholds · Collection intervals · Tuning thresholds · Licence alerts · Monitoring templates · Duplicate alerts on instance targets · Incident rules, configuration comparison and drift · Runbooks for common alerts · After upgrading from GA

## How findings become alerts {#how-alerts-work}

1. A collection runs on its schedule and emits one row per finding onto the target.
2. Enterprise Manager compares each row's alerting column against that metric's Warning and Critical thresholds.
3. When a threshold is crossed for the required number of consecutive collections, Enterprise Manager raises a metric alert (an event) on the target.
4. Enterprise Manager's out-of-box incident rule set turns a **Critical** metric alert, a target going down, and a drop in a compliance score into an **incident**. A **Warning** stays an event on the target's pages unless a rule set of yours, or the optional [incident rule set](#incident-rules), opens an incident for it.
5. The incident routes through your existing notification rules and connectors.
6. At the next collection after the finding resolves, the alert clears itself.

The plug-in adds no alerting pipeline of its own: every threshold is an ordinary Enterprise Manager metric threshold, with alert history, editable per target or through a template.

## Default thresholds {#default-thresholds}

The plug-in ships **60 default metric thresholds**: 54 on the IBM Db2 Database target and 6 on the IBM Db2 Instance target. Each target type also has one availability condition, the `Status` column of its `Response` metric (Critical when `Status` is not 1), which drives the target's Up and Down state. Every other column ships `Not Defined`: these are raw counters where no default suits every site, and you can set any of them yourself.

To list the thresholds a target carries now, including any you have changed:

```
emcli get_threshold -target_name="<target>" -target_type="ip_db2_database"
emcli get_threshold -target_name="<instance target>" -target_type="ip_db2_instance"
```

### IBM Db2 Database target (54)

An empty cell means that level ships no value. Occurrences is the number of consecutive collections that must breach before the alert opens.

| Area | Metric group | Column | Operator | Warning | Critical | Occurrences |
| :--- | :--- | :--- | :---: | :--- | :--- | :---: |
| Status | `DetailedResponse` | `db_status` | ≠ | `ACTIVE` | | 1 |
| Status | `DetailedResponse` | `db2_status` | matches | `QUIESCE_PEND` or `QUIESCED` | | 1 |
| Status | `CollectorStatus` | `Status` | matches | | `COLLECTION_ERROR` | 2 |
| Status | `Monitor_Metrics` | `metrics_off` | matches | anything but `OK` | | 1 |
| Licence | `License` | `license_severity` | ≥ | 1 | 2 | 1 |
| Licence | `License` | `days_remaining` | < | 30 | 7 | 1 |
| Licence | `Db2_License_Usage` | `feature_use_status` | = | `IN_VIOLATION` | | 1 |
| Locks | `DB_Monitoring` | `average_lock_wait_time` (ms) | > | 1000 | 5000 | 3 |
| Locks | `DB_Monitoring` | `percent_appls_waiting_on_lock` (%) | > | 50 | 70 | 3 |
| Locks | `DB_Monitoring` | `lock_timeouts_rate` (per second) | > | 0.1 | 0.5 | 3 |
| Locks | `DB_Monitoring` | `deadlocks_rate` (per second) | > | 0.05 | 0.2 | 3 |
| Locks | `DB_Monitoring` | `lock_escals_rate` (per second) | > | 0 | 0.01 | 3 |
| Locks | `DB_Monitoring` | `lock_list_utilization` (%) | > | 70 | 85 | 2 |
| Locks | `Oldest_Transactions` | `uow_age_sec` | > | 1800 (30 minutes) | 7200 (2 hours) | 1 |
| Capacity | `DB_Monitoring` | `space_utilization` (%) | > | 80 | 90 | 3 |
| Capacity | `DB_Monitoring` | `connection_utilization` (%) | > | 80 | 90 | 3 |
| Memory | `General_Info` | `sortheap_utilization` (%) | > | 90 | 100 | 3 |
| Memory | `SortHeap` | `sorts_overflow_ratio` | > | 30 | 50 | 3 |
| Memory | `Instance_Memory` | `instance_memory_utilization` (%) | ≥ | 90 | 97 | 3 |
| Memory | `Db_Perf` | `bufferpool_hit_ratio` (%) | < | 90 | 80 | 3 |
| Memory | `Db_Perf` | `bufferpool_data_hit_ratio` (%) | < | 90 | 80 | 3 |
| Memory | `Db_Perf` | `bufferpool_index_hit_ratio` (%) | < | 95 | 85 | 3 |
| Memory | `Cache` | `catalog_cache_hit_ratio` (%) | < | 80 | 70 | 3 |
| Memory | `Cache` | `package_cache_hit_ratio` (%) | < | 80 | 70 | 3 |
| Waits | `Wait_Time` | `wait_time_pct` (% of request time) | > | 60 | 80 | 2 |
| Waits | `Wait_Time` | `lock_wait_pct` (% of request time) | > | 20 | 40 | 2 |
| Waits | `BufferPool_IO_Time` | `avg_sync_read_ms` (ms) | > | 20 | 50 | 2 |
| Waits | `WLM_Service_Classes` | `queue_time_pct` (% of request time) | > | 30 | 60 | 2 |
| Storage | `Tablespace_Storage` | `tablespace_utilization` (%) | > | 80 | 90 | 1 |
| Storage | `Tablespace_Storage` | `tablespace_state` | matches | a fault state (see below) | contains `OFFLINE` | 1 |
| Storage | `Tablespace_Forecast` | `DaysToFull` | < | 30 | 7 | 2 |
| Storage | `Tablespace_Forecast` | `ResizeFailed` | = | | 1 | 1 |
| Storage | `Storage_Paths` | `fs_used_pct` (%) | > | 85 | 95 | 1 |
| Transaction log | `Log_Storage` | `space_utilization` (%) | > | 75 | 85 | 3 |
| Transaction log | `Log_Storage` | `sec_logs_allocated` | > | 0 | | 1 |
| Transaction log | `Log_Archive` | `archive_status` | matches | | `FAILED` | 1 |
| Transaction log | `Log_Archive` | `archive_log_gap` (log files) | ≥ | 5 | 20 | 2 |
| Backup and recovery | `DB_Backup` | `days_since_last_backup` | > | 1 | 3 | 3 |
| Backup and recovery | `DB_History` | `operation_failed` | = | | 1 | 1 |
| Backup and recovery | `Utilities` | `elapsed_sec` | > | 28800 (8 hours) | 86400 (24 hours) | 1 |
| HADR | `HADR_Status` | `HadrConnectStatus` | matches | `CONGESTED` | `DISCONNECTED` | 1 |
| HADR | `HADR_Readiness` | `TakeoverReady` | = | | 0 | 2 |
| HADR | `HADR_Readiness` | `HadrLogGap` (bytes) | > | 10485760 (10 MB) | 104857600 (100 MB) | 3 |
| HADR | `HADR_Readiness` | `RecvReplayGap` (bytes) | > | 10485760 (10 MB) | 104857600 (100 MB) | 3 |
| HADR | `HADR_Readiness` | `ReplayLagSec` | > | 60 | 300 | 3 |
| HADR | `HADR_Readiness` | `StateAlert` | matches | anything but `OK` | | 2 |
| Members | `Member_Status` | `member_active` | = | | 0 | 1 |
| Members | `PureScale_Members` | `severity` | ≥ | 1 | 2 | 1 |
| Members | `PureScale_CFs` | `severity` | ≥ | 1 | 2 | 1 |
| Members | `PureScale_GBP` | `gbp_full_per_min` | > | 1 | | 1 |
| Maintenance | `Table_Maintenance` | `stats_stale_days` | > | 7 | 30 | 1 |
| Maintenance | `Table_Maintenance` | `overflow_pct` (%) | > | 5 | 20 | 1 |
| Maintenance | `Invalid_Objects` | `invalid_count` | > | | 0 | 1 |
| Diagnostics | `Diag_Log_File_Monitoring` | `count` | > | 0 | 3 | 1 |

The `tablespace_state` Warning matches a state that contains any of `OFFLINE`, `STORAGE_MUST_BE_DEFINED`, `RESTORE_PENDING`, `ROLLFORWARD_PENDING`, `DELETE_PENDING`, `DISABLE_PENDING`, `DROP_PENDING`, `LOAD_PENDING` or `SUSPEND_WRITE`. It deliberately leaves out routine transient states, such as an online backup or a rebalance, so it does not warn every night.

### IBM Db2 Instance target (6)

| Metric group | Column | Operator | Warning | Critical | Occurrences |
| :--- | :--- | :---: | :--- | :--- | :---: |
| `Instance_Status` | `db2_status` | matches | `QUIESCE_PEND` or `QUIESCED` | | 1 |
| `License` | `license_severity` | ≥ | 1 | 2 | 1 |
| `License` | `days_remaining` | < | 30 | 7 | 1 |
| `Instance_Memory` | `instance_memory_utilization` (%) | ≥ | 90 | 97 | 3 |
| `Diag_Log_File_Monitoring` | `count` | > | 0 | 3 | 1 |
| `CollectorStatus` | `Status` | matches | | `COLLECTION_ERROR` | 2 |

### Reading the tables

- **Upgrades keep your values.** A threshold value you changed yourself is kept when the plug-in is upgraded.
- **Ratio alerts are per collection interval.** The hit ratios, the sort-overflow ratio and the average lock wait are computed from the change since the previous collection, not from totals since the database was activated. An interval with too little activity to judge reports the healthy value.
- **`Oldest_Transactions` alerts per rank.** Rank 1 is the oldest open transaction of the moment, whichever connection runs it, and the message names the application, handle and user.
- **`Monitor_Metrics`** warns when a `MON_REQ_METRICS`, `MON_ACT_METRICS` or `MON_OBJ_METRICS` switch is `NONE`, which makes Db2 return zeros instead of real metrics. The fix, which takes effect online, is in the alert message: `db2 update db cfg for <database> using MON_REQ_METRICS BASE MON_ACT_METRICS BASE MON_OBJ_METRICS BASE`.
- **`Log_Archive`** on an HADR standby reads `STANDBY`, with a gap of 0, and raises no alert: only the primary archives. Watch archiving on the primary's target.
- **`Diag_Log_File_Monitoring : count`** does not clear when a later collection finds no match. It needs the agent on the Db2 server, as do the local administrative jobs. See [Network and ports](prerequisites.md#network).
- **`Member_Status`** collects on partitioned (DPF) and pureScale databases only, and the three `PureScale_*` groups on pureScale only. On any other target these thresholds have nothing to evaluate. The pureScale groups are implemented and not lab-certified; see [pureScale](metrics-reference.md#purescale).
- **On a target that monitors an HADR standby**, `DetailedResponse : db_status` warns, because a standby reports `STANDBY` (or `ACTIVE_STANDBY` with reads on standby). Set the threshold to the standby's own healthy value; the command is under [Tuning thresholds](#tuning-thresholds). HADR's thresholds, including what `TakeoverReady = -1` means, are explained on [HADR monitoring](hadr-monitoring.md#default-alerts).
- **The lock-wait groups ship no threshold.** `Longest_Lock_Waits`, `Lock_Waits_By_Blocked_App`, `Lock_Waits_By_Blocking_App`, `Lock_Waits_By_Table` and `Blocking_Tree` collect and show on the Locks page without alerting. The Production-critical template adds two of them; see [Monitoring templates](#monitoring-templates).

Each metric group and column is described in the [metrics reference](metrics-reference.md).

## Collection intervals {#collection-intervals}

Each metric group collects on its own schedule, from 5 minutes to 24 hours.

| Interval | IBM Db2 Database target |
| :--- | :--- |
| 5 min | Response, DetailedResponse, CollectorStatus, Oldest_Transactions, Longest_Lock_Waits, Lock_Waits_By_Table, Lock_Waits_By_Blocked_App, Lock_Waits_By_Blocking_App, Blocking_Tree, HADR_Readiness, Member_Status, PureScale_Members, PureScale_CFs |
| 15 min | License, DB_Monitoring, General_Info, Application_Statistics, Appl_Connection, Agent_Connection, Agent_Perf, MemMgr_Perf, SortHeap, Db_Perf, BufferPool, Cache, LogIO, NonBufferedIO, Wait_Time, BufferPool_IO_Time, Latch_Waits, WLM_Workloads, WLM_Service_Classes, Instance_Memory, Log_Archive, Tablespace_Storage, HADR_Status, Utilities, Rebalance_Status, Deadlocks, Query_Analytics, Statement_Text, PureScale_GBP |
| 30 min | Log_Storage, Storage_Paths, Tablespace_Forecast, DB_Backup, Diag_Log_File_Monitoring, Top_Queries_Cpu_Time, Top_Queries_Execution_Count, Index_Activity, FCM_Buffers, Memory_Sets |
| 1 hr | DB_History, Invalid_Objects, Monitor_Metrics, Top_Sessions, readiness_summary |
| 2 hr | Table_Overflow, Table_Properties, Db2_License_Usage |
| 6 hr | Table_Maintenance |
| 24 hr | Unused_Indexes, the configuration snapshot |

| Interval | IBM Db2 Instance target |
| :--- | :--- |
| 5 min | Response, Instance_Status, CollectorStatus |
| 15 min | License, Agent_Connection, Instance_Memory, Active_Databases, Latch_Waits |
| 30 min | Memory_Sets, FCM_Buffers, Diag_Log_File_Monitoring |
| 24 hr | The instance configuration snapshot |

A collection schedule and a threshold are independent. An alert with 3 occurrences on a 30-minute group confirms 1.5 hours after the threshold is first crossed, and lowering a threshold does not make the metric collect more often.

## Tuning thresholds {#tuning-thresholds}

1. From the target home page, choose **Target menu → Monitoring → Metric and Collection Settings**.
2. Set the **View** list to **All metrics** so every group above is included.
3. Find the metric and the column you want. The console shows each column's label; `emcli get_threshold` uses the names in the tables above.
4. Enter values in **Warning Threshold** and **Critical Threshold**. Leave a field empty to switch that level off.
5. Set **Number of Occurrences** to the number of consecutive collections that must breach before the alert opens.
6. To change how often the metric runs, click the metric's **Collection Schedule** link and set a new interval.
7. Click **OK** to save.

A threshold edited this way applies to one target. To set one from EM CLI, for example the `db_status` warning on a target that monitors an HADR standby:

```
emcli modify_threshold -target_name="<standby target>" -target_type=ip_db2_database \
                       -metric=DetailedResponse -column=db_status -warning_threshold=ACTIVE_STANDBY
```

Where a value should hold across many targets, put it in a monitoring template and apply that instead, so the next template you apply does not undo a target-by-target edit.

## Licence alerts {#licence-alerts}

`License` carries two thresholds, on both target types:

- **`license_severity`**: Warning at 1, during the 14-day grace period after the key expires (status `Grace Period`, collection continues), and Critical at 2, for any other status that is not `Active` (collection stops). This is the alert on this page you should not disable, because it is also the signal that a target has stopped collecting almost everything else.
- **`days_remaining`**: Warning at 30 days and Critical at 7 days before the key expires. A key with expiration `Never` has no expiry alert.

After an upgrade from GA, `license_severity` stays empty, and the licence-status alert does not fire, until the OMS is restarted once (`emctl stop oms`, then `emctl start oms`). See [Upgrade notes](upgrade-notes.md#restart-oms). Licence statuses are explained under [Licensing](targets-and-properties.md#licence-statuses); what an unlicensed target looks like is under [Troubleshooting](troubleshooting.md#licence-gate).

## Monitoring templates {#monitoring-templates}

Three monitoring templates for the IBM Db2 Database target type (`ip_db2_database`) ship beside the plug-in, not inside it. Enterprise Manager has no way to package a template inside a plug-in, so importing the OPAR does not install them: you import them into your OMS yourself.

| Template | File | What it sets |
| :--- | :--- | :--- |
| `IP_DB2_Starter_v1` | `ip_db2_monitoring_starter_v1.xml` | 15 of the shipped defaults: availability, log space, table space, backup age, log archiving and HADR. A short base to copy into your own standard. |
| `IP_DB2_Standard_v1` | `ip_db2_monitoring_standard_v1.xml` | The 55 shipped values of the database target (the 54 thresholds above and the availability condition). Applying it puts a target back on the defaults. |
| `IP_DB2_Production_Critical_v1` | `ip_db2_monitoring_production_critical_v1.xml` | The 55, with 20 of them tighter, plus 3 more alerts. It also reads log space every 15 minutes instead of 30. |

The templates name metric groups this release adds, such as `Log_Archive` and `Wait_Time`, so deploy this release to the OMS and the agents before you import them. They replace the GA threshold starter kit, which reverted the shipped `tablespace_state` values when applied. If you applied that kit, apply Starter or Standard to put them back.

### Import and apply

Copy the file to the OMS host, then:

```
emcli import_template -files="/tmp/ip_db2_monitoring_production_critical_v1.xml"
emcli apply_template  -name="IP_DB2_Production_Critical_v1" \
                      -targets="<target>:ip_db2_database"
```

`-files` takes a plain path, or several separated by `;`. In the console: **Enterprise → Monitoring → Monitoring Templates → Import**, then select the template and **Apply**.

- **Applying a template is an Enterprise Manager job.** The values appear in `emcli get_threshold` when the job completes.
- **The templates are additive.** By default (`-replace_metrics=0`) a template changes only the columns it names, and every other threshold on the target stays as it was. Never pass `-replace_metrics=1`: it clears every threshold the template does not name, silently disabling the shipped defaults it leaves out.
- **Check per-key thresholds after you apply.** Whether applying a template replaces a threshold you set for one key (for example one table space) on a column the template names is not verified. Check such a threshold with `get_threshold` and set it again if it changed.
- **Standard does not undo everything Production-critical does.** It restores the 55 shipped values, but leaves Production-critical's 3 extra alerts and its 15-minute log-space schedule in place. Change those in **Monitoring → Metric and Collection Settings**.
- **On an HADR standby target, set `db_status` again after you apply a template.** All three templates set the `ACTIVE` warning; run the `modify_threshold` command under [Tuning thresholds](#tuning-thresholds).
- **Enterprise Manager 13.5:** importing the templates on a 13.5 OMS has not been verified.
- **Early-Access installs only:** `ip_db2_beta_threshold_starter_kit_v1.xml` is for the beta plug-in identity (`ip.em.xdbb`). Its values ship as defaults, so on this plug-in use Starter or Standard.

### What Production-critical changes

| Metric : column | Shipped (W / C) | Production-critical (W / C) |
| :--- | :--- | :--- |
| `Log_Storage : space_utilization` | 75 / 85 % | 60 / 75 % |
| `Log_Storage` collection | every 30 min | every 15 min |
| `Tablespace_Storage : tablespace_utilization` | 80 / 90 % | 75 / 85 % |
| `Tablespace_Forecast : DaysToFull` | < 30 / < 7 days | < 60 / < 14 days |
| `Storage_Paths : fs_used_pct` | 85 / 95 % | 80 / 90 % |
| `DB_Monitoring : space_utilization` | 80 / 90 % | 75 / 85 % |
| `DB_Monitoring : connection_utilization` | 80 / 90 % | 70 / 85 % |
| `DB_Monitoring : lock_list_utilization` | 70 / 85 % | 60 / 75 % |
| `DB_Monitoring : average_lock_wait_time` | 1000 / 5000 ms | 500 / 2000 ms |
| `DB_Monitoring : percent_appls_waiting_on_lock` | 50 / 70 % | 25 / 50 % |
| `DB_Monitoring : lock_timeouts_rate` | 0.1 / 0.5 per second | 0.05 / 0.2 per second |
| `DB_Monitoring : deadlocks_rate` | 0.05 / 0.2 per second, 3 occurrences | any (> 0) / 0.05 per second, 1 occurrence |
| `DB_Monitoring : int_deadlocks_rollbacks_rate` | not set | **added:** any (> 0) / 0.01 per second, 1 occurrence |
| `Longest_Lock_Waits : Duration` | not set | **added:** 30 / 120 seconds, 1 occurrence |
| `Lock_Waits_By_Blocking_App : Duration` | not set | **added:** 120 / 600 seconds total, 1 occurrence |
| `SortHeap : sorts_overflow_ratio` | 30 / 50 | 10 / 25 |
| `General_Info : sortheap_utilization` | 90 / 100 % | 80 / 95 % |
| `Table_Maintenance : stats_stale_days` | 7 / 30 days | 3 / 14 days |
| `Oldest_Transactions : uow_age_sec` | 1800 / 7200 seconds | 600 / 1800 seconds |
| `Utilities : elapsed_sec` | 8 / 24 hours | 4 / 12 hours |
| `HADR_Readiness : ReplayLagSec` | 60 / 300 seconds | 30 / 120 seconds |
| `HADR_Readiness : TakeoverReady` | Critical at 0, 2 occurrences | Critical at 0, 1 occurrence |
| `DB_Backup : days_since_last_backup` | 1 / 3 days | 1 / 2 days |
| `CollectorStatus : Status` | `COLLECTION_ERROR`, 2 occurrences | `COLLECTION_ERROR`, 1 occurrence |

The hit ratios, the HADR byte gaps, the pattern and equality checks, and the thresholds this release adds stay at their shipped values in Production-critical. Hit ratios and wait shares follow the workload's shape, so tightening them alerts on every batch window.

## Duplicate alerts on instance targets {#duplicate-alerts}

The instance-scope groups (`Instance_Memory`, `Agent_Connection`, `FCM_Buffers`, `Latch_Waits`, `Memory_Sets` and `Diag_Log_File_Monitoring`) are collected on both target types. Once you add an IBM Db2 Instance target, one instance-level breach opens an incident on the instance target and on each of its database targets. With five databases, one `Instance_Memory` breach opens six incidents.

Two of those groups ship a threshold on the database target: `Instance_Memory : instance_memory_utilization` and `Diag_Log_File_Monitoring : count`. To stop the duplicates, clear those thresholds on the database targets of instances that have their own target, and keep them on the instance target. A template of your own that names those columns with no Warning and no Critical value does this across many targets; applied with the default `-replace_metrics=0`, it clears only those columns. Apply it after Standard or Production-critical, which set both columns again. See [Duplicate alerts](targets-and-properties.md#duplicate-alerts).

## Incident rules, configuration comparison and drift {#incident-rules}

Three optional pieces ship beside the plug-in, each with an EM CLI script. They change nothing in the plug-in and can be removed again. Enterprise Manager accepts incident rule sets and comparison templates inside a plug-in only from Oracle's own plug-ins, which is why these are separate files.

| Piece | Files | What it does |
| :--- | :--- | :--- |
| Comparison template **IP Db2 DB and DBM Configuration** | `ip_db2_db_dbm_cfg_compare_template.xml`, `db2_compare_template.sh` | Compares the DB CFG and DBM CFG parts of the daily configuration snapshot. It ignores parameters that can be `AUTOMATIC` (`MON_HEAP_SZ`, `NUM_POOLAGENTS`, `FCM_NUM_BUFFERS`), values Db2 computes from the hardware (`CPUSPEED`, `COMM_BANDWIDTH`), host-specific paths and ports, and Enterprise Manager's target properties. |
| Drift definition **IP Db2 Configuration Drift** | `db2_config_drift.sh` | Compares chosen databases with a gold configuration through the template, and raises a compliance violation when a compared value differs. |
| Incident rule set **IP Db2 - Shipped Thresholds and Drift** | `ip_db2_incident_rule_set.xml`, `db2_incident_rules.sh` | Opens an incident for each drift violation, and for a Critical alert on any shipped default threshold where the out-of-box rule set has not already opened one. A third rule does the same for Warning alerts; it ships **disabled**. Scoped to IBM Db2 Database targets. |

### Set them up

Set them up in this order, because the rule set's drift rule names the drift definition. Run each script from the folder it ships in:

```sh
./db2_compare_template.sh import
./db2_config_drift.sh create --gold-target <reference database> --associate <database>,<database>
./db2_incident_rules.sh import      # Critical and drift rules on, Warning off
```

- Each script takes `--dry-run` to print the EM CLI commands without running them.
- The gold configuration is the only input specific to your site: a reference database's latest configuration, or a saved configuration (`--saved-snapshot "<name>"`). `./db2_config_drift.sh associate --associate <database>` adds databases later.
- Choose a gold database on the same operating system as the databases it is compared with: `SYSADM_GROUP` and `NUMDB` default differently on Linux and UNIX than on Windows.
- None of the files names an owner; Enterprise Manager makes the administrator who imports them the owner. Importing the rule set needs the **Create Enterprise Rule Set** privilege.

**The Warning rule is off by default.** Several shipped Warning thresholds fire often by design: the per-table maintenance columns (up to 100 tables per database), the db2diag.log count (it does not clear when a later collection finds nothing), any lock escalation, and a day without a backup. Tune those first, then turn the rule on with `./db2_incident_rules.sh enable-warnings`, or import with `--with-warnings`.

**Notifications belong in a rule set of your own.** Create one in **Setup → Incidents → Incident Rules** for IBM Db2 Database targets, with a rule on incidents (for example new incidents of severity Critical) and your e-mail or device notifications. It then picks up incidents whichever rule set opened them. Notifications added inside **IP Db2 - Shipped Thresholds and Drift** are lost if it is replaced: `import` refuses to replace an existing rule set unless you pass `--overwrite --yes`, and then exports the old copy first.

### What to expect

- **A Critical alert on a shipped threshold opens one incident.** With the out-of-box rule set enabled, that rule set runs first and opens it. This rule set's Critical rule opens it instead only if you disable the out-of-box Critical rule or move this rule set ahead of it (**Reorder Rule Sets**). Either way your notification rule set picks it up.
- **With the Warning rule on**, a Warning such as `Log_Storage : space_utilization` above 75 % also opens an incident.
- **Drift is seen after the next daily configuration collection** of the changed database; **Configuration → Refresh** on the target collects at once. The out-of-box rule set opens an incident for the drop in the definition's compliance score, and this rule set one for each violation. For the differing values side by side, open **Enterprise → Configuration → Comparison & Drift Management → Drift Results**.
- **Use one gold per class of database sized alike.** The log and backup sizing parameters are compared, so a database sized differently from the gold drifts.
- **To compare two databases once, without alerting,** use **One-Time Comparison** with the template, under **Enterprise → Configuration → Comparison & Drift Management**.

### Remove them

Remove the drift definition first, then the template, then disable the rule set:

```sh
./db2_config_drift.sh remove --yes
./db2_compare_template.sh delete --yes
./db2_incident_rules.sh disable
```

EM CLI cannot delete a rule set. Delete it in **Setup → Incidents → Incident Rules**; incidents it already opened stay open.

## Runbooks for common alerts {#runbooks}

On **Enterprise Manager 24ai**, the plug-in installs six Enterprise Manager runbooks. The runbooks need Enterprise Manager 24ai. Enterprise Manager lists them under **Enterprise → Runbooks** as "Oracle Provided", which is how it labels every runbook installed with a plug-in. When you open a matching incident on a Db2 target, Enterprise Manager recommends them in the incident's **Runbook Sessions** region.

| Runbook | For the alert on | What it walks through |
| :--- | :--- | :--- |
| IBM DB2: Database Down or Unreachable | The target going Down (an availability incident) | When the outage started; what the agent saw on its last check, with the driver's reason; whether other Db2 databases on the same server are down too; then how to bring it back |
| IBM DB2: Tablespace Running Out of Space | Tablespace Storage | Each tablespace's use, auto-resize and MAXSIZE; the growth forecast and what limits it; storage-path headroom; then the fix |
| IBM DB2: Transaction Log Filling | Log Storage | Log use and the oldest transaction holding it; open transactions; then how to release the log |
| IBM DB2: Backup Overdue | Database Backup | The last backup; recent recovery history, including failed backups; then how to take one now |
| IBM DB2: HADR Standby Not Ready for Takeover | HADR Takeover Readiness | Each standby's state, gaps and lag; open HADR alerts; then how to bring it back |
| IBM DB2: Applications Blocked on Locks | Longest Lock Waits | Who is blocking whom, on which table; open transactions; then whether to wait, ask, or force |

- **The lock runbook needs a lock-wait threshold.** `Longest_Lock_Waits` ships no threshold, so set one, or apply the Production-critical template, which sets `Duration` to 30 / 120 seconds.
- **What a session reads.** Each runbook opens with an overview. Its query steps read the target's own current values from the Enterprise Manager repository: the same numbers its pages show, at the moment you run the step. It ends with the commands that fix the problem and a step to confirm the alert clears.
- **Nothing runs on your database.** The runbooks never connect to the database and run nothing on the host. Every command is shown for you to run.
- **Down, or a collection error?** The Database Down runbook opens on availability incidents only. Enterprise Manager reads a Db2 database as Down when the agent cannot reach it: the connection is refused or times out, or the instance is stopped. A database that answers but rejects the plug-in (a wrong password, a missing privilege, a quiesced database) shows as a metric collection error instead, and raises no availability incident.
- **Your own copy.** To adapt one, use **Create Like** on the Runbooks page. A plug-in upgrade replaces the plug-in's own copies, but not yours.

To have Enterprise Manager archive the transaction log automatically when `Log_Storage : space_utilization` goes Critical, attach the archive job as a corrective action. Nothing ships attached; see [Corrective action](jobs-and-metric-extensions.md#corrective-action).

## After upgrading from GA {#after-upgrade}

**Seven lock and session groups are renamed, and thresholds set on the old names do not move.** Each old group was keyed by a connection id; the new groups use bounded keys. On the upgrade Enterprise Manager deletes the retired groups' stored data. Re-apply any threshold, template or incident rule of your own on the new name. See [Upgrade notes](upgrade-notes.md#renamed-groups).

| Retired group | Replaced by |
| :--- | :--- |
| `AgentStatistics` | `Application_Statistics` |
| `Sessions` | `Top_Sessions` |
| `Open_Transactions` | `Oldest_Transactions` |
| `Lock_Waits` | `Longest_Lock_Waits` |
| `Lock_Waits_By_Blkd_App` | `Lock_Waits_By_Blocked_App` |
| `Lock_Waits_By_Blkng_App` | `Lock_Waits_By_Blocking_App` |
| `Blocking_Chains` | `Blocking_Tree` |

The shipped defaults (`Oldest_Transactions : uow_age_sec` at 1800 / 7200 seconds), the three templates and the incident rule set already use the new names.

**New default alerts.** This release adds `Log_Archive` (`archive_status`, `archive_log_gap`), `Instance_Memory`, `Wait_Time` (`wait_time_pct`, `lock_wait_pct`), `BufferPool_IO_Time`, `WLM_Service_Classes`, `Member_Status` and the three pureScale groups, and moves the licence-status alert to `license_severity`. All are in the [default thresholds](#default-thresholds) above. What else changed is on [What's new](whats-new.md#update-24-1-2).

## Related

- [Metrics reference](metrics-reference.md): every metric group and column behind the thresholds above
- [Monitoring pages](monitoring-pages.md): the console pages that show the same data
- [HADR monitoring](hadr-monitoring.md#default-alerts): the HADR thresholds, explained in full
- [Compliance standards](compliance-standards.md): findings that report through compliance scores rather than a metric threshold
- [Instance targets](targets-and-properties.md#instance-targets): adding IBM Db2 Instance targets
- [Corrective action](jobs-and-metric-extensions.md#corrective-action): archiving the log when it fills
- [Upgrade notes](upgrade-notes.md#update-24-1-2): what to do when you upgrade from GA
