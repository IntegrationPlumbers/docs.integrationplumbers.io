---
title: Changelog
nav_order: 18
---

# Changelog

This page lists what changed in each release of the PostgreSQL plug-in, most recent first.

## 13.5.15.0.0

**New pages**

- [Monitoring Readiness](monitoring-readiness.md) — checks each advisor's prerequisites against what's live on the target, and applies the `auto_explain` settings for you where the plug-in can set them itself.
- [Plan Analysis](plan-analysis.md) — captured execution plans with per-node estimated-versus-actual rows and insight-rule recommendations.
- [Plan Drift Advisor](plan-drift-advisor.md) — plan baselines, drift detection against the accepted baseline, and the Fix Workbench, the only place the plug-in runs an EXPLAIN.
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

- `ip_xpgs_tier01_critical` — critical production
- `ip_xpgs_tier23_standard` — dev, test, and staging
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
- Fixed silent job-failure bugs in Backup, Restore, Switchover, and Custom Query job wrappers (Perl wrappers now correctly propagate the Java exit code so failed jobs are reported as Failed in OEM)
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

- Fixed compatibility issues with newer versions of OEM

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
