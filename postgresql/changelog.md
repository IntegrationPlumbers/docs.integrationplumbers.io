---
title: Changelog
nav_order: 18
---

# Changelog

This page lists what changed in each release of the PostgreSQL plug-in, most recent first.

## 24.1.4.0.0 (Enterprise Manager 24ai) / 13.5.18.0.0 (Enterprise Manager 13.5)

One release, two builds with the same content: 24.1.4.0.0 installs on Enterprise Manager 24ai, 13.5.18.0.0 on Enterprise Manager 13.5. A feature release: one new job, nine new metrics, and new history sections on most existing pages. Everything historical is read from the agent-side history store; Enterprise Manager receives only the summary rows that thresholds and incidents use. Upgrading uses the same three steps as any plug-in update; see [Upgrade from an earlier release](install-and-upgrade.md#upgrade). If the sections new in this release stay empty after the upgrade, restart the OMS: an Enterprise Manager server can go on serving the previous release's list of metrics until it is restarted. The optional log-based features need a one-time grant on the monitored server; see [Enabling the log-enhanced features](log-enhanced-features.md).

**New sections on existing pages**

- Locks — three history sections below the blocking-sessions view: *Lock Wait History* (sessions seen waiting on a lock, sampled every 10 minutes), *Recent Lock Waits* with the blocking session and whether it was idle in an open transaction, and *Lock Waits by Query*. A **Database** selector at the top of the page filters the live blocking-sessions table (by the waiting session's database) and the history sections; it starts on All databases.
- Logs — *Events from the Server Log* and *Recent Events*: log entries sorted into 26 categories (deadlocks, timeouts, refused connections, connection limit, temporary files, slow statements, wraparound warnings, out of memory or disk, crashes, start/stop/recovery, configuration changes, replication, WAL archiving, constraint violations, permission denied, other SQL errors, and more), with counts per window and the most recent sample of each. Reads stderr and, on PostgreSQL 15 and later, jsonlog; csvlog is not read. The page's **Database** selector scopes the recent events.
- Overview — *Checkpoint History*: checkpoint frequency and duration over the retained history (90 days by default), with the last 24 hours compared against the target's own baseline. *Database Size History*: cluster size over the retained history (90 days by default), the change per database, and a 30- and 90-day projection.
- Database — *Buffer Cache*: what is in `shared_buffers`, the dirty share, each database's share, and the most-cached relations, sampled every 15 minutes where the `pg_buffercache` extension is installed.
- Configuration — *Parameter Changes*: every change to a server parameter since monitoring began, with the old and new value and when it was first seen, kept for a year.
- Vacuum Advisor — *Vacuum History* for any table; *Autovacuum Activity from the Server Log* (read from stderr and, on PostgreSQL 15 and later, jsonlog): each autovacuum run with its duration, index passes, lock-conflict skips and cancellations, anti-wraparound runs, autoanalyze runs, and the buffer and WAL cost per run; *Bloat and Dead Rows from the Server Log*: tables whose dead rows a vacuum could not remove (held back by the xmin horizon) and tables where space was freed but no page released (a rebuilt table loses the finding at its next pgstattuple measurement; without the extension, once the next logged autovacuum run reports the smaller heap), with a measured free-space chart where `pgstattuple` is installed; a calendar-time wraparound forecast ("~N days to wraparound") above the XID consumption chart, with the projection drawn in; a transaction-ID age chart over the retained Databases history (90 days by default), its label stating the window.
- Index Advisor — *Index History*: 12 months of size and usage for any index, month-over-month or over a custom range, with drift badges on the recommendations and drift-aware ranking; *Apply History*; an **Apply** action on each exact index recommendation (see *New jobs*). A usage trend (rising, declining, steady) is stated only where the history holds 60 days for that index; with less, a badge says only "unused" or "accumulating". An index reads "accumulating" on the day it is first seen and through the following day, and is not offered as a confirmed drop in that time.
- Plan Drift Advisor — *Workload Anomalies*: statements whose mean time or call rate over the last 24 hours departs from the prior week, linked to their captured plans and badged "Slower N×" / "Busier N×" in the plan list; query-rewrite recommendation cards for captured plans where a rewrite is estimated to run at least ten times faster (the plug-in never runs a proposed rewrite; the Fix Workbench stays the only place a statement is executed).
- Plan Analysis — the four supplementary plan insights (Disk Sort, Hash Batches, Expensive Node, Large Offset) and the non-sargable-predicate rewrite call-out now surface on the page and in the `plan_insights` metric beside the five existing insights. The metric's HIGH-severity condition applies to every insight code, so after the upgrade a sort spilling 256 MB or more to disk, or a hash join of 8 batches or more, raises a Warning (and a ticket where incidents route to ServiceNow) on targets that had none before; the work_mem values on those cards are copy-ready. Expensive Node is a Low, informational pointer to the plan node that owns the runtime. It is not shown when another insight already explains that node's cost, and the data-change, row-lock and function-scan nodes themselves are never pointed at (their time is lock waits, triggers or function bodies, not plan shape); when such a node holds a visible part of the time, the pointer says how much sits outside the plan nodes.
- PostgreSQL Cluster overview — *Leader Change History*: every switchover and failover the cluster has seen, newest first, with the time since the last change, and a warning on the cluster target while a leader change is under 24 hours old.
- Monitoring Readiness — rows for the `pg_buffercache` extension, for which server-log reader the monitoring role can use, and for whether `log_line_prefix` carries the database name that captured plans need (on the PostgreSQL default prefix `'%m [%p] '` the plan capture section shows a warning until `%u@%d` is added; see [Enabling the log-enhanced features](log-enhanced-features.md#log-line-prefix)).
- Retention Policies — windows and protected minimums for the new history types (autovacuum log events, server-log events, lock samples, buffer cache samples and parameter changes). Server-log events are kept for 90 days by default.

**New metrics**

- Transaction ID Wraparound Forecast — days until wraparound per database from the consumption rate of the last 7 days; warning at 14 days, critical at 7 (two consecutive collections). Blank until 24 hours of history exist.
- Cluster Size Capacity Forecast — projected size in 30 and 90 days; the capacity thresholds ship undefined because the plug-in cannot see the storage behind the cluster.
- Workload Anomalies — per-statement mean-time and call-rate ratios, last 24 hours against the prior 7 days; thresholds ship undefined.
- Vacuum Log Insights — the last 24 hours of autovacuum activity from the server log, with the status of the log read.
- Server Log Events — one row per event category with its 24-hour count and most recent sample.
- Lock Contention — sessions waiting on a lock at each sample, the longest wait and its relation, and blockers idle in an open transaction.
- Buffer Cache — `shared_buffers` occupancy, dirty and pinned buffers, and the average usage count per sample.
- Parameter Drift — parameters changed in the last 24 hours, how many of them matter for performance or safety, parameters awaiting a restart, and the last change.
- Background Writer gains six columns comparing the last 24 hours of checkpoints against the target's baseline, with a warning at 2× and critical at 3× the baseline rate.
- Leader Change Alert (Patroni), on the cluster target — one row per leader change of the last 7 days, evaluated in the repository, with a warning while the newest change is under 24 hours old.
- Cluster Events (Patroni) gains *Hours Since Leader Change*.
- Locks gains *Blocked Database* and Idle Connections gains *Database Name*, the columns the new Database selectors filter on.

All new conditions ship with no threshold unless stated above; set them in a monitoring template.

**New jobs**

- PostgreSQL - Apply Index Recommendation — runs the `CREATE INDEX CONCURRENTLY` or `DROP INDEX CONCURRENTLY` behind one Index Advisor recommendation with the submitting user's Preferred PostgreSQL credentials. The job rebuilds the statement from the recommendation's parts after checking each against the live catalog; it never accepts SQL text. Every run is recorded under *Apply History*.

**Changed jobs**

- PostgreSQL - Read Workload History Data accepts a database scope and a per-object filter, so the history charts can show any table or index.
- PostgreSQL - Set Granular Retention Days has windows and protected minimums for the new history types, among them `Server Log Events (Days)`.

**Monitoring templates**

- The three database templates carry thresholds for the wraparound forecast; Production Critical and Standard also carry them for the checkpoint-spike ratio. The two full templates list every collection of the target type, so applying one in complete mode no longer switches off collections it did not name. Apply the Starter template in partial mode; it is a seed to copy.
- New: `ip_xpgs_cluster_production_critical` for the cluster target, with the leader-change warning.
- The four templates ship beside the plug-in archive in the release zip, under `xpgs_monitoring_templates_v1/`.

**Metric-extension template**

- pgBackRest backup history — a customer-deployable Metric Extension (Perl, with sample output) that reports the newest backup per stanza and its age; see [pgBackRest backup history](jobs-and-metric-extensions.md#pgbackrest).

**Enabling the log-enhanced features**

The vacuum history, bloat findings, server-log events and plan capture read the server log through the target's own database connection. The monitoring role needs `pg_monitor` and one of two read routes in each monitored database: EXECUTE on the four built-in log-read functions, or the narrower `xpgs_monitor` reader that the onboarding script installs (superuser-owned functions that can read files in the log directory only). Never `pg_read_server_files`. The checklist, a read-only check script and an idempotent grant script are on [Enabling the log-enhanced features](log-enhanced-features.md); the Monitoring Readiness page reports which route is in use. A superuser runs the scripts, with psql 11 or later. Each sets `search_path` to `pg_catalog` before it calls anything and names every built-in function and catalog by schema, so a function another role has created in `public` is never run in its place.

**Changed**

- Plan Analysis and Plan Drift Advisor list captured plans whose database could not be read from the log line (a `log_line_prefix` without `%d`) under every database, shown as "unknown", instead of hiding them while still counting them.
- Page layout: every page has a title, every section sits on a panel with one heading style, and the navigation lists the sections of the current page under *On this page*. Long tables show 15 rows a page. On the Index Advisor, *Unused & Invalid Indexes* now follows *Missing Index Recommendations*. The Overview's agent host figures are grouped tiles with a link to the host target.
- Idle Connections and Vacuums in Progress have the same **Database** selector as Locks and Logs.
- A new dynamic property, `buffercache_enabled`, turns the buffer cache collection on when the extension is present. No target property needs setting.

**Fixed**

- The bundled `log4j-api` and `log4j-core` are 2.26.1 (were 2.26.0): CVE-2026-49844, malformed JSON for non-finite numbers in `MapMessage.asJson`. The plug-in does not log through that path, so earlier builds were not exposed in practice; the upgrade keeps dependency scanners from flagging the jar.
- The Logs page raised an "Error getting metric from Agent" dialog on every refresh when the target's optional **Path to postgres log file** was blank. *Log Statistics* and *PostgreSQL Logs* now stay empty in that case and say why. The *Log Statistics* title now says what it counts: the last 500 log lines. The same applies to a scheduled collection: a target with *Log Statistics* collection enabled and no path used to report a collection error and now reports no data and no error, so an empty metric there means the path is not set. A path that is set but cannot be read still reports an error.
- Security: a job parameter value containing a comma could add or override another parameter of the same job, because Enterprise Manager joins a job's parameters with commas without escaping them. Every job script now accepts only the parameters its job type declares, refuses a repeated one, and never passes a value through a shell.
- Security: database names, statement text and user names from a monitored database were written into HTML attributes with their quotes unescaped, so a value containing a quote could add markup to a console page. Both quote characters are now encoded everywhere such a value is written.
- Realtime pages (Locks, Queries, Logs, Idle Connections, Vacuums in Progress, Vacuum xmin Horizon): the collection-throttle banner and the Logs page's *Log Statistics* did not follow the Auto Refresh setting. Every feed on a page now does.
- On Enterprise Manager 24ai the notice and confirmation popup opened too short to show its message (the Retention Policies save notice and the Plan Drift Advisor's Retire Baseline confirmation).
- On a slow connection a database target page could fail to open with "Load timeout for modules: xpgs/CommonXpgsController". The console library is now minified (about 40% smaller).
- Plan Analysis and Plan Drift Advisor: insight cards showed three unreadable characters in place of a dash in the Stale Statistics and Lossy Bitmap text. The text now uses a plain hyphen.
- Plan Drift Advisor: after another query was selected, the heading changed at once while the tiles, chart, captures, plan comparison, baselines and audit trail went on showing the previous query until each finished loading, and a baseline action taken in that interval applied to the previous query. Every panel now clears as soon as a query is selected and the baseline actions stay disabled until that query's baselines have loaded. A panel that cannot load says so.
- Overview: the header under the PostgreSQL logo read "undefined" in place of the port on a target added without a Port. It now shows 5432, the port such a target is monitored on.

## 24.1.3.0.0 (Enterprise Manager 24ai) / 13.5.17.0.0 (Enterprise Manager 13.5)

One release, two builds with the same content: 24.1.3.0.0 installs on Enterprise Manager 24ai, 13.5.17.0.0 on Enterprise Manager 13.5. Certified on Enterprise Manager 24ai Release Update 13 (24.1 RU 13) and Enterprise Manager 13.5 Release Update 34 (13.5 RU 34). A maintenance release: no new pages or metrics. Upgrading uses the same three steps as any plug-in update; see [Upgrade from an earlier release](install-and-upgrade.md#upgrade). One prerequisite changed: the server log read access that plan capture needs is now a per-database `GRANT EXECUTE` on the log-file functions instead of the `pg_read_server_files` role; see **Changed** below and [The server log read grant](prerequisites.md#log-read-grant).

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
