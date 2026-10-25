---
title: Changelog
nav_order: 13
---

# Changelog

This page lists what changed in each release of the IBM Db2 plug-in, most recent first, in brief: [What's new](whats-new.md) has the detail. The plug-in is `ip.em.xdb2`, with target types `ip_db2_database` and, from 24.1.2.0.0 / 13.5.3.0.0, `ip_db2_instance`. Its Enterprise Manager 24ai and Enterprise Manager 13.5 builds are versioned independently. The Open Beta history follows the released versions, under [Beta line](#beta-line).

## 24.1.2.0.0 (Enterprise Manager 24ai) / 13.5.3.0.0 (Enterprise Manager 13.5), GA, 2026-10-23 {#update-24-1-2}

The general-availability release of `ip.em.xdb2`. It installs fresh, or in place over the initial release, 24.1.1.0.0 / 13.5.2.0.0. Moving from the Open Beta is a clean install: see [Moving from the beta to GA](beta-pre-release.md). One release, two builds with the same content: 24.1.2.0.0 installs on Enterprise Manager 24ai, 13.5.3.0.0 on Enterprise Manager 13.5. The full detail is on [What's new](whats-new.md#update-24-1-2), and the operator actions are on [Upgrade notes](upgrade-notes.md#update-24-1-2).

- Redesigned the console: every page opens with the question it answers and a row of KPI tiles, under a left navigation grouped as Workload, Storage and Logs, and Protection. Renamed Home to Overview, SQL Analytics to SQL, Analysis to Locks, Backup History to Backup, and HADR to High Availability, and moved the transaction log from a section of Storage to its own Transaction Log page.
- Added ten database pages (Sessions, Waits, Members, Tables, Indexes, Transaction Log, Memory & Sorts, Configuration, Monitoring Readiness, License Info), auto-refresh on Locks and Sessions (paused while the browser tab is in the background), statement history and Explain Plan in Statement Detail (also opened from Recent Deadlocks), and a Back Up Database dialog. The backup job (type 1.6) refuses a partitioned (DPF) database however it is submitted.
- Added the IBM Db2 Instance target type, automatic discovery of local databases, partitioned (DPF) database support, and pureScale member and CF health (implemented, not lab-certified).
- Added monitoring for log archiving, instance memory, waits, latches, WLM, indexes, blocking chains, deadlocks (opt-in) and sessions, twelve compliance rules, the Archive IBM Db2 Active Log job, Kerberos authentication, and three monitoring templates.
- Moved the licence key into a credential set, with a 14-day grace period after expiry, and counted keys of 100 instances or more.
- Renamed seven lock and session metric groups, whose stored history restarts on the upgrade. Thresholds set on the old names must be set again on the new ones:

  | Retired group | Replaced by |
  | :--- | :--- |
  | `AgentStatistics` | `Application_Statistics` |
  | `Sessions` | `Top_Sessions` |
  | `Open_Transactions` | `Oldest_Transactions` |
  | `Lock_Waits` | `Longest_Lock_Waits` |
  | `Lock_Waits_By_Blkd_App` | `Lock_Waits_By_Blocked_App` |
  | `Lock_Waits_By_Blkng_App` | `Lock_Waits_By_Blocking_App` |
  | `Blocking_Chains` | `Blocking_Tree` |

- Keyed SQL statements by digest, so literal values no longer create repository keys.
- Moved the plug-in's caches and log out of the agent plug-in home, into the agent state directory.
- Signed the release downloads: each OPAR comes with a `SHA256SUMS` file and a detached cosign signature for each file.
- Moved the console to theme 1.1.0: higher-contrast colours, and Days to Full coloured amber under 30 days and red under 7.
- Fixed the 24.1.1.0.0 known issue (Top Statements losing its SQL text), numeric sorting in the console tables, the oldest open transaction reading *0 s*, one inflated Wait_Time and Query_Analytics interval when a DPF partition stops or comes back, and the remote admin jobs on TLS targets with a custom truststore.

**Release files and SHA-256 checksums**

| Enterprise Manager | File | SHA-256 |
| :--- | :--- | :--- |
| 24ai | `24.1.2.0.0_ip.em.xdb2_2000_0.opar` | `ff70441d9bd6be2fb1f8b928062cd11d540488b315b46d272f32cfb34d8bf4d7` |
| 13.5 | `13.5.3.0.0_ip.em.xdb2_2000_0.opar` | `c1540e8d3f12f24b22613e46e01ed4615aec2e953cc5f2a8b0aab75fdbc115b1` |

The same checksums are in the signed `SHA256SUMS` file delivered with the download: verify the signature before you trust either, see [Verify the download](install-and-upgrade.md#verify).

## 24.1.1.0.0 (Enterprise Manager 24ai) / 13.5.2.0.0 (Enterprise Manager 13.5), initial release, 2026-10-12 {#ga}

The initial release of `ip.em.xdb2`. One release, two builds with the same content: 24.1.1.0.0 installs on Enterprise Manager 24ai, 13.5.2.0.0 on Enterprise Manager 13.5. There is no earlier release of `ip.em.xdb2` to upgrade from. Moving from the Open Beta is a clean install: see [Moving from the beta to GA](beta-pre-release.md). The full detail is on [What's new](whats-new.md).

- Released the first version of the IBM Db2 plug-in for Oracle Enterprise Manager after the Open Beta, for Db2 12.1 and 11.5. Moving from the Open Beta is a clean install, and the two can run side by side while you move over.
- Added monitoring for storage-path headroom, table maintenance, open and idle units of work, lock-list use, running utilities, and the SQL text behind each statement.
- Added a health overview on the Home page, links between the plug-in's pages, a shared time window, and runbooks for the most common Db2 alerts.
- Added three administrative jobs (force an application, refresh table statistics, and take an online backup) that work on remotely monitored databases and run as a separate administrator account.
- Added compliance standards with seventeen rules, and HADR monitoring that follows the primary through a takeover and reports a standby as up.
- Renamed every administrative job type, and changed the default alert thresholds and collection intervals.

**Known issue:** after one failed text lookup, Top Statements keeps showing numbers without SQL text until the time window or the ranking changes (fixed in 24.1.2.0.0 / 13.5.3.0.0): see [What's new](whats-new.md#known-issue).

**Release files and SHA-256 checksums**

| Enterprise Manager | File | SHA-256 |
| :--- | :--- | :--- |
| 24ai | `24.1.1.0.0_ip.em.xdb2_2000_0.opar` | `afa4e2fbb38651f6cd3b699e9fd5551f51e39fa56839dff7f300281faa08aa35` |
| 13.5 | `13.5.2.0.0_ip.em.xdb2_2000_0.opar` | `2cb83675ff82e21fd83b19c4f2294f1b8f7fd8747eefca15dd4afeb94568c7e9` |

## Beta line {#beta-line}

The Open Beta shipped as a separate plug-in, `ip.em.xdbb` (target type `ip_db2_database_beta`, shown as *IBM DB2 Database (Beta)*), versioned `24.1.9.N.0` for Enterprise Manager 24ai and `13.5.9.N.0` for Enterprise Manager 13.5. The beta line is closed: there are no further beta drops. These entries are kept for history.

### 24.1.9.9.0 (Enterprise Manager 24ai) / 13.5.9.4.0 (Enterprise Manager 13.5) — Open Beta

The last Open Beta drop, and the first to make the Enterprise Manager 13.5 build available alongside 24ai.

**New in this release**

- Full metric parity rebuilt on the clean `MON_GET_*` surface: availability, roughly 14 performance groups, storage, and locking with by-table, by-blocked-application, and by-blocking-application roll-ups. No discontinued `SNAP_GET_*` interface is used.
- Backup, restore, and load history (`DB_History`, from `SYSIBMADM.DB_HISTORY`) with a failed-operation alert, beyond the existing age-only backup check.
- SQL workload analytics (QAN v1): periodic top-SQL delta snapshots with per-statement CPU-time and execution-count trends, keyed by a statement-ID hash.
- Deep HADR monitoring: role, state, sync mode, connect status, heartbeats, and log positions, plus a takeover-readiness composite and a connection-status alert. See [HADR monitoring](hadr-monitoring.md).
- Tablespace growth trending and forecasting, with per-tablespace days-to-full projection and auto-resize tracking.
- Curated default Warning/Critical thresholds across the metric surface, in place of the `Not Defined` thresholds a first release would otherwise ship. See [Alerts and thresholds](alerts-and-templates.md#default-thresholds).
- First-class TLS transport with client-truststore validation, and DRDA AES-256 encryption promoted to a first-class target property.
- A documented, certified least-privilege monitoring grant — `CONNECT` + `SQLADM`, nothing more. See [The monitoring role](prerequisites.md#monitoring-role).
- Compliance and advisor pack: configuration best-practices, version end-of-life advisory, and audit-posture standards. See [Compliance standards](compliance-standards.md).
- Three native console pages — Home, Analysis, Performance — with no dependency on a legacy report platform.
- Six administrative job types, including Purge Orphaned IBM DB2 Plug-in Cache Files. See [Jobs](jobs-and-metric-extensions.md).
- Amazon RDS for Db2 compatibility, documented. See [Troubleshooting](troubleshooting.md#rds-for-db2).
- **Licensing enforcement.** Every target now carries a **Plugin Licence Key** property and a `License` metric (status, days remaining, expiration, instances, customer), checked every 15 minutes and again whenever the key changes. While the status is anything but `Active`, every metric group except License, Response, and Version reports `Collection stopped by license status: <status>` until a valid key is entered; availability keeps reporting, so the target stays Up. See [Troubleshooting](troubleshooting.md#licence-gate).
- Query Analytics windows now say what they actually are: any window wider than roughly seven days is served from Enterprise Manager's hourly rollup rather than raw samples, and is now labelled `(aggregated)` so the count on screen is not read as a raw statement count.

**Security**

- The licence instance-count connection to the OMS validates the OMS certificate and hostname by default, and no longer retries in cleartext HTTP on a failed HTTPS attempt. Both behaviors are now opt-in, lab-only escape hatches rather than the default. See [Troubleshooting](troubleshooting.md#oms-licence-count).

**Upgrade notes**

- An OMS presenting a self-signed certificate that previously validated a limited-instance licence key's count will now fail that check — this is the certificate-validation fix above taking effect, not a regression. See [Troubleshooting](troubleshooting.md#oms-licence-count) for the fix.
- Run, or schedule, [the cache purge job](jobs-and-metric-extensions.md#purge-stale-cache) (**Purge Orphaned IBM DB2 Plug-in Cache Files**) after this and every future upgrade.

**Also in this drop**

- The **DB Status** threshold on the detailed response metric uses deviation semantics, matching the DB Monitoring condition: enter the healthy status (for example `ACTIVE`) and the alert fires only when the database leaves it.

### Earlier beta drops

These predate the beta guide and are recorded here for history only.

- **24.1.9.6.0** (2026-08-31) — First release cut through a repeatable release pipeline, producing an OPAR, a customer-verifiable `SHA256SUMS`, and a `build-info.txt` naming the exact commit. Install and upgrade gates verified (Enterprise Manager 24ai only — the 13.5 line was not built for this drop).
- **24.1.9.4.0** — Beta job types renamed so a beta install can no longer collide with a GA install on the same OMS.
- **24.1.9.3.0** — Internal build and test tooling refinements.
- **24.1.9.2.0** — The drop first documented for early access: feature-complete scope, verified live OMS deployment and Db2 12.1 collection on Enterprise Manager 24ai, and end-to-end licensing.

## Related

- [What's new](whats-new.md): each release in detail
- [Upgrade notes](upgrade-notes.md): the operator actions each upgrade needs
- [Moving from the beta to GA](beta-pre-release.md): for Open Beta users
- [Install and upgrade](install-and-upgrade.md#download): download, verify and install the release files
- [IBM Db2 Plug-in](index.md): the documentation hub for every page in this guide
