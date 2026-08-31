---
title: What's new
nav_order: 1
---

# What's new in this release

This is the Open Beta of the IBM DB2 plug-in — the first release covered by this guide. It ships as two builds with the same features, **24.1.9.7.0** for Enterprise Manager 24ai and **13.5.9.2.0** for Enterprise Manager 13.5, the first drop to make the 13.5 build available alongside 24ai. Everything below is new, because there is nothing before it: read this page as the feature list for the release, and [the beta terms](#beta-terms) as what you are agreeing to by installing it.

**Where to find it:** the plug-in appears under **Setup → Extensibility → Plug-ins → Databases → IBM DB2 Database (Beta)**; its pages appear in the `ip_db2_database_beta` target's own navigation tree once a target is added.

**In this page:** What is verified · Beta identity · Feature-complete scope · Known limitations · Beta terms · Feedback · Full changelog

## What is verified {#beta-status}

Open Beta means the release is feature-complete for its scope and has been exercised end to end against live systems — not yet a production-supported release. Read the columns below as what to trust today versus what to treat as still closing out.

| Area | Status |
| :--- | :--- |
| Offline build / EDK validation | **Verified** — both the GA and beta identities build clean through Oracle's plug-in packager. |
| Live OMS deployment (24ai) | **Verified** — import, server-side deploy, and agent-side deploy against a running Enterprise Manager 24ai, on both a local Linux agent and a remote Windows agent. |
| Live Db2 12.1 collection | **Verified** — real metric collection cycles against a Db2 12.1 target. |
| Licensing | **Verified** end to end against real keys: Active, Expired, Invalid Signature, Exceeded Limit, and the beta↔GA identity dead end in both directions. |
| Metric semantics | **Verified** against IBM Db2 12.1 documentation, with a hard rule that a metric must mean the same thing as the plug-in it replaces, so thresholds carried over from prior monitoring behave predictably. |
| Least-privilege grant, TLS, audit-posture config | **Verified** — certified against a live Db2 12.1.4 instance; see [The monitoring role](prerequisites.md#monitoring-role). |
| Live Db2 11.5 collection | **Not yet closed.** A full 11.5 collection run is still to be completed; 11.5 is supported by design and certification is in progress. |
| Enterprise Manager 13.5 line | **Not yet closed.** The 13.5.9.2.0 build passes the full 13.5 EDK validation but has not yet been through the live-deploy and console verification given to 24ai — treat 24ai as the reference platform until it catches up. |
| HADR standby pair | **Not yet closed.** HADR deep monitoring is built and metric-verified, but has not been exercised against a live primary+standby failover pair — see [HADR monitoring](hadr-monitoring.md#known-limitation). |
| Amazon RDS for Db2 | **Documentation-verified only.** See [Troubleshooting](troubleshooting.md#rds-for-db2). |

## Beta identity {#beta-identity}

The beta ships under its own plug-in identity, deliberately separate from the eventual GA release:

| | Open Beta | General availability |
| :--- | :--- | :--- |
| Plug-in ID | `ip.em.xdbb` | `ip.em.xdb2` |
| Target type | `ip_db2_database_beta` | `ip_db2_database` |
| Display name | IBM DB2 Database (Beta) | IBM DB2 Database |
| Version line | `24.1.9.N.0` / `13.5.9.N.0` | `24.1.<n>.0.0` |
| Licence keys | Issued for `ip.em.xdbb` | Issued for `ip.em.xdb2` |

- **Beta to beta upgrades in place**, within the beta line — see [Install and upgrade](install-and-upgrade.md#upgrade).
- **Beta to GA is always a clean install, never a migration.** Nothing a beta install writes to your repository — targets, metric history, tuned thresholds — carries into GA, and a beta target remains identifiable as such in any audit. Plan the GA rollout as a fresh deployment alongside the beta, then retire the beta targets.
- Both plug-ins can be deployed to the same OMS and the same agent at once; a licence key minted for one identity is structurally rejected by the other (`Invalid Signature`) rather than silently accepted.

## Feature-complete scope

Everything the beta covers, all new in this release:

- **Full metric parity with a curated set of new capability**, rebuilt cleanly on `MON_GET_*` — availability, roughly 14 performance groups (buffer pool, cache, sort/hash memory, transaction-log and direct I/O, agent and connection statistics), storage, and locking with by-table, by-blocked-application, and by-blocking-application roll-ups. No discontinued `SNAP_GET_*` interface is used anywhere. See [Monitoring pages](monitoring-pages.md).
- **Backup, restore, and load history.** A `DB_History` metric group reads `SYSIBMADM.DB_HISTORY` directly, with per-operation status and a failed-operation alert — beyond the age-only backup check every prior Db2 monitoring tool shipped.
- **SQL workload analytics (QAN v1).** Periodic top-SQL delta snapshots keyed by a statement-ID hash, with per-statement CPU-time and execution-count trends.
- **Deep HADR monitoring.** Role, state, sync mode, connection status, heartbeats, and log positions, plus a takeover-readiness composite and a connection-status alert. See [HADR monitoring](hadr-monitoring.md).
- **Tablespace growth forecasting.** Per-tablespace snapshots feed a growth-rate and days-to-full projection alongside auto-resize tracking.
- **Curated default thresholds.** Sensible Warning/Critical values ship enabled on the metrics that matter, instead of arriving `Not Defined` across the board. See [Alerts and thresholds](alerts-and-templates.md).
- **First-class TLS and least privilege.** A first-class SSL/TLS transport with client-truststore validation, DRDA AES-256 encryption as a first-class property, and a documented, certified least-privilege monitoring grant — `CONNECT` + `SQLADM`, nothing more. See [Prerequisites](prerequisites.md#monitoring-role).
- **Compliance and advisor pack v1.** The first-ever compliance content for a Db2 plug-in: configuration best-practices, a version end-of-life advisory, and audit-posture rules. See [Compliance standards](compliance-standards.md).
- **Native console pages.** Three MPCUI pages — Home, Analysis, Performance — with no dependency on a legacy report platform.
- **Six administrative job types**, including a Purge Stale Plugin Cache job you should run (or schedule) after every upgrade. See [Jobs](jobs-and-metric-extensions.md#purge-stale-cache).
- **Amazon RDS for Db2 compatibility, documented.** The JDBC metric surface is expected to work unchanged against an RDS endpoint; the local-only admin jobs and diagnostic-log monitoring are not. See [Troubleshooting](troubleshooting.md#rds-for-db2).
- **Licensing enforcement.** Every target needs a beta licence key or it stops collecting everything but three deliberately-exempt metric categories — see [Getting started](getting-started.md#licence-key) and [Troubleshooting](troubleshooting.md#licence-gate).

## Known limitations

- **Live Db2 11.5 collection, the Enterprise Manager 13.5 line, and an HADR standby pair are still closing out** — see [What is verified](#beta-status) above.
- **Amazon RDS for Db2 is documentation-only in this release.** Compatibility, including the `rdsadmin` grant path, is doc-verified but not lab-certified. On RDS the five local administrative jobs and diagnostic-log monitoring are unavailable, because the agent cannot be co-located with the instance. See [Troubleshooting](troubleshooting.md#rds-for-db2).
- **SQL workload analytics are numeric-only.** Top-SQL trends are keyed by a statement-ID hash; full statement-text capture is planned for a later release.
- **Deferred to a later release:** Workload Management (WLM), lock/deadlock event capture, BLU/columnar, pureScale, AI Query Optimizer monitoring, Q Replication, auto-discovery, remote administrative operations, and Db2 for z/OS.

## Beta terms {#beta-terms}

By installing, deploying, or using this build you accept the following.

1. **Not for production.** Deploy it to a non-production Enterprise Manager and monitor non-critical Db2 databases. Do not use it for production monitoring, for compliance-of-record, or as the basis for operational decisions until the general-availability release.
2. **No warranty and no service level.** The software is provided "as is". There is no guarantee of availability, accuracy, fitness for a particular purpose, response time, or resolution.
3. **Behaviour may change.** Metric names, collection intervals, default thresholds, and console pages may change between beta drops and before GA. Changes that need action on your side are recorded in this page's [changelog](changelog.md).
4. **A licence key is required.** Each target needs a beta licence key entered on it, or it reports `License Required` and stops collecting everything but Response, Version, and its own License metric. See [Getting started](getting-started.md#licence-key).
5. **Support is best effort.** Beta issues are handled through your Integration Plumbers support contact, not a production support queue.

## Feedback

Send findings — bugs, confusing metrics, missing thresholds, unclear documentation — through your Integration Plumbers support contact. Include the plug-in version (`emcli list_plugins_on_server`), the Enterprise Manager line (24ai or 13.5), the Db2 version (11.5 or 12.1), the metric group or console page involved, and any deploy log, agent log, or collection-error text. HADR-pair, Db2 11.5, and RDS observations fill known gaps in our own lab coverage and are especially valuable.

## Full changelog

The [Changelog](changelog.md) lists every beta drop, most recent first, including the drops that predate this guide.

## Related

- [Getting started](getting-started.md) — install the plug-in and add your first target
- [Trial setup](trial.md) — request a beta licence key and work the guided evaluation
- [Prerequisites](prerequisites.md) — supported versions, the monitoring role, and network requirements
- [Troubleshooting](troubleshooting.md#licence-gate) — what an unlicensed target looks like, and how to fix it
- [Changelog](changelog.md) — every beta drop in detail
