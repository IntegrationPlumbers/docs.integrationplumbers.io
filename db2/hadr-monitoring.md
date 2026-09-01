---
title: HADR monitoring
nav_order: 8
---

# HADR monitoring

High Availability Disaster Recovery (HADR) pairs get their own metric groups beyond the summary table on Home: role, state, sync mode, connect status and heartbeats, log positions, and a takeover-readiness composite you can alert on directly, so "is the standby actually ready to take over" is answerable from Enterprise Manager rather than from a manual `db2 get snapshot for database` on the standby.

> **Prerequisites for this page**
> - A database participating in an HADR pair — the HADR metric groups populate only on databases in a pair, and read empty otherwise.
> - The target's licence status is `Active` — see [Troubleshooting](troubleshooting.md#licence-gate).

**Where to find it:** the summary table is on the target's **Home** page; the full column set is under **All Metrics → HADR_Status** and **All Metrics → HADR_Readiness**.

**In this page:** HADR Status on Home · HADR_Status metric group · HADR_Readiness and takeover readiness · Default alerts · Known limitation

## HADR Status on Home

The **HADR Status** table on the target's [Home page](monitoring-pages.md#home) shows database, role, state, sync mode, connect status, connect time, missed heartbeats, timeout, and the primary and standby log positions, one row per HADR-paired database. This is the quick-glance view; the two metric groups below carry the full detail and the alerting.

## HADR_Status metric group

`HADR_Status` collects every 45 minutes, keyed by database name. Beyond what Home shows, it carries local and remote host, service, and instance identity, and the primary's log file, page, and LSN alongside the standby's log position — the detail you need to reason about replay lag rather than just connection health.

**Shipped alert:** `HadrConnectStatus` — Warning when `CONGESTED`, Critical when `DISCONNECTED` (1 occurrence).

## HADR_Readiness and takeover readiness

`HADR_Readiness` adds the composite this page exists for: `TakeoverReady`, a single column that answers whether the standby could actually take over right now, plus log-gap, replay-gap, and replay-lag columns that explain *why* when it cannot.

- `TakeoverReady = 1` — the standby is caught up enough to take over.
- `TakeoverReady = 0` — it is not; check the gap and lag columns for how far behind.
- `TakeoverReady = -1` — the database is an auxiliary standby in a multi-standby configuration, not the one that would be promoted. This value never alerts, because it does not describe a readiness problem.

**Shipped alert:** `TakeoverReady` Critical when equal to `0` (an auxiliary standby's `-1` never triggers it).

## Default alerts {#default-alerts}

| Metric | Column | Warning | Critical | Occurrences |
| :--- | :--- | :--- | :--- | :---: |
| HADR_Status | `HadrConnectStatus` | `CONGESTED` | `DISCONNECTED` | 1 |
| HADR_Readiness | `TakeoverReady` | Not set | Equal to `0` | 1 |

Both are ordinary Enterprise Manager metric thresholds — edit them per target under **Metric and Collection Settings**, the same way as any other metric. See [Alerts and thresholds](alerts-and-templates.md#tuning-thresholds).

## Known limitation {#known-limitation}

HADR deep monitoring runs against a **live primary+standby pair** — role `PRIMARY`, state `PEER`, connected, standby registered, collected by Enterprise Manager. What has **not yet been exercised is a controlled takeover or failover**: the role change has not been observed end to end. If you run a switchover or failover against a real HADR pair during the beta, that observation is exactly the kind of gap report that matters most right now. See [What's new](whats-new.md#beta-status) and [Trial setup](trial.md#send-us-your-findings).

## Related

- [Monitoring pages](monitoring-pages.md#home) — the HADR Status summary table on Home
- [Alerts and thresholds](alerts-and-templates.md) — tuning the default thresholds above
- [What's new](whats-new.md#beta-status) — the full verification matrix for this release
- [Trial setup](trial.md) — the guided evaluation checklist, including the HADR step
