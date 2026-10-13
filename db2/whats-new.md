---
title: What's new
nav_order: 1
---

# What's new in this release

This is the first general-availability (GA) release of the IBM Db2 plug-in, `ip.em.xdb2`, released on 2026-10-12. It ships as two builds with the same features: **24.1.1.0.0** for Enterprise Manager 24ai and **13.5.2.0.0** for Enterprise Manager 13.5. The two lines are versioned independently. Both builds have been verified on a live Enterprise Manager, including deployment and every console page.

**Where to find it:** the plug-in appears under **Setup → Extensibility → Plug-ins → Databases → IBM DB2 Database**. Its pages appear in the `ip_db2_database` target's own navigation tree once a target is added.

**In this page:** Read this first · Known issue · Breaking changes · Statement text and your data · What's new for monitoring · What's new in the console · What's new for administration · Changed defaults · Fixes · Feedback

## Read this first {#read-this-first}

- **This is the first GA release**, so there is no earlier GA release to upgrade from. Install it fresh: see [Getting started](getting-started.md). The first GA update after it is the first release that upgrades in place.
- **Moving from the Open Beta is a clean install, not an upgrade.** GA is a different plug-in from the Open Beta:

  | | Open Beta | GA |
  | :--- | :--- | :--- |
  | Plug-in ID | `ip.em.xdbb` | `ip.em.xdb2` |
  | Target type | `ip_db2_database_beta` | `ip_db2_database` |
  | Display name | IBM DB2 Database (Beta) | IBM DB2 Database |

  Nothing from a beta install carries over. Add the targets again under GA, and set thresholds, templates and credentials on them again. The two plug-ins can run side by side on one OMS and agent while you move over. A beta licence key does not unlock GA. When the move is done, undeploy the beta. The steps are on [Moving from the beta to GA](beta-pre-release.md).
- **What changes for anyone coming from the beta:**
  - The administrative job types are renamed. See [Breaking changes](#breaking-changes).
  - Availability reads differently. An HADR standby is up, not down. A database on an unsupported Db2 version or topology still reports availability, and says what it cannot collect.
  - Alerts and collection intervals have new defaults. See [Changed defaults](#changed-defaults).
- **Support levels.** Db2 12.1 is certified at the Comprehensive level, and Db2 11.5 at the Basic level. Every metric collects on both. The level is the certification label in Enterprise Manager's plug-in catalog. Amazon RDS for Db2 is not certified: see [Troubleshooting](troubleshooting.md#rds-for-db2).

## Known issue {#known-issue}

**After one failed text lookup, Top Statements keeps showing numbers without SQL text** on the SQL Analytics page, until you change the time window or the ranking. Refreshing the page does not retry the lookup. The ranking and the numbers stay correct. This is fixed in the first update after GA.

## Breaking changes {#breaking-changes}

**Every administrative job type is renamed.** Job type names are global across the OMS. The old names sat in the namespace of Oracle's own Db2 plug-in, which this plug-in is designed to run alongside.

| Before | GA job type |
| :--- | :--- |
| `sidb_startup_db2` | `ip_db2_start_instance` |
| `sidb_shutdown_db2` | `ip_db2_stop_instance` |
| `sidb_quiesce_dbinst` | `ip_db2_quiesce_database` |
| `sidb_unquiesce_dbinst` | `ip_db2_unquiesce_database` |
| `sidb_kill_agent` | `ip_db2_kill_application` |

Job history, saved jobs and library entries recorded under the old names do not carry over. The beta's names were `sidbb_*`, and moving from the beta is a clean install anyway. See [Jobs](jobs-and-metric-extensions.md).

**DataFiles is retired and replaced by Table_Overflow** ("Table Overflow and Reorganization"). DataFiles keyed each row on a cumulative reorganization counter, so every reorg gave a table a new row identity. Table_Overflow keys on schema and table and carries the same counters. It keeps one row per table, summed over data partitions, leaves out temporary tables, and uploads the 100 tables with the most overflow accesses. A threshold or monitoring template set on `DataFiles.overflow_accesses` does not move to the new group: set it again on `Table_Overflow.overflow_accesses`.

## Statement text and your data {#statement-text-privacy}

The SQL Analytics page now shows the SQL text of each statement. That text is **stored in the Enterprise Manager repository, and it can contain data**:

- Db2 records SQL as it was submitted. A statement with literal values (names, IDs, amounts) carries those values in its text, unless the application uses parameter markers or the database's statement concentrator replaces literals.
- The **SQL Statement Text** metric group (`Statement_Text`) keeps that text with the repository's string metric history. Enterprise Manager retains that history for 12 months by default.
- The Top Queries groups (by CPU time and by execution count) also store statement text, and their alert messages include it.

**To stop collecting it**, disable **SQL Statement Text** for the target under **Monitoring → Metric and Collection Settings → Other Collected Items**, or in a monitoring template. With EM CLI:

```
emcli modify_collection_schedule -targetType=ip_db2_database -targetNames=<target> \
      -collectionName=Statement_Text -collectionStatus=Disabled
```

Top Statements then shows its numbers without the text.

## What's new for monitoring {#monitoring}

- **SQL text for any window.** Top Statements follows the SQL Analytics page's time window, from the last hour to the last month, and shows each statement's SQL text. The new **SQL Statement Text** group stores each statement's text at most once a day. It reads what the analytics collection already fetched, so it adds no load on the database. Text is flattened to one line and cut at 2,000 characters.
- **Storage-path headroom.** A new `Storage_Paths` group, collected every 30 minutes, reports each automatic-storage path's file system. A shipped alert warns at 85% used and goes critical at 95%.
- **A forecast for unlimited table spaces.** `Tablespace_Forecast` now forecasts auto-resize table spaces that have no maximum size, which is the Db2 default. The ceiling is the free space on their storage group's file systems. Before, they read `9999` (no forecast). A new `CapacitySource` column says which limit applies.
- **Table maintenance.** A new `Table_Maintenance` group (every 6 hours) lists tables whose statistics are stale or that need a reorg. A new `Invalid_Objects` group (hourly) counts packages that need a rebind and other invalid objects.
- **Open and idle-in-transaction units of work.** A new `Open_Transactions` group (every 5 minutes) lists the oldest open units of work. That includes idle-in-transaction sessions, which hold locks and pin the active log. `Log_Storage` now names the connection holding the oldest transaction, and for how long.
- **Lock-list use.** `DB_Monitoring` adds the lock-list size and how much of it is in use. An alert at 70% / 85% warns ahead of the lock escalations a full lock list causes.
- **Running utilities and a wider recovery history.** New `Utilities` and `Rebalance_Status` groups show the utilities running now, with a long-running alert, and the table spaces being rebalanced. `DB_History` adds reorg and rollforward entries, and a failed reorg or rollforward raises the same alert as a failed backup.
- **Monitor-switch check.** A new `Monitor_Metrics` group warns when a `MON_*_METRICS` switch is `NONE`. At `NONE`, Db2 returns zeros rather than real metrics, so dashboards look healthy while measuring nothing. The alert message gives the online fix.
- **Curated db2diag.log patterns.** Diagnostic-log monitoring ships a default pattern set: administration-notification errors, log full, table space full, HADR errors, critical records, traps and panics. Your own pattern files go in the agent state directory, which upgrades do not touch. A record that names another database is reported only by that database's target.
- **An HADR standby is monitored as a standby.** A standby reads Up, raises no collection errors for the groups it cannot serve, and can be added as a target in its own right. See [HADR monitoring](hadr-monitoring.md#monitoring-a-standby).
- **Follow the HADR primary through a takeover.** Five optional target properties turn on the driver's client reroute. A target given the other side of its pair as an alternate reads the new primary after a takeover, and the original after a failback. See [HADR monitoring](hadr-monitoring.md#client-reroute).
- **Unsupported versions and topologies fail open, and say so.** Availability collects on any Db2 version. Every other group is limited to 11.5 and 12.1. Partitioned (DPF) and pureScale databases are detected and gated off. CollectorStatus names the reason for each group it gates off.
- **Topology associations.** Each database is linked to the host target it runs on. A target with HADR alternates set is linked to the standby targets they name.
- **TLS hardening.** A new optional **TLS Hostname Validation** property (`BASIC`, the default, or `OFF`). The security mechanism is now explicit. A TLS failure names its cause instead of reading as the database being down. See [Optional transport security](prerequisites.md#tls).
- **Collection telemetry.** CollectorStatus adds how long each group's last collection took and how many attempts in a row have failed.

## What's new in the console {#console}

- **Seven pages:** Home, Analysis, Performance, Storage, Backup History, SQL Analytics and HADR. See [Monitoring pages](monitoring-pages.md).
- **Home health overview.** One row per area: availability, storage, transaction log, backup and recovery, HADR, locks, performance, SQL workload, licence, and diagnostics. Each row shows Enterprise Manager's own current verdict, the number of open alerts, the worst alert's message, and a link to the page behind it. The verdicts come from Enterprise Manager's alerts, so the overview cannot disagree with the Incidents list after you tune a threshold.
- **The pages link up.** Home shows **Related Targets**: the Db2 server, the HADR partner, the monitoring agent and its host. Analysis shows **Job Activity** and **Incidents and Problems**, and HADR shows its incidents too.
- **Each alerting metric is on the page its alert sends you to.** Backup History opens with a Last Backup section, and Storage has a Transaction Log section.
- **A time window on Storage, Backup History and HADR.** Each page gains a **Trend** section (Past hour, Past day, Past week, Past month). The trend reads stored data, so it adds no load on the database. One set of window labels is used across every page.
- **The console asks the agent for less.** Real-time charts on Home and Performance refresh once a minute. A real-time chart now starts empty and fills in as samples arrive; for history, pick **Past hour** or longer on Performance.
- **Theme and accessibility.** Status colours come from the shared Integration Plumbers theme, and a status is always a word as well as a colour. Screen readers announce every section, chart and table. Long text cells stay inside their column, with the full text in the tooltip.

## What's new for administration {#administration}

- **Three remote admin jobs:** Force Application, RUNSTATS on a Table, and Online Backup. They work on any target, including a remotely monitored one. Each runs one Db2 command over `SYSPROC.ADMIN_CMD` on the target's JDBC connection. They run as a separate admin user, held in the new **IBM DB2 Database Admin Credentials** preferred credential set, and never as the monitoring user. Every parameter is validated before anything runs. See [Remote admin jobs](jobs-and-metric-extensions.md#remote-admin-jobs).
- **Kill Blocking Application.** The Analysis page's kill action now sits on the *Blocking* table, so it forces the lock holder rather than the waiter. It asks for an explicit Yes naming the application, then reports the result.
- **The five local admin jobs enforce "local only".** Each refuses to run unless the agent is on the target's Db2 host, and none passes job parameters to a shell. Start and Stop are labelled as instance-wide.
- **Preferred host credentials.** The local jobs use a new **IBM DB2 Database Host Credentials** set. Set it per target before you use the Kill button.
- **Six runbooks (Enterprise Manager 24ai).** Runbooks for the most common Db2 alerts install with the plug-in, and Enterprise Manager recommends each on the matching incident. See [Alerts and thresholds](alerts-and-templates.md#runbooks).
- **A diagnostics job.** *Collect IBM DB2 Plug-in Diagnostics* writes one archive of the plug-in's logs and environment for support, with every credential redacted.
- **17 compliance rules.** Five rules join the three standards: the instance offers TLS; on Windows, Db2 extended security is not turned off; audit records are written asynchronously; SYSADM belongs to a named group; and the server runs the latest modification pack of its release. See [Compliance standards](compliance-standards.md).

## Changed defaults {#changed-defaults}

**New default alerts.** Several conditions that used to ship with no value now alert out of the box: table space fault states; HADR log gap, replay gap, replay lag and standby state; lock escalations; IBM licence feature use; database and instance status; and secondary logs in use. `sec_logs_allocated` now alerts on "more than 0"; before, it fired on the healthy value. The full list is on [Alerts and thresholds](alerts-and-templates.md#default-thresholds).

**Shorter collection intervals** for the metrics whose alerts could lag:

| Metric group | Was | Now |
| :--- | :--- | :--- |
| `Lock_Waits` and its three roll-ups | 30 min | 5 min |
| `HADR_Status` | 45 min | 15 min |
| `DB_Backup` | 2 h | 30 min |

All of them read light monitor sources, and the lock groups upload rows only while waits exist. The backup-age alert now confirms 1.5 hours after the threshold is crossed, not 6. The HADR connection alert now fires within 15 minutes.

## Fixes {#fixes}

- **"Target is down" now means down.** A wrong or empty password, a revoked grant, a TLS or truststore problem, a missing driver, or a database quiesced against the monitoring user now shows as a *metric collection error* that says what to fix. Unreachable hosts and stopped instances still read Down. A quiesced or roll-forward-pending database counts as Up.
- **The ratio alerts can fire again.** The buffer-pool, catalog-cache and package-cache hit ratios, the sort-overflow ratio and the average lock wait are computed per collection interval, not from totals since the database was activated. After an upgrade they report from the second collection.
- **Collector connections are always released.** Every collection query has a timeout, 60 seconds by default, which the new optional **Query Timeout** property changes. Every query returns at most 10,000 rows.
- **Arithmetic and unit corrections** to `sync_index_read_rate`, `creation_to_assigning_ratio`, the HADR log positions (now in bytes), `tablespace_max_size` (-1 for no maximum) and `HadrTimeout` (now in seconds). A new `ValuesLive` column says when the HADR gap and lag values are last-known rather than live.
- **A `|` inside a collected value**, such as Db2's `||` operator in statement text, no longer corrupts the row.

## Feedback

Send findings — bugs, confusing metrics, missing thresholds, unclear documentation — to **helpdesk@integrationplumbers.io** or through the [customer portal](https://integrationplumbers.zohodesk.com/portal/en/signin). Include the plug-in version (`emcli list_plugins_on_server`), the Enterprise Manager line (24ai or 13.5), the Db2 version (11.5 or 12.1), the metric group or console page involved, and any deploy log, agent log, or collection-error text.

## Related

- [Moving from the beta to GA](beta-pre-release.md) — for Open Beta users
- [Getting started](getting-started.md) — install the plug-in and add your first target
- [Install and upgrade](install-and-upgrade.md#download) — the release files and their SHA-256 checksums
- [Troubleshooting](troubleshooting.md#licence-gate) — what an unlicensed target looks like, and how to fix it
- [Changelog](changelog.md) — every release, with the beta history below
