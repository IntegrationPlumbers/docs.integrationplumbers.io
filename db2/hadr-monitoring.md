---
title: HADR monitoring
nav_order: 8
---

# HADR monitoring

High Availability Disaster Recovery (HADR) pairs get their own page and metric groups beyond the HADR row on the Overview: role, state, sync mode, connect status and heartbeats, log positions, standby lag, and a takeover-readiness composite you can alert on directly, so "is the standby actually ready to take over" is answerable from Enterprise Manager rather than from a manual check on the standby. A standby can be monitored as a target in its own right, and a target can follow whichever side is primary through a takeover.

> **Prerequisites for this page**
> - A database participating in an HADR pair. The HADR metric groups populate only on databases in a pair, and read empty otherwise.
> - The target's licence status is `Active`: see [Troubleshooting](troubleshooting.md#licence-gate).

**Partitioned (DPF) databases:** HADR runs one pair per partition, so the HADR groups are not collected on a DPF database; CollectorStatus reports them as `DISABLED` with that reason ([Metrics reference](metrics-reference.md#dpf)).

**Where to find it:** the target's **High Availability** page; the HADR row of the **Database** card on the **Overview** page; the full column set under **All Metrics → HADR_Status** and **All Metrics → HADR_Readiness**.

**In this page:** The High Availability page · HADR_Status metric group · HADR_Readiness and takeover readiness · Default alerts · Monitoring a standby · Following the primary through a takeover · Associations

## The High Availability page

The target's [High Availability page](monitoring-pages.md#high-availability) answers *can we take over?* Its **Takeover Readiness** tiles count the standbys and how many could take over now, with the worst readiness score, the largest log gap and the largest replay lag. The **Standbys** table shows, per standby, whether it could take over now, a 0–100 readiness score, its state and sync mode, log gap, log received but not yet replayed, replay lag, missed heartbeats, and the reason in plain words. Two charts show the log gap and replay lag per standby over the time window, and the target's incidents sit at the bottom.

The **Database** card on the [Overview](monitoring-pages.md#overview) is the quick-glance view: its HADR row shows the role and state.

## HADR_Status metric group

`HADR_Status` collects every 15 minutes, keyed by database name. Beyond what the Overview shows, it carries local and remote host, service, and instance identity, the HADR timeout in seconds, the primary's log file and page, and the primary and standby log positions in bytes (`HadrPrimaryLogLsn`, `HadrStandbyLogPos`): the detail you need to reason about replay lag rather than just connection health.

**Shipped alert:** `HadrConnectStatus`: Warning when `CONGESTED`, Critical when `DISCONNECTED` (1 occurrence), so it fires within 15 minutes of a pair breaking.

## HADR_Readiness and takeover readiness

`HADR_Readiness` collects every 5 minutes, one row per standby. It adds the composite this page exists for: `TakeoverReady`, a single column that answers whether the standby could actually take over right now, plus log-gap, replay-gap, and replay-lag columns that explain *why* when it cannot.

- `TakeoverReady = 1`: the standby is caught up enough to take over.
- `TakeoverReady = 0`: it is not; check the gap and lag columns for how far behind.
- `TakeoverReady = -1`: the database is an auxiliary standby in a multi-standby configuration, not the one that would be promoted. This value never alerts, because it does not describe a readiness problem.

Three more columns help you read it:

- **`ValuesLive`** is `YES` while the pair is connected. When it reads `NO`, the log gap, received-not-replayed gap and replay lag are **last-known** values: Db2 stops updating them while the pair is disconnected.
- **`StateAlert`** is `OK` when the standby is in the state it should be in: PEER, or REMOTE_CATCHUP under SUPERASYNC; an auxiliary standby is always `OK`. Otherwise it holds the unexpected state, which its alert names.
- **`ReplayOnlyWindow`** reads `Y` while the standby is in a replay-only window (DDL or a maintenance operation replaying from the primary), and the readiness detail names the window. Neither the readiness score nor `TakeoverReady` is affected, because a replay-only window does not stop a takeover.

`TimeSinceLastRecv` is in milliseconds. A 0 means a message arrived within the last second; it is also what Db2 reports while the pair is not connected.

## Default alerts {#default-alerts}

| Metric | Column | Warning | Critical | Occurrences |
| :--- | :--- | :--- | :--- | :---: |
| HADR_Status | `HadrConnectStatus` | `CONGESTED` | `DISCONNECTED` | 1 |
| HADR_Readiness | `TakeoverReady` | Not set | Equal to `0` | 2 |
| HADR_Readiness | `HadrLogGap` | 10 MB | 100 MB | 3 |
| HADR_Readiness | `RecvReplayGap` | 10 MB | 100 MB | 3 |
| HADR_Readiness | `ReplayLagSec` | 60 seconds | 300 seconds | 3 |
| HADR_Readiness | `StateAlert` | Anything but `OK` | Not set | 2 |

A healthy PEER pair measures exactly 0 on every gap and on replay lag, so "not zero" is already abnormal; the byte and second values are the tunable part. All of these are ordinary Enterprise Manager metric thresholds: edit them per target under **Metric and Collection Settings**, the same way as any other metric. See [Alerts and thresholds](alerts-and-templates.md#tuning-thresholds).

## Monitoring a standby {#monitoring-a-standby}

A standby database of an HADR pair can be added as a target in its own right: same type, its own host and port. A standby is **never reported Down for being a standby**. What it reports depends on whether **reads on standby** (`DB2_HADR_ROS=ON` on the standby instance) is enabled:

| Standby | Availability (Response) | Other groups | CollectorStatus |
| :--- | :--- | :--- | :--- |
| **Reads on standby on** | Up (`DB_STATUS` is `STANDBY` or `ACTIVE_STANDBY`) | Collected, read with Uncommitted Read (UR) | `OK` |
| **Reads on standby off** | Up | Not collected: a standby without reads on standby accepts no connections (`SQL1776N` reason 1) | `DISABLED`, with the reason and what to change |
| **In its replay-only window** (reads on standby on) | Up | Not collected this cycle: connections are blocked while the window lasts (`SQL1776N` reason 4) | `DISABLED` until the window closes |

- **No false alerts from a standby.** The groups a standby cannot serve write nothing, so they raise no metric collection errors and no threshold evaluates them.
- **Roles are followed live.** After a takeover, the new primary collects everything on its next collection, and the new standby switches to the behaviour above. The plug-in decides per collection, so there is nothing to refresh.
- **Set the status threshold on a standby target.** `DetailedResponse : db_status` warns on anything but `ACTIVE`. A standby reports `STANDBY`, or `ACTIVE_STANDBY` with reads on standby, so on a standby target set that threshold to its own healthy value:

  ```
  emcli modify_threshold -target_name=<standby target> -target_type=ip_db2_database \
                         -metric=DetailedResponse -column=db_status -warning_threshold=ACTIVE_STANDBY
  ```

- **A standby added while it refuses connections** shows its version as "unknown (HADR standby …)", because the plug-in cannot read it. Once the database is readable (after a takeover, or with reads on standby on), refresh the version with `emctl reload agent dynamicproperties <target>:ip_db2_database` or an agent restart. Until then the version check cannot catch an unsupported Db2 level, so add a standby as a target only if it runs 11.5 or 12.1, as the primary does.

## Following the primary through a takeover {#client-reroute}

By default a target monitors the one database at its Host and Port, so after an HADR takeover it is watching the new standby. To have a target follow whichever side is primary, give it the other side of the pair as an alternate. For a target on the primary `db2host:50000` with its standby on `db2host:25011`:

| Property | Value |
| :--- | :--- |
| HADR Alternate Servers | `db2host` |
| HADR Alternate Ports | `25011` |
| Client Affinities List | `YES` (optional; see below) |

Every collection opens a fresh connection. When the configured server cannot serve it (including an HADR standby, which refuses connections with `SQL1776N`), the driver tries the alternates. So after a takeover the target reads the new primary on its next collection, and after a failback it reads the original one again. This has been verified against a live pair through a takeover and a failback, with every group collected on each side.

- **Client Affinities List = YES** tries the servers in a fixed order: this target's own Host and Port first, then the alternates. The plug-in puts the target's own server at the head of the list for you. With Client Affinities List unset, the driver tries Host and Port first and the alternates only when that fails.
- **Retries** default to 2, 1 second apart, so a pair that is entirely down does not hold every collection.
- **Servers and ports pair by position.** A list that does not pair up (a different count, or a port that is not a number from 1 to 65535) leaves client reroute off, with a warning in the collector log, rather than breaking a target that connects fine without it.
- **Backup age follows the primary too.** Each HADR instance keeps its own recovery history, so after a takeover `DB_Backup` and `DB_History` report the new primary's history. Back up both sides, or expect the backup-age alert after a takeover.
- **Use host names for the alternates.** HADR alternate servers have not been verified with IPv6 addresses.
- **Keep a separate standby target if you also want the standby watched.** A target that follows the primary always shows the primary; the standby's own view needs a target on the standby's host and port without alternates.

## Associations {#associations}

Enterprise Manager links each Db2 target to related targets, which places it in topology views and in the **Related Targets** region on the Overview:

- **`runs_on`**: the database to the host target it runs on, matched from the server name the database reports. No matching host target means no `runs_on`.
- **`depends_on`**: a target with **HADR Alternate Servers / Ports** set (normally the HADR primary) to each Db2 target those alternates name, matched by database name, port and host. These are the same properties that let it follow the primary through a takeover.

Both are derived from the daily configuration collection, so a change to the alternates, or a standby target added later, appears after the primary's next configuration collection.

## Related

- [Monitoring pages](monitoring-pages.md#high-availability): the High Availability page, and the HADR row on the Overview
- [Targets and properties](targets-and-properties.md#target-properties): the client-reroute properties alongside every other target property
- [Alerts and thresholds](alerts-and-templates.md): tuning the default thresholds above, and the HADR runbook
- [Trial setup](trial.md#guided-evaluation): the guided evaluation checklist, including the HADR step
