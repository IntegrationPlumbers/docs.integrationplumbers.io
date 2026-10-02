---
title: Changelog
nav_order: 18
---

# Changelog

This page lists what changed in each release of the PostgreSQL plug-in, most recent first.

## 24.1.3.0.0 (Enterprise Manager 24ai) / 13.5.17.0.0 (Enterprise Manager 13.5)

One release, two builds with the same content: 24.1.3.0.0 installs on Enterprise Manager 24ai, 13.5.17.0.0 on Enterprise Manager 13.5. A maintenance release: no new pages or metrics. Upgrading uses the same three steps as any plug-in update; see [Upgrade from an earlier release](install-and-upgrade.md#upgrade). One prerequisite changed: the server log read access that plan capture needs is now a per-database `GRANT EXECUTE` on the log-file functions instead of the `pg_read_server_files` role; see **Changed** below and [The server log read grant](prerequisites.md#log-read-grant).

**Fixed**

- **Backup Management** can schedule backups and restores again. Every submission failed with ORA-20411 because blank optional parameters were sent as empty values; they are now omitted. A job Enterprise Manager reports as failed (for example, `pg_dump` missing on the agent host) now shows an error instead of closing the dialog as if it had succeeded. The page acts on the database selected in the navigation tree rather than always on `postgres`, the submit button is disabled while a job is in flight, and database names that the PostgreSQL client library would read as a connection string are refused.
- Every database-scoped page follows the database selected in the navigation tree, and switching the same page between database nodes now repaints it; it previously did nothing. The Database, Tables, and Indexes pages no longer poll.
- **Database** page: the Database Size chart plotted zeros, and a custom date range returned nothing because it sent no database key.
- **Tables** and **Indexes**: the Table Size and Index Size donuts total the whole database, not the rendered page; the paging badge keeps Enterprise Manager's own "a–b of n" positions; the text filter applies to every row of the database and no longer misses results that arrived before the first keystroke; charts keep their time axis pinned to the selected window.
- **Overview**: the Replication panel showed raw bytes under its "Data Lag (MB)" header.
- **Workload History** read all zeros on busy servers because **SQL Statements** kept the top N statements by lifetime total; it now keeps the top N by activity in the collection interval.
- **Monitoring Readiness** is probed per database, so a database whose settings differ from the primary's reports its own values; when a target is unreachable the page still renders. One failed probe no longer leaves every later item reading `undetermined`.
- The **Configure auto_explain** job configures the selected database; a blank database defaults to the target's primary database.
- **Vacuum Advisor**: the Bloat findings count read 1 while the bloat table was empty.
- A monitoring role that holds `pg_read_server_files` but cannot execute the log-file functions was reported as ready for plan capture while every harvest silently failed; a role set up the other way round was told to grant the role. Readiness now checks the function grants themselves and names exactly what is missing.
- Byte values are labelled "B", matching the KiB/MiB casing used elsewhere.

**Changed**

- **Server log read access.** Plan capture reads the server log with `pg_current_logfile()`, `pg_stat_file()`, and `pg_read_file()`, which PostgreSQL does not let ordinary roles execute. The monitoring role now needs EXECUTE on those functions, granted in the database the target monitors; `pg_read_server_files` is no longer required and is no longer checked. **Monitoring Readiness** shows the exact statement with your role name filled in, and a new **Monitoring role (pg_monitor)** item reports whether the role holds `pg_monitor`, which the plug-in requires. The Plan Capture Readiness metric's column is labelled "Server Log Read Access Granted".
- **Monitoring Readiness Detail** rows are reported per database: the Item value carries the database as `item@database`, and a Database Name column was added. A report or emcli query that matched on the bare item name should match on the prefix.
- The **Configure auto_explain** job has an optional Database parameter.
- The download package is a zip containing the plug-in OPAR, the OPAR's SHA-256 checksum, and the three monitoring templates, with a SHA-256 checksum of the zip beside it.

## 24.1.2.0.0 (Enterprise Manager 24ai) / 13.5.16.0.0 (Enterprise Manager 13.5)

One release, two builds with the same content: 24.1.2.0.0 installs on Enterprise Manager 24ai, 13.5.16.0.0 on Enterprise Manager 13.5. A maintenance release: no new pages, jobs, templates, or target properties. Upgrading uses the same three steps as any plug-in update; see [Upgrade from an earlier release](install-and-upgrade.md#upgrade).

**Fixed**

- Failover detection on the PostgreSQL Database target works. The **Replication Failover** metric's Failover Status could never become true, and Replication Role Change read true one collection after every agent restart and stayed true. Both columns now report from the server's write-ahead-log timeline and recovery state, so the `ip_xpgs_production_critical` template's failover alert fires on a real failover and clears afterwards.
- The PostgreSQL Cluster target's **Replication Failover** roll-up reports one failover once. A standby only sees a new timeline at its next restartpoint, so it can report the same failover one collection after the primary; the roll-up now follows the member that reports itself primary instead of re-raising on the standby's late report.
- The navigation tree lists every database on the target again. It could fall back to the primary database alone when the database list was still loading, which affected multi-database targets most. Template databases stay hidden.
- **Blocked Queries** and the Realtime **Locks** page count only sessions actually waiting on another session. They previously counted every session sharing a lock object, including the lock holder and concurrent readers.
- **Query Analyzer** Mean Time (ms) is the cumulative mean per call. It was always 0.
- The **Tables** metric's *Hours Since Last Vacuum / Autovacuum / Analyze / Autoanalyze* columns report the full elapsed hours. Past one day they reported only the hour-of-day part, so three days read as 0.
- Tables and Databases report Total Rows Fetched, and their summed counters no longer wrap past 2,147,483,647.
- The **Replication** metric's Sent, Write, Flush, and Replay LSN columns are populated. They were always blank on PostgreSQL 10 and later.
- Realtime **Vacuums in Progress** shows Percent Vacuumed while a vacuum runs. It read 0 until the vacuum finished.
- On PostgreSQL 17 and later, the Background Writer's *Buffers Backend* and *Buffers Backend Fsync* rates are left blank instead of showing 0; PostgreSQL no longer reports those counters there.

**Changed**

- Every metric column carries a unit and unit category, shown under All Metrics and reported to Enterprise Manager's MCP server.
- Clearer column labels throughout: interval rates end in "(Interval Avg)", read-from-disk is distinguished from buffer-cache hit, bare "Status" columns say what they report, and time columns carry their unit.
- Two redundant columns are retired: *Blocked PIDs (No Locks Granted)* and its count on **Blocked Queries** (the waiting-session count already covers them), and *Average Execution Time per Second* on **SQL Statements** (it always equalled Average Execution Time per Call). A monitoring template or report that referenced either should use the remaining column.

## 24.1.1.0.0 (Enterprise Manager 24ai) / 13.5.15.0.0 (Enterprise Manager 13.5)

One release, two builds with the same content: 24.1.1.0.0 installs on Enterprise Manager 24ai, 13.5.15.0.0 on Enterprise Manager 13.5.

**New pages**

- [Monitoring Readiness](monitoring-readiness.md) — checks each advisor's prerequisites against what's live on the target, and applies the `auto_explain` settings for you where the plug-in can set them itself.
- [Plan Analysis](plan-analysis.md) — captured execution plans with per-node estimated-versus-actual rows and insight-rule recommendations.
- [Plan Drift Advisor](plan-drift-advisor.md) — plan baselines, drift detection against the accepted baseline, and the Fix Workbench, the only place the plug-in executes a statement to obtain a plan.
- [Workload History](workload-history.md) — per-statement workload trends over a retained window, with equal-length window comparison and per-statement drill-down.
- [Index Advisor](index-advisor.md) — catalog-native index detection across five categories, with ready-to-review CREATE and DROP statements, enriched by HypoPG and pg_qualstats when present.
- [Vacuum Advisor](vacuum-advisor.md) — per-table autovacuum tuning recommendations and wraparound visibility.
- [Retention Policies](history-store-and-retention.md#retention-policies) — the retention-day and size-ceiling editor for the agent-side history store.
- Realtime ▸ [Vacuum xmin Horizon](vacuum-advisor.md#xmin-horizon-root-cause) — the exact session, replication slot, or prepared transaction holding vacuum back, with the release command ready to copy.

**New metrics**

- Index Advisor
- Index Advisor What-If
- Index Advisor (Predicate Stats)
- Vacuum Advisor (Frequency)
- Table Bloat Estimate
- Vacuum xmin Horizon (Root Cause)
- Plan Drift
- Plan Insights
- Wait Events Sampled
- Super-user / Privilege Audit
- Plan Capture Readiness
- Monitoring Readiness Detail
- Cluster Events (Patroni)
- Collection Throttle
- Historical Collection Trim

**New jobs**

- PostgreSQL - Set Granular Retention Days
- PostgreSQL - Set Plan Archive Size Ceiling
- PostgreSQL - Reclaim Collection Store Disk Space
- PostgreSQL - Set Wait History Retention Threshold
- PostgreSQL - Configure auto_explain
- PostgreSQL - Set Plan Capture Window & Opt-in
- PostgreSQL - Trim Historical Granular Collections

**Monitoring templates**

- `ip_xpgs_production_critical` — critical production
- `ip_xpgs_standard` — dev, test, and staging
- `ip_xpgs_starter` — a minimal starter to clone and extend

**Changed**

- The Query Analyzer explain workbench moved to the Fix Workbench on [Plan Drift Advisor](plan-drift-advisor.md).
- The retention editor moved from [Workload History](workload-history.md) to the [Retention Policies](history-store-and-retention.md#retention-policies) page.
- The `waits_sampled` metric is retired in favor of Wait Events Sampled.
- Collection throttle target properties were added.

**Fixed**

- SQL statement text is now bounded at the source, preventing excessive agent memory use with very large statements (SR 8965).
- The log collector now parses custom and CIS-hardened `log_line_prefix` formats.
- The Indexes metric reports individual index sizes.
- Captured-plan timestamps are correct in daylight-saving time zones.

### 13.5.12.0.0

- Added Patroni REST API as a cluster monitoring source, with TLS modes (`disable` / `require` / `verify-full`), optional CA certificate, and optional HTTP Basic authentication. See [Patroni REST API monitoring](targets-and-properties.md#patroni).
- Added four schema-inventory metrics: Triggers, Prepared Transactions, Sequences, User Functions (see [Schema inventory metrics](monitoring-pages.md#schema-inventory-metrics))
- JET 14 and JET 18 (Redwood) UI compatibility fixes
- Fixed intermittent `MetricGetException: Result has repeating key value` on SQL Statements, Blocked Queries, and Idle Connections pages under active workload
- Fixed Tables and Indexes toggle-all and clear-filter controls
- Suppressed transient error dialogs shown when a target is DOWN on the Overview and Configuration pages
- Fixed License banner handling when no license is configured
- Fixed silent job-failure bugs in Backup, Restore, Switchover, and Custom Query job wrappers (Perl wrappers now correctly propagate the Java exit code so failed jobs are reported as Failed in Enterprise Manager)
- Security updates
- Bug fixes

### 13.5.10.0.0

- Added support for PG 18
- Updated licensing
- Bug fixes

### 13.5.9.0.0

- Added historical visualization of wait events
- Added support for custom queries via Metric Extensions (BETA)
- Added UI button to trigger a switchover of a patroni cluster
- Bug fixes

### 13.2.8.3.0

- Added support for PG 17
- Added Real-time metric pages for Logs and Idle Connections
- Added Job to kill idle connections
- Added Query Analyzer UI page
- Added Log Stats metric group
- Bug fixes

### 13.2.8.2.0

- Fixed compatibility issues with newer versions of Oracle Enterprise Manager

### 13.2.8.1.0

- Added OMS host + credentials to test connection
- updated PG JDBC driver

### 13.2.8.0.0

- Updated licensing

### 13.2.7.7.0

- Fixed heap memory issue from excessive query returns
- Fixed parsing issue in patroni collections

### 13.2.7.6.0

- Fixed multiple jruby dependencies

### 13.2.7.5.0

- Fixed bug in collecting patroni metrics

### 13.2.7.4.0

- Added metrics for patroni logs

### 13.2.7.3.0

- Stability added to new metrics

### 13.2.7.2.0

- Bug fixes

### 13.2.7.1.0

- Bug fixes

### 13.2.7.0.0

- Cluster target / dashboard
- Queries update
- Backup & Restore jobs added
- New Metrics
- Autodiscovery
- Replication Metrics added

### 13.2.6.0.0

- Support added for PG 15

### 13.2.5.1.0

- Compile with Java 8

### 13.2.5.0.0

- Support added for PG 9

### 13.2.4.0.0

- PG 13 & 14 Support added
- Compile with Java 7

### 13.2.3.0.0

- PostgreSQL 12 support

### 13.2.2.0.0

- Fixed issues running Java on certain system configurations
- Fixed unused indexes count displayed on Overview page

### 13.2.1.0.0

- Enterprise Manager 13.3 support
- PostgreSQL 11 support
- New HTML/JavaScript user interface
- Threshold configurations for more metrics
- Individual collection schedules for each metric group
- Security updates

## Related

- [What's new in this release](whats-new.md) — the current release in detail, page by page, with what changed or moved
- [Install and upgrade](install-and-upgrade.md) — how to move an existing deployment onto a newer build
- [PostgreSQL Plug-in](index.md) — the documentation hub for every page in this guide
