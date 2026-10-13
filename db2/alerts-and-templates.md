---
title: Alerts and thresholds
nav_order: 10
---

# Alerts and thresholds

Most of the metrics that matter ship with a curated Warning and Critical threshold already set, so a freshly added target raises real incidents without any tuning. Every threshold is an ordinary Enterprise Manager metric threshold — editable, with alert history, and routed through whatever notification connector you already have bound. No importable monitoring templates ship in this release, and none are needed: the curated defaults ship inside the plug-in. Thresholds are tuned per target or per group through the standard console. On Enterprise Manager 24ai, six runbooks walk you through the most common Db2 alerts.

> **Prerequisites for this page**
> - A deployed plug-in and at least one target with `License` reporting `Active` — see [Troubleshooting](troubleshooting.md#licence-gate).
> - An Enterprise Manager administrator with console access to Metric and Collection Settings.

**Where to find it:** metric values under **Target menu → Monitoring → All Metrics**; thresholds and schedules under **Target menu → Monitoring → Metric and Collection Settings**.

**In this page:** How findings become alerts · Default thresholds · Collection intervals · Tuning thresholds · The License metric's own alerts · Runbooks for common alerts

## How findings become alerts

1. A collection runs on its schedule and emits one row per finding onto the target.
2. Enterprise Manager compares the alerting column in each row against that metric's Warning and Critical thresholds.
3. When a threshold is crossed for the required number of consecutive collections, Enterprise Manager opens an incident, exactly as it does for any other target type.
4. The incident routes through your existing notification framework and connectors.
5. At the next collection after the finding resolves, the metric stops emitting the row and the alert clears itself.

The plug-in adds no alerting pipeline of its own.

## Default thresholds {#default-thresholds}

| Metric | Column | Warning | Critical | Occurrences |
| :--- | :--- | :--- | :--- | :---: |
| Response | `Status` | — | `≠ 1` (target down) | 1 |
| DetailedResponse | `db_status` | not `ACTIVE` | — | — |
| DetailedResponse | `db2_status` | `QUIESCE_PEND` or `QUIESCED` | — | — |
| DB_Monitoring | `average_lock_wait_time` | 1000 ms | 5000 ms | 3 |
| DB_Monitoring | `percent_appls_waiting_on_lock` | 50% | 70% | 3 |
| DB_Monitoring | `lock_timeouts_rate` | 0.1 | 0.5 | 3 |
| DB_Monitoring | `deadlocks_rate` | 0.05 | 0.2 | 3 |
| DB_Monitoring | `lock_escals_rate` | above 0 per second | above 0.01 per second | 3 |
| DB_Monitoring | `lock_list_utilization` | 70% | 85% | 2 |
| DB_Monitoring | `space_utilization` | 80% | 90% | 3 |
| DB_Monitoring | `connection_utilization` | 80% | 90% | 3 |
| General_Info | `sortheap_utilization` | 90 | 100 | 3 |
| Cache | catalog- and package-cache hit ratio | below 80% | below 70% | 3 |
| SortHeap | `sorts_overflow_ratio` | 30 | 50 | 3 |
| Log_Storage | `space_utilization` | 75% | 85% | 3 |
| Log_Storage | `sec_logs_allocated` | above 0 | — | — |
| Tablespace_Storage | `tablespace_utilization` | 80% | 90% | 1 |
| Tablespace_Storage | `tablespace_state` | a fault state (`OFFLINE`, `*_PENDING`, `STORAGE_MUST_BE_DEFINED`, `SUSPEND_WRITE`) | `OFFLINE` | 1 |
| Tablespace_Forecast | `DaysToFull` | below 30 days | below 7 days | — |
| Tablespace_Forecast | `ResizeFailed` | — | equal to 1 | — |
| Storage_Paths | `fs_used_pct` | above 85% | above 95% | — |
| Table_Maintenance | `stats_stale_days` | above 7 days | above 30 days | — |
| Table_Maintenance | `overflow_pct` | above 5% | above 20% | — |
| Invalid_Objects | `invalid_count` | — | above 0 | — |
| Open_Transactions | `uow_age_sec` (how long a unit of work has been open) | 30 minutes | 2 hours | — |
| Utilities | `elapsed_sec` | above 8 hours | above 24 hours | 1 |
| Locking (Lock_Waits and roll-ups) | — | Not defined | Not defined | — |
| HADR_Status | `HadrConnectStatus` | `CONGESTED` | `DISCONNECTED` | 1 |
| HADR_Readiness | `TakeoverReady` | Not set | equal to `0` | 1 |
| HADR_Readiness | `HadrLogGap`, `RecvReplayGap` | 10 MB | 100 MB | 3 |
| HADR_Readiness | `ReplayLagSec` | 60 seconds | 300 seconds | 3 |
| HADR_Readiness | `StateAlert` | anything but `OK` | — | 2 |
| DB_Backup | `days_since_last_backup` | greater than 1 day | greater than 3 days | 3 |
| DB_History | `operation_failed` | — | equal to 1 | 1 |
| Diag_Log_File_Monitoring | `count` | greater than 0 | greater than 3 | — |
| Monitor_Metrics | `metrics_off` | anything but `OK` | — | 1 |
| Db2_License_Usage | `feature_use_status` | `IN_VIOLATION` | — | — |
| CollectorStatus | `Status` | — | matches `COLLECTION_ERROR` | 2 |
| License | licence status | — | not `Active` | — |
| License | days until the key expires | 30 days | 7 days | — |

Reading the table:

- **Not defined** means the metric ships with no threshold value; the collection still runs and the rows still appear in All Metrics. Nothing alerts until you enter a value.
- Columns not listed here (the majority of what each metric group collects) ship `Not Defined` and are available for you to set — see [Monitoring pages](monitoring-pages.md) for what each group covers. `emcli get_threshold -target_name=<target> -target_type=ip_db2_database` lists every threshold a target carries.
- **Upgrades keep your values.** A threshold value you changed yourself is kept when the plug-in is upgraded.
- HADR's thresholds are documented in full, including what `TakeoverReady = -1` means, on [HADR monitoring](hadr-monitoring.md#default-alerts). **On a target that monitors an HADR standby**, set `DetailedResponse : db_status` to the standby's own healthy value, `STANDBY` or `ACTIVE_STANDBY` — see [Monitoring a standby](hadr-monitoring.md#monitoring-a-standby).
- `Monitor_Metrics` warns when a `MON_REQ_METRICS`, `MON_ACT_METRICS` or `MON_OBJ_METRICS` switch is `NONE`, which makes Db2 return zeros instead of real metrics. The fix, which takes effect online, is in the alert message: `db2 update db cfg for <database> using MON_REQ_METRICS BASE MON_ACT_METRICS BASE MON_OBJ_METRICS BASE`.
- `Diag_Log_File_Monitoring` and the five local administrative jobs need the agent co-located with the database — see [Network and ports](prerequisites.md#network).
- **Ratio alerts are per collection interval.** The hit ratios, the sort-overflow ratio and the average lock wait are computed from the change since the previous collection, not from totals since the database was activated. An interval with too little activity to judge reports the healthy value.

## Collection intervals {#collection-intervals}

Each metric group collects on its own schedule, from 5 minutes to 24 hours. The intervals most worth knowing:

| Metric group | Interval |
| :--- | :--- |
| Response (availability), HADR_Readiness, Lock_Waits and its three roll-ups, Open_Transactions, CollectorStatus | 5 min |
| DB_Monitoring, Tablespace_Storage, HADR_Status, Utilities, Rebalance_Status, License, and the performance groups | 15 min |
| Log_Storage, DB_Backup, Storage_Paths, Diag_Log_File_Monitoring, Top_Queries_Cpu_Time, Top_Queries_Execution_Count | 30 min |
| DB_History, Invalid_Objects, Monitor_Metrics | 1 hr |
| Table_Overflow | 2 hr |
| Table_Maintenance | 6 hr |
| Configuration snapshot | 24 hr |

A collection schedule and a threshold are independent: an alert with 3 occurrences on a 30-minute group confirms 1.5 hours after the threshold is first crossed.

## Tuning thresholds {#tuning-thresholds}

1. From the target home page, choose **Target menu → Monitoring → Metric and Collection Settings**.
2. Set the **View** list to **All metrics** so every group above is included.
3. Find the metric and the column you want.
4. Enter values in **Warning Threshold** and **Critical Threshold**. Leave a field empty to switch that level off.
5. Set **Number of Occurrences** to the number of consecutive collections that must breach before an incident opens.
6. To change how often the metric runs, click the metric's **Collection Schedule** link and set a new interval.
7. Click **OK** to save.

Threshold edits made this way apply to one target. Collection schedules and thresholds are independent: lowering a threshold does not make the metric collect more often.

## The License metric's own alerts

`License` carries two thresholds: Critical whenever the status is anything other than `Active`, and Warning at 30 days / Critical at 7 days before the key expires (a key with expiration `Never` has no expiry alert). The status alert is the one on this page you should not disable, because it is also the plug-in's signal that a target has stopped collecting almost everything else. See [Licensing](targets-and-properties.md#licensing) and [Troubleshooting](troubleshooting.md#licence-gate).

## Runbooks for common alerts {#runbooks}

On **Enterprise Manager 24ai**, the plug-in installs six Enterprise Manager runbooks. Enterprise Manager lists them under **Enterprise → Runbooks** as "Oracle Provided", which is how it labels every runbook installed with a plug-in, and recommends them in a matching incident's **Runbook Sessions** region.

| Runbook | For the alert on | What it walks through |
| :--- | :--- | :--- |
| IBM DB2: Database Down or Unreachable | The target going Down (an availability incident) | When the outage started; what the agent saw on its last check; whether other Db2 databases on the same server are down too; then how to bring it back |
| IBM DB2: Tablespace Running Out of Space | Tablespace Storage | Each tablespace's use, auto-resize and MAXSIZE; the growth forecast and what limits it; storage-path headroom; then the fix |
| IBM DB2: Transaction Log Filling | Transaction Log Storage | Log use and the oldest transaction holding it; open transactions; then how to release the log |
| IBM DB2: Backup Overdue | Database Backup | The last backup; recent recovery history, including failed backups; then how to take one now |
| IBM DB2: HADR Standby Not Ready for Takeover | HADR Takeover Readiness | Each standby's state, gaps and lag; open HADR alerts; then how to bring it back |
| IBM DB2: Applications Blocked on Locks | Lock Waits | Who is blocking whom, on which table; open transactions; then whether to wait, ask, or force |

- **What a session reads.** Each runbook's query steps read the target's own current values from the Enterprise Manager repository — the same numbers its pages show, at the moment you run the step. It ends with the commands that fix the problem and a step to confirm the alert clears.
- **Nothing runs on your database.** The runbooks never connect to the database and run nothing on the host. Every command is shown for you to run.
- **Down, or a collection error?** The Database Down runbook opens on availability incidents only. A database that answers but rejects the plug-in (a wrong password, a missing privilege, a quiesced database) shows as a metric collection error instead, and raises no availability incident.
- **Your own copy.** To adapt one, use **Create Like** on the Runbooks page. A plug-in upgrade replaces the plug-in's own copies, but not yours.

## Related

- [Monitoring pages](monitoring-pages.md) — the pages behind the metric groups above
- [HADR monitoring](hadr-monitoring.md#default-alerts) — the HADR thresholds, in full
- [Compliance standards](compliance-standards.md) — findings that alert through the compliance dashboard rather than a metric threshold
- [Troubleshooting](troubleshooting.md#licence-gate) — what an unlicensed target's alerts look like
