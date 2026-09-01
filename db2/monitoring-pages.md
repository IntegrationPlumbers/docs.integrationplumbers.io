---
title: Monitoring pages
nav_order: 7
---

# Monitoring pages

The plug-in ships three native console pages — **Home**, **Analysis**, and **Performance** — reachable from the target's menu. All regions refresh in real time. Backup/restore/load history, SQL-workload trends, and the full HADR column set are collected as metric groups rather than as dedicated page regions in this release; they live under the target's **All Metrics** page and in charts, and HADR gets its own guide — see [HADR monitoring](hadr-monitoring.md).

> **Prerequisites for this page**
> - A target added and collecting — see [Targets and properties](targets-and-properties.md#add-target-console).
> - The **License** metric reporting `Active`, or every page below stays empty — see [Troubleshooting](troubleshooting.md#licence-gate).
> - The **Kill Application** action on Analysis needs [Preferred Credentials](prerequisites.md#preferred-credentials) set for the target.

**Where to find it:** IBM DB2 Database (Beta) target navigation tree — Home, Analysis, and Performance at the top level; the full metric detail under All Metrics.

**In this page:** Home · Analysis · Performance · Where the rest of the data lives

## Home {#home}

**Home** is the target's landing page — open it first to see whether a database is healthy at a glance.

- **Availability** — a 7-day availability timeline for the target.
- **Configuration Summary** — instance name, database, status, database path, capacity, current size, and current connection count.
- **Connections** — a line chart of remote, local, and total application connections.
- **Lock & Deadlock Activity** — a line chart of lock-timeout, lock-escalation, and deadlock rates.
- **HADR Status** — a table of database, role, state, sync mode, connect status, connect time, missed heartbeats, timeout, and the primary/standby log positions for high-availability pairs. Empty on a database that is not in an HADR pair — see [HADR monitoring](hadr-monitoring.md).
- **Incidents** — open incidents for the target.

## Analysis {#analysis}

**Analysis** is where you chase lock contention.

- **Lock Contention** — a paged table of live lock waits: the requesting application, user, and statement; the lock name and object type; the locked schema and table; the wait duration; and the holding application, user, and statement.
- **Top Waits by Blocked Application** — the applications waiting longest on locks, with a **Kill Application** button. Selecting a row and clicking it submits the **Kill DB2 Application** job (see [Jobs](jobs-and-metric-extensions.md)) against the selected application ID. Needs [Preferred Credentials](prerequisites.md#preferred-credentials) and an agent local to the database.
- **Top Waits by Blocking Application** — the applications holding locks that others are waiting on.

An empty Lock Contention table is a healthy, uncontended database, not a collection failure.

## Performance {#performance}

**Performance** is where the buffer pool, cache, and I/O detail lives.

- **Buffer Pool I/O** — a per-buffer-pool table of hit ratio and logical/physical data and index reads.
- **Cache Hit Ratios** — a line chart of catalog- and package-cache hit ratios.
- **Transaction Log I/O** — a line chart of log reads, log writes, and LSN-gap cleaners.
- **Direct (Non-Buffered) I/O Rate** — average direct read and write rates.
- **SQL Activity Rate** — static, dynamic, commit, and rollback SQL rates.
- **Space Utilization & Lock Wait** — database space utilization and average lock-wait time.

## Where the rest of the data lives

Three parts of the metric surface do not have a dedicated page region in this release, and are available through **All Metrics** and in charts instead:

- **Backup, restore, and load history.** `DB_History` reads `SYSIBMADM.DB_HISTORY` directly — operation type, timing, status, and a failed-operation flag on each row. `DB_Backup` carries the simpler backup-age check.
- **SQL workload trends.** `Top_Queries_Cpu_Time` and `Top_Queries_Execution_Count` are periodic top-SQL delta snapshots, keyed by a statement-ID hash, with CPU-time and execution-count trends per statement. Numeric-only in this release — see [What's new](whats-new.md#known-limitations).
- **The full HADR column set.** Home's HADR Status table shows the essentials; every column, plus the takeover-readiness composite and log-gap trending, is on [HADR monitoring](hadr-monitoring.md).

To open any of these: target menu → **Monitoring → All Metrics**, then pick the metric group by name. See [Alerts and thresholds](alerts-and-templates.md) for the metric groups' shipped thresholds.

## Related

- [HADR monitoring](hadr-monitoring.md) — the full HADR column set, the takeover-readiness composite, and log-gap trending
- [Jobs](jobs-and-metric-extensions.md) — the Kill DB2 Application job behind the Analysis page's Kill Application button
- [Alerts and thresholds](alerts-and-templates.md) — the default Warning/Critical thresholds shipped on these metric groups
- [Troubleshooting](troubleshooting.md#licence-gate) — why a page can stay empty on an Up target
