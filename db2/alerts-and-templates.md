---
title: Alerts and thresholds
nav_order: 10
---

# Alerts and thresholds

Most of the metrics that matter ship with a curated Warning and Critical threshold already set, so a freshly added target raises real incidents without any tuning. Every threshold is an ordinary Enterprise Manager metric threshold — editable, with alert history, and routed through whatever notification connector you already have bound. No importable monitoring templates ship in this release; thresholds are tuned per target or per group through the standard console.

> **Prerequisites for this page**
> - A deployed plug-in and at least one target with `License` reporting `Active` — see [Troubleshooting](troubleshooting.md#licence-gate).
> - An Enterprise Manager administrator with console access to Metric and Collection Settings.

**Where to find it:** metric values under **Target menu → Monitoring → All Metrics**; thresholds and schedules under **Target menu → Monitoring → Metric and Collection Settings**.

**In this page:** How findings become alerts · Default thresholds · Tuning thresholds · The License metric's own alert

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
| DB_Monitoring | `average_lock_wait_time` | 1000 ms | 5000 ms | 3 |
| DB_Monitoring | `percent_appls_waiting_on_lock` | 50% | 70% | 3 |
| DB_Monitoring | `lock_timeouts_rate` | 0.1 | 0.5 | 3 |
| DB_Monitoring | `deadlocks_rate` | 0.05 | 0.2 | 3 |
| DB_Monitoring | `space_utilization` | 80% | 90% | 3 |
| DB_Monitoring | `connection_utilization` | 80% | 90% | 3 |
| General_Info | `sortheap_utilization` | 90 | 100 | 3 |
| Cache | catalog- and package-cache hit ratio | below 80% | below 70% | 3 |
| SortHeap | `sorts_overflow_ratio` | 30 | 50 | 3 |
| Log_Storage | `space_utilization` | 75% | 85% | 3 |
| Tablespace_Storage | `tablespace_utilization` | 80% | 90% | 1 |
| Tablespace_Forecast | `DaysToFull` | below 30 days | below 7 days | — |
| Tablespace_Forecast | `ResizeFailed` | — | equal to 1 | — |
| Locking (Lock_Waits and roll-ups) | — | Not defined | Not defined | — |
| HADR_Status | `HadrConnectStatus` | `CONGESTED` | `DISCONNECTED` | 1 |
| HADR_Readiness | `TakeoverReady` | Not set | equal to `0` | 1 |
| DB_Backup | `days_since_last_backup` | greater than 1 day | greater than 3 days | 3 |
| DB_History | `operation_failed` | — | equal to 1 | 1 |
| Diag_Log_File_Monitoring | `count` | greater than 0 | greater than 3 | — |
| License | `Status` | — | not `Active` | — |

Reading the table:

- **Not defined** means the metric ships with no threshold value; the collection still runs and the rows still appear in All Metrics. Nothing alerts until you enter a value.
- Columns not listed here (the majority of what each metric group collects) ship `Not Defined` and are available for you to set — see [Monitoring pages](monitoring-pages.md) for what each group covers.
- HADR's two thresholds are documented in full, including what `TakeoverReady = -1` means, on [HADR monitoring](hadr-monitoring.md#default-alerts).
- `Diag_Log_File_Monitoring` and the five local-only administrative jobs it pairs with need the agent co-located with the database — see [Network and ports](prerequisites.md#network).

## Tuning thresholds {#tuning-thresholds}

1. From the target home page, choose **Target menu → Monitoring → Metric and Collection Settings**.
2. Set the **View** list to **All metrics** so every group above is included.
3. Find the metric and the column you want.
4. Enter values in **Warning Threshold** and **Critical Threshold**. Leave a field empty to switch that level off.
5. Set **Number of Occurrences** to the number of consecutive collections that must breach before an incident opens.
6. To change how often the metric runs, click the metric's **Collection Schedule** link and set a new interval.
7. Click **OK** to save.

Threshold edits made this way apply to one target. Collection schedules and thresholds are independent: lowering a threshold does not make the metric collect more often.

## The License metric's own alert

`License` carries its own threshold — Critical when `Status` is anything other than `Active` — and it is the one alert on this page you should not disable, because it is also the plug-in's signal that a target has stopped collecting almost everything else. See [Troubleshooting](troubleshooting.md#licence-gate) for what that looks like and how to fix it.

## Related

- [Monitoring pages](monitoring-pages.md) — the pages behind the metric groups above
- [HADR monitoring](hadr-monitoring.md#default-alerts) — the two HADR thresholds, in full
- [Compliance standards](compliance-standards.md) — findings that alert through the compliance dashboard rather than a metric threshold
- [Troubleshooting](troubleshooting.md#licence-gate) — what an unlicensed target's alerts look like
