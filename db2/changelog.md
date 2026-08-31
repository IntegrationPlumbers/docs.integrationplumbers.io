---
title: Changelog
nav_order: 13
---

# Changelog

This page lists what changed in each drop of the IBM DB2 plug-in, most recent first. Two identities ship from the same source: the beta line (`ip.em.xdbb`, target type `ip_db2_database_beta`, version `24.1.9.N.0` / `13.5.9.N.0`) this guide covers, and the eventual GA line (`ip.em.xdb2`, target type `ip_db2_database`, version `24.1.<n>.0.0`). Beta-to-beta upgrades in place; beta-to-GA is always a clean install — see [What's new](whats-new.md#beta-identity).

## 24.1.9.8.0 (Enterprise Manager 24ai) / 13.5.9.3.0 (Enterprise Manager 13.5) — Open Beta

The Open Beta drop this guide describes, and the first to make the Enterprise Manager 13.5 build available alongside 24ai.

**New in this release**

- Full metric parity rebuilt on the clean `MON_GET_*` surface: availability, roughly 14 performance groups, storage, and locking with by-table, by-blocked-application, and by-blocking-application roll-ups. No discontinued `SNAP_GET_*` interface is used.
- Backup, restore, and load history (`DB_History`, from `SYSIBMADM.DB_HISTORY`) with a failed-operation alert, beyond the existing age-only backup check.
- SQL workload analytics (QAN v1): periodic top-SQL delta snapshots with per-statement CPU-time and execution-count trends, keyed by a statement-ID hash.
- Deep HADR monitoring: role, state, sync mode, connect status, heartbeats, and log positions, plus a takeover-readiness composite and a connection-status alert. See [HADR monitoring](hadr-monitoring.md).
- Tablespace growth trending and forecasting, with per-tablespace days-to-full projection and auto-resize tracking.
- Curated default Warning/Critical thresholds across the metric surface, in place of the `Not Defined` thresholds a first release would otherwise ship. See [Alerts and thresholds](alerts-and-templates.md#default-thresholds).
- First-class TLS transport with client-truststore validation, and DRDA AES-256 encryption promoted to a first-class target property.
- A documented, certified least-privilege monitoring grant — `CONNECT` + `SQLADM`, nothing more. See [The monitoring role](prerequisites.md#monitoring-role).
- The first compliance content ever shipped for a Db2 plug-in: configuration best-practices, version end-of-life advisory, and audit-posture standards. See [Compliance standards](compliance-standards.md).
- Three native console pages — Home, Analysis, Performance — with no dependency on a legacy report platform.
- Six administrative job types, including Purge Stale Plugin Cache. See [Jobs](jobs-and-metric-extensions.md).
- Amazon RDS for Db2 compatibility, documented. See [Troubleshooting](troubleshooting.md#rds-for-db2).
- **Licensing enforcement.** Every target now carries a **Plugin Licence Key** property and a `License` metric (status, days remaining, expiration, instances, customer), checked every 15 minutes and again whenever the key changes. While the status is anything but `Active`, every metric group except License, Response, and Version reports `Collection stopped by license status: <status>` until a valid key is entered; availability keeps reporting, so the target stays Up. See [Troubleshooting](troubleshooting.md#licence-gate).
- Query Analytics windows now say what they actually are: any window wider than roughly seven days is served from Enterprise Manager's hourly rollup rather than raw samples, and is now labelled `(aggregated)` so the count on screen is not read as a raw statement count.

**Security**

- The licence instance-count connection to the OMS validates the OMS certificate and hostname by default, and no longer retries in cleartext HTTP on a failed HTTPS attempt. Both behaviors are now opt-in, lab-only escape hatches rather than the default. See [Troubleshooting](troubleshooting.md#oms-licence-count).

**Upgrade notes**

- An OMS presenting a self-signed certificate that previously validated a limited-instance licence key's count will now fail that check — this is the certificate-validation fix above taking effect, not a regression. See [Troubleshooting](troubleshooting.md#oms-licence-count) for the fix.
- Run, or schedule, [Purge Stale Plugin Cache](jobs-and-metric-extensions.md#purge-stale-cache) after this and every future upgrade.

### Also in this drop

- The **DB Status** threshold on the detailed response metric now uses deviation semantics, matching the DB Monitoring condition: enter the healthy status (for example `ACTIVE`) and the alert fires only when the database leaves it. An earlier internal build had this inverted; no published build carried it.

## Earlier beta drops

These predate the guide and are recorded here for history only.

- **24.1.9.6.0** (2026-08-31) — First release cut through a repeatable release pipeline (`make release` / `make release-beta`), producing an OPAR, a customer-verifiable `SHA256SUMS`, and a `build-info.txt` naming the exact commit. `META_VER` policy documented in the target metadata. Install and upgrade gates verified on the lab OMS (Enterprise Manager 24ai only — the 13.5 line was not built for this drop).
- **24.1.9.4.0** — Beta job types renamed so a beta install can no longer collide with a GA install on the same OMS.
- **24.1.9.3.0** — Recurring demo-load schedule added, alongside a beta drop.
- **24.1.9.2.0** — The drop first documented for early access: feature-complete scope, verified live OMS deployment and Db2 12.1 collection on Enterprise Manager 24ai, and end-to-end licensing.

## Related

- [What's new](whats-new.md) — the current release in detail, page by page, with what is and is not verified
- [Install and upgrade](install-and-upgrade.md) — how to move between beta drops
- [IBM DB2 Plug-in](index.md) — the documentation hub for every page in this guide
