---
title: What's new in this release
nav_order: 1
---

# What's new in this release

If you monitor PostgreSQL with 13.5.12 today, this release keeps what you already have. It ships as two builds with the same features, 24.1.4.0.0 for Enterprise Manager 24ai and 13.5.18.0.0 for Enterprise Manager 13.5 (the advisory pages below arrived in 24.1.1.0.0 / 13.5.15.0.0; the current release adds history, forecasts, and server log features to them, summarized under [New in 24.1.4.0.0 / 13.5.18.0.0](#new-in-this-release)). This release is certified on Enterprise Manager 24ai Release Update 15 (24.1 RU 15) and Enterprise Manager 13.5 Release Update 34 (13.5 RU 34). Your targets, console, and alert routing carry forward, and on top of them the plug-in becomes advisory. It names the index worth creating and the table autovacuum is falling behind on, each with SQL for you to review and run or, for an exact index recommendation, apply from the page after confirming it, and it tells you when a query has left its accepted plan, with both plans side by side so you can test a rewrite or accept the new plan.

Everything in this release is additive. Your targets, thresholds, schedules, and credentials carry forward unchanged; a few surfaces moved, and those are listed under [What changed or moved](#what-changed-or-moved). The upgrade itself is the ordinary import-and-deploy sequence. There is one new decision to make, and it is on the database side: the features that read the server log need a read grant for your monitoring role, and plan capture also needs `auto_explain` configured. Among the settings the plug-in could apply itself, that grant is the one it deliberately never does. It is needed for the two plan pages, the Vacuum Advisor's server-log sections, and the server log events on the Logs page; everything else in this release works without it.

**Where to find it:** the new pages appear in the PostgreSQL Database target's navigation tree — **Realtime ▸ Vacuum xmin Horizon** under the Realtime group, the rest under each database name — and in the same target menu you use today. The new metrics appear under **Target menu → Monitoring → All Metrics**.

**In this page:** New in 24.1.4.0.0 / 13.5.18.0.0 · The new pages at a glance · Monitoring Readiness · Plan Analysis · Plan Drift Advisor · Workload History and wait events · Index Advisor · Vacuum Advisor and xmin horizon · Retention Policies and the history store · Alerts and monitoring templates · Collection throttle · What changed or moved · New prerequisites · Upgrading from 13.5.12 · Full changelog

## New in 24.1.4.0.0 / 13.5.18.0.0 {#new-in-this-release}

This is a feature release: one new job, nine new metrics, and new history sections on most existing pages. Everything historical is read from the agent-side history store; Enterprise Manager receives only the summary rows that thresholds and incidents use. If you are upgrading from 24.1.3.0.0 / 13.5.17.0.0, this section is the whole of what changed for you. The [Changelog](changelog.md) has every item and every fix.

**History on the pages you already use**

| Page | What it gained | Read more |
|---|---|---|
| **Overview** | **Checkpoint History**, with the last 24 hours compared against the target's own baseline, and **Database Size History**, with a 30- and 90-day projection | [Overview](monitoring-pages.md#overview) |
| **Database** | **Buffer Cache**: what is in `shared_buffers`, the dirty share, each database's share, and the most-cached relations | [Buffer Cache](monitoring-pages.md#buffer-cache) |
| **Configuration** | **Parameter Changes**: every change to a server parameter, with the old and new value, kept for a year | [Parameter Changes](monitoring-pages.md#parameter-changes) |
| **Locks** | **Lock Wait History**, **Recent Lock Waits**, and **Lock Waits by Query**: who was blocked, by whom, and whether the blocker was idle in an open transaction | [Locks](monitoring-pages.md#locks) |
| **Logs** | **Events from the Server Log** and **Recent Events**: server log entries sorted into 26 categories, with counts and the entries themselves | [Logs](monitoring-pages.md#logs) |
| **Vacuum Advisor** | **Vacuum History** for any table, each autovacuum run from the server log, dead rows a vacuum could not remove, and a wraparound forecast in days | [Vacuum Advisor](vacuum-advisor.md#vacuum-history) |
| **Index Advisor** | **Index History**: 12 months of size and usage for any index, with usage badges on the recommendations; **Apply** and **Apply History** | [Index Advisor](index-advisor.md#index-history) |
| **Plan Drift Advisor** | **Workload Anomalies**: statements slower or busier over the last 24 hours than over the prior week; query-rewrite cards | [Workload Anomalies](plan-drift-advisor.md#workload-anomalies) |
| **Plan Analysis** | Four more insights (Disk Sort, Hash Batches, Expensive Node, Large Offset) and a non-sargable-predicate call-out | [The insights](plan-analysis.md#the-insights) |
| **PostgreSQL Cluster** home | **Leader Change History**: every switchover and failover, newest first | [Leader Change History](monitoring-pages.md#leader-change-history) |

Locks, Logs, Idle Connections, and Vacuums in Progress also gained a **Database** selector, and every page now has a title, one heading style, and its sections listed in the navigation under **On this page**.

**Apply an index recommendation from the page.** Each exact recommendation on **Index Advisor** has an **Apply** action. It shows the exact `CREATE INDEX CONCURRENTLY` or `DROP INDEX CONCURRENTLY` statement, you confirm it, and it runs as the new job **PostgreSQL - Apply Index Recommendation** with your own Preferred Credentials. Nothing runs without that confirmation. See [Apply a recommendation](index-advisor.md#apply).

**Forecasts and anomalies as metrics.** Nine new metrics publish the same findings to Enterprise Manager. Two ship with thresholds: **Transaction ID Wraparound Forecast** warns at 14 days and goes critical at 7, and the **Background Writer** metric's new checkpoint spike ratio warns at 2 times the baseline and goes critical at 3. On the cluster target, **Leader Change Alert (Patroni)** warns while a leader change is under 24 hours old. The others (**Cluster Size Capacity Forecast**, **Workload Anomalies**, **Vacuum Log Insights**, **Server Log Events**, **Lock Contention**, **Buffer Cache**, **Parameter Drift**) ship with no threshold, for you to set in a monitoring template. See [Default thresholds](alerts-and-templates.md#default-thresholds).

**A fourth monitoring template.** `ip_xpgs_cluster_production_critical` covers the cluster target, and the three database templates carry the wraparound forecast thresholds. See [Monitoring templates](alerts-and-templates.md#templates).

**A narrower way to grant server log access.** The features that read the server log now work through three superuser-owned functions that can read files in the log directory only. A script installs them and grants your monitoring role EXECUTE. The grant on PostgreSQL's built-in functions that earlier releases asked for still works. See [Enabling the log-enhanced features](log-enhanced-features.md).

**A pgBackRest metric extension.** A script and instructions for reporting pgBackRest backup history as an Enterprise Manager metric. See [pgBackRest backup history](jobs-and-metric-extensions.md#pgbackrest).

**Three things to know before you upgrade**

- **Plan Insights can raise new Warnings.** The metric's HIGH-severity condition applies to the new insight codes too. After the upgrade, a sort spilling 256 MB or more to disk, or a hash join of 8 batches or more, raises a Warning on targets that had none before, and a ticket where your incident rules route to a ticketing connector. See [Plan Insights alerts](plan-analysis.md#plan-insights-alerts).
- **The log-based sections stay inactive until the grant is in place.** A target that already has plan capture working already has a grant that covers them. The vacuum history also needs `log_autovacuum_min_duration = 0`.
- **Captured plans need the database name in `log_line_prefix`.** On the PostgreSQL default prefix, plans are listed under every database as "unknown" until `%u@%d` is added. See [Log line prefix](log-enhanced-features.md#log-line-prefix).

## The new pages at a glance

| Page | What it answers | Needs |
|---|---|---|
| **Monitoring Readiness** | Is this target configured for each feature, and what exactly is missing? | [The monitoring role](prerequisites.md#monitoring-role) to view; [Preferred Credentials](prerequisites.md#preferred-credentials) to apply settings |
| **Plan Analysis** | What plan did this query actually run, and what is wrong with it? | [Plan capture (auto_explain)](prerequisites.md#auto-explain) and [the server log read grant](prerequisites.md#log-read-grant) |
| **Plan Drift Advisor** | Is this query still on a plan I certified, and when did it leave? | [Plan capture (auto_explain)](prerequisites.md#auto-explain) and [the server log read grant](prerequisites.md#log-read-grant) |
| **Workload History** | Which statements grew over the last weeks, and by how much? | [Statement statistics (pg_stat_statements)](prerequisites.md#pg-stat-statements) |
| **Index Advisor** | Which indexes should I create, drop, or rebuild? | Nothing. [`hypopg` and `pg_qualstats`](prerequisites.md#optional-extensions) add cost simulation and predicate evidence |
| **Vacuum Advisor** | Why is autovacuum not keeping this table clean? | Nothing. [`pgstattuple`](prerequisites.md#optional-extensions) adds the bloat estimate |
| **Retention Policies** | How long is each kind of history kept, and how large can the store get? | [Preferred Credentials](prerequisites.md#preferred-credentials) |
| **Realtime ▸ Vacuum xmin Horizon** | What is holding the transaction horizon back right now? | [The monitoring role](prerequisites.md#monitoring-role) |

## Monitoring Readiness

**Monitoring Readiness** is where to go first after the upgrade. It probes the target once when the page loads and reports, feature by feature, what that feature needs, the value live on the server now, and what happens while the two differ. Eight panels cover the monitoring connection, plan capture, `pg_stat_statements`, wait-event sampling, the two Index Advisor extensions, `pgstattuple`, `pg_buffercache`, and the agent-local history store, each with an **OK**, **Attention**, or **Not functional** chip. Where the plug-in can set something itself, a **Configure auto_explain** button appears and previews exactly what it will apply before you confirm; the settings take effect for new sessions with no restart. Extensions and the server log read grants are never applied for you, so those rows show the statement to run in your own tooling instead.

![The Monitoring Readiness page with its feature panels and status chips](images/13-5-15/readiness-page.png)

*Monitoring Readiness: one panel per feature, each showing the live value beside the value the feature needs.*

Read more: [Monitoring Readiness](monitoring-readiness.md)

## Plan Analysis

**Plan Analysis** keeps the execution plan a slow query actually ran, which is usually gone by the time anyone goes looking. `auto_explain` writes the plan to the server log during the query's own execution, and the plug-in harvests it over its existing JDBC connection: there is no re-execution, and no EXPLAIN triggered by the plug-in. Each capture renders as a plan tree with estimated versus actual rows per node, and nine detection rules run over it (Insufficient Index, Misestimate, Stale Statistics, Slow Sequential Scan, Lossy Bitmap, Disk Sort, Hash Batches, Expensive Node, Large Offset), each producing a card that names the pathology and, where there is one, the setting to change. When the highest-impact finding across all captures is a missing index, a banner above the list carries an **Open Index Advisor →** button.

![The Plan Analysis page with its KPI tiles and the Historical Query Insights list](images/13-5-15/plan-analysis-page.png)

*Plan Analysis: the plan archive, the live capture threshold, and one row per captured statement with its insight count.*

Read more: [Plan Analysis](plan-analysis.md)

## Plan Drift Advisor

**Plan Drift Advisor** answers the other half of the question: whether the query is still running a plan you certified. It keeps a set of accepted baseline plans per query, compares every new capture against that set, and lists only the queries that have drifted, so once you have accepted baselines, an empty **Problematic Queries** list ("No problematic queries found.") is the healthy state. Select a row and you get the drift history over a window you choose, a side-by-side plan-tree comparison against the baseline, insight cards for the current plan, an Audit Trail carrying the labels and reasons you enter while managing baselines, and the **Fix Workbench: Test a Rewrite**. Baseline mode ships as Manual, so no plan becomes accepted-good without a named operator action. The workbench runs the only EXPLAIN that executes a statement, `EXPLAIN (ANALYZE, FORMAT JSON)` once per click, and is the one place the plug-in's console runs SQL you supply (custom-query Metric Extensions you define run your own SQL on their own schedule — see [Jobs and metric extensions](jobs-and-metric-extensions.md)). Nowhere else does the plug-in execute a statement to obtain a plan: the Index Advisor's HypoPG simulation plans a synthetic lookup with `EXPLAIN (FORMAT JSON)` and executes nothing. Nothing runs until you click **Run Explain**.

![The Plan Drift Advisor page showing the Problematic Queries list](images/13-5-15/plan-drift-problematic-queries.png)

*Problematic Queries is the entry point: severity, cost delta against the baseline, and how recently each query was captured.*

Read more: [Plan Drift Advisor](plan-drift-advisor.md)

## Workload History and wait events

**Workload History** replays the `pg_stat_statements` snapshots kept in the agent-local store across a window you pick, so a database that got slower over two weeks shows the shape of it rather than a spike you missed. The KPI band gives history depth, the statements active in the window, and this window measured against the equal-length window before it; the detail list ranks statements or databases by total execution time, calls, mean, rows returned, or I/O share, and clicking a statement plots that one statement's own history. Wait-event sampling arrives with it: install `pg_wait_sampling` and the **Wait Events Sampled** metric enables itself on that target, feeding the **Wait Events** chart on **Query Analyzer** for a selected statement over the last day, week, or month.

![The Workload History page with its KPI band, trend chart, and workload detail list](images/13-5-15/workload-history-page.png)

*Workload History: the trend for the selected metric, and the statements behind it ranked for the same window.*

Read more: [Workload History](workload-history.md)

## Index Advisor

**Index Advisor** lists the indexes worth creating, dropping, or rebuilding across every database on the instance. Catalog-native detection needs no extension and covers five categories (Missing, Unused, Invalid, HOT-inhibiting, Consolidation), with an impact rank, an evidence sentence, and a `CONCURRENTLY` statement on every row. The configuration to aim for is `hypopg` and `pg_qualstats` installed in the databases you care about: `hypopg` prices each missing-index candidate by planning it as a hypothetical index, with no build and no lock taken, and reports the estimated speedup; `pg_qualstats` ranks candidates by the predicates your workload actually filtered on and infers the right access method, including GIN and GIST. Nothing is applied without your say-so. You click a SQL cell, copy the statement, and run it in your own tooling, or you use **Apply** on an exact recommendation, confirm the statement shown, and let it run as an Enterprise Manager job.

![The top of the Index Advisor page with its category KPIs, a recommendation banner with its Apply button, and the Missing Index Recommendations section](images/24-1-4/index-advisor-top.png)

*Index Advisor: detections by category, a headline recommendation confirmed by the index history, and the summary tables.*

Read more: [Index Advisor](index-advisor.md)

## Vacuum Advisor and xmin horizon

**Vacuum Advisor** answers why a table keeps growing while autovacuum is nominally running. It recomputes each table's real trigger point from its effective settings, so a per-table `reloptions` override that moved the trigger becomes visible instead of mysterious, and it hands you the `ALTER TABLE` statement that tightens it. The same page reports XID consumption against the wraparound limit, dead-tuple bloat, autovacuum runs in the last 24 hours, and the xmin-horizon root cause: the session, replication slot, or prepared transaction pinning cleanup, named, with the release command ready to copy. **Realtime ▸ Vacuum xmin Horizon** watches the same holders live at a refresh interval you choose, and with `pgstattuple` installed an avoidable-growth estimate per table joins the page. Every command here is text for you to run; the plug-in executes none of it.

![The Vacuum Advisor page with the XID Consumption panel, its wraparound forecast, and the Vacuum Health KPIs](images/24-1-4/vacuum-advisor-page.png)

*Vacuum Advisor: wraparound position and forecast, the health KPIs, and the xmin-horizon root-cause card.*

Read more: [Vacuum Advisor](vacuum-advisor.md)

## Retention Policies and the history store

The granular history behind these pages lives in a per-target SQLite database on the agent host rather than in the Enterprise Manager repository, so months of statement-level and object-level detail cost the repository nothing. The store creates itself at the first collection that persists history, condenses each completed day once a day, and prunes itself on the same schedule. **Retention Policies** is the single control surface: a retention window and a protected minimum for each of the nineteen history types, plus the whole-store size ceiling. Most types ship at 90 days, and the index archive and the parameter change history at 365. The whole-store ceiling ships disabled, so the retention windows are the bound until you set one; the captured-plan archive has its own ceiling, which ships enabled at 100 MB and evicts oldest first. Saved changes take effect at the next daily trim.

![The Retention Policies page with the Retention Windows table](images/24-1-4/retention-policies-page.png)

*Retention Policies: every history type's window and protected minimum.*

Read more: [History store and retention](history-store-and-retention.md)

## Alerts and monitoring templates

Every new advisor finding also publishes as a standard Enterprise Manager metric, so you can be told rather than go looking. Plan drift, plan insights, the three Index Advisor metrics, autovacuum frequency, table bloat, and the xmin horizon all carry editable collection schedules, tunable thresholds, alert history, and routing through whatever notification connector you already have bound. Thresholds ship pre-set where a safe default exists, and undefined where the right value is site policy: the xmin horizon metric warns at Wraparound Severity 1 (an XID age of 1 billion) and goes critical at severity 2 (1.5 billion) after two consecutive collections, while the super-user count threshold ships empty because only you know your sanctioned roster size. Four importable [monitoring templates](alerts-and-templates.md#templates) apply a curated set in one step: `ip_xpgs_production_critical` for critical production, `ip_xpgs_standard` for dev, test, and staging, `ip_xpgs_starter` as a seed to clone, and `ip_xpgs_cluster_production_critical` for the cluster target.

![The Vacuum xmin Horizon metric and its shipped thresholds under All Metrics](images/13-5-15/all-metrics-xmin-horizon-thresholds.png)

*New advisor findings arrive as ordinary metrics, with the thresholds and schedules you already know how to edit.*

Read more: [Alerts and templates](alerts-and-templates.md)

## Collection throttle

On a local agent running on Linux, you can now set **Collection Throttle: CPU Threshold (%)** and **Collection Throttle: Memory Threshold (%)** on the target. While the agent host sits at or above either threshold, the plug-in skips its heavier scheduled collections for that cycle instead of adding to the load, and an amber informational banner reports it at the top of every plug-in page. Availability checks, real-time pages, and anything you trigger yourself are never gated, and no collection schedule is changed by any of this. Both properties are empty by default, which leaves the feature off. The `collection_throttle` metric records every gate window and its reason, so gaps in a chart always have an explanation.

Read more: [Collection throttle](history-store-and-retention.md#collection-throttle)

## What changed or moved {#what-changed-or-moved}

- **The explain workbench moved off Query Analyzer.** Testing a rewrite now happens in **Fix Workbench: Test a Rewrite** on [Plan Drift Advisor](plan-drift-advisor.md), beside the plan comparison you need in order to judge the result. It still runs `EXPLAIN (ANALYZE, FORMAT JSON)` on the statement in the box, and still only when you click **Run Explain**.
- **The retention editor moved off Workload History.** All retention windows now live on the [Retention Policies](history-store-and-retention.md#retention-policies) page, together with the store size ceiling. Workload History links to it from the bottom of the page. Older screenshots and guides show the editor in its previous position.
- **The `waits_sampled` metric is retired.** Wait-event data now comes from **Wait Events Sampled**, which enables itself only on targets where `pg_wait_sampling` is detected. See [Wait-event sampling](workload-history.md#wait-event-sampling).
- **Two target properties were added.** **Collection Throttle: CPU Threshold (%)** and **Collection Throttle: Memory Threshold (%)** appear on Database and Cluster targets, both empty by default. See [Collection throttle properties](targets-and-properties.md#throttle-properties).

## New prerequisites

Nothing here is required to keep monitoring what you monitor today. Each item adds one part of the release, and **Monitoring Readiness** checks the grant, the `auto_explain` settings, and the extensions live, per target.

- [ ] `auto_explain` installed on the database server and configured for capture, with `log_min_duration` set to 0 or higher, `log_format = json`, and `log_analyze = on`, plus the server-side logging settings capture reads from (`logging_collector = on`, the `stderr` log destination, and a `%m`-led `log_line_prefix`), which are yours to set — see [Plan capture (auto_explain)](prerequisites.md#auto-explain). Required for **Plan Analysis** and **Plan Drift Advisor**. The plug-in applies the `auto_explain` settings for you from **Configure auto_explain**.
- [ ] The server log read grant, run by a superuser in each monitored database, so the plug-in can read the server log: `enable_log_enhanced_features.sql` for the narrow `xpgs_monitor` reader, or EXECUTE on the four built-in log functions — see [The server log read grant](prerequisites.md#log-read-grant). Required for **Plan Analysis**, **Plan Drift Advisor**, the Vacuum Advisor's server-log sections, and the server log events on **Logs**. Of the settings the plug-in could apply itself, this is the one it deliberately never does.
- [ ] `log_autovacuum_min_duration = 0`, and `%u@%d` in `log_line_prefix`, for the vacuum history and for captured plans that name their database — see [Enabling the log-enhanced features](log-enhanced-features.md).
- [ ] Optional extensions, installed by you through your own packaging and detected automatically — see [Optional extensions](prerequisites.md#optional-extensions). `hypopg` and `pg_qualstats` for the full **Index Advisor** output, `pg_wait_sampling` for wait events, `pgstattuple` for bloat estimates, `pg_buffercache` for the **Buffer Cache** section.
- [ ] Preferred Credentials set for the target, because the advisor pages read their data through Enterprise Manager jobs — see [Preferred Credentials](prerequisites.md#preferred-credentials).

## Upgrading from 13.5.12

1. Import the new OPAR (13.5.18.0.0 on Enterprise Manager 13.5, 24.1.4.0.0 on 24ai) and deploy it to the OMS and to every monitoring agent, the same three steps as any plug-in update. See [Upgrade from an earlier release](install-and-upgrade.md#upgrade). Targets, thresholds, schedules, and credentials carry forward unchanged, and the agent-local history store is created automatically at the first collection after the upgrade.
2. Allow up to 24 hours for the OMS metadata refresh. An "Error getting meta-data" message during that period clears itself. See [After an upgrade](install-and-upgrade.md#after-upgrade).
3. Open **Monitoring Readiness** on each target and read the panels top to bottom. The panels tell you which of the new prerequisites that particular target is still missing.
4. On the targets where you want plan capture or the other server-log features, run the server log read grant; for plan capture, then click **Configure auto_explain** and **Apply**. Reload the page to confirm the panel turned green.

## Full changelog

The [Changelog](changelog.md) lists every new page, metric, job, template, and fix in the current release (24.1.4.0.0 / 13.5.18.0.0), and the releases before it.

## Related

- [Prerequisites](prerequisites.md#checklist) — the full checklist, split into what existing monitoring needs and what the advisory features add
- [Install and upgrade](install-and-upgrade.md#upgrade) — the import-and-deploy sequence for the upgrade
- [Monitoring Readiness](monitoring-readiness.md) — the per-target view of which prerequisites are in place
- [Changelog](changelog.md) — every new page, metric, job, and fix in this release
